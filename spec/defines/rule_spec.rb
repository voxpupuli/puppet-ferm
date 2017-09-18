require 'spec_helper'

describe 'ferm::rule', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      let(:title) { 'filter-ssh' }
      let :params do
        {
          chain: 'INPUT',
          policy: 'ACCEPT',
          proto: 'tcp',
          dport: '22',
          saddr: '127.0.0.1'
        }
      end

      context 'default params create simple rule' do
        it { is_expected.to compile.with_all_deps }
        #it { is_expected.to contain_concat__fragment('INPUT-filter-ssh').with_content("proto tcp dport ssh  saddr @ipfilter(127.0.0.1)  ACCEPT;") }
        it { is_expected.to contain_concat__fragment('INPUT-filter-ssh') }
      end
    end
  end
end
