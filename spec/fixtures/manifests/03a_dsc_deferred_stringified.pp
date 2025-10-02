# spec/fixtures/manifests/03a_dsc_deferred_stringified.pp
file { 'C:/Temp': ensure => directory }

$deferred = Deferred('join', [['hello','-','var'], ''])

# WRONG on purpose: coerces Deferred to a String at compile time
$stringified = String($deferred)

dsc { 'WriteFileViaDSCVarStringified':
  resource_name => 'File',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'DestinationPath' => 'C:\Temp\from_dsc_var_string.txt',
    'Type'            => 'File',
    'Ensure'          => 'Present',
    'Contents'        => $stringified,
  },
  require => File['C:/Temp'],
}
