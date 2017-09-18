require 'spec_helper'

describe 'ferm::chain', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      let(:title) { 'INPUT' }
      let(:params) {{policy: 'DROP'}}

      context 'default params creates INPUT chain' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-policy') }
        it { is_expected.to contain_concat('/etc/ferm.d/chains/INPUT.conf') }
        it { is_expected.to contain_ferm__chain('INPUT') }
      end
    end
  end
end
