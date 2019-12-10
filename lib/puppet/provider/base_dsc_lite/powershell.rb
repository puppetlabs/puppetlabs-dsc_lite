require 'pathname'
require 'json'
require 'ruby-pwsh'
require_relative '../../../puppet_x/puppetlabs/dsc_lite/powershell_hash_formatter'

Puppet::Type.type(:base_dsc_lite).provide(:powershell) do
  confine operatingsystem: :windows
  defaultfor operatingsystem: :windows

  commands powershell: (if File.exist?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                          "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
                        elsif File.exist?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                          "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
                        else
                          'powershell.exe'
                        end)

  desc 'Applies DSC Resources by generating a configuration file and applying it.'

  DSC_LITE_MODULE_PUPPET_UPGRADE_MSG = <<-UPGRADE.freeze
  Currently, the dsc module has reduced functionality on this agent
  due to one or more of the following conditions:
  - Puppet 3.x (non-x64 version)
    Puppet 3.x uses a Ruby version that requires a library to support a colored
    console. Unfortunately this library prevents the PowerShell module from
    using a shared PowerShell process to dramatically improve the performance of
    resource application.
  To enable these improvements, it is suggested to upgrade to any x64 version of
  Puppet (including 3.x), or to a Puppet version newer than 3.x.
  UPGRADE

  def self.upgrade_message
    Puppet.warning DSC_LITE_MODULE_PUPPET_UPGRADE_MSG unless @upgrade_warning_issued
    @upgrade_warning_issued = true
  end

  def self.vendored_modules_path
    File.expand_path(Pathname.new(__FILE__).dirname + '../../../' + 'puppet_x/dsc_resources')
  end

  def dsc_parameters
    resource.parameters_with_value.select do |p|
      p.name.to_s =~ %r{dsc_}
    end
  end

  def dsc_property_param
    resource.parameters_with_value.select { |pr| pr.name == :properties }.each do |p|
      p.name.to_s =~ %r{dsc_}
    end
  end

  def self.template_path
    File.expand_path(Pathname.new(__FILE__).dirname)
  end

  def ps_manager
    debug_output = Puppet::Util::Log.level == :debug
    Pwsh::Manager.instance(command(:powershell), Pwsh::Manager.powershell_args, debug: debug_output)
  end

  DSC_LITE_COMMAND_TIMEOUT = 1_200_000 # 20 minutes

  def exists?
    version = Facter.value(:powershell_version)
    Puppet.debug "PowerShell Version: #{version}"
    script_content = ps_script_content('test')
    Puppet.debug "\n" + self.class.redact_content(script_content)

    if Pwsh::Manager.windows_powershell_supported?
      output = ps_manager.execute(script_content, DSC_LITE_COMMAND_TIMEOUT)[:stdout]
    else
      self.class.upgrade_message
      output = powershell(Pwsh::Manager.powershell_args, script_content)
    end
    Puppet.debug "Dsc Resource returned: #{output}"
    data = JSON.parse(output)
    raise(data['errormessage']) unless data['errormessage'].empty?
    exists = data['indesiredstate']
    Puppet.debug "Dsc Resource Exists?: #{exists}"
    Puppet.debug "dsc_ensure: #{resource[:dsc_ensure]}" if resource.parameters.key?(:dsc_ensure)
    Puppet.debug "ensure: #{resource[:ensure]}"
    exists
  end

  def create
    script_content = ps_script_content('set')
    Puppet.debug "\n" + self.class.redact_content(script_content)

    if Pwsh::Manager.windows_powershell_supported?
      output = ps_manager.execute(script_content, DSC_LITE_COMMAND_TIMEOUT)[:stdout]
    else
      self.class.upgrade_message
      output = powershell(Pwsh::Manager.powershell_args, script_content)
    end
    Puppet.debug "Create Dsc Resource returned: #{output}"
    data = JSON.parse(output)

    raise(data['errormessage']) unless data['errormessage'].empty?

    notify_reboot_pending if data['rebootrequired'] == true

    data
  end

  def notify_reboot_pending
    Puppet.info 'A reboot is required to progress further. Notifying Puppet.'

    reboot_resource = resource.catalog.resource(:reboot, 'dsc_reboot')
    unless reboot_resource
      Puppet.warning "No reboot resource found in the graph that has 'dsc_reboot' as its name. Cannot signal reboot to Puppet."
      return
    end

    if reboot_resource.provider.respond_to?(:reboot_required)
      # internal API used to let reboot resource knows a reboot is pending
      reboot_resource.provider.reboot_required = true
    else
      Puppet.warning 'Reboot module must be updated, since resource does not have :reboot_required method implemented. Cannot signal reboot to Puppet.'
      return
    end
  end

  def self.format_dsc_lite(dsc_value)
    PuppetX::PuppetLabs::DscLite::PowerShellHashFormatter.format(dsc_value)
  end

  def self.escape_quotes(text)
    text.gsub("'", "''")
  end

  def self.redact_content(content)
    # Note that here we match after an equals to ensure we redact the value being passed, but not the key.
    # This means a redaction of a string not including '= ' before the string value will not redact.
    # Every secret unwrapped in this module will unwrap as "'secret' # PuppetSensitive" and, currently,
    # always inside a hash table to be passed along. This means we can (currently) expect the value to
    # always come after an equals sign.
    # Note that the line may include a semi-colon and/or a newline character after the sensitive unwrap.
    content.gsub(%r{= '.+' # PuppetSensitive;?(\\n)?$}, "= '[REDACTED]'")
  end

  def ps_script_content(mode)
    self.class.ps_script_content(mode, resource, self)
  end

  def self.ps_script_content(mode, resource, provider)
    dsc_invoke_method = mode
    @param_hash = resource
    template_name = resource.generic_dsc ? '/invoke_generic_dsc_resource.ps1.erb' : '/invoke_dsc_resource.ps1.erb'
    file = File.new(template_path + template_name, encoding: Encoding::UTF_8)
    template = ERB.new(file.read, nil, '-')
    template.result(binding)
  end
end
