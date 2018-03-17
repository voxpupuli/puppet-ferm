require 'spec_helper'

describe 'ferm::chain', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      let(:title) { 'INPUT' }

      context 'default params creates INPUT chain' do
        let :params do
          {
            policy: 'DROP',
            disable_conntrack: false
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat__fragment('INPUT-policy'). \
            with_content(%r{ESTABLISHED RELATED})
        end
        it { is_expected.to contain_concat('/etc/ferm.d/chains/INPUT.conf') }
        it { is_expected.to contain_ferm__chain('INPUT') }
      end

      context 'without conntrack' do
        let :params do
          {
            policy: 'DROP',
            disable_conntrack: true
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat__fragment('INPUT-policy')
          is_expected.not_to contain_concat__fragment('INPUT-policy'). \
            with_content(%r{ESTABLISHED RELATED})
        end
      end
    end
  end
end
