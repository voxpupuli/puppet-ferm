# @api private
# This class handles the configuration file. Avoid modifying private classes.
class ferm::config {

  # this is a private class
  assert_private("You're not supposed to do that!")

  $_ip = join($ferm::ip_versions, ' ')

  # copy static files to ferm
  # on a long term point of view, we want to package this
  file{$ferm::configdirectory:
    ensure => 'directory',
  }
  -> file{"${ferm::configdirectory}/definitions":
    ensure => 'directory',
  }
  -> file{"${ferm::configdirectory}/chains":
    ensure => 'directory',
  }

  if $ferm::manage_configfile {
    concat{$ferm::configfile:
      ensure  => 'present',
    }
    concat::fragment{'ferm_header.conf':
      target  => $ferm::configfile,
      content => epp("${module_name}/ferm_header.conf.epp", {'configdirectory' => $ferm::configdirectory}),
      order   => '01',
    }

    concat::fragment{'ferm.conf':
      target  => $ferm::configfile,
      content => epp(
        "${module_name}/ferm.conf.epp", {
          'ip'                        => $_ip,
          'configdirectory'           => $ferm::configdirectory,
          'preserve_chains_in_tables' => $ferm::preserve_chains_in_tables,
          }
      ),
      order   => '50',
    }
  }

  ferm::chain{'INPUT':
    policy              => $ferm::input_policy,
    disable_conntrack   => $ferm::disable_conntrack,
    log_dropped_packets => $ferm::input_log_dropped_packets,
  }
  ferm::chain{'FORWARD':
    policy              => $ferm::forward_policy,
    disable_conntrack   => $ferm::disable_conntrack,
    log_dropped_packets => $ferm::forward_log_dropped_packets,
  }
  ferm::chain{'OUTPUT':
    policy              => $ferm::output_policy,
    disable_conntrack   => $ferm::disable_conntrack,
    log_dropped_packets => $ferm::output_log_dropped_packets,
  }

  # initialize default tables and chains
  ['PREROUTING', 'OUTPUT'].each |$raw_chain| {
    ferm::chain{"raw-${raw_chain}":
      chain               => $raw_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'raw',
    }
  }
  ['PREROUTING', 'INPUT', 'OUTPUT', 'POSTROUTING'].each |$nat_chain| {
    ferm::chain{"nat-${nat_chain}":
      chain               => $nat_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'nat',
    }
  }
  ['PREROUTING', 'INPUT', 'FORWARD', 'OUTPUT', 'POSTROUTING'].each |$mangle_chain| {
    ferm::chain{"mangle-${mangle_chain}":
      chain               => $mangle_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'mangle',
    }
  }
}
