# @api private
# This class handles the configuration file. Avoid modifying private classes.
class ferm::config {

  # this is a private class
  assert_private("You're not supposed to do that!")

  $_ip = join($ferm::ip_versions, ' ')

  # copy static files to ferm
  # on a long term point of view, we want to package this
  file{'/etc/ferm.d':
    ensure => 'directory',
  }
  -> file{'/etc/ferm.d/definitions':
    ensure => 'directory',
  }
  -> file{'/etc/ferm.d/chains':
    ensure => 'directory',
  }

  if $ferm::manage_configfile {
    concat{$ferm::configfile:
      ensure  => 'present',
    }
    concat::fragment{'ferm_header.conf':
      target  => $ferm::configfile,
      content => epp("${module_name}/ferm_header.conf.epp"),
      order   => '01',
    }

    concat::fragment{'ferm.conf':
      target  => $ferm::configfile,
      content => epp(
        "${module_name}/ferm.conf.epp", {
          'ip' => $_ip,
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
}
