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

describe 'ferm' do
  context 'with basics settings' do
    pp = %(
      class { 'ferm':
        manage_service    => true,
        manage_configfile => true,
        manage_initfile   => #{manage_initfile}, # CentOS-6 does not provide init script
        forward_policy    => 'DROP',
        output_policy     => 'DROP',
        input_policy      => 'DROP',
        rules             => {
          'allow acceptance_tests' => {
            chain  => 'INPUT',
            policy => 'ACCEPT',
            proto  => tcp,
            dport  => 22,
          },
        },
        ip_versions      => ['ip'], #only ipv4 available with CI
      }
    )

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
      it { is_expected.to have_rule('-A INPUT -p tcp -m comment --comment "allow acceptance_tests" -m tcp --dport 22 -j ACCEPT').with_table('filter').with_chain('INPUT') }
    end
  end
end
