#
# @api private
#
# @summary This class handles the configuration file. Avoid modifying private classes.
#
class ferm::config {
  # this is a private class
  assert_private("You're not supposed to do that!")

  $_ip = join($ferm::ip_versions, ' ')

  if $facts['systemd'] { #fact provided by systemd module
    if $ferm::install_method == 'vcsrepo' and $ferm::manage_service {
      systemd::dropin_file { 'ferm.conf':
        unit    => 'ferm.service',
        content => epp("${module_name}/dropin_ferm.conf.epp"),
        before  => Service['ferm'],
      }
    }
  }

  # copy static files to ferm
  # on a long term point of view, we want to package this
  file { $ferm::configdirectory:
    ensure => 'directory',
  }
  -> file { "${ferm::configdirectory}/definitions":
    ensure => 'directory',
  }
  -> file { "${ferm::configdirectory}/chains":
    ensure => 'directory',
  }

  if $ferm::manage_configfile {
    concat { $ferm::configfile:
      ensure => 'present',
    }
    concat::fragment { 'ferm_header.conf':
      target  => $ferm::configfile,
      content => epp("${module_name}/ferm_header.conf.epp", { 'configdirectory' => $ferm::configdirectory }),
      order   => '01',
    }

    concat::fragment { 'ferm.conf':
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

  ferm::chain { 'INPUT':
    policy                              => $ferm::input_policy,
    disable_conntrack                   => $ferm::input_disable_conntrack,
    log_dropped_packets                 => $ferm::input_log_dropped_packets,
    drop_invalid_packets_with_conntrack => $ferm::input_drop_invalid_packets_with_conntrack,
  }
  ferm::chain { 'FORWARD':
    policy              => $ferm::forward_policy,
    disable_conntrack   => $ferm::forward_disable_conntrack,
    log_dropped_packets => $ferm::forward_log_dropped_packets,
  }
  ferm::chain { 'OUTPUT':
    policy              => $ferm::output_policy,
    disable_conntrack   => $ferm::output_disable_conntrack,
    log_dropped_packets => $ferm::output_log_dropped_packets,
  }

  # some default chains and features depend on support from the kernel
  $kver = $facts['kernelversion']

  # initialize default tables and chains
  ['PREROUTING', 'OUTPUT'].each |$raw_chain| {
    ferm::chain { "raw-${raw_chain}":
      chain               => $raw_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'raw',
    }
  }
  ['PREROUTING', 'INPUT', 'OUTPUT', 'POSTROUTING'].each |$nat_chain| {
    if versioncmp($kver, '3.17.0') >= 0 {
      # supports both nat INPUT chain and ip6table_nat
      $domains = $ferm::ip_versions
    } elsif versioncmp($kver, '2.6.36') >= 0 {
      # supports nat INPUT chain, but not ip6table_nat
      if ('ip6' in $ferm::ip_versions and 'ip' in $ferm::ip_versions) {
        $domains = ['ip']
      }
    } else {
      # supports neither nat INPUT nor ip6table_nat
      if $nat_chain == 'INPUT' { next() }
      if ('ip6' in $ferm::ip_versions and 'ip' in $ferm::ip_versions) {
        $domains = ['ip']
      }
    }
    ferm::chain { "nat-${nat_chain}":
      chain               => $nat_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'nat',
      ip_versions         => $domains,
    }
  }
  ['PREROUTING', 'INPUT', 'FORWARD', 'OUTPUT', 'POSTROUTING'].each |$mangle_chain| {
    ferm::chain { "mangle-${mangle_chain}":
      chain               => $mangle_chain,
      policy              => 'ACCEPT',
      disable_conntrack   => true,
      log_dropped_packets => false,
      table               => 'mangle',
    }
  }
}
