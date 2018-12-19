# defined resource which creates all rules for one chain
# @param policy [Ferm::Policies] Set the default policy for a CHAIN
# @param disable_conntrack [Boolean] disable/enable usage of conntrack
# @param chain [Ferm::Chains] name of the chain that should be managed
# @param log_dropped_packets [Boolean] boolean to enable/disable logging of packets to the kernel log, if no explicit chain matched
define ferm::chain (
  Ferm::Policies $policy,
  Boolean $disable_conntrack,
  Boolean $log_dropped_packets,
  Ferm::Chains $chain = $name,
) {

  # concat resource for the chain
  $filename = downcase($chain)
  concat{"/etc/ferm.d/chains/${chain}.conf":
    ensure  => 'present',
  }

  concat::fragment{"${chain}-policy":
    target  => "/etc/ferm.d/chains/${chain}.conf",
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
      target  => "/etc/ferm.d/chains/${chain}.conf",
      content => epp("${module_name}/ferm_chain_footer.conf.epp", { 'chain' => $chain }),
      order   => '99',
    }
  }
}
