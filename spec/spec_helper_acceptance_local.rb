# frozen_string_literal: true

require 'lib/dsc_utils'
require 'securerandom'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

# run_puppet_install_helper
# configure_type_defaults_on(hosts)

# install_ca_certs

# proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# hosts.each do |host|
#   install_module_dependencies_on(host)
#   install_dev_puppet_module_on(host, source: proj_root, module_name: 'dsc_lite')
# end
def single_dsc_resource_manifest(dsc_type, dsc_props)
  output = "dsc_#{dsc_type} {'#{dsc_type}_test':\n"
  dsc_props.each do |k, v|
    output += if %r{^\[.*\]$}.match?(v)
                "  #{k} => #{v},\n"
              elsif %r{^(true|false)$}.match?(v)
                "  #{k} => #{v},\n"
              elsif %r{^{.*}$}.match?(v)
                "  #{k} => #{v},\n"
              else
                "  #{k} => '#{v}',\n"
              end
  end
  output += "}\n"
  output
end

def create_windows_file(folder_path, file_name, content)
  content = content.tr('"', "'")
  manifest = <<-FILEMANIFEST
    file{"#{folder_path}":
      ensure => directory,
    }
    file { "#{folder_path}/#{file_name}":
      content => "#{content}",
    }
  FILEMANIFEST
  apply_manifest(manifest)
end

# This method allows a block to be passed in and if an exception is raised
# that matches the 'error_matcher' matcher, the block will wait a set number
# of seconds before retrying.
# Params:
# - max_retry_count - Max number of retries
# - retry_wait_interval_secs - Number of seconds to wait before retry
# - error_matcher - Matcher which the exception raised must match to allow retry
# Example Usage:
# retry_on_error_matching(3, 5, /OpenGPG Error/) do
#   apply_manifest(pp, :catch_failures => true)
# end
def retry_on_error_matching(max_retry_count = 3, retry_wait_interval_secs = 5, error_matcher = nil)
  try = 0
  begin
    try += 1
    yield
  rescue StandardError => e
    raise unless try < max_retry_count && (error_matcher.nil? || e.message =~ error_matcher)

    sleep retry_wait_interval_secs
    retry
  end
end
