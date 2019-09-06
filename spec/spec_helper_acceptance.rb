require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
install_module
install_module_dependencies

RSpec.configure do |c|
  # Configure all nodes in nodeset
  c.before :suite do
    # ferm is into epel with RedHat like OSes
    install_module_from_forge('stahnma-epel', '>= 1.3.1 < 2.0.0') if fact('os.family') == 'RedHat'

    pp = %(
      include epel
    )

    apply_manifest(pp, catch_failures: true) if fact('os.family') == 'RedHat'
  end
end
