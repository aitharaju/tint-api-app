$ar_databases = ['activerecord_unittest', 'activerecord_unittest2']
$as_vagrant   = 'sudo -u ubuntu -H bash -l -c'
$home         = '/home/ubuntu'
include redis
# Pick a Ruby version modern enough, that works in the currently supported Rails
# versions, and for which RVM provides binaries.
$ruby_version = '2.1.1'
$installdir = '/opt/nginx'
$options = "--auto --auto-download  --prefix=${installdir}"

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'apt-get -y update':
    unless => "test -e ${home}/.rvm"
  }
}
class { 'apt_get_update':
  stage => preinstall
}

# --- SQLite -------------------------------------------------------------------

package { ['sqlite3', 'libsqlite3-dev']:
  ensure => installed;
}

# --- Packages -----------------------------------------------------------------

package { 'curl':
  ensure => installed
}

#package { 'build-essential':
#  ensure => installed
#}

package { 'git-core':
  ensure => installed
}

# Nokogiri dependencies.
package { ['libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed
}

# ExecJS runtime.
package { 'nodejs':
  ensure => installed
}


# --- Ruby ---------------------------------------------------------------------

exec { 'installrvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm/bin/rvm",
  require => Package['curl']
}

exec { 'install_ruby_dev':
	command => 'sudo apt-get -q -y install ruby-dev'
}

exec { 'install_ruby':
  # We run the rvm executable directly because the shell function assumes an
  # interactive environment, in particular to display messages or ask questions.
  # The rvm executable is more suitable for automated installs.
  #
  # use a ruby patch level known to have a binary
  command => "${as_vagrant} '~/.rvm/bin/rvm install ruby-${ruby_version}'",
  creates => "${home}/.rvm/bin/ruby",
  require => Exec['installrvm'],
  timeout => 0
}

# RVM installs a version of bundler, but for edge Rails we want the most recent one.
#exec { "bundler":
#command => "gem install bundler", 
# creates => "${home}/.rvm/bin/bundle",
#  require => Exec['rvm']
#}

package { 'vim':
    ensure => present
  }
  
exec {	"rvm_rubygems_current":
	command => "${as_vagrant} 'source ~/.rvm/scripts/rvm'",
	require => Exec['installrvm']

}
exec { "rvm":
	command => "sudo -u ubuntu -H bash -l -c ~/.rvm/bin/rvm rubygems current",
	require => Exec['rvm_rubygems_current']

}

exec { 'default_ruby':
	command => "${as_vagrant} 'rvm use ruby-2.1.1 --default'",
	require => Exec['rvm'],
	logoutput => true

}

exec { 'passenger':
	command => "${as_vagrant} 'gem install passenger'",
	require => Exec['rvm'],
	logoutput => true
	}
#include nginx


# -- Local
   $passenger_deps = [ 'libcurl4-openssl-dev' ]

    

    package { $passenger_deps: ensure => present }
exec { 'nginx-install':

      command => "${as_vagrant} 'rvmsudo  passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx'",
      unless  => "/usr/bin/test -d ${installdir}",
      require => Exec['passenger'],
      logoutput => true
    }
#     -------------------------------------------------------------------

exec { 'nginx':
       command => "wget -O init-deb.sh http://library.linode.com/assets/660-init-deb.sh; sudo mv init-deb.sh /etc/init.d/nginx; sudo chmod +x /etc/init.d/nginx; sudo /usr/sbin/update-rc.d -f nginx defaults",
	require => Exec['nginx-install']
}

exec {'mysql':
	command => "${as_vagrant} 'sudo apt-get install -y libmysqlclient-dev'",
	require => Exec['rvm']

}

exec {'bundle install':
	command => "${as_vagrant} 'bundle install --gemfile=/home/ubuntu/rails-api/Gemfile'",
	require => [Exec['nginx'],Exec['mysql']],
	logoutput => true


}
# Needed for docs generation.
exec { 'update-locale':
  command => 'update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8'
}

exec { 'resque-web':  
  command => "${as_vagrant} 'gem install resque-web'",
  logoutput => true,
  require => Exec['default_ruby']
}
exec { 'nohup-resque-web':
  command => "${as_vagrant} 'resque-web -p 8282'",
  require => Exec['resque-web'], 
  logoutput => true
}
file { "/opt/nginx/conf/conf":
    ensure => "directory" 
}

vhostfile { "localhost":
      server_name => "localhost",
      environment => "development",
      app_directory => "/home/ubuntu/rails-api/public"
  }

service {'nginx':
	 ensure => 'running',
	start => 'service nginx stop;service nginx start',
	stop => 'service nginx stop'
}

define vhostfile($server_name, $environment, $app_directory){

    file { "/opt/nginx/conf/conf/${server_name}":
       
        content => template("my_module/nginx.erb"),
	notify => Service['nginx']
    }
  }
