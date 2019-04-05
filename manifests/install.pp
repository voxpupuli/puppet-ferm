# @api private
# This class handles the configuration file. Avoid modifying private classes.
class ferm::install {

  # this is a private class
  assert_private("You're not supposed to do that!")

  package{'ferm':
    ensure => 'latest',
  }

  if $ferm::manage_initfile {
    if $facts['os']['family'] == 'RedHat' and versioncmp($facts['os']['release']['major'], '6') <= 0 {
      file{'/etc/init.d/ferm':
        ensure => 'present',
        mode   => '0755',
        source => "puppet:///modules/${module_name}/ferm",
      }
    }
  }
}
