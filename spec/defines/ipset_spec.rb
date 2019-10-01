require 'spec_helper'

describe 'ferm::ipset', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      let(:title) { 'INPUT' }

      let :pre_condition do
        'include ferm'
      end

      context 'default params creates INPUT2 chain' do
        let :params do
          {
            sets: {
              office: 'ACCEPT',
              internet: 'DROP'
            }
          }
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
