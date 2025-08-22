# frozen_string_literal: true

require 'spec_helper'

describe 'Ferm::Addr_Type' do
  describe 'valid values' do
    %w[
      ANYCAST
      BLACKHOLE
      BROADCAST
      LOCAL
      MULTICAST
      NAT
      PROHIBIT
      THROW
      UNICAST
      UNREACHABLE
      UNSPEC
      XRESOLVE
    ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid values' do
    context 'with garbage inputs' do
      [
        # :symbol, # this should not match but seems liks String[1] allows it?
        # nil,     # this should not match but seems liks String[1] allows it?
        '',
        true,
        false,
        %w[meep meep],
        65_538,
        [95_000, 67_000],
        {},
        { 'foo' => 'bar' },
        %w[MYFANCYCUSTOMCHAINNAMEISALSOVALID],
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
