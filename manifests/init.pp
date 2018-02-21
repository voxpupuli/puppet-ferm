# Class: ferm
#
# This class manages ferm installation and rule generation on modern linux systems
#
# @example deploy ferm and start it
# class{'ferm':
#   manage_service =>  true,
# }
#
# @param manage_service [Boolean] disable/enable the management of the ferm daemon
#   Default value: false
#   Allowed values: (true|false)
# @param manage_configfile [Boolean] disable/enable the management of the ferm default config
#   Default value: false
#   Allowed values: (true|false)
# @param configfile [Stdlib::Absolutepath] path to the config file
#   Default value: /etc/ferm.conf
#   Allowed values: Stdlib::Absolutepath
# @param forward_policy [Ferm::Policies] default policy for the FORWARD chain
#   Default value: DROP
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param output_policy [Ferm::Policies] default policy for the OUTPUT chain
#   Default value: ACCEPT
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param input_policy [Ferm::Policies] default policy for the INPUT chain
#   Default value: DROP
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param rules a hash that holds all data for ferm::rule
#   Default value: Empty Hash
#   Allowed value: Any Hash
class ferm (
  Boolean $manage_service,
  Boolean $manage_configfile,
  Stdlib::Absolutepath $configfile,
  Ferm::Policies $forward_policy,
  Ferm::Policies $output_policy,
  Ferm::Policies $input_policy,
  Hash $rules,
) {
  contain ferm::install
  contain ferm::config
  contain ferm::service

  Class['ferm::install']
  -> Class['ferm::config']
  ~> Class['ferm::service']

  $rules.each |$rulename, $attributes| {
    ferm::rule{$rulename:
      * => $attributes,
    }
  }
  # import all exported resources with ferm rules for this node
  Ferm::Rule <<| tag == $trusted['certname'] |>>
}
