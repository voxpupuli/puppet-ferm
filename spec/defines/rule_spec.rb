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

      context 'without policy or action' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Exactly one of "action" or the deprecated "policy" param is required}) }
      end

      context 'with both policy and action' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            policy: 'ACCEPT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Cannot specify both policy and action}) }
      end

      context 'with outerface on input chain' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            saddr: '127.0.0.1',
            outerface: 'eth1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Outgoing interface can only be set in the "FORWARD", "OUTPUT" and "POSTROUTING" chains}) }
      end

      context 'with to_source when action is not SNAT' do
        let(:title) { 'snat-ssh' }
        let :params do
          {
            chain: 'POSTROUTING',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            saddr: '127.0.0.1',
            to_source: '192.168.1.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Setting new source address is only valid with the "SNAT" action}) }
      end

      context 'with to_destination when action is not DNAT' do
        let(:title) { 'dnat-ssh' }
        let :params do
          {
            chain: 'PREROUTING',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '22',
            daddr: '172.16.0.1',
            to_destination: '192.168.1.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Setting new destination address is only valid with the "DNAT" action}) }
      end

      context 'without a specific interface using legacy policy param' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            policy: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-ssh').with_content("mod comment comment 'filter-ssh' proto tcp dport 22 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
      end

      context 'without a specific interface' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-ssh').with_content("mod comment comment 'filter-ssh' proto tcp dport 22 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
        it { is_expected.to contain_concat__fragment('filter-OUTPUT-config-include') }
      end

      context 'with a specific interface' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
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
            dport: 22,
            daddr: ['127.0.0.1', '123.123.123.123', ['10.0.0.1', '10.0.0.2']],
            interface: 'eth0'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-filter-ssh').with_content("  mod comment comment 'filter-ssh' proto tcp dport 22 daddr @ipfilter((127.0.0.1 123.123.123.123 10.0.0.1 10.0.0.2)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-aaa').with_content("interface eth0 {\n") }
        it { is_expected.to contain_concat__fragment('INPUT-eth0-zzz').with_content("}\n") }
      end

      context 'without a specific interface using array for proto' do
        let(:title) { 'filter-consul' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: %w[tcp udp],
            dport: [8301, 8302],
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-consul').with_content("mod comment comment 'filter-consul' proto (tcp udp) mod multiport destination-ports (8301 8302) saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
        it { is_expected.to contain_concat__fragment('filter-OUTPUT-config-include') }
      end

      context 'with a valid destination-port range' do
        let(:title) { 'filter-portrange' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '20000:25000',
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-portrange').with_content("mod comment comment 'filter-portrange' proto tcp dport 20000:25000 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
        it { is_expected.to contain_concat__fragment('filter-OUTPUT-config-include') }
      end

      context 'with a malformed source-port range' do
        let(:title) { 'filter-malformed-portrange' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            sport: '25000:20000',
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Lower port number of the port range is larger than upper. 25000:20000}) }
      end

      context 'with an invalid destination-port range' do
        let(:title) { 'filter-invalid-portrange' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '50000:65538',
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{The data type should be 'Tuple\[Stdlib::Port, Stdlib::Port\]', not 'Tuple\[Integer\[50000, 50000\], Integer\[65538, 65538\]\]'. The data is \[50000, 65538\]}) }
      end

      context 'with an invalid destination-port string' do
        let(:title) { 'filter-invalid-portnumber' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '65538',
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{parameter 'dport' expects a Ferm::Port .* value, got String}) }
      end

      context 'with an invalid source-port number' do
        let(:title) { 'filter-invalid-portnumber' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            sport: 65_538,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{parameter 'sport' expects a Ferm::Port .* value, got Integer}) }
      end

      context 'with jumping to custom chains' do
        # create custom chain
        let(:pre_condition) do
          'include ferm ;
          ferm::chain{"check-ssh":
            chain               => "SSH",
            disable_conntrack   => true,
            log_dropped_packets => false,
          }'
        end
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            action: 'SSH',
            proto: 'tcp',
            dport: 22
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('filter-SSH-policy') }
        it do
          is_expected.to contain_concat__fragment('INPUT-filter-ssh').\
            with_content("mod comment comment 'filter-ssh' proto tcp dport 22 jump SSH;\n"). \
            that_requires('Ferm::Chain[check-ssh]')
        end
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        if facts[:os]['name'] == 'Debian'
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/filter-SSH.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.d/chains/filter-SSH.conf') }
        end
      end

      context 'definining rules in custom chains' do
        # create custom chain
        let(:pre_condition) do
          'include ferm ;
          ferm::chain{"check-ssh":
            chain               => "SSH",
            disable_conntrack   => true,
            log_dropped_packets => false,
          }'
        end
        let(:title) { 'allow-ssh-localhost' }
        let :params do
          {
            chain: 'SSH',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('SSH-allow-ssh-localhost').with_content("mod comment comment 'allow-ssh-localhost' proto tcp dport 22 saddr @ipfilter((127.0.0.1)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('filter-SSH-config-include') }
      end

      context 'source nat with outerface and to_source' do
        let(:title) { 'source-nat' }
        let :params do
          {
            chain: 'POSTROUTING',
            action: 'SNAT',
            proto: 'all',
            saddr: '172.16.0.0/24',
            outerface: 'eth1',
            to_source: '192.168.1.1',
            table: 'nat'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('POSTROUTING-source-nat').with_content("mod comment comment 'source-nat' proto all saddr @ipfilter((172.16.0.0/24)) outerface eth1 SNAT to @ipfilter((192.168.1.1));\n") }
        it { is_expected.to contain_concat__fragment('nat-POSTROUTING-config-include') }
      end

      context 'destination nat with to_destination' do
        let(:title) { 'destination-nat' }
        let :params do
          {
            chain: 'PREROUTING',
            action: 'DNAT',
            proto: 'tcp',
            daddr: '172.16.0.1',
            to_destination: '192.168.1.1',
            table: 'nat'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('PREROUTING-destination-nat').with_content("mod comment comment 'destination-nat' proto tcp daddr @ipfilter((172.16.0.1)) DNAT to-destination @ipfilter((192.168.1.1));\n") }
        it { is_expected.to contain_concat__fragment('nat-PREROUTING-config-include') }
      end
    end
  end
end
