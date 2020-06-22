# puppet-ferm

[![Build Status](https://travis-ci.org/voxpupuli/puppet-ferm.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-ferm)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/ferm.svg)](https://forge.puppetlabs.com/puppet/ferm)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/ferm.svg)](https://forge.puppetlabs.com/puppet/ferm)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/ferm.svg)](https://forge.puppetlabs.com/puppet/ferm)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/ferm.svg)](https://forge.puppetlabs.com/puppet/ferm)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://voxpupuli.org/puppet-ferm)
[![AGPL v3 License](https://img.shields.io/github/license/voxpupuli/puppet-ferm.svg)](LICENSE)

## Table of Contents

* [Overview](#overview)
* [What happened to older releases?](#what-happenend-to-older-releases)
* [Setup](#setup)
* [Examples](#examples)
* [Support](#support)
* [Reference](#reference)
* [Development](#development)
* [Authors](#authors)

----

## Overview

This module manages the [ferm](http://ferm.foo-projects.org/) firewalling
software. It allows you to configure the actual software, but also all related
rules.

## What happened to older releases?

You maybe wonder what happend to release 1.1.0 and 1.0.0. We had to take them
down because they contained sensitive information.

## Setup

This is very easy:

```puppet
include ferm
```

This will install the package, but nothing more. It won't explicitly enable it
or write any rules. Be careful here: The default Debian package enabled
autostart for the service and only allows incoming SSH/IPSec connections.

It is also possible to install ferm from sources:
```puppet
class {'ferm':
  install_method = 'vcsrepo',
}
```

When `install_method` is `vcsrepo`, the `git` binary is required, this module should handle Git installation.

When `install_method` is `vcsrepo` with `vcstag` >= `v2.5` ferm call "legacy" xtables tools because nft based tools are incompatible.

You can easily define rules in Puppet (they don't need to be exported resources):

```puppet
  @@ferm::rule{"allow_kafka_server2server-${trusted['certname']}":
    chain  => 'INPUT',
    policy => 'ACCEPT',
    proto  => 'tcp',
    dport  => [9092, 9093],
    saddr  => "(${facts['networking']['ip6']}/128 ${facts['networking']['ip']}/32)",
    tag    => 'allow_kafka_server2server',
  }
```

You can collect them like this:

```puppet
# collect all exported resources with the tag allow_vault_server2server
Ferm::Rule <<| tag == 'allow_kafka_server2server' |>>
```

You can also define rules in Hiera. Make sure to use `alias()` as interpolation
function, because `hiera()` will always return a string.

```yaml
---
subnet01: '123.123.123.0/24'
subnet02: '123.123.124.0/24'
subnet03:
 - '123.123.125.0/24'
 - '123.123.126.0/24'

subnets:
  - "%{alias('subnet01')}"
  - "%{alias('subnet02')}"
  - "%{alias('subnet03')}"
  - 123.123.127.0/24

ferm::rules:
  'allow_http_https':
    chain: 'INPUT'
    policy: 'ACCEPT'
    proto: 'tcp'
    dport:
      - 80
      - 443
    saddr: "%{alias('subnets')}"
```

ferm::rules is a hash. configured for deep merge. Hiera will collect all
defined hashes and hand them over to the class. The main class will create
rules for all of them. It also collects all exported resources that are tagged
with the FQDN of a box.

It's also possible to match against [ipsets](http://ipset.netfilter.org/). This
allows to easily match against a huge amount of IP addresses or network ranges.
You can use this as follows:

```puppet
ferm::ipset { 'INPUT':
  sets => {
   'office'   => 'ACCPET',
   'internet' => 'DROP',
  }
}
```

please see the [references](#reference) section for more examples.

## Examples

### disable conntrack for all non-local destinations (e.g. for hypervisors)

General best practices for firewalling recommend that you use explicit whitelisting.
Usually this boils down to configuring your firewall in a stateful manner, i.e. allowing `ESTABLISHED` and `RELATED` connections in addition to some whitelisted ports (i.e. TCP/22 for SSHD, likely limited to certain source addresses).
For this to work you need connection tracking, provided by the `nf_conntrack` kernel module and configurable via the iptables `conntrack` module.
However, especially in virtualization environments, you do not want to track *every* connection being routed through the hypervisor.
You only want to track connections directly addressed to the hypervisor itself, i.e. traffic ending up in the `filter/INPUT` chain, but not traffic that is later going through `filter/FORWARD` to guest systems.
Unfortunately the `ferm` tool does not allow negating lists (i.e. `@ipfilter()`) and thus we cannot easily negate `saddr` or `daddr` params, which forces us to configure two rules instead of one.

Connection tracking can only be controlled in the `PREROUTING` chain of the `raw` table.

```yaml
ferm::rules:
  'allow_conntrack_local':
    chain: 'PREROUTING'
    table: 'raw'
    proto: 'all'
    daddr:
      - "%{facts.ipaddress}"
      - "%{facts.ipaddress6}"
    action: 'RETURN'
  'disable_conntrack_nonlocal':
    chain: 'PREROUTING'
    table: 'raw'
    proto: 'all'
    action: 'NOTRACK'
    interface: "%{facts.networking.primary}"
```

The upper `RETURN` rule will stop evaluating further rules in the `PREROUTING` chain of the `raw` table if the traffic is addressed directly to the current node applying the catalogue.
The second rule will disable connection tracking for all other traffic coming in over the primary network interface, that is not addressed directly to the current node, i.e. guest systems hosted on it.

This will prevent your conntrack table from overflowing, tracking only the relevant connections and allowing you to use a stateful ruleset.

#### create a custom chain, e.g. for managing custom FORWARD chain rule for OpenVPN using custom ferm DSL.

```puppet
$my_rules = @(EOT)
chain OPENVPN_FORWORD_RULES {
  proto udp {
    interface tun0 {
      outerface enp4s0 {
        mod conntrack ctstate (NEW) saddr @ipfilter((10.8.0.0/24)) ACCEPT;
      }
    }
  }
}
| EOT

ferm::chain{'OPENVPN_FORWORD_RULES':
  chain   => 'OPENVPN_FORWORD_RULES',
  content => $my_rules,
}

ferm::rule { "OpenVPN - FORWORD all udp traffic from network 10.8.0.0/24 to subchain OPENVPN_FORWORD_RULES":
  chain     => 'FORWARD',
  action    => 'OPENVPN_FORWORD_RULES',
  saddr     => '10.8.0.0/24',
  proto     => 'udp',
}
```

## Reference

All parameters are documented within the classes. We generate markdown
documentation. It's available in the [REFERENCE.md](REFERENCE.md). It also
contains many examples.

## Development

This project contains tests for [rspec-puppet](http://rspec-puppet.com/).

Quickstart to run all linter and unit tests:

```bash
bundle install --path .vendor/ --without system_tests --without development --without release
bundle exec rake test
```

For more details about the development workflow and on how to contribute,
please check the [CONTRIBUTING.md](.github/CONTRIBUTING.md).

## Authors

puppet-ferm is maintained by [Vox Pupuli](https://voxpupuli.org), it was written
by [Tim 'bastelfreak' Meusel](https://github.com/bastelfreak).
