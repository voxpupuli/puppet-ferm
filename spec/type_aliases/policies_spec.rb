# frozen_string_literal: true

require 'spec_helper'

describe 'Ferm::Policies' do
  describe 'valid values' do
    %w[
      ACCEPT
      DROP
    ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid values' do
    context 'with garbage inputs' do
      [
        'RETURN',
        'REJECT',
        'foobar',
        :symbol,
        nil,
        '',
        true,
        false,
        %w[meep meep],
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
