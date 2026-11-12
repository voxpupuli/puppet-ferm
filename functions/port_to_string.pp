#
# @summary
#   Transform given Ferm::Port value(s) to String usable with ferm rules
#
# @example ferm::port_to_string(direction, port, negate)
#
#   ferm::port_to_string('destination', '22:222', true)
#   # => "dport !22:222"
#
#   ferm::port_to_string('source', [22, 222], false)
#   # => "mod multiport source-ports (22, 222)"
#
#   ferm::port_to_string('destination')
#   # => ""
#
#   ferm::port_to_string('source', 'foobar')
#   # => "invalid source-port: 'foobar'"
#
# @param direction
#   Either 'destination' or 'source'
#
# @param port
#   Ferm::Port (e.g. 22, '22:222', [ 22, 222 ]
#
# @param negate
#   Negate port/ports
#
# @return
#   String
#
function ferm::port_to_string (
  Enum['destination', 'source'] $direction,
  Optional[Ferm::Port]          $port   = undef,
  Boolean                       $negate = false,
) >> String {
  # can't negate a port not given
  #
  $_negate = if $port and $negate { '!' } else { '' }

  case $port {
    Array: {
      $ports = join($port, ' ')

      "mod multiport ${direction}-ports ${_negate}(${ports})"
    }
    Integer: {
      "${direction[0]}port ${_negate}${port}"
    }
    Pattern[/^\d*:\d+$/]: {
      $portrange = split($port, /:/)

      $lower = if $portrange[0].empty { 0 } else { Integer($portrange[0]) }
      $upper = Integer($portrange[1])

      assert_type(Tuple[Stdlib::Port, Stdlib::Port], [$lower, $upper]) |$expected, $actual| {
        fail("The data type should be \'${expected}\', not \'${actual}\'. The data is [${lower}, ${upper}])}.")
      }

      if $lower > $upper {
        fail("Lower port number of the port range is larger than upper. ${lower}:${upper}")
      }

      "${direction[0]}port ${_negate}${lower}:${upper}"
    }
    Undef: {
      ''
    }
    default: {
      fail("invalid ${direction}-port: ${_negate}${port}")
    }
  }
}
