require 'ruby-pwsh'

Facter.add(:powershell_version) do
  setcode do
    if Puppet::Util::Platform.windows?
      version = Pwsh::WindowsPowerShell.version
      version
    end
  end
end
