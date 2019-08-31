# @summary a type that allows the default iptables chains
type Ferm::Chains = Enum['INPUT', 'FORWARD', 'OUTPUT']
