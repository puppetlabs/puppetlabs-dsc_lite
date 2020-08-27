# NOTE: this is a main/agent test that does not run with Litmus.
# require 'spec_helper_acceptance'

# describe 'use dsc resource on a Linux agent' do
#   fake_name = SecureRandom.uuid
#   test_file_contents = SecureRandom.uuid

#   dsc_manifest = <<-MANIFEST
#     dsc { '#{fake_name}':
#       resource_name => 'puppetfakeresource',
#       module => '#{installed_path}/1.0',
#       properties => {
#         ensure          => 'present',
#         importantstuff  => '#{test_file_contents}',
#         destinationpath => 'C:\\#{fake_name}',
#       },
#     }
#   MANIFEST

#   let(:error_msg) { %r{Could not find a suitable provider for dsc} }

#   # NOTE: this test only runs when in a main / agent setup with more than Windows hosts
#   confine_block(:except, platform: 'windows') do
#     agents.each do |_agent|
#       it 'applies manifest, raises error' do
#         execute_manifest(dsc_manifest, expect_failures: true) do |result|
#           expect(result.exit_code).to eq(4)
#           expect(result.stderr).to match(%r{#{error_msg}})
#         end

#         expect(file("C:\\#{fake_name}")).not_to exist
#       end
#     end
#   end
# end
