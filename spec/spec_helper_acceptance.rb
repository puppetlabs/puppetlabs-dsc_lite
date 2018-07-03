require 'beaker-rspec/spec_helper'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'lib/dsc_utils'
require 'securerandom'

# automatically load any shared examples or contexts
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

run_puppet_install_helper

install_ca_certs

proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
hosts.each do |host|
  install_module_dependencies_on(host)
  install_dev_puppet_module_on(host, :source => proj_root, :module_name => 'dsc_lite')
end

def installed_path
 get_dsc_resource_fixture_path(usage = :manifest)
end

def windows_agents
  agents.select { |agent| agent['platform'].include?('windows') }
end

def beaker_opts
  @env ||= {
      acceptable_exit_codes: (0...256),
      debug: true,
      trace: true,
  }
end
