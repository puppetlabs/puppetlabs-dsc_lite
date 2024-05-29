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
