# @api private
# This class handles the configuration file. Avoid modifying private classes.
class ferm::service {

  # this is a private class
  assert_private("You're not supposed to do that!")

  if $ferm::manage_service {
    service{'ferm':
      ensure => 'running',
      enable => true,
    }

    # on Ubuntu, we can't start the service, unless we set ENABLED=true in /etc/default/ferm...
    if ($facts['os']['name'] == 'Ubuntu') {
      file_line{'enable_ferm':
        path  => '/etc/default/ferm',
        line  => 'ENABLED="yes"',
        match => 'ENABLED=',
      }
    }
  }
}
