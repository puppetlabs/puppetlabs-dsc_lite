# rubocop:disable Style/ClassAndModuleChildren
module PuppetX
  # Puppetlabs namespace
  module PuppetLabs
    # Dsclite Puppet module
    module DscLite
      # Gets the Powershell version
      class PowerShellVersion
      end
    end
  end
end

if Puppet::Util::Platform.windows?
  require 'win32/registry'
end

module PuppetX
  module PuppetLabs
    module DscLite
      # Gets the Powershell version
      class PowerShellVersion
        # Access rights used to access registry
        ACCESS_TYPE = Win32::Registry::KEY_READ | 0x100
        # Alias for HKEY_LOCAL_MACHINE registry
        HKLM              = Win32::Registry::HKEY_LOCAL_MACHINE
        # Registry key for PS 1 engine path
        PS_ONE_REG_PATH   = 'SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine'.freeze
        # Registry key for PS 3 engine path
        PS_THREE_REG_PATH = 'SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'.freeze
        # Registry key for current PS version
        REG_KEY           = 'PowerShellVersion'.freeze

        # Retrieves version of current PS installation. An installation for PS 3 and PS 1 is checked
        # for, with the version of a PS 3 installation taking precedence over that of a PS 1
        # installation.
        #
        # @return [String] version
        def self.version
          powershell_three_version || powershell_one_version
        end

        # Retrieves version of PS 1 installation
        #
        # @return [String] version
        def self.powershell_one_version
          version = nil
          begin
            HKLM.open(PS_ONE_REG_PATH, ACCESS_TYPE) do |reg|
              version = reg[REG_KEY]
            end
          rescue
            version = nil
          end
          version
        end

        # Retrieves version of PS 3 installation
        #
        # @return [String] version
        def self.powershell_three_version
          version = nil
          begin
            HKLM.open(PS_THREE_REG_PATH, ACCESS_TYPE) do |reg|
              version = reg[REG_KEY]
            end
          rescue
            version = nil
          end
          version
        end
      end
    end
  end
end
