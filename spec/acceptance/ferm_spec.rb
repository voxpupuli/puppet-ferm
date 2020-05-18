require 'spec_helper_acceptance'

os_name = fact('os.name')
os_release = fact('os.release.major')

sut_os = "#{os_name}-#{os_release}"

manage_initfile = case sut_os
                  when 'CentOS-6'
                    true
                  else
                    false
                  end

iptables_output = case sut_os
                  when 'Debian-10'
                    [
                      '-A INPUT -p tcp -m tcp --dport 22 -m comment --comment allow_acceptance_tests -j ACCEPT',
                      '-A INPUT -p tcp -m tcp --dport 80 -m comment --comment jump_http -j HTTP',
                      '-A HTTP -s 127.0.0.1/32 -p tcp -m tcp --dport 80 -m comment --comment allow_http_localhost -j ACCEPT'
                    ]
                  else
                    [
                      '-A INPUT -p tcp -m comment --comment ["]*allow_acceptance_tests["]* -m tcp --dport 22 -j ACCEPT',
                      '-A INPUT -p tcp -m comment --comment ["]*jump_http["]* -m tcp --dport 80 -j HTTP',
                      '-A HTTP -s 127.0.0.1/32 -p tcp -m comment --comment ["]*allow_http_localhost["]* -m tcp --dport 80 -j ACCEPT'
                    ]
                  end

iptables_output_custom = ['-A FORWARD -s 10.8.0.0/24 -p udp -m comment --comment "OpenVPN - FORWORD all udp traffic from network 10.8.0.0/24 to subchain OPENVPN_FORWORD_RULES" -j OPENVPN_FORWORD_RULES',
                          '-A OPENVPN_FORWORD_RULES -s 10.8.0.0/24 -i tun0 -o enp4s0 -p udp -m conntrack --ctstate NEW -j ACCEPT']

basic_manifest = %(
  class { 'ferm':
    manage_service    => true,
    manage_configfile => true,
    manage_initfile   => #{manage_initfile}, # CentOS-6 does not provide init script
    forward_policy    => 'DROP',
    output_policy     => 'ACCEPT',
    input_policy      => 'DROP',
    rules             => {
      'allow_acceptance_tests' => {
        chain  => 'INPUT',
        action => 'ACCEPT',
        proto  => tcp,
        dport  => 22,
      },
    },
    ip_versions      => ['ip'], #only ipv4 available with CI
  }
)

describe 'ferm' do
  context 'with basics settings' do
    pp = basic_manifest

    it 'works with no error' do
      apply_manifest(pp, catch_failures: true)
    end
    it 'works idempotently' do
      apply_manifest(pp, catch_changes: true)
    end

    describe package('ferm') do
      it { is_expected.to be_installed }
    end

    describe service('ferm') do
      it { is_expected.to be_running }
    end

    describe command('iptables-save') do
      its(:stdout) { is_expected.to match %r{.*filter.*:INPUT DROP.*:FORWARD DROP.*:OUTPUT ACCEPT.*}m }
      its(:stdout) { is_expected.not_to match %r{state INVALID -j DROP} }
    end

    describe iptables do
      it do
        is_expected.to have_rule(iptables_output[0]). \
          with_table('filter'). \
          with_chain('INPUT')
      end
    end

    context 'with custom chains' do
      advanced_manifest = %(
        ferm::chain { 'check-http':
          chain               => 'HTTP',
          disable_conntrack   => true,
          log_dropped_packets => false,
        }
        ferm::rule { 'jump_http':
          chain             => 'INPUT',
          action            => 'HTTP',
          proto             => 'tcp',
          dport             => '80',
          require           => Ferm::Chain['check-http'],
        }
        ferm::rule { 'allow_http_localhost':
          chain             => 'HTTP',
          action            => 'ACCEPT',
          proto             => 'tcp',
          dport             => '80',
          saddr             => '127.0.0.1',
          require           => Ferm::Chain['check-http'],
        }
      )
      pp = [basic_manifest, advanced_manifest].join("\n")

      it 'works with no error' do
        apply_manifest(pp, catch_failures: true)
      end
      it 'works idempotently' do
        apply_manifest(pp, catch_changes: true)
      end

      describe iptables do
        it do
          is_expected.to have_rule(iptables_output[1]). \
            with_table('filter'). \
            with_chain('INPUT')
        end
        it do
          is_expected.to have_rule(iptables_output[2]). \
            with_table('filter'). \
            with_chain('HTTP')
        end
      end
    end

    context 'with dropping INVALID packets' do
      pp2 = %(
        class { 'ferm':
          manage_service                            => true,
          manage_configfile                         => true,
          manage_initfile                           => #{manage_initfile}, # CentOS-6 does not provide init script
          forward_policy                            => 'DROP',
          output_policy                             => 'ACCEPT',
          input_policy                              => 'DROP',
          input_drop_invalid_packets_with_conntrack => true,
          rules             => {
            'allow_acceptance_tests' => {
              chain  => 'INPUT',
              action => 'ACCEPT',
              proto  => tcp,
              dport  => 22,
            },
          },
          ip_versions      => ['ip'], #only ipv4 available with CI
        }
      )

      it 'works with no error' do
        apply_manifest(pp2, catch_failures: true)
      end
      it 'works idempotently' do
        apply_manifest(pp2, catch_changes: true)
      end

      describe service('ferm') do
        it { is_expected.to be_running }
      end

      describe command('iptables-save') do
        its(:stdout) { is_expected.to match %r{INPUT.*state INVALID -j DROP} }
      end
    end
  end

  context 'with custom chain using ferm DSL as content' do
    advanced_manifest = %(
      $my_rules = @(EOT)
      chain OPENVPN_FORWORD_RULES {
        proto udp {
          interface tun0 {
            outerface enp4s0 {
              mod conntrack ctstate (NEW) saddr @ipfilter((10.8.0.0/24)) ACCEPT;
            }
          }
        }
      }
      | EOT

      ferm::chain{'OPENVPN_FORWORD_RULES':
        chain   => 'OPENVPN_FORWORD_RULES',
        content => $my_rules,
      }

      ferm::rule { "OpenVPN - FORWORD all udp traffic from network 10.8.0.0/24 to subchain OPENVPN_FORWORD_RULES":
        chain     => 'FORWARD',
        action    => 'OPENVPN_FORWORD_RULES',
        saddr     => '10.8.0.0/24',
        proto     => 'udp',
      }
    )
    pp = [basic_manifest, advanced_manifest].join("\n")

    it 'works with no error' do
      apply_manifest(pp, catch_failures: true)
    end
    it 'works idempotently' do
      apply_manifest(pp, catch_changes: true)
    end

    describe iptables do
      it do
        is_expected.to have_rule(iptables_output_custom[0]). \
          with_table('filter'). \
          with_chain('FORWARD')
      end
      it do
        is_expected.to have_rule(iptables_output_custom[1]). \
          with_table('filter'). \
          with_chain('OPENVPN_FORWORD_RULES')
      end
    end

    describe service('ferm') do
      it { is_expected.to be_running }
    end

    describe command('iptables-save') do
      its(:stdout) { is_expected.to match %r{FORWARD.*-j OPENVPN_FORWORD_RULES} }
    end
  end
end
