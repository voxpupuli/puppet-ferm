# @summary a list of allowed actions for a rule
type Ferm::Actions = Enum['ACCEPT','DROP', 'REJECT', 'NOTRACK', 'LOG']
