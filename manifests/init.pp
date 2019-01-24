# Class: ferm
#
# This class manages ferm installation and rule generation on modern linux systems
#
# @example deploy ferm and start it, on node with only ipv6 enabled
# class{'ferm':
#   manage_service => true,
#   ip_versions    =>  ['ip6'],
# }
#
# @param manage_service Disable/Enable the management of the ferm daemon
#   Default value: false
#   Allowed values: (true|false)
# @param manage_configfile Disable/Enable the management of the ferm default config
#   Default value: false
#   Allowed values: (true|false)
# @param configfile Path to the config file
#   Default value: /etc/ferm.conf
#   Allowed values: Stdlib::Absolutepath
# @param disable_conntrack Disable/Enable the generation of conntrack rules
#   Default value: false
#   Allowed values: (true|false)
# @param forward_policy Default policy for the FORWARD chain
#   Default value: DROP
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param output_policy Default policy for the OUTPUT chain
#   Default value: ACCEPT
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param input_policy Default policy for the INPUT chain
#   Default value: DROP
#   Allowed values: (ACCEPT|DROP|REJECT)
# @param rules A hash that holds all data for ferm::rule
#   Default value: Empty Hash
#   Allowed value: Any Hash
# @param forward_log_dropped_packets Enable/Disable logging in the FORWARD chain of packets to the kernel log, if no explicit chain matched
#   Default value: false
#   Allowed values: (true|false)
# @param output_log_dropped_packets Enable/Disable logging in the OUTPUT chain of packets to the kernel log, if no explicit chain matched
#   Default value: false
#   Allowed values: (true|false)
# @param input_log_dropped_packets Enable/Disable logging in the INPUT chain of packets to the kernel log, if no explicit chain matched
#   Default value: false
#   Allowed values: (true|false)
# @param ip_versions Set list of versions of ip we want ot use.
#   Default value: ['ip', 'ip6']
class ferm (
  Boolean $manage_service,
  Boolean $manage_configfile,
  Stdlib::Absolutepath $configfile,
  Boolean $disable_conntrack,
  Ferm::Policies $forward_policy,
  Ferm::Policies $output_policy,
  Ferm::Policies $input_policy,
  Boolean $forward_log_dropped_packets,
  Boolean $output_log_dropped_packets,
  Boolean $input_log_dropped_packets,
  Hash $rules,
  Array[Enum['ip','ip6']] $ip_versions,
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
