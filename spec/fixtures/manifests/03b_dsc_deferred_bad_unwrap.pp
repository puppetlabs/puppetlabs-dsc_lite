# spec/fixtures/manifests/03b_dsc_deferred_bad_unwrap.pp
file { 'C:/Temp': ensure => directory }

$deferred = Deferred('join', [['hello','-','var'], ''])

# WRONG: unwrap applies to Sensitive, not Deferred; this should compile-fail
$unwrapped_deferred = String($deferred.unwrap)

dsc { 'WriteFileViaDSCVarBadUnwrap':
  resource_name => 'File',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'DestinationPath' => 'C:\Temp\from_dsc_var_bad_unwrap.txt',
    'Type'            => 'File',
    'Ensure'          => 'Present',
    'Contents'        => $unwrapped_deferred,
  },
  require => File['C:/Temp'],
}
