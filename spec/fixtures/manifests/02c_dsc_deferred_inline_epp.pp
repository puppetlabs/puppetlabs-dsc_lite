# spec/fixtures/manifests/02_dsc_deferred_direct.pp
file { 'C:/Temp':
  ensure => directory,
}

$deferred = Deferred('join', [['hello','-','dsc', '-', 'epp'], ''])

dsc { 'WriteFileViaDSC':
  resource_name => 'File',
  module        => 'PSDesiredStateConfiguration',
  properties    => {
    'DestinationPath' => 'C:\Temp\from_dsc.txt',
    'Type'            => 'File',
    'Ensure'          => 'Present',
    'Contents'        => Deferred('inline_epp', ['<%= $content.unwrap %>', { content => $deferred }]),
  },
  require => File['C:/Temp'],
}
