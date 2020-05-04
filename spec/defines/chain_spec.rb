require 'spec_helper'

describe 'ferm::chain', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end
      let(:title) { 'INPUT2' }

      let :pre_condition do
        'include ferm'
      end

      context 'default params creates INPUT2 chain' do
        let :params do
          {
            disable_conntrack: false,
            log_dropped_packets: true
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('filter-INPUT2-config-include') }
        it do
          is_expected.to contain_concat__fragment('filter-INPUT2-policy'). \
            with_content(%r{ESTABLISHED RELATED})
        end
        it do
          is_expected.to contain_concat__fragment('filter-INPUT2-footer'). \
            with_content(%r{LOG log-prefix 'INPUT2: ';})
        end
        if facts[:os]['name'] == 'Debian'
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/filter-INPUT2.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.d/chains/filter-INPUT2.conf') }
        end
        it { is_expected.to contain_ferm__chain('INPUT2') }
      end

      context 'without conntrack' do
        let :params do
          {
            disable_conntrack: true,
            log_dropped_packets: false
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat__fragment('filter-INPUT2-policy')
          is_expected.not_to contain_concat__fragment('filter-INPUT2-policy'). \
            with_content(%r{ESTABLISHED RELATED})
        end
        it do
          is_expected.not_to contain_concat__fragment('filter-INPUT2-footer'). \
            with_content(%r{LOG log-prefix 'INPUT2: ';})
        end
      end

      context 'with policy setting for custom chain' do
        let :params do
          {
            chain: 'INPUT2',
            policy: 'DROP',
            disable_conntrack: true,
            log_dropped_packets: false
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Can only set a default policy for builtin chains}) }
      end

      context 'with custom chain FERM-DSL using content parameter' do
        let(:title) { 'FERM-DSL' }
        let :params do
          {
            content: 'mod rpfilter invert DROP;'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('filter-FERM-DSL-config-include') }
        it do
          is_expected.to contain_concat__fragment('filter-FERM-DSL-custom-content'). \
            with_content(%r{mod rpfilter invert DROP;})
        end
        it do
          is_expected.not_to contain_concat__fragment('filter-FERM-DSL-policy')
        end
        it do
          is_expected.not_to contain_concat__fragment('filter-FERM-DSL-footer')
        end
        if facts[:os]['name'] == 'Debian'
          it { is_expected.to contain_concat('/etc/ferm/ferm.d/chains/filter-FERM-DSL.conf') }
        else
          it { is_expected.to contain_concat('/etc/ferm.d/chains/filter-FERM-DSL.conf') }
        end
        it { is_expected.to contain_ferm__chain('FERM-DSL') }
      end
    end
  end
end
