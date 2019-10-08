# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v2.6.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.6.0) (2019-10-08)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.5.0...v2.6.0)

**Implemented enhancements:**

- implement ipset support [\#80](https://github.com/voxpupuli/puppet-ferm/pull/80) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- ipset: allow multiple instances of defined resource [\#85](https://github.com/voxpupuli/puppet-ferm/pull/85) ([bastelfreak](https://github.com/bastelfreak))
- disable conntrack filtering in FORWARD/OUTPUT [\#81](https://github.com/voxpupuli/puppet-ferm/pull/81) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- update docker firewalling example [\#84](https://github.com/voxpupuli/puppet-ferm/pull/84) ([bastelfreak](https://github.com/bastelfreak))
- delete legacy docs/ folder [\#83](https://github.com/voxpupuli/puppet-ferm/pull/83) ([bastelfreak](https://github.com/bastelfreak))
- move common from hiera data values to init.pp [\#75](https://github.com/voxpupuli/puppet-ferm/pull/75) ([Dan33l](https://github.com/Dan33l))

## [v2.5.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.5.0) (2019-09-13)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.4.0...v2.5.0)

**Implemented enhancements:**

- Add more examples [\#73](https://github.com/voxpupuli/puppet-ferm/pull/73) ([foxxx0](https://github.com/foxxx0))
- expose parameter to initialize custom chains [\#68](https://github.com/voxpupuli/puppet-ferm/pull/68) ([foxxx0](https://github.com/foxxx0))
- allow using an array for $proto [\#67](https://github.com/voxpupuli/puppet-ferm/pull/67) ([foxxx0](https://github.com/foxxx0))
- add ability to configure rules in tables other than the default "filter" table [\#58](https://github.com/voxpupuli/puppet-ferm/pull/58) ([foxxx0](https://github.com/foxxx0))

**Fixed bugs:**

- idempotency issue with CentOS6 since module version 2.2.0 [\#63](https://github.com/voxpupuli/puppet-ferm/issues/63)
- unable to configure Debian OSes [\#60](https://github.com/voxpupuli/puppet-ferm/issues/60)
- fix kernel incompatibilities [\#72](https://github.com/voxpupuli/puppet-ferm/pull/72) ([foxxx0](https://github.com/foxxx0))
- Fix config handling and caching on Debian [\#69](https://github.com/voxpupuli/puppet-ferm/pull/69) ([bastelfreak](https://github.com/bastelfreak))
- add missing status option for CentOS 6 init script [\#65](https://github.com/voxpupuli/puppet-ferm/pull/65) ([Dan33l](https://github.com/Dan33l))

**Closed issues:**

- Please support JUMP. [\#61](https://github.com/voxpupuli/puppet-ferm/issues/61)

**Merged pull requests:**

- enhance puppet-strings documentation [\#71](https://github.com/voxpupuli/puppet-ferm/pull/71) ([bastelfreak](https://github.com/bastelfreak))
- drop Debian from supported OSes [\#62](https://github.com/voxpupuli/puppet-ferm/pull/62) ([Dan33l](https://github.com/Dan33l))
- enable acceptance and drop EOL ubuntu1404 [\#59](https://github.com/voxpupuli/puppet-ferm/pull/59) ([Dan33l](https://github.com/Dan33l))

## [v2.4.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.4.0) (2019-09-02)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.3.0...v2.4.0)

**Implemented enhancements:**

- allow preserving of chains in tables [\#55](https://github.com/voxpupuli/puppet-ferm/pull/55) ([bastelfreak](https://github.com/bastelfreak))
- Add Debian 10 support & make configdirectory configureable [\#54](https://github.com/voxpupuli/puppet-ferm/pull/54) ([bastelfreak](https://github.com/bastelfreak))
- allow all supported iptables protocolls & enhance puppet-strings documentation Unverified [\#52](https://github.com/voxpupuli/puppet-ferm/pull/52) ([bastelfreak](https://github.com/bastelfreak))
- Allow array for saddr and daddr [\#51](https://github.com/voxpupuli/puppet-ferm/pull/51) ([kBite](https://github.com/kBite))

**Merged pull requests:**

- remove FreeBSD from supported OS list [\#53](https://github.com/voxpupuli/puppet-ferm/pull/53) ([bastelfreak](https://github.com/bastelfreak))

## [v2.3.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.3.0) (2019-07-12)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.2.0...v2.3.0)

**Implemented enhancements:**

- add support for interface specific rules [\#48](https://github.com/voxpupuli/puppet-ferm/pull/48) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- Allow puppetlabs/concat 6.x, puppetlabs/stdlib 6.x [\#46](https://github.com/voxpupuli/puppet-ferm/pull/46) ([dhoppe](https://github.com/dhoppe))

**Merged pull requests:**

- add `managed by puppet` header to template [\#47](https://github.com/voxpupuli/puppet-ferm/pull/47) ([bastelfreak](https://github.com/bastelfreak))

## [v2.2.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.2.0) (2019-04-05)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.1.0...v2.2.0)

**Implemented enhancements:**

- Add RedHat init script [\#43](https://github.com/voxpupuli/puppet-ferm/pull/43) ([kBite](https://github.com/kBite))

## [v2.1.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.1.0) (2019-03-14)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v2.0.0...v2.1.0)

**Implemented enhancements:**

- add 'all' to protocols [\#40](https://github.com/voxpupuli/puppet-ferm/pull/40) ([kBite](https://github.com/kBite))
- enhance type validation; require stdlib 4.25.0 [\#39](https://github.com/voxpupuli/puppet-ferm/pull/39) ([bastelfreak](https://github.com/bastelfreak))

## [v2.0.0](https://github.com/voxpupuli/puppet-ferm/tree/v2.0.0) (2019-01-24)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.4.0...v2.0.0)

**Breaking changes:**

- modulesync 2.5.1 and drop Puppet4 [\#36](https://github.com/voxpupuli/puppet-ferm/pull/36) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- permit to choose ipv4, ipv6 or both [\#35](https://github.com/voxpupuli/puppet-ferm/pull/35) ([Dan33l](https://github.com/Dan33l))

## [v1.4.0](https://github.com/voxpupuli/puppet-ferm/tree/v1.4.0) (2018-12-20)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.3.2...v1.4.0)

**Implemented enhancements:**

- Implement logging to kernel log [\#32](https://github.com/voxpupuli/puppet-ferm/pull/32) ([bastelfreak](https://github.com/bastelfreak))

## [v1.3.2](https://github.com/voxpupuli/puppet-ferm/tree/v1.3.2) (2018-10-05)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.3.1...v1.3.2)

**Merged pull requests:**

- allow puppet 6.x and  puppetlabs/concat 5.x [\#27](https://github.com/voxpupuli/puppet-ferm/pull/27) ([bastelfreak](https://github.com/bastelfreak))

## [v1.3.1](https://github.com/voxpupuli/puppet-ferm/tree/v1.3.1) (2018-08-31)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.3.0...v1.3.1)

**Merged pull requests:**

- allow puppetlabs/stdlib 5.x [\#24](https://github.com/voxpupuli/puppet-ferm/pull/24) ([bastelfreak](https://github.com/bastelfreak))

## [v1.3.0](https://github.com/voxpupuli/puppet-ferm/tree/v1.3.0) (2018-07-13)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.2.0...v1.3.0)

**Implemented enhancements:**

- Add `proto\_options` to enable usage of icmp types [\#20](https://github.com/voxpupuli/puppet-ferm/pull/20) ([kBite](https://github.com/kBite))
- Add official ubuntu support [\#17](https://github.com/voxpupuli/puppet-ferm/pull/17) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- ferm fails to apply changed/new rules on Ubuntu 16.04 [\#16](https://github.com/voxpupuli/puppet-ferm/issues/16)

**Merged pull requests:**

- Remove docker nodesets [\#15](https://github.com/voxpupuli/puppet-ferm/pull/15) ([bastelfreak](https://github.com/bastelfreak))
- drop EOL OSs; fix puppet version range [\#13](https://github.com/voxpupuli/puppet-ferm/pull/13) ([bastelfreak](https://github.com/bastelfreak))

## [v1.2.0](https://github.com/voxpupuli/puppet-ferm/tree/v1.2.0) (2018-03-17)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/v1.1.1...v1.2.0)

**Implemented enhancements:**

- Make usage of conntrack optional [\#9](https://github.com/voxpupuli/puppet-ferm/issues/9)
- introduce parameter disable\_conntrack [\#10](https://github.com/voxpupuli/puppet-ferm/pull/10) ([kBite](https://github.com/kBite))

## [v1.1.1](https://github.com/voxpupuli/puppet-ferm/tree/v1.1.1) (2018-03-15)

[Full Changelog](https://github.com/voxpupuli/puppet-ferm/compare/2d355a4c1baadc761d6b12645d0274da8866f722...v1.1.1)

**Merged pull requests:**

- release 1.1.1 [\#8](https://github.com/voxpupuli/puppet-ferm/pull/8) ([bastelfreak](https://github.com/bastelfreak))
- add notice about older releases [\#7](https://github.com/voxpupuli/puppet-ferm/pull/7) ([bastelfreak](https://github.com/bastelfreak))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
