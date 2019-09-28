# @summary This defined resource manages a single rule in a specific chain
#
# @example Jump to the 'SSH' chain for all incoming SSH traffic (see chain.pp examples on how to create the chain)
#   ferm::rule{'incoming-ssh':
#     chain  => 'INPUT',
#     action => 'SSH',
#     proto  => 'tcp',
#     dport  => '22',
#   }
#
# @example Create a rule in the 'SSH' chain to allow connections from localhost
#   ferm::rule{'allow-ssh-localhost':
#     chain  => 'SSH',
#     action => 'ACCEPT',
#     proto  => 'tcp',
#     dport  => '22',
#     saddr  => '127.0.0.1',
#   }
#
#
# @example Confuse people that do a traceroute/mtr/ping to your system
#   ferm::rule{'drop-icmp-time-exceeded':
#     chain         => 'OUTPUT',
#     policy        => 'DROP',
#     proto         => 'icmp',
#     proto_options => 'icmp-type time-exceeded',
#   }
#
# @example allow multiple protocols
#   ferm::rule{'allow_consul':
#     chain  => 'INPUT',
#     policy => 'ACCEPT',
#     proto  => ['udp', 'tcp'],
#     dport  => 8301,
#   }
#
# @param chain Configure the chain where we want to add the rule
# @param proto Which protocol do we want to match, typically UDP or TCP
# @param comment A comment that will be added to the ferm config and to ip{,6}tables
# @param action Configure what we want to do with the packet (drop/accept/reject, can also be a target chain name)
#   Default value: undef
#   Allowed values: (RETURN|ACCEPT|DROP|REJECT|NOTRACK|LOG|MARK|DNAT|SNAT|MASQUERADE|REDIRECT|String[1])
# @param policy Configure what we want to do with the packet (drop/accept/reject, can also be a target chain name) [DEPRECATED]
#   Default value: undef
#   Allowed values: (RETURN|ACCEPT|DROP|REJECT|NOTRACK|LOG|MARK|DNAT|SNAT|MASQUERADE|REDIRECT|String[1])
# @param dport The destination port, can be a range as string or a single port number as integer
# @param sport The source port, can be a range as string or a single port number as integer
# @param saddr The source address we want to match
# @param daddr The destination address we want to match
# @param proto_options Optional parameters that will be passed to the protocol (for example to match specific ICMP types)
# @param interface an Optional interface where this rule should be applied
# @param outerface an Optional Outerface to match egress packets
# @param table Select the target table (filter/raw/mangle/nat)
#   Default value: filter
#   Allowed values: (filter|raw|mangle|nat) (see Ferm::Tables type)
define ferm::rule (
  String[1] $chain,
  Ferm::Protocols $proto,
  String $comment = $name,
  Optional[Ferm::Actions] $action = undef,
  Optional[Ferm::Policies] $policy = undef,
  Optional[Variant[Stdlib::Port,String[1]]] $dport = undef,
  Optional[Variant[Stdlib::Port,String[1]]] $sport = undef,
  Optional[Variant[Array, String[1]]] $saddr = undef,
  Optional[Variant[Array, String[1]]] $daddr = undef,
  Optional[String[1]] $proto_options = undef,
  Optional[String[1]] $interface = undef,
  Optional[String[1]] $outerface = undef,
  Enum['absent','present'] $ensure = 'present',
  Ferm::Tables $table = 'filter',
){

  if $policy and $action {
    fail('Cannot specify both policy and action. Do not provide policy when using the new action param.')
  } elsif $policy and ! $action {
    warning('The param "policy" is deprecated (superseded by "action") and will be dropped in a future release.')
    $action_temp = $policy
  } elsif $action and ! $policy {
    $action_temp = $action
  } else {
    fail('Exactly one of "action" or the deprecated "policy" param is required.')
  }

  if $action_temp in ['RETURN', 'ACCEPT', 'DROP', 'REJECT', 'NOTRACK', 'LOG',
                      'MARK', 'DNAT', 'SNAT', 'MASQUERADE', 'REDIRECT'] {
    $action_real = $action_temp
  } else {
    # assume the action contains a target chain, so prefix it with the "jump" statement
    $action_real = "jump ${action_temp}"
    # make sure the target chain is created before we try to add rules to it
    Ferm::Chain <| chain == $action_temp and table == $table |> -> Ferm::Rule[$name]
  }

  $proto_real = $proto ? {
    Array  => "proto (${join($proto, ' ')})",
    String => "proto ${proto}",
  }

  $dport_real = $dport ? {
    undef   => '',
    default => "dport ${dport}",
  }
  $sport_real = $sport ? {
    undef   => '',
    default => "sport ${sport}",
  }
  if $saddr =~ Array {
    assert_type(Array[Stdlib::IP::Address], flatten($saddr)) |$expected, $actual| {
      fail( "The data type should be \'${expected}\', not \'${actual}\'. The data is ${flatten($saddr)}." )
        ''
    }
  }
  $saddr_real = $saddr ? {
    undef   => '',
    Array   => "saddr @ipfilter((${join(flatten($saddr).unique, ' ')}))",
    String  => "saddr @ipfilter((${saddr}))",
    default => '',
  }
  if $daddr =~ Array {
    assert_type(Array[Stdlib::IP::Address], flatten($daddr)) |$expected, $actual| {
      fail( "The data type should be \'${expected}\', not \'${actual}\'. The data is ${flatten($daddr)}." )
        ''
    }
  }
  $daddr_real = $daddr ? {
    undef   => '',
    Array   => "daddr @ipfilter((${join(flatten($daddr).unique, ' ')}))",
    String  => "daddr @ipfilter((${daddr}))",
    default => '',
  }
  $outerface_real = $outerface ? {
    undef   => '',
    String  => "outerface ${outerface}",
    default => '',
  }
  $proto_options_real = $proto_options ? {
    undef   =>  '',
    default => $proto_options
  }
  $comment_real = "mod comment comment '${comment}'"

  # prevent unmanaged files due to new naming schema
  # keep the default "filter" chains in the original location
  # only prefix chains in other tables with the table name
  if $table == 'filter' and $chain in ['INPUT', 'FORWARD', 'OUTPUT'] {
    $filename = "${ferm::configdirectory}/chains/${chain}.conf"
  } else {
    $filename = "${ferm::configdirectory}/chains/${table}-${chain}.conf"
  }

  $rule = squeeze("${comment_real} ${proto_real} ${proto_options_real} ${outerface_real} ${dport_real} ${sport_real} ${daddr_real} ${saddr_real} ${action_real};", ' ')
  if $ensure == 'present' {
    if $interface {
      unless defined(Concat::Fragment["${chain}-${interface}-aaa"]) {
        concat::fragment{"${chain}-${interface}-aaa":
          target  => $filename,
          content => "interface ${interface} {\n",
          order   => $interface,
        }
      }

      concat::fragment{"${chain}-${interface}-${name}":
        target  => $filename,
        content => "  ${rule}\n",
        order   => $interface,
      }

      unless defined(Concat::Fragment["${chain}-${interface}-zzz"]) {
        concat::fragment{"${chain}-${interface}-zzz":
          target  => $filename,
          content => "}\n",
          order   => $interface,
        }
      }
    } else {
      concat::fragment{"${chain}-${name}":
        target  => $filename,
        content => "${rule}\n",
      }
    }
  }
}
