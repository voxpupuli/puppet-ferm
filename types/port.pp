# @summary ferm port-spec
#
# allowed variants:
# -----------------
# + single Integer port
# + Array of Integers (creates a multiport matcher)
# + ferm range port-spec (pair of colon-separated integer, assumes 0 if first is omitted)
type Ferm::Port = Variant[
  Stdlib::Port,
  Array[Stdlib::Port],
  Pattern['^\d*:\d+$'],
]
