# @summary list of keywords that support negation
type Ferm::Negation = Variant[
  Enum['saddr', 'daddr', 'sport', 'dport'],
  Array[Enum['saddr', 'daddr', 'sport', 'dport']],
]
