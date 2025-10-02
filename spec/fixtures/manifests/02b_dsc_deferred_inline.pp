# spec/fixtures/manifests/02b_dsc_deferred_inline.pp
file { 'C:/Temp':
  ensure => directory,
}

dsc { 'WriteFileViaDSCInline':
  resource_name => 'File',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'DestinationPath' => 'C:\Temp\from_dsc_inline.txt',
    'Type'            => 'File',
    'Ensure'          => 'Present',
    'Contents'        => Deferred('join', [['hello','-','dsc-inline'], '']),
  },
  require => File['C:/Temp'],
}
