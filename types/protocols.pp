# @summary a list of allowed protocolls to match
type Ferm::Protocols = Enum['icmp', 'tcp', 'udp', 'udplite', 'icmpv6', 'esp', 'ah', 'sctp', 'mh', 'all']
