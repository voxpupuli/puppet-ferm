require 'spec_helper'

describe 'ferm::rule', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end

      let :pre_condition do
        'include ferm'
      end

      context 'without a specific interface' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-ssh').with_content("mod comment comment 'filter-ssh' proto tcp dport 22 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
      end
      context 'with a specific interface' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            saddr: '127.0.0.1',
            interface: 'eth0'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-filter-ssh').with_content("  mod comment comment 'filter-ssh' proto tcp dport 22 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-aaa').with_content("interface eth0 {\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-zzz').with_content("}\n") }
      end
      context 'with a specific interface using array for daddr' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            daddr: ['127.0.0.1', '123.123.123.123', ['10.0.0.1', '10.0.0.2']],
            interface: 'eth0'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-filter-ssh').with_content("  mod comment comment 'filter-ssh' proto tcp dport 22 daddr @ipfilter((127.0.0.1 123.123.123.123 10.0.0.1 10.0.0.2)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-aaa').with_content("interface eth0 {\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-zzz').with_content("}\n") }
      end
    end
  end
end
