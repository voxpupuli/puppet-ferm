# @summary Define allowed values for (e.g.) 'daddr' and 'saddr'
#
type Ferm::Address = Variant[
  Array[Ferm::Address],
  Stdlib::IP::Address,
  String[1],
]
