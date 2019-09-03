# @summary a list of allowed actions for a rule
# As you can also *jump* to other chains, each chain-name is also a valid action/target
type Ferm::Actions = Variant[
  Enum['RETURN', 'ACCEPT', 'DROP', 'REJECT', 'NOTRACK', 'LOG', 'MARK', 'DNAT', 'SNAT', 'MASQUERADE', 'REDIRECT'],
  String[1],
]
