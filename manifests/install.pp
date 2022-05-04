#
# @api private
#
# @summary This class handles the configuration file. Avoid modifying private classes.
#
class ferm::install {
  # this is a private class
  assert_private("You're not supposed to do that!")

  case $ferm::install_method {
    'package': {
      package { 'ferm':
        ensure => $ferm::package_ensure,
      }
    }
    'vcsrepo': {
      $_source_path = '/opt/ferm'
      ensure_packages (['git', 'iptables', 'perl', 'make'], { ensure => present })

      package { 'ferm':
        ensure => absent,
      }
      -> vcsrepo { $_source_path :
        ensure   => present,
        provider => git,
        source   => $ferm::vcsrepo,
        revision => $ferm::vcstag,
      }
      -> exec { 'make install':
        cwd     => $_source_path,
        path    => '/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/core_perl/pod2text', # pod2text on arch is in a subdir
        creates => '/usr/sbin/ferm',
      }
      -> file { '/etc/ferm':
        ensure => directory,
        owner  => 0,
        group  => 0,
        mode   => '0700',
      }
    }
    default: {
      fail("unexpected install_method ${ferm::install_method}")
    }
  }
}
