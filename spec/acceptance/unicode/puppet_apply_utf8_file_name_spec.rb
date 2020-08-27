require 'spec_helper_acceptance'

describe 'UTF-8' do
  # different UTF-8 widths
  # 1-byte A
  # 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
  # 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
  # 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
  MIXED_UTF8 = "A\u06FF\u16A0\u{2070E}".freeze # Aۿᚠ𠜎

  file_name = MIXED_UTF8
  file_path = SecureRandom.uuid
  test_file_contents = SecureRandom.uuid

  dsc_create_manifest = <<-MANIFEST
    dsc {'some_name':
      resource_name => 'puppetfakeresource',
      # NOTE: install_fake_reboot_resource installs on main, which pluginsyncs here
      module => '#{dsc_resource_fixture_path}/1.0',
      properties => {
        ensure          => 'present',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{file_path}\\#{file_name}'
      }
    }
  MANIFEST

  dsc_remove_manifest = <<-MANIFEST
    dsc {'some_name':
      resource_name => 'puppetfakeresource',
      module => '#{dsc_resource_fixture_path}/1.0',
      properties => {
        ensure          => 'absent',
        importantstuff  => '#{test_file_contents}',
        destinationpath => 'C:\\#{file_path}\\#{file_name}'
      }
    }
  MANIFEST

  before(:all) do
    run_shell("powershell.exe -NoProfile -Nologo -Command \"New-Item -Path /#{file_path}\" -ItemType \"directory\"")
    setup_dsc_resource_fixture
  end

  after(:all) do
    teardown_dsc_resource_fixture
    run_shell("powershell.exe -NoProfile -Nologo -Command \"Remove-Item -Recurse -Force C:/#{file_path}\"")
  end

  context 'create DSC resource with ensure present on UTF-8 file name' do
    it 'applies manifest' do
      create_manifest_location = create_manifest_file(dsc_create_manifest)
      apply_manifest(nil, catch_failures: true, manifest_file_location: create_manifest_location) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'creates file' do
      run_shell("powershell.exe -NoProfile -Nologo -Command \"Test-Path 'C:\\#{file_path}\\#{file_name}' -PathType Leaf\"") do |result|
        expect(result.stdout.to_s).to match(%r{True})
      end
    end
  end

  context 'remove DSC resource contains ensure absent on UTF-8 file name' do
    it 'applies manifest' do
      remove_manifest_location = create_manifest_file(dsc_remove_manifest)
      apply_manifest(nil, catch_failures: true, manifest_file_location: remove_manifest_location) do |result|
        expect(result.stderr).not_to match(%r{Error:})
      end
    end

    it 'removes file' do
      run_shell("powershell.exe -NoProfile -Nologo -Command \"Test-Path 'C:\\#{file_path}\\#{file_name}' -PathType Leaf\"") do |result|
        expect(result.stdout.to_s).to match(%r{False})
      end
    end
  end
end
