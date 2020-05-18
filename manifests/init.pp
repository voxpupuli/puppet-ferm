# @summary This class manages ferm installation and rule generation on modern linux systems
#
# @example deploy ferm without any configured rules, but also don't start the service or modify existing config files
#   include ferm
#
# @example deploy ferm and start it, on nodes with only ipv6 enabled
#   class{'ferm':
#     manage_service  => true,
#     ip_versions     => ['ip6'],
#   }
#
# @example deploy ferm and don't touch chains from other software, like fail2ban and docker
#   class{'ferm':
#     manage_service            => true,
#     preserve_chains_in_tables => {
#       'filter' => [
#         'f2b-sshd',
#         'DOCKER',
#         'DOCKER-ISOLATION-STAGE-1',
#         'DOCKER-ISOLATION-STAGE-2',
#         'DOCKER-USER',
#         'FORWARD',
#       ],
#       'nat' => [
#         'DOCKER',
#       ],
#     },
#   }
#
# @param manage_service Disable/Enable the management of the ferm daemon
# @param manage_configfile Disable/Enable the management of the ferm default config
# @param manage_initfile Disable/Enable the management of the ferm init script for RedHat-based OS
# @param configfile Path to the config file
# @param configdirectory Path to the directory where the module stores ferm configuration files
# @param forward_disable_conntrack Enable/Disable the generation of conntrack rules for the FORWARD chain
# @param output_disable_conntrack Enable/Disable the generation of conntrack rules for the OUTPUT chain
# @param input_disable_conntrack Enable/Disable the generation of conntrack rules for the INPUT chain
# @param forward_policy Default policy for the FORWARD chain
# @param output_policy Default policy for the OUTPUT chain
# @param input_policy Default policy for the INPUT chain
# @param input_drop_invalid_packets_with_conntrack Enable/Disable the `mod conntrack ctstate INVALID DROP` statement. Only works if `$disable_conntrack` is `false`. You can set this to false if your policy is DROP. This only effects the INPUT chain.
# @param rules A hash that holds all data for ferm::rule
# @param chains A hash that holds all data for ferm::chain
# @param forward_log_dropped_packets Enable/Disable logging in the FORWARD chain of packets to the kernel log, if no explicit chain matched
# @param output_log_dropped_packets Enable/Disable logging in the OUTPUT chain of packets to the kernel log, if no explicit chain matched
# @param input_log_dropped_packets Enable/Disable logging in the INPUT chain of packets to the kernel log, if no explicit chain matched
# @param ip_versions Set list of versions of ip we want ot use.
# @param preserve_chains_in_tables Hash with table:chains[] to use ferm @preserve for (since ferm v2.4)
#   Example: {'nat' => ['PREROUTING', 'POSTROUTING']}
# @param install_method method used to install ferm
# @param vcsrepo git repository where ferm sources are hosted
# @param vcstag git tag used when install_method is vcsrepo
class ferm (
  Stdlib::Absolutepath $configfile,
  Stdlib::Absolutepath $configdirectory,
  Boolean $manage_service = false,
  Boolean $manage_configfile = false,
  Boolean $manage_initfile = false,
  Boolean $forward_disable_conntrack = true,
  Boolean $output_disable_conntrack = true,
  Boolean $input_disable_conntrack = false,
  Ferm::Policies $forward_policy = 'DROP',
  Ferm::Policies $output_policy = 'ACCEPT',
  Ferm::Policies $input_policy = 'DROP',
  Boolean $forward_log_dropped_packets = false,
  Boolean $output_log_dropped_packets = false,
  Boolean $input_log_dropped_packets = false,
  Boolean $input_drop_invalid_packets_with_conntrack = false,
  Hash $rules = {},
  Hash $chains = {},
  Array[Enum['ip','ip6']] $ip_versions = ['ip','ip6'],
  Hash[String[1],Array[String[1]]] $preserve_chains_in_tables = {},
  Enum['package','vcsrepo'] $install_method = 'package',
  Stdlib::HTTPSUrl $vcsrepo = 'https://github.com/MaxKellermann/ferm.git',
  String[1] $vcstag = 'v2.5.1',
) {
  contain ferm::install
  contain ferm::config
  contain ferm::service

  Class['ferm::install']
  -> Class['ferm::config']
  ~> Class['ferm::service']

  Ferm::Chain <| |>
  ~> Class['ferm::service']

  $chains.each |$chainname, $attributes| {
    ferm::chain{$chainname:
      * => $attributes,
    }
  }

  $rules.each |$rulename, $attributes| {
    ferm::rule{$rulename:
      * => $attributes,
    }
  }
  # import all exported resources with ferm rules for this node
  Ferm::Rule <<| tag == $trusted['certname'] |>>
}
