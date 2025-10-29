# frozen_string_literal: true

require 'pathname'
require 'json'
require_relative '../../../puppet_x/puppetlabs/dsc_lite/powershell_hash_formatter'

Puppet::Type.type(:base_dsc_lite).provide(:powershell) do
  confine feature: :pwshlib
  confine 'os.name' => :windows
  defaultfor 'os.name' => :windows

  commands powershell: (if File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                          "#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
                        elsif File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                          "#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
                        else
                          'powershell.exe'
                        end)

  desc 'Applies DSC Resources by generating a configuration file and applying it.'

  DSC_LITE_MODULE_PUPPET_UPGRADE_MSG = <<-UPGRADE
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

  def self.template_path
    File.expand_path(Pathname.new(__FILE__).dirname)
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

  # ---------------------------
  # Deferred value resolution - NEW APPROACH
  # ---------------------------

  # Resolve deferred values in properties right before PowerShell script generation
  # This is the correct timing - after catalog application starts but before template rendering
  def resolve_deferred_values!
    return unless resource.parameters.key?(:properties)

    current_properties = resource.parameters[:properties].value
    return unless contains_deferred_values?(current_properties)

    Puppet.notice('DSC PROVIDER → Resolving deferred values in properties')

    begin
      # Resolve deferred values directly using the properties hash
      resolved_properties = manually_resolve_deferred_values(current_properties)

      # Update the resource with resolved properties
      resource.parameters[:properties].value = resolved_properties

      # Verify resolution worked
      if contains_deferred_values?(resolved_properties)
        Puppet.warning('DSC PROVIDER → Some deferred values could not be resolved')
      else
        Puppet.notice('DSC PROVIDER → All deferred values resolved successfully')
      end
    rescue => e
      Puppet.warning("DSC PROVIDER → Error resolving deferred values: #{e.class}: #{e.message}")
      Puppet.debug("DSC PROVIDER → Error backtrace: #{e.backtrace.join("\n")}")
      # Continue with unresolved values - they will be stringified but at least won't crash
    end
  end

  # Recursively resolve deferred values in a data structure
  def manually_resolve_deferred_values(value)
    case value
    when Hash
      resolved_hash = {}
      value.each do |k, v|
        resolved_key = manually_resolve_deferred_values(k)
        resolved_value = manually_resolve_deferred_values(v)
        resolved_hash[resolved_key] = resolved_value
      end
      resolved_hash
    when Array
      value.map { |v| manually_resolve_deferred_values(v) }
    else
      # Handle different types of deferred objects
      if value.is_a?(Puppet::Pops::Evaluator::DeferredValue)
        # DeferredValue objects have a @proc instance variable we can call
        proc = value.instance_variable_get(:@proc)
        return proc.call if proc && proc.respond_to?(:call)

        Puppet.debug('DSC PROVIDER → DeferredValue has no callable proc')
        return value.to_s

      elsif value && value.class.name.include?('Deferred')
        # For other Deferred types, try standard resolution
        if value.respond_to?(:name)
          begin
            return Puppet::Pops::Evaluator::DeferredResolver.resolve(value.name, nil, {})
          rescue => e
            Puppet.debug("DSC PROVIDER → Failed to resolve Deferred object: #{e.message}")
            return value.to_s
          end
        else
          Puppet.debug('DSC PROVIDER → Deferred object has no name method')
          return value.to_s
        end
      end

      # Return the value unchanged if it's not deferred
      value
    end
  end

  # Check if a value contains any deferred values (recursively)
  def contains_deferred_values?(value)
    case value
    when Hash
      value.any? { |k, v| contains_deferred_values?(k) || contains_deferred_values?(v) }
    when Array
      value.any? { |v| contains_deferred_values?(v) }
    else
      # Check if this is a Deferred object or DeferredValue
      value && (value.class.name.include?('Deferred') ||
                value.is_a?(Puppet::Pops::Evaluator::DeferredValue))
    end
  end

  def dsc_parameters
    resource.parameters_with_value.select do |p|
      p.name.to_s.include? 'dsc_'
    end
  end

  def dsc_property_param
    resource.parameters_with_value.select { |pr| pr.name == :properties }.each do |p|
      p.name.to_s.include? 'dsc_'
    end
  end

  def set_timeout
    resource[:dsc_timeout] ? resource[:dsc_timeout] * 1000 : 1_200_000
  end

  def ps_manager
    debug_output = Puppet::Util::Log.level == :debug
    Pwsh::Manager.instance(command(:powershell), Pwsh::Manager.powershell_args, debug: debug_output)
  end

  # Keep for ERBs that call provider.format_for_ps(...)
  def format_for_ps(value)
    self.class.format_dsc_lite(value)
  end

  def exists?
    # Resolve deferred values right before we start processing
    resolve_deferred_values!

    timeout = set_timeout
    Puppet.debug "Dsc Timeout: #{timeout} milliseconds"
    version = Facter.value(:powershell_version)
    Puppet.debug "PowerShell Version: #{version}"

    script_content = ps_script_content('test')
    Puppet.debug "\n" + self.class.redact_content(script_content)

    if Pwsh::Manager.windows_powershell_supported?
      output = ps_manager.execute(script_content, timeout)
      raise Puppet::Error, output[:errormessage] if output[:errormessage]&.match?(%r{PowerShell module timeout \(\d+ ms\) exceeded while executing})
      output = output[:stdout]
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
    # Resolve deferred values right before we start processing
    resolve_deferred_values!

    timeout = set_timeout
    Puppet.debug "Dsc Timeout: #{timeout} milliseconds"

    script_content = ps_script_content('set')
    Puppet.debug "\n" + self.class.redact_content(script_content)

    if Pwsh::Manager.windows_powershell_supported?
      output = ps_manager.execute(script_content, timeout)
      raise Puppet::Error, output[:errormessage] if output[:errormessage]&.match?(%r{PowerShell module timeout \(\d+ ms\) exceeded while executing})
      output = output[:stdout]
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
      nil
    end
  end

  def ps_script_content(mode)
    self.class.ps_script_content(mode, resource, self)
  end

  def self.ps_script_content(mode, resource, provider)
    dsc_invoke_method = mode
    @param_hash = resource
    template_name = resource.generic_dsc ? '/invoke_generic_dsc_resource.ps1.erb' : '/invoke_dsc_resource.ps1.erb'
    file = File.new(template_path + template_name, encoding: Encoding::UTF_8)

    # Make vendored_modules_path visible in ERB if the template uses it
    vendored_modules_path = self.vendored_modules_path

    template = ERB.new(file.read, trim_mode: '-')
    template.result(binding)
  end
end
