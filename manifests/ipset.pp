#
# @summary a defined resource that can match for ipsets at the top of a chain. This is a per-chain resource. You cannot mix IPv4 and IPv6 sets.
#
# @see http://ferm.foo-projects.org/download/2.1/ferm.html#set
#
# @example
#   ferm::ipset { 'CONSUL':
#     sets => {
#       'internet' => 'ACCEPT'
#     },
#   }
#
# @example create to matches for IPv6, both at the end of the `INPUT` chain. Explicitly mention the `filter` table.
#   ferm::ipset { 'INPUT':
#     prepend_to_chain => false,
#     table            => 'filter',
#     ip_version       => 'ip6',
#     sets             => {
#       'testset01'      => 'ACCEPT',
#       'anothertestset' => 'DROP'
#     },
#   }
#
# @param chain
#   name of the chain we want to apply those rules to. The name of the defined resource will be used as default value for this.
#
# @param table
#   name of the table where we want to apply  this. Defaults to `filter` because that's the most common usecase.
#
# @param ip_version
#   sadly, ip sets are version specific. You cannot mix IPv4 and IPv6 addresses. Because of this you need to provide the version.
#
# @param sets
#   A hash with multiple sets. For each hash you can provide an action like `DROP` or `ACCEPT`.
#
define ferm::ipset (
  Hash[String[1], Ferm::Actions] $sets,
  String[1]                      $chain            = $name,
  Ferm::Tables                   $table            = 'filter',
  Enum['ip','ip6']               $ip_version       = 'ip',
  Boolean                        $prepend_to_chain = true,
) {

  $suffix = $prepend_to_chain ? {
    true  => 'aaa',
    false => 'ccc',
  }

  # make sure the generated snippet is actually included
  concat::fragment{"${table}-${chain}-${name}":
    target  => $ferm::configfile,
    content => epp(
      "${module_name}/ferm-chain-ipset.epp", {
        'ip'    => $ip_version,
        'table' => $table,
        'chain' => $chain,
        'sets'  => $sets,
      }
    ),
    order   => "${table}-${chain}-${suffix}",
  }
}
