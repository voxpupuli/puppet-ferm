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
        it { is_expected.to contain_file('/etc/ferm.d') }
        it { is_expected.to contain_file('/etc/ferm.d/definitions') }
        it { is_expected.to contain_file('/etc/ferm.d/chains') }
        it { is_expected.not_to contain_service('ferm') }
        it { is_expected.not_to contain_file('/etc/ferm.conf') }
      end

      context 'with managed service' do
        let :params do
          { manage_service: true }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('ferm') }
      end
      context 'with managed configfile' do
        let :params do
          { manage_configfile: true }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat('/etc/ferm.conf') }
        it { is_expected.to contain_concat__fragment('ferm_header.conf') }
        it { is_expected.to contain_concat__fragment('ferm.conf') }
      end
      context 'it creates chains' do
        it { is_expected.to contain_concat__fragment('FORWARD-policy') }
        it { is_expected.to contain_concat__fragment('INPUT-policy') }
        it { is_expected.to contain_concat__fragment('OUTPUT-policy') }
        it { is_expected.to contain_concat('/etc/ferm.d/chains/FORWARD.conf') }
        it { is_expected.to contain_concat('/etc/ferm.d/chains/INPUT.conf') }
        it { is_expected.to contain_concat('/etc/ferm.d/chains/OUTPUT.conf') }
        it { is_expected.to contain_ferm__chain('FORWARD') }
        it { is_expected.to contain_ferm__chain('OUTPUT') }
        it { is_expected.to contain_ferm__chain('INPUT') }
      end
    end
  end
end
