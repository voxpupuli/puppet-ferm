# @summary This defined resource manages a single rule in a specific chain
#
# @example Jump to the 'SSH' chain for all incoming SSH traffic (see chain.pp examples on how to create the chain)
#   ferm::rule{'incoming-ssh':
#     chain  => 'INPUT',
#     action => 'SSH',
#     proto  => 'tcp',
#     dport  => 22,
#   }
#
# @example Create a rule in the 'SSH' chain to allow connections from localhost
#   ferm::rule{'allow-ssh-localhost':
#     chain  => 'SSH',
#     action => 'ACCEPT',
#     proto  => 'tcp',
#     dport  => 22,
#     saddr  => '127.0.0.1',
#   }
#
#
# @example Confuse people that do a traceroute/mtr/ping to your system
#   ferm::rule{'drop-icmp-time-exceeded':
#     chain         => 'OUTPUT',
#     action        => 'DROP',
#     proto         => 'icmp',
#     proto_options => 'icmp-type time-exceeded',
#   }
#
# @example allow multiple protocols
#   ferm::rule{'allow_consul':
#     chain  => 'INPUT',
#     action => 'ACCEPT',
#     proto  => ['udp', 'tcp'],
#     dport  => 8301,
#   }
#
# @param chain Configure the chain where we want to add the rule
# @param proto Which protocol do we want to match, typically UDP or TCP
# @param comment A comment that will be added to the ferm config and to ip{,6}tables
# @param action Configure what we want to do with the packet (drop/accept/reject, can also be a target chain name). The parameter is mandatory.
#   Allowed values: (RETURN|ACCEPT|DROP|REJECT|NOTRACK|LOG|MARK|DNAT|SNAT|MASQUERADE|REDIRECT|String[1])
# @param dport The destination port, can be a single port number as integer or an Array of integers (which will then use the multiport matcher)
# @param sport The source port, can be a single port number as integer or an Array of integers (which will then use the multiport matcher)
# @param saddr The source address we want to match
# @param daddr The destination address we want to match
# @param proto_options Optional parameters that will be passed to the protocol (for example to match specific ICMP types)
# @param interface an Optional interface where this rule should be applied
# @param ensure Set the rule to present or absent
# @param table Select the target table (filter/raw/mangle/nat)
#   Default value: filter
#   Allowed values: (filter|raw|mangle|nat) (see Ferm::Tables type)
# @param negate Single keyword or array of keywords to negate
#   Default value: undef
#   Allowed values: (saddr|daddr|sport|dport) (see Ferm::Negation type)
define ferm::rule (
  String[1] $chain,
  Ferm::Protocols $proto,
  Ferm::Actions $action,
  String $comment = $name,
  Optional[Ferm::Port] $dport = undef,
  Optional[Ferm::Port] $sport = undef,
  Optional[Variant[Array, String[1]]] $saddr = undef,
  Optional[Variant[Array, String[1]]] $daddr = undef,
  Optional[String[1]] $proto_options = undef,
  Optional[String[1]] $interface = undef,
  Enum['absent','present'] $ensure = 'present',
  Ferm::Tables $table = 'filter',
  Optional[Ferm::Negation] $negate = undef,
) {
  if $action in ['RETURN', 'ACCEPT', 'DROP', 'REJECT', 'NOTRACK', 'LOG', 'MARK', 'DNAT', 'SNAT', 'MASQUERADE', 'REDIRECT'] {
    $action_real = $action
  } else {
    # assume the action contains a target chain, so prefix it with the "jump" statement
    $action_real = "jump ${action}"
    # make sure the target chain is created before we try to add rules to it
    Ferm::Chain <| chain == $action and table == $table |> -> Ferm::Rule[$name]
  }

  $proto_real = $proto ? {
    Array   => "proto (${join($proto, ' ')})",
    String  => "proto ${proto}",
    Integer => "proto ${proto}",
  }

  # convert String to Array to equally handle both cases
  $_negate = [$negate].flatten.unique

  $negate_saddr = 'saddr' in $_negate ? { true => '!', false => '', }
  $negate_daddr = 'daddr' in $_negate ? { true => '!', false => '', }
  $negate_sport = 'sport' in $_negate ? { true => '!', false => '', }
  $negate_dport = 'dport' in $_negate ? { true => '!', false => '', }

  if $dport =~ Array {
    $dports = join($dport, ' ')
    $dport_real = "mod multiport destination-ports ${negate_dport}(${dports})"
  } elsif $dport =~ Integer {
    $dport_real = "dport ${negate_dport}${dport}"
  } elsif String($dport) =~ /^\d*:\d+$/ {
    $portrange = split($dport, /:/)
    $lower = $portrange[0] ? {
      ''      => 0,
      default => Integer($portrange[0]),
    }
    $upper = Integer($portrange[1])
    assert_type(Tuple[Stdlib::Port, Stdlib::Port], [$lower, $upper]) |$expected, $actual| {
      fail("The data type should be \'${expected}\', not \'${actual}\'. The data is [${lower}, ${upper}])}.")
      ''
    }
    if $lower > $upper {
      fail("Lower port number of the port range is larger than upper. ${lower}:${upper}")
    }
    $dport_real = "dport ${negate_dport}${lower}:${upper}"
  } elsif String($dport) == '' {
    $dport_real = ''
  } else {
    fail("invalid destination-port: ${negate_dport}${dport}")
  }

  if $sport =~ Array {
    $sports = join($sport, ' ')
    $sport_real = "mod multiport source-ports ${negate_sport}(${sports})"
  } elsif $sport =~ Integer {
    $sport_real = "sport ${negate_sport}${sport}"
  } elsif String($sport) =~ /^\d*:\d+$/ {
    $portrange = split($sport, /:/)
    $lower = $portrange[0] ? {
      ''      => 0,
      default => Integer($portrange[0]),
    }
    $upper = Integer($portrange[1])
    assert_type(Tuple[Stdlib::Port, Stdlib::Port], [$lower, $upper]) |$expected, $actual| {
      fail("The data type should be \'${expected}\', not \'${actual}\'. The data is [${lower}, ${upper}])}.")
      ''
    }
    if $lower > $upper {
      fail("Lower port number of the port range is larger than upper. ${lower}:${upper}")
    }
    $sport_real = "sport ${negate_sport}${lower}:${upper}"
  } elsif String($sport) == '' {
    $sport_real = ''
  } else {
    fail("invalid source-port: ${sport}")
  }

  if $saddr =~ Array {
    assert_type(Array[Stdlib::IP::Address], flatten($saddr)) |$expected, $actual| {
      fail( "The data type should be \'${expected}\', not \'${actual}\'. The data is ${flatten($saddr)}." )
      ''
    }
  }
  $saddr_real = $saddr ? {
    undef   => '',
    Array   => "saddr ${negate_saddr}@ipfilter((${join(flatten($saddr).unique, ' ')}))",
    String  => "saddr ${negate_saddr}@ipfilter((${saddr}))",
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
    Array   => "daddr ${negate_daddr}@ipfilter((${join(flatten($daddr).unique, ' ')}))",
    String  => "daddr ${negate_daddr}@ipfilter((${daddr}))",
    default => '',
  }
  $proto_options_real = $proto_options ? {
    undef   => '',
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

  $rule = squeeze("${comment_real} ${proto_real} ${proto_options_real} ${dport_real} ${sport_real} ${daddr_real} ${saddr_real} ${action_real};", ' ')
  if $ensure == 'present' {
    if $interface {
      unless defined(Concat::Fragment["${chain}-${interface}-aaa"]) {
        concat::fragment { "${chain}-${interface}-aaa":
          target  => $filename,
          content => "interface ${interface} {\n",
          order   => $interface,
        }
      }

      concat::fragment { "${chain}-${interface}-${name}":
        target  => $filename,
        content => "  ${rule}\n",
        order   => $interface,
      }

      unless defined(Concat::Fragment["${chain}-${interface}-zzz"]) {
        concat::fragment { "${chain}-${interface}-zzz":
          target  => $filename,
          content => "}\n",
          order   => $interface,
        }
      }
    } else {
      concat::fragment { "${chain}-${name}":
        target  => $filename,
        content => "${rule}\n",
      }
    }
  }
}
