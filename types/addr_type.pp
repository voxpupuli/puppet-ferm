# @summary Define allowed match types
#
# - https://ipset.netfilter.org/iptables-extensions.man.html
#
type Ferm::Addr_Type = Enum[
  'ANYCAST',
  'BLACKHOLE',
  'BROADCAST',
  'LOCAL',
  'MULTICAST',
  'NAT',
  'PROHIBIT',
  'THROW',
  'UNICAST',
  'UNREACHABLE',
  'UNSPEC',
  'XRESOLVE',
]
