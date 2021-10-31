# frozen_string_literal: true

require 'spec_helper'

describe 'Ferm::Port' do
  describe 'valid values' do
    [
      17,
      65_535,
      '25:30',
      ':22',
      [80, 443, 8080, 8443],
    ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid values' do
    context 'with garbage inputs' do
      [
        'asdf',
        true,
        false,
        :symbol,
        %w[meep meep],
        65_538,
        [95_000, 67_000],
        '12345',
        '20:22:23',
        '1024:',
        'ネット',
        nil,
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
