require 'spec_helper_acceptance'

describe 'dsc exceptions' do
  throw_message = SecureRandom.uuid

  before(:all) do
    setup_dsc_resource_fixture
  end

  after(:all) do
    teardown_dsc_resource_fixture
  end

  context 'with valid and invalid dsc resources' do
    error_msg = %r{failed to execute Set-TargetResource functionality with error message: #{throw_message}}

    dsc_manifest = <<-MANIFEST
        dsc { 'good_resource':
          resource_name => 'puppetfakeresource',
          module => '#{dsc_resource_fixture_path}/1.0',
          properties => {
            ensure          => 'present',
            importantstuff  => 'foo',
          }
        }

        dsc { 'throw_resource':
          resource_name => 'puppetfakeresource',
          module => '#{dsc_resource_fixture_path}/1.0',
          properties => {
            ensure          => 'present',
            importantstuff  => 'bar',
            throwmessage    => '#{throw_message}',
          }
        }
    MANIFEST

    it 'applies manifest, raises error' do
      apply_manifest(dsc_manifest, expect_failures: true) do |result|
        expect(result.stderr).to match(%r{#{error_msg}})
        expect(result.stdout).to match(%r{Stage\[main\]\/Main\/Dsc\[good_resource\]\/ensure\: invoked})
      end
    end
  end

  context 'with multiple invalid dsc resources' do
    throw_message_a = SecureRandom.uuid
    throw_message_b = SecureRandom.uuid

    let(:dsc_manifest) do
      <<-MANIFEST
        dsc { 'throw_1':
          resource_name => 'puppetfakeresource',
          module => '#{dsc_resource_fixture_path}/1.0',
          properties => {
            ensure          => 'present',
            importantstuff  => 'foo',
            throwmessage    => '#{throw_message_a}',
          }
        }

        dsc { 'throw_2':
          resource_name => 'puppetfakeresource',
          module => '#{dsc_resource_fixture_path}/1.0',
          properties => {
            ensure          => 'present',
            importantstuff  => 'bar',
            throwmessage    => '#{throw_message_b}',
          }
        }
      MANIFEST
    end

    let(:error_msg_a) { %r{failed to execute Set-TargetResource functionality with error message: #{throw_message_a}} }
    let(:error_msg_b) { %r{failed to execute Set-TargetResource functionality with error message: #{throw_message_b}} }

    it 'applies manifest, raises error' do
      apply_manifest(dsc_manifest, expect_failures: true) do |result|
        expect(result.stderr).to match(%r{#{error_msg_a}})
        expect(result.stderr).to match(%r{#{error_msg_b}})
      end
    end
  end
end
