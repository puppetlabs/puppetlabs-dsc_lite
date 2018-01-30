require 'erb'
require 'master_manipulator'
require 'dsc_utils'
require 'securerandom'
test_name 'FM-2623 - C68790 - Attempt to Run DSC Manifest on a Linux Agent'

# Init
local_files_root_path = ENV['MANIFESTS'] || 'tests/manifests'

# Manifest
fake_name = SecureRandom.uuid
test_file_contents = SecureRandom.uuid

dsc_manifest = <<-MANIFEST
dsc_puppetfakeresource {'#{fake_name}':
  dsc_ensure          => 'present',
  dsc_importantstuff  => '#{test_file_contents}',
  dsc_destinationpath => 'C:\\#{fake_name}'
}
MANIFEST

# Verify
error_msg = /Could not find a suitable provider for dsc_puppetfakeresource/

# Teardown
teardown do
  uninstall_fake_reboot_resource(master)
end

# Setup
step 'Copy Test Type Wrappers'
install_fake_reboot_resource(master)
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => dsc_manifest)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# Tests
confine_block(:except, :platform => 'windows') do
  agents.each do |agent|

    step 'Run Puppet Agent'
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => 4) do |result|
      assert_match(error_msg, result.stderr, 'Expected error was not detected!')
    end

    # if this file exists, we're in trouble!
    on(agent, "test -f /cygdrive/c/#{fake_name}", :acceptable_exit_codes => [1])
  end
end
