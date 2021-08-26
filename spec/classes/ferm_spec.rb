require 'spec_helper'

describe 'ferm' do
  let :node do
    'example.com'
  end

  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end

      context 'with all defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('ferm::config') }
        it { is_expected.to contain_class('ferm::service') }
        it { is_expected.to contain_class('ferm::install') }
        if facts[:os]['name'] == 'Debian'
          it { is_expected.to contain_file('/etc/ferm/ferm.d') }
          it { is_expected.to contain_file('/etc/ferm/ferm.d/definitions') }
          it { is_expected.to contain_file('/etc/ferm/ferm.d/chains') }
        else
          it { is_expected.to contain_file('/etc/ferm.d') }
          it { is_expected.to contain_file('/etc/ferm.d/definitions') }
          it { is_expected.to contain_file('/etc/ferm.d/chains') }
        end
        if facts[:os]['name'] == 'SLES'
          it { is_expected.to contain_package('ferm').with_ensure('absent') }
          it { is_expected.to contain_vcsrepo('/opt/ferm') }
        else
          it { is_expected.to contain_package('ferm').with_ensure('installed') }
          it { is_expected.not_to contain_vcsrepo('/opt/ferm') }
        end

        it { is_expected.not_to contain_service('ferm') }
        it { is_expected.not_to contain_file('/etc/ferm.conf') }
        if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i <= 6
          it { is_expected.not_to contain_file('/etc/init.d/ferm') }
        end
      end

      context 'with managed service' do
        let :params do
          { manage_service: true }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('ferm') }
        if facts[:os]['name'] == 'Ubuntu'
          it { is_expected.to contain_file_line('enable_ferm') }
          it { is_expected.to contain_file_line('disable_ferm_cache') }
        end
      end
      context 'with managed configfile' do
        let :params do
          { manage_configfile: true }
        end

        if facts[:os]['family'] == 'Debian'
          it { is_expected.to contain_concat('/etc/ferm/ferm.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.conf') }
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('ferm_header.conf') }
        it { is_expected.to contain_concat__fragment('ferm.conf') }
        # the following string exists only if we preserve chains
        it do
          is_expected.to contain_concat__fragment('ferm.conf'). \
            without_content(%r{@preserve;})
        end
        it { is_expected.to contain_concat__fragment('raw-PREROUTING-config-include') }
        it { is_expected.to contain_concat__fragment('raw-OUTPUT-config-include') }
        it { is_expected.to contain_concat__fragment('nat-PREROUTING-config-include') }
        if Gem::Version.new(facts[:kernelversion]) >= Gem::Version.new('2.6.36')
          it { is_expected.to contain_concat__fragment('nat-INPUT-config-include') }
        else
          it { is_expected.not_to contain_concat__fragment('nat-INPUT-config-include') }
        end
        it { is_expected.to contain_concat__fragment('nat-OUTPUT-config-include') }
        it { is_expected.to contain_concat__fragment('nat-POSTROUTING-config-include') }
        it { is_expected.to contain_concat__fragment('mangle-PREROUTING-config-include') }
        it { is_expected.to contain_concat__fragment('mangle-INPUT-config-include') }
        it { is_expected.to contain_concat__fragment('mangle-FORWARD-config-include') }
        it { is_expected.to contain_concat__fragment('mangle-OUTPUT-config-include') }
        it { is_expected.to contain_concat__fragment('mangle-POSTROUTING-config-include') }
      end

      context 'it creates chains' do
        it { is_expected.to contain_concat__fragment('raw-PREROUTING-policy') }
        it { is_expected.to contain_concat__fragment('raw-OUTPUT-policy') }
        it { is_expected.to contain_concat__fragment('nat-PREROUTING-policy') }
        if Gem::Version.new(facts[:kernelversion]) >= Gem::Version.new('2.6.36')
          it { is_expected.to contain_concat__fragment('nat-INPUT-policy') }
        else
          it { is_expected.not_to contain_concat__fragment('nat-INPUT-policy') }
        end
        it { is_expected.to contain_concat__fragment('nat-OUTPUT-policy') }
        it { is_expected.to contain_concat__fragment('nat-POSTROUTING-policy') }
        it { is_expected.to contain_concat__fragment('mangle-PREROUTING-policy') }
        it { is_expected.to contain_concat__fragment('mangle-INPUT-policy') }
        it { is_expected.to contain_concat__fragment('mangle-FORWARD-policy') }
        it { is_expected.to contain_concat__fragment('mangle-OUTPUT-policy') }
        it { is_expected.to contain_concat__fragment('mangle-POSTROUTING-policy') }
        it { is_expected.to contain_concat__fragment('filter-INPUT-policy') }
        it { is_expected.to contain_concat__fragment('filter-FORWARD-policy') }
        it { is_expected.to contain_concat__fragment('filter-OUTPUT-policy') }
        if facts[:os]['name'] == 'Debian'
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/raw-PREROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/raw-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/nat-PREROUTING.conf') }
          if Gem::Version.new(facts[:kernelversion]) >= Gem::Version.new('2.6.36')
            it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/nat-INPUT.conf') }
          else
            it { is_expected.not_to contain_concat('/etc/ferm/ferm.d/chains/nat-INPUT.conf') }
          end
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/nat-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/nat-POSTROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/mangle-PREROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/mangle-INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/mangle-FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/mangle-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/mangle-POSTROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/OUTPUT.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.d/chains/raw-PREROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/raw-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/nat-PREROUTING.conf') }
          if Gem::Version.new(facts[:kernelversion]) >= Gem::Version.new('2.6.36')
            it { is_expected.to contain_concat('/etc/ferm.d/chains/nat-INPUT.conf') }
          else
            it { is_expected.not_to contain_concat('/etc/ferm.d/chains/nat-INPUT.conf') }
          end
          it { is_expected.to contain_concat('/etc/ferm.d/chains/nat-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/nat-POSTROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/mangle-PREROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/mangle-INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/mangle-FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/mangle-OUTPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/mangle-POSTROUTING.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/OUTPUT.conf') }
        end
        it { is_expected.to contain_ferm__chain('raw-PREROUTING') }
        it { is_expected.to contain_ferm__chain('raw-OUTPUT') }
        it { is_expected.to contain_ferm__chain('nat-PREROUTING') }
        if Gem::Version.new(facts[:kernelversion]) >= Gem::Version.new('2.6.36')
          it { is_expected.to contain_ferm__chain('nat-INPUT') }
        else
          it { is_expected.not_to contain_ferm__chain('nat-INPUT') }
        end
        it { is_expected.to contain_ferm__chain('nat-OUTPUT') }
        it { is_expected.to contain_ferm__chain('nat-POSTROUTING') }
        it { is_expected.to contain_ferm__chain('mangle-PREROUTING') }
        it { is_expected.to contain_ferm__chain('mangle-INPUT') }
        it { is_expected.to contain_ferm__chain('mangle-FORWARD') }
        it { is_expected.to contain_ferm__chain('mangle-OUTPUT') }
        it { is_expected.to contain_ferm__chain('mangle-POSTROUTING') }
        it { is_expected.to contain_ferm__chain('FORWARD') }
        it { is_expected.to contain_ferm__chain('OUTPUT') }
        it { is_expected.to contain_ferm__chain('INPUT') }
      end
      context 'it preserves chains' do
        let :params do
          {
            manage_configfile: true,
            preserve_chains_in_tables: { 'nat' => %w[PREROUTING POSTROUTING] }
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat__fragment('ferm.conf'). \
            with_content(%r{domain \(ip ip6\) table nat \{})
        end
        it do
          is_expected.to contain_concat__fragment('ferm.conf'). \
            with_content(%r{chain PREROUTING @preserve;})
        end
        it do
          is_expected.to contain_concat__fragment('ferm.conf'). \
            with_content(%r{chain POSTROUTING @preserve;})
        end
      end
      context 'it works with git clone' do
        let :params do
          {
            install_method: 'vcsrepo',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('git').with_ensure('installed') }
        it { is_expected.to contain_package('iptables').with_ensure('installed') }
        it { is_expected.to contain_package('perl').with_ensure('installed') }
        it { is_expected.to contain_package('make').with_ensure('installed') }
        it { is_expected.to contain_package('ferm').with_ensure('absent') }
        it { is_expected.to contain_exec('make install') }
        it { is_expected.to contain_file('/etc/ferm') }
        it { is_expected.to contain_vcsrepo('/opt/ferm') }
      end
      context 'it works with ensure latest' do
        let :params do
          {
            package_ensure: 'latest',
            install_method: 'package',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('ferm').with_ensure('latest') }
      end
    end
  end
end
