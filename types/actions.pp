# @summary a list of allowed actions for a rule
#
type Ferm::Actions = Enum['RETURN', 'ACCEPT', 'DROP', 'REJECT', 'NOTRACK', 'LOG', 'MARK', 'DNAT', 'SNAT', 'MASQUERADE', 'REDIRECT']
