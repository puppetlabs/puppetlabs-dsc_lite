# spec/acceptance/deferred_spec.rb
# frozen_string_literal: true

require 'spec_helper_acceptance'

def read_fixture(name)
  File.read(File.join(__dir__, '..', 'fixtures', 'manifests', name))
end

def read_win_file_if_exists(path)
  # Use a script block with literals; avoid $variables to prevent transport/quoting expansion
  # Also keep exit 0 regardless of existence so run_shell doesn't raise.
  ps = %{& { if (Test-Path -LiteralPath '#{path}') { Get-Content -Raw -LiteralPath '#{path}' } else { '<<<FILE_NOT_FOUND>>>' } } }
  r  = run_shell(%(powershell.exe -NoProfile -NonInteractive -Command "#{ps}"))
  body = (r.stdout || '').to_s
  exists = !body.include?('<<<FILE_NOT_FOUND>>>')
  { exists: exists, content: exists ? body : '' }
end

describe 'deferred values with dsc_lite' do
  let(:control_manifest)         { read_fixture('01_file_deferred.pp') }
  let(:dsc_control_manifest_epp) { read_fixture('01b_file_deferred_with_epp.pp') }
  let(:dsc_deferred_direct)      { read_fixture('02_dsc_deferred_direct.pp') }
  let(:dsc_deferred_inline)      { read_fixture('02b_dsc_deferred_inline.pp') } # ← NEW
  let(:dsc_deferred_epp_inline)  { read_fixture('02c_dsc_deferred_inline_epp.pp') } # ← NEW
  let(:dsc_deferred_stringified) { read_fixture('03a_dsc_deferred_stringified.pp') }
  let(:dsc_deferred_bad_unwrap)  { read_fixture('03b_dsc_deferred_bad_unwrap.pp') }

  it 'control (01): native file + Deferred resolves to hello-file' do
    result = idempotent_apply(control_manifest)
    expect(result.exit_code).to eq(0)
    out = read_win_file_if_exists('C:/Temp/deferred_ok.txt')
    expect(out[:exists]).to be(true)
    expect(out[:content].strip).to eq('hello-file')
  end

  it 'control (01b): native file + Deferred resolves to hello-file (EPP)' do
    result = idempotent_apply(dsc_control_manifest_epp)
    expect(result.exit_code).to eq(0)
    out = read_win_file_if_exists('C:/Temp/deferred_ok.txt')
    expect(out[:exists]).to be(true)
    expect(out[:content].strip).to eq('hello-file')
  end

  it '02: passing Deferred via variable to DSC resolves to hello-dsc (otherwise flag bug)' do
    apply = apply_manifest(dsc_deferred_direct)
    out   = read_win_file_if_exists('C:/Temp/from_dsc.txt')
    content = out[:content].strip
    if out[:exists] && content == 'hello-dsc'
      expect(true).to be(true)
    elsif out[:exists] && content =~ %r{Deferred\s*\(|Puppet::Pops::Types::Deferred}i
      raise "BUG: 02 wrote stringified Deferred: #{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    else
      raise "Unexpected 02 outcome. Exists=#{out[:exists]} Content=#{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    end
  end

  # NEW 02b: inline Deferred on the DSC property (no variable intermediary)
  it '02b: passing Deferred inline to DSC resolves to hello-dsc-inline (otherwise flag bug)' do
    apply = apply_manifest(dsc_deferred_inline)
    out   = read_win_file_if_exists('C:/Temp/from_dsc_inline.txt')
    content = out[:content].strip
    if out[:exists] && content == 'hello-dsc-inline'
      expect(true).to be(true)
    elsif out[:exists] && content =~ %r{Deferred\s*\(|Puppet::Pops::Types::Deferred}i
      raise "BUG: 02b wrote stringified Deferred: #{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    else
      raise "Unexpected 02b outcome. Exists=#{out[:exists]} Content=#{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    end
  end

  # NEW 02c: inline Deferred on the DSC property (no variable intermediary)
  it '02c: passing a Deferred inline while calling an epp' do
    apply = apply_manifest(dsc_deferred_epp_inline)
    out   = read_win_file_if_exists('C:/Temp/from_dsc_inline.txt')
    content = out[:content].strip
    if out[:exists] && content == 'hello-dsc-epp'
      expect(true).to be(true)
    elsif out[:exists] && content =~ %r{Deferred\s*\(|Puppet::Pops::Types::Deferred}i
      raise "BUG: 02c wrote stringified Deferred: #{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    else
      raise "Unexpected 02c outcome. Exists=#{out[:exists]} Content=#{content.inspect}\nApply:\n#{apply.stdout}#{apply.stderr}"
    end
  end

  it '03a: stringifying a Deferred writes the function form (reproduces customer report)' do
    apply_manifest(dsc_deferred_stringified)
    out = read_win_file_if_exists('C:/Temp/from_dsc_var_string.txt')
    expect(out[:exists]).to be(true)
    expect(out[:content]).to match(%r{Deferred\s*\(|Puppet::Pops::Types::Deferred}i)
    expect(out[:content]).not_to match(%r{\bhello-var\b})
  end

  it '03b: unwrap on a non‑Sensitive is a no‑op; also writes the function form' do
    apply_manifest(dsc_deferred_bad_unwrap)
    out   = read_win_file_if_exists('C:/Temp/from_dsc_var_bad_unwrap.txt')
    out   = read_win_file_if_exists('C:/Temp/from_dsc_var.txt') unless out[:exists]
    expect(out[:exists]).to be(true)
    expect(out[:content]).to match(%r{Deferred\s*\(|Puppet::Pops::Types::Deferred}i)
    expect(out[:content]).not_to match(%r{\bhello-var\b})
  end
end
