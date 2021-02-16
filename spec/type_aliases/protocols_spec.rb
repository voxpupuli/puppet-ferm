# rubocop:disable Style/WordArray, Style/TrailingCommaInLiteral
require 'spec_helper'

describe 'Ferm::Protocols' do
  describe 'valid values' do
    [
      'icmp',
      'tcp',
      'udp',
      'udplite',
      'icmpv6',
      'esp',
      'ah',
      'sctp',
      'mh',
      'all',
      ['icmp', 'tcp', 'udp'],
      0,
      [0, 4],
    ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid values' do
    context 'with garbage inputs' do
      [
        :symbol,
        nil,
        'foobar',
        '',
        true,
        false,
        ['meep', 'meep'],
        65_538,
        [95_000, 67_000],
        {},
        { 'foo' => 'bar' },
        256,
        ['icmp', 256],
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
