# defined resource which creates a single rule in a specific chain
# @param chain Configure the chain where we want to add the rule
# @param policy Configure what we want to do with the packet (drop, accept, log...)
# @param proto Which protocol do we want to match, typically UDP or TCP
# @param comment A comment that will be added to the ferm config and to ip{,6}tables
# @param dport The destination port, can be a range as string or a single port number as integer
# @param sport The source port, can be a range as string or a single port number as integer
# @param saddr The source address we want to match
# @param daddr The destination address we want to match
# @param proto_options Optional parameters that will be passed to the protocol (for example to match specific ICMP types)
# @param ensure Set the rule to present or absent
define ferm::rule (
  Ferm::Chains $chain,
  Ferm::Policies $policy,
  Ferm::Protocols $proto,
  String $comment = $name,
  Optional[Variant[Stdlib::Port,String[1]]] $dport = undef,
  Optional[Variant[Stdlib::Port,String[1]]] $sport = undef,
  Optional[String[1]] $saddr = undef,
  Optional[String[1]] $daddr = undef,
  Optional[String[1]] $proto_options = undef,
  Enum['absent','present'] $ensure = 'present',
){
  $proto_real = "proto ${proto}"

  $dport_real = $dport ? {
    undef   => '',
    default => "dport ${dport}",
  }
  $sport_real = $sport ? {
    undef   => '',
    default => "sport ${sport}",
  }
  $saddr_real = $saddr ? {
    undef   => '',
    default => "saddr @ipfilter(${saddr})",
  }
  $daddr_real = $daddr ? {
    undef   =>  '',
    default => "daddr @ipfilter(${daddr})"
  }
  $proto_options_real = $proto_options ? {
    undef   =>  '',
    default => $proto_options
  }
  $comment_real = "mod comment comment '${comment}'"

  $rule = squeeze("${comment_real} ${proto_real} ${proto_options_real} ${dport_real} ${sport_real} ${daddr_real} ${saddr_real} ${policy};", ' ')
  if $ensure == 'present' {
    concat::fragment{"${chain}-${name}":
      target  => "/etc/ferm.d/chains/${chain}.conf",
      content => "${rule}\n",
    }
  }
}
