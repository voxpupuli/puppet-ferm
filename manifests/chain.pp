# defined resource which creates all rules for one chain
# @param policy Set the default policy for a CHAIN
# @param disable_conntrack Disable/Enable usage of conntrack
# @param log_dropped_packets Enable/Disable logging of packets to the kernel log, if no explicit chain matched
# @param chain Name of the chain that should be managed
# @param table Select the target table (filter/raw/mangle/nat)
define ferm::chain (
  Ferm::Policies $policy,
  Boolean $disable_conntrack,
  Boolean $log_dropped_packets,
  String[1] $chain = $name,
  Ferm::Tables $table = 'filter',
) {

  # concat resource for the chain
  if $table == 'filter' {
    $filename = "${ferm::configdirectory}/chains/${chain}.conf"
  } else {
    $filename = "${ferm::configdirectory}/chains/${table}-${chain}.conf"
  }

  concat{$filename:
    ensure  => 'present',
  }

  concat::fragment{"${chain}-policy":
    target  => $filename,
    content => epp(
      "${module_name}/ferm_chain_header.conf.epp", {
        'policy'            => $policy,
        'disable_conntrack' => $disable_conntrack,
      }
    ),
    order   => '01',
  }

  if $log_dropped_packets {
    concat::fragment{"${chain}-footer":
      target  => $filename,
      content => epp("${module_name}/ferm_chain_footer.conf.epp", { 'chain' => $chain }),
      order   => 'zzzzzzzzzzzzzzzzzzzzz',
    }
  }
}
