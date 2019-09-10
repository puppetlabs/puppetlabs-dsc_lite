# Discover the path to the DSC module on a host.
def locate_dsc_module
  # Init
  module_paths = run_shell('puppet config print modulepath').stdout.delete("\n").delete("\r").split(';')
  # Search the available module paths.
  module_paths.each do |module_path|
    dsc_module_path = "#{module_path}/dsc_lite".tr('\\', '/')
    ps_command = "Test-Path -Type Container -Path #{dsc_module_path}"
    run_shell("powershell.exe -NoProfile -Nologo -Command \"if ( #{ps_command} ) { exit 0 } else { exit 1 }\"", expect_failures: true) do |result|
      if result.exit_code == 0
        return dsc_module_path
      end
    end
  end
  # Return nothing if module is not installed.
  ''
end

# Copy the "PuppetFakeResource" module to target host. This resource is used for invoking
# a reboot event from DSC and consumed by the "reboot" module.
def setup_dsc_resource_fixture
  # Init
  fake_reboot_resource_source_path = 'spec/fixtures/dsc_puppetfakeresource/PuppetFakeResource/1.0'
  fake_reboot_resource_source_path2 = 'spec/fixtures/dsc_puppetfakeresource/PuppetFakeResource/2.0'
  fake_reboot_type_source_path = 'spec/fixtures/dsc_puppetfakeresource/dsc_puppetfakeresource.rb'

  dsc_resource_target_path = 'lib/puppet_x/dsc_resources/PuppetFakeResource'
  puppet_type_target_path = 'lib/puppet/type'

  # 'Determine Correct DSC Module Path'
  dsc_module_path = locate_dsc_module
  dsc_resource_path = "#{dsc_module_path}/#{dsc_resource_target_path}"
  dsc_type_path = "#{dsc_module_path}/#{puppet_type_target_path}"

  # 'Copy DSC Fake Reboot Resource to Host'
  # without vendored content, must ensure dir created for desired structure
  run_shell("powershell.exe -NoProfile -Nologo -Command \"New-Item -Path #{dsc_resource_path} -ItemType 'Directory'\"", expect_failures: true)
  if ENV['TARGET_HOST'].nil? || ENV['TARGET_HOST'] == 'localhost'
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Copy-Item -Recurse #{Dir.pwd}/#{fake_reboot_resource_source_path} #{dsc_resource_path}\"")
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Copy-Item -Recurse #{Dir.pwd}/#{fake_reboot_resource_source_path2} #{dsc_resource_path}\"")
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Copy-Item -Recurse #{Dir.pwd}/#{fake_reboot_type_source_path} #{dsc_type_path}\"")
  else
    bolt_upload_file(fake_reboot_resource_source_path, dsc_resource_path)
    bolt_upload_file(fake_reboot_resource_source_path2, dsc_resource_path)
    bolt_upload_file(fake_reboot_type_source_path, dsc_type_path)
  end
end

def dsc_resource_fixture_path
  "#{locate_dsc_module}/lib/puppet_x/dsc_resources/PuppetFakeResource"
end

# Remove the "PuppetFakeResource" module on target.
def teardown_dsc_resource_fixture
  # Init
  dsc_resource_target_path = 'lib/puppet_x/dsc_resources/PuppetFakeResource'
  puppet_type_target_path = 'lib/puppet/type'

  # 'Determine Correct DSC Module Path'
  dsc_module_path = locate_dsc_module
  dsc_resource_path = "#{dsc_module_path}/#{dsc_resource_target_path}/1.0"
  dsc_resource_path2 = "#{dsc_module_path}/#{dsc_resource_target_path}/2.0"
  dsc_type_path = "#{dsc_module_path}/#{puppet_type_target_path}/dsc_puppetfakeresource.rb"

  # 'Remove DSC Fake Reboot Resource from Host'
  ps_rm_dsc_resource = "Remove-Item -Recurse -Path #{dsc_resource_path}"
  ps_rm_dsc_resource2 = "Remove-Item -Recurse -Path #{dsc_resource_path2}"
  ps_rm_dsc_type = "Remove-Item -Path #{dsc_type_path}/dsc_puppetfakeresource.rb"

  run_shell("powershell.exe -NoProfile -Nologo -Command \"if ( #{ps_rm_dsc_resource} ) { exit 0 } else { exit 1 }\"", expect_failures: true)
  run_shell("powershell.exe -NoProfile -Nologo -Command \"if ( #{ps_rm_dsc_resource2} ) { exit 0 } else { exit 1 }\"", expect_failures: true)
  run_shell("powershell.exe -NoProfile -Nologo -Command \"if ( #{ps_rm_dsc_type} ) { exit 0 } else { exit 1 }\"", expect_failures: true)
end

def assert_reboot_pending
  run_shell('shutdown /a', accept_all_exit_codes: true) do |result|
    assert(result.exit_code == 0, 'Expected reboot is not pending!')
  end
end
