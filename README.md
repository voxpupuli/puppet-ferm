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

You can also define rules in Hiera. Make sure to use `alias()` as interpolation function, because `hiera()` will always return a string.

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
    dport: '(80 443)'
    saddr: "%{alias('subnets')}"
```

ferm::rules is a hash. configured for deep merge. Hiera will collect all
defined hashes and hand them over to the class. The main class will create
rules for all of them. It also collects all exported resources that are tagged
with the FQDN of a box.

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
