# frozen_string_literal: true

require 'spec_helper'

describe 'ferm::rule', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let :pre_condition do
        'include ferm'
      end

      context 'without action' do
        let(:title) { 'filter-ssh' }
        let :params do
          {
            chain: 'INPUT',
            proto: 'tcp',
            dport: 22,
            saddr: '127.0.0.1'
          }
        end

        it { is_expected.not_to compile }
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

      context 'without a specific interface using array for daddr with negation' do
        let(:title) { 'filter-ssh-negated' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: 22,
            daddr: ['127.0.0.1', '123.123.123.123', ['10.0.0.1', '10.0.0.2']],
            negate: %w[saddr daddr sport]
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-ssh-negated').with_content("mod comment comment 'filter-ssh-negated' proto tcp dport 22 daddr !@ipfilter((127.0.0.1 123.123.123.123 10.0.0.1 10.0.0.2)) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
        it { is_expected.to contain_concat__fragment('filter-OUTPUT-config-include') }
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

      context 'with a valid destination-port range with negation of destination-port and source-address' do
        let(:title) { 'filter-portrange-negated' }
        let :params do
          {
            chain: 'INPUT',
            action: 'ACCEPT',
            proto: 'tcp',
            dport: '20000:25000',
            saddr: '127.0.0.1',
            negate: %w[saddr dport]
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('INPUT-filter-portrange-negated').with_content("mod comment comment 'filter-portrange-negated' proto tcp dport !20000:25000 saddr !@ipfilter((127.0.0.1)) ACCEPT;\n") }
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
          expect(subject).to contain_concat__fragment('INPUT-filter-ssh'). \
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

      context 'with outerface on forward chain with jump action' do
        let(:title) { 'filter_FORWARD_jump_DOCKER' }
        let :params do
          {
            proto: 'all',
            table: 'filter',
            chain: 'FORWARD',
            outerface: 'docker0',
            action: 'DOCKER',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('FORWARD-filter_FORWARD_jump_DOCKER').with_content("mod comment comment 'filter_FORWARD_jump_DOCKER' proto all outerface docker0 jump DOCKER;\n") }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
      end

      context 'with saddr_type LOCAL jump to DOCKER chain' do
        let(:title) { 'saddr_type_local_jump_docker' }
        let :params do
          {
            proto: 'all',
            table: 'nat',
            chain: 'OUTPUT',
            saddr_type: 'LOCAL',
            action: 'DOCKER',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('OUTPUT-saddr_type_local_jump_docker').with_content("mod comment comment 'saddr_type_local_jump_docker' proto all mod addrtype src-type LOCAL jump DOCKER;\n") }
        it { is_expected.to contain_concat__fragment('nat-OUTPUT-config-include') }
      end

      context 'with daddr_type LOCAL jump to DOCKER chain' do
        let(:title) { 'daddr_type_local_jump_docker' }
        let :params do
          {
            proto: 'all',
            table: 'nat',
            chain: 'OUTPUT',
            daddr: '127.0.0.0/8',
            daddr_type: 'LOCAL',
            action: 'DOCKER',
            negate: %w[daddr]
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('OUTPUT-daddr_type_local_jump_docker').with_content("mod comment comment 'daddr_type_local_jump_docker' proto all daddr !@ipfilter((127.0.0.0/8)) mod addrtype dst-type LOCAL jump DOCKER;\n") }
        it { is_expected.to contain_concat__fragment('nat-OUTPUT-config-include') }
      end

      context 'with outerface docker0 matching ctstates' do
        let(:title) { 'filter_FORWARD_ctstate_accept' }
        let :params do
          {
            proto: 'all',
            table: 'filter',
            chain: 'FORWARD',
            ctstate: %w[RELATED ESTABLISHED],
            outerface: 'docker0',
            action: 'ACCEPT',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('FORWARD-filter_FORWARD_ctstate_accept').with_content("mod comment comment 'filter_FORWARD_ctstate_accept' proto all outerface docker0 mod conntrack ctstate (RELATED ESTABLISHED) ACCEPT;\n") }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-config-include') }
      end
    end
  end
end
