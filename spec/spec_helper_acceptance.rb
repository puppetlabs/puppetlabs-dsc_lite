require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper

install_ca_certs

proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
hosts.each do |host|
  install_module_dependencies_on(host)
  install_dev_puppet_module_on(host, :source => proj_root, :module_name => 'dsc')
end

def windows_agents
  agents.select { |agent| agent['platform'].include?('windows') }
end

# add spec/lib path to LOAD_PATH so we can load the dsc_util.rb file
lib_path = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib_path)