# @api private
# This class handles the configuration file. Avoid modifying private classes.
class ferm::install {

  # this is a private class
  assert_private("You're not supposed to do that!")

  package{'ferm':
    ensure => 'latest',
  }
}
