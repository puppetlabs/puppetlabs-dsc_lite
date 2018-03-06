# Discover the path to the DSC module on a host.
#
# ==== Attributes
#
# * +host+ - A host with the DSC module installed. If an array of hosts is provided then
#   then only the first host will be used to determine the DSC module path.
#
# ==== Returns
#
# +string+ - The fully qualified path to the DSC module on the host. Empty string if
#   the DSC module is not installed on the host.
#
# ==== Raises
#
# +nil+
#
# ==== Examples
#
# locate_dsc_module(agent)
def locate_dsc_module(host)
  # Init
  host = host.kind_of?(Array) ? host[0] : host
  module_paths = host.puppet['modulepath'].split(host[:pathseparator])

  # Search the available module paths.
  module_paths.each do |module_path|
    dsc_module_path = "#{module_path}/dsc".gsub('\\', '/')
    ps_command = "Test-Path -Type Container -Path #{dsc_module_path}"

    if host.is_powershell?
      on(host, powershell("if ( #{ps_command} ) { exit 0 } else { exit 1 }"), :accept_all_exit_codes => true) do |result|
        if result.exit_code == 0
          return dsc_module_path
        end
      end
    else
      on(host, "test -d #{dsc_module_path}", :accept_all_exit_codes => true) do |result|
        if result.exit_code == 0
          return dsc_module_path
        end
      end
    end
  end

  # Return nothing if module is not installed.
  return ''
end

# Copy the "PuppetFakeResource" module to target host. This resource is used for invoking
# a reboot event from DSC and consumed by the "reboot" module.
#
# ==== Attributes
#
# * +host+ - A Beaker host with the DSC module already installed.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# +nil+
#
# ==== Examples
#
# install_fake_reboot_resource(agent, '/dsc/tests/files/reboot')
def install_fake_reboot_resource(host)
  # Init
  fake_reboot_resource_source_path = "tests/files/dsc_puppetfakeresource/PuppetFakeResource"
  fake_reboot_resource_source_path2 = "tests/files/dsc_puppetfakeresource/PuppetFakeResource2"
  fake_reboot_type_source_path = "tests/files/dsc_puppetfakeresource/dsc_puppetfakeresource.rb"

  dsc_resource_target_path = 'lib/puppet_x/dsc_resources'
  puppet_type_target_path = 'lib/puppet/type'

  step 'Determine Correct DSC Module Path'
  dsc_module_path = locate_dsc_module(host)
  dsc_resource_path = "#{dsc_module_path}/#{dsc_resource_target_path}"
  dsc_type_path = "#{dsc_module_path}/#{puppet_type_target_path}"

  step 'Copy DSC Fake Reboot Resource to Host'
  # without vendored content, must ensure dir created for desired structure
  on(host, "mkdir -p #{dsc_resource_path}")
  scp_to(host, fake_reboot_resource_source_path, dsc_resource_path)
  scp_to(host, fake_reboot_resource_source_path2, dsc_resource_path)
  scp_to(host, fake_reboot_type_source_path, dsc_type_path)

  # if installing to a master, then agents must pluginsync
  if (host['roles'].include?('master'))
    step 'Sync DSC resource implementations from master to agents'
    on(agents, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2])
  end
end

def get_fake_reboot_resource_install_path(usage = :manifest)
  # Master or masterless determine content locations
  is_pluginsync = hosts.any? { |h| h['roles'].include?('master') }

  install_root = usage == :manifest ? 'C:/' : '/cygdrive/c'

  install_base = "#{install_root}/ProgramData/PuppetLabs/" +
    (is_pluginsync ? 'puppet/cache' : 'code/modules/dsc')

  installed_path = "#{install_base}/lib/puppet_x/dsc_resources"
end

# Remove the "PuppetFakeResource" module on target host.
#
# ==== Attributes
#
# * +host+ - A Beaker host with the DSC module already installed.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# +nil+
#
# ==== Examples
#
# uninstall_fake_reboot_resource(agent)
def uninstall_fake_reboot_resource(host)
  # Init
  dsc_resource_target_path = 'lib/puppet_x/dsc_resources'
  puppet_type_target_path = 'lib/puppet/type'

  step 'Determine Correct DSC Module Path'
  dsc_module_path = locate_dsc_module(host)
  dsc_resource_path = "#{dsc_module_path}/#{dsc_resource_target_path}/PuppetFakeResource"
  dsc_resource_path2 = "#{dsc_module_path}/#{dsc_resource_target_path}/PuppetFakeResource2"
  dsc_type_path = "#{dsc_module_path}/#{puppet_type_target_path}/dsc_puppetfakeresource.rb"

  step 'Remove DSC Fake Reboot Resource from Host'
  if host.is_powershell?
    ps_rm_dsc_resource = "Remove-Item -Recurse -Path #{dsc_resource_path}"
    ps_rm_dsc_resource2 = "Remove-Item -Recurse -Path #{dsc_resource_path2}"
    ps_rm_dsc_type = "Remove-Item -Path #{dsc_type_path}/dsc_puppetfakeresource.rb"

    on(host, powershell("if ( #{ps_rm_dsc_resource} ) { exit 0 } else { exit 1 }"))
    on(host, powershell("if ( #{ps_rm_dsc_resource2} ) { exit 0 } else { exit 1 }"))
    on(host, powershell("if ( #{ps_rm_dsc_type} ) { exit 0 } else { exit 1 }"))
  else
    on(host, "rm -rf #{dsc_resource_path}")
    on(host, "rm -rf #{dsc_resource_path2}")
    on(host, "rm -rf #{dsc_type_path}")
  end
end

module Beaker
  module DSL
    module Assertions
      # Verify that a reboot is pending on the system.
      #
      # ==== Attributes
      #
      # * +hosts+ - The target Windows hosts for verification.
      #
      # ==== Returns
      #
      # +nil+
      #
      # ==== Raises
      #
      # +Minitest::Assertion+ - Reboot is not pending.
      #
      # ==== Examples
      #
      # assert_reboot_pending(agents)
      def assert_reboot_pending(host)
        on(host, 'shutdown /a', :accept_all_exit_codes => true) do |result|
          assert(0 == result.exit_code, 'Expected reboot is not pending!')
        end
      end
    end
  end
end
