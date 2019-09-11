# @summary a list of allowed protocolls to match
type Ferm::Protocols = Variant[
  Enum['icmp', 'tcp', 'udp', 'udplite', 'icmpv6', 'esp', 'ah', 'sctp', 'mh', 'all'],
  Array[Enum['icmp', 'tcp', 'udp', 'udplite', 'icmpv6', 'esp', 'ah', 'sctp', 'mh', 'all']],
]
