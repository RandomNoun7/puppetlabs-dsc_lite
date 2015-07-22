require 'erb'
require 'dsc_utils'
test_name 'MODULES-2230 - C88970 - Apply DSC Registry Resource with "Force" Enabled'

# Init
test_dir_name = 'test'
local_files_root_path = ENV['MANIFESTS'] || 'tests/manifests'

# ERB Manifest
dsc_type = 'registry'
dsc_props = {
  :dsc_ensure    => 'Present',
  :dsc_key       => 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey',
  :dsc_valuename => 'TestForceValue',
  :dsc_valuedata => 'Gif Party!',
  :dsc_valuetype => 'String'
}

dsc_manifest_template_path = File.join(local_files_root_path, 'basic_dsc_resources', 'dsc_single_resource.pp.erb')
dsc_manifest = ERB.new(File.read(dsc_manifest_template_path), 0, '>').result(binding)

# Teardown
teardown do
  confine_block(:to, :platform => 'windows') do
    step 'Remove Test Artifacts'
    set_dsc_resource(
      agents,
      dsc_type,
      :Ensure    => 'Absent',
      :Key       => dsc_props[:dsc_key],
      :ValueName => dsc_props[:dsc_valuename]
    )
  end
end

# Tests
confine_block(:to, :platform => 'windows') do
  agents.each do |agent|
    step 'Apply Manifest to Create Value'
    on(agent, puppet('apply'), :stdin => dsc_manifest, :acceptable_exit_codes => [0,2]) do |result|
      expect_failure('Expected to fail because of MODULES-2256') do
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    # New manifest to force value.
    dsc_props[:dsc_force] = 'true'
    dsc_force_manifest = ERB.new(File.read(dsc_manifest_template_path), 0, '>').result(binding)

    step 'Apply Manifest Again with Force Enabled'
    on(agent, puppet('apply'), :stdin => dsc_force_manifest, :acceptable_exit_codes => [0,2]) do |result|
      expect_failure('Expected to fail because of MODULES-2256') do
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step 'Verify Results'
    expect_failure('Expected to fail because of MODULES-2256') do
      assert_dsc_resource(
        agent,
        dsc_type,
        :Ensure    => dsc_props[:dsc_ensure],
        :Key       => dsc_props[:dsc_key],
        :ValueName => dsc_props[:dsc_valuename],
        :ValueData => dsc_props[:dsc_valuedata],
        :ValueType => dsc_props[:dsc_valuetype],
        :Force     => dsc_props[:dsc_force]
      )
    end
  end
end