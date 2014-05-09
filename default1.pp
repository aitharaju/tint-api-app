$ar_databases = ['activerecord_unittest', 'activerecord_unittest2']
$as_vagrant   = 'sudo -u ubuntu -H bash -l -c'
$home         = '/home/ubuntu'

# Pick a Ruby version modern enough, that works in the currently supported Rails
# versions, and for which RVM provides binaries.
$ruby_version = '2.1.1'
$installdir = '/opt/nginx'
$options = "--auto --auto-download  --prefix=${installdir}"

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm/bin/rvm",
  #require => Package['curl']
}

exec { 'install_ruby':
  # We run the rvm executable directly because the shell function assumes an
  # interactive environment, in particular to display messages or ask questions.
  # The rvm executable is more suitable for automated installs.
  #
  # use a ruby patch level known to have a binary
 command => "${as_vagrant} '${home}/.rvm/bin/rvm install ruby-${ruby_version}'",
  creates => "${home}/.rvm/bin/ruby",
  require => Exec['install_rvm'],
logoutput => true,
 timeout => 0
}

exec { "gem install bundler --no-rdoc --no-ri":
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['install_ruby']
}

exec { "defaulruby":
      creates => "${as_vagrant} 'rvm use ${ruby_version} --default'",
      require => Exec['rvm']
}
package { 'vim':
    ensure => present
  }

exec {  "rvm":
        command => "${as_vagrant} 'source ~/.rvm/scripts/rvm'",
        group => 'root'

}

exec { "rvm  sssrubygems current":
        command => "${as_vagrant} 'rvm rubygems current'",
	require => Exec['rvm']
}

#exec { 'passenger':
 #       command => "gem install passenger"
  #      }
