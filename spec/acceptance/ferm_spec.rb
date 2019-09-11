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

basic_manifest = %(
  class { 'ferm':
    manage_service    => true,
    manage_configfile => true,
    manage_initfile   => #{manage_initfile}, # CentOS-6 does not provide init script
    forward_policy    => 'DROP',
    output_policy     => 'DROP',
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
      its(:stdout) { is_expected.to match %r{.*filter.*:INPUT DROP.*:FORWARD DROP.*:OUTPUT DROP.*}m }
    end

    describe iptables do
      it do
        is_expected.to have_rule('-A INPUT -p tcp -m comment --comment ["]*allow_acceptance_tests["]* -m tcp --dport 22 -j ACCEPT'). \
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
          is_expected.to have_rule('-A INPUT -p tcp -m comment --comment ["]*jump_http["]* -m tcp --dport 80 -j HTTP'). \
            with_table('filter'). \
            with_chain('INPUT')
        end
        it do
          is_expected.to have_rule('-A HTTP -s 127.0.0.1/32 -p tcp -m comment --comment ["]*allow_http_localhost["]* -m tcp --dport 80 -j ACCEPT'). \
            with_table('filter'). \
            with_chain('HTTP')
        end
      end
    end
  end
end
