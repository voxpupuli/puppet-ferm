# @summary a list of allowed protocolls to match
type Ferm::Protocols = Variant[
  Integer[0, 255],
  Array[Integer[0, 255]],
  Enum['icmp', 'tcp', 'udp', 'udplite', 'icmpv6', 'esp', 'ah', 'sctp', 'mh', 'all'],
  Array[Enum['icmp', 'tcp', 'udp', 'udplite', 'icmpv6', 'esp', 'ah', 'sctp', 'mh', 'all']],
]
