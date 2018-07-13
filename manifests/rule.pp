define ferm::rule (
  Ferm::Chains $chain,
  Ferm::Policies $policy,
  Ferm::Protocols $proto,
  String $comment = $name,
  Optional[Variant[Integer,String]] $dport = undef,
  Optional[Variant[Integer,String]] $sport = undef,
  Optional[String] $saddr = undef,
  Optional[String] $daddr = undef,
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
