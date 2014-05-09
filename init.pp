include rvm
rvm_system_ruby {
  'ruby-1.9.2-p290':
    ensure => 'present',
    default_use => true;
  'ruby-1.8.7-p357':
    ensure => 'present',
    default_use => false;
}
