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
        it { is_expected.to contain_package('ferm') }
        if facts[:os]['release']['major'].to_i == 10
          it { is_expected.to contain_file('/etc/ferm/ferm.d') }
          it { is_expected.to contain_file('/etc/ferm/ferm.d/definitions') }
          it { is_expected.to contain_file('/etc/ferm/ferm.d/chains') }
        else
          it { is_expected.to contain_file('/etc/ferm.d') }
          it { is_expected.to contain_file('/etc/ferm.d/definitions') }
          it { is_expected.to contain_file('/etc/ferm.d/chains') }
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

        if facts[:os]['name'] == 'Ubuntu' || facts[:os]['release']['major'].to_i == 10
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
      end
      context 'with managed initfile' do
        let :params do
          { manage_initfile: true }
        end

        if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i <= 6
          it { is_expected.to contain_file('/etc/init.d/ferm') }
        else
          it { is_expected.not_to contain_file('/etc/init.d/ferm') }
        end
      end
      context 'it creates chains' do
        it { is_expected.to contain_concat__fragment('FORWARD-policy') }
        it { is_expected.to contain_concat__fragment('INPUT-policy') }
        it { is_expected.to contain_concat__fragment('OUTPUT-policy') }
        if facts[:os]['release']['major'].to_i == 10
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/OUTPUT.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.d/chains/FORWARD.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/INPUT.conf') }
          it { is_expected.to contain_concat('/etc/ferm.d/chains/OUTPUT.conf') }
        end
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
    end
  end
end
