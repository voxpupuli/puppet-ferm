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

You can easily define rules in Puppet (they don't need to be exported resources):

```puppet
  @@ferm::rule{"allow_kafka_server2server-${trusted['certname']}":
    chain  => 'INPUT',
    policy => 'ACCEPT',
    proto  => 'tcp',
    dport  => '(9092 9093)',
    saddr  => "(${facts['networking']['ip6']}/128 ${facts['networking']['ip']}/32)",
    tag    => 'allow_kafka_server2server',
  }
```

You can collect them like this:

```puppet
# collect all exported resources with the tag allow_vault_server2server
Ferm::Rule <<| tag == 'allow_kafka_server2server' |>>
```

You can also define rules in hiera:

```yaml
---
ferm::rules:
  'allow_http_https':
    chain: 'INPUT'
    policy: 'ACCEPT'
    proto: 'tcp'
    dport: '(80 443)'
    saddr: "%{hiera('some_other_hiera_key')}"
```

ferm::rules is a hash. configured for deep merge. Hiera will collect all
defined hashes and hand them over to the class. The main class will create
rules for all of them. It also collects all exported resources that are tagged
with the FQDN of a box.

## Reference

### Main class

The main class has the following parameters:

#### `manage_service`

[Boolean] disable/enable the management of the ferm daemon

#### `manage_configfile`

[Boolean] disable/enable the management of the ferm default config

#### `manage_initfile`

[Boolean] disable/enable the management of the ferm init script for RedHat-based OS

#### `configfile`

[Stdlib::Absolutepath] path to the config file

#### `forward_policy`

[Ferm::Policies] default policy for the FORWARD chain

#### `output_policy`

[Ferm::Policies] default policy for the OUTPUT chain

#### `input_policy`

[Ferm::Policies] default policy for the INPUT chain

#### `rules`

A hash that holds all data for ferm::rule

### rule defined resource

This creates an entry in the correct chain file for ferm.

#### `chain`

The chain where we place this rule

#### `policy`

The desired policy. Allowed values are Enum['ACCEPT','DROP', 'REJECT']

#### `protocol`

the protocol we would like to filter. Allowed values are Enum['icmp', 'tcp', 'udp']

### `proto_options`

The protocol options we would like to add.
The following example will suppress the hostname in programs like `traceroute`:
```yaml
---
ferm::rules:
  'drop_output_traceroute':
    chain: 'OUTPUT'
    policy: 'DROP'
    proto: 'icmp'
    proto_options: 'icmp-type time-exceeded'
```

#### `comment`

A comment that will be written into the file and into ip(6)tables

#### `dport`

The destination port we want to filter for. Can be any string from /etc/services or an integer

#### `sport`

Like the destination port above, just for the source port

#### `saddr`

Source IPv4/IPv6 address. Can be one or many of them. Multiple addresses are
always encapsulated in braces:
'(127.0.0.1 2003::)'

IPv4 and IPv6 addresses can be mixed. CIDR notation is possible if you want to
block networks, otherwise /32 or /128 is assumed by ferm/ip(6)tables

#### `daddr`

Same as above, just for the destination IP address

#### `ensure`

Add or remove it from the ruleset

#### `interface`

If set, this rule only applies to this specific interface

### chain defined resource

The module defines the three default chains for you, INPUT, FORWARD and OUTPUT.
You're able to define own chains if you want to

#### `policy`

The desired default policy for the chain

#### `chain`

The name of the chain

## Development

This project contains tests for [rspec-puppet](http://rspec-puppet.com/).

Quickstart to run all linter and unit tests:

```bash
bundle install --path .vendor/ --without system_tests --without development --without release
bundle exec rake test
```

## Authors

puppet-ferm is maintained by [Vox Pupuli](https://voxpupuli.org), it was written by [Tim 'bastelfreak' Meusel](https://github.com/bastelfreak).
