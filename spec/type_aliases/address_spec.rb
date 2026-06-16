# frozen_string_literal: true

require 'spec_helper'

describe 'Ferm::Address' do
  describe 'valid values' do
    [
      ['10.0.0.0/8', ['10.0.0.1', '10.0.0.2'], %w[string]], # Array[Ferm::Address]
      '10.0.0.3',                                           # Stdlib::IP::Address
      %w[string],                                           # String[1]
    ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid values' do
    context 'with garbage inputs' do
      [
        '',
        true,
        false,
        65_538,
        [95_000, 67_000],
        {},
        { 'foo' => 'bar' },
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
