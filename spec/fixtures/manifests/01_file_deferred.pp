# spec/fixtures/manifests/01_file_deferred.pp
file { 'C:/Temp':
  ensure => directory,
}

$deferred = Deferred('join', [['hello','-','file'], ''])

file { 'C:/Temp/deferred_ok.txt':
  ensure  => file,
  content => $deferred,
  require => File['C:/Temp'],
}
