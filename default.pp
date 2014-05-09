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

package { 'build-essential':
  ensure => installed
}

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

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm/bin/rvm",
  require => Package['curl']
}

exec { 'install_ruby':
  # We run the rvm executable directly because the shell function assumes an
  # interactive environment, in particular to display messages or ask questions.
  # The rvm executable is more suitable for automated installs.
  #
  # use a ruby patch level known to have a binary
  command => "${as_vagrant} '${home}/.rvm/bin/rvm install ruby-${ruby_version} --binary --autolibs=enabled && rvm alias create default ${ruby_version}'",
  creates => "${home}/.rvm/bin/ruby",
  require => Exec['install_rvm']
}

# RVM installs a version of bundler, but for edge Rails we want the most recent one.
exec { "${as_vagrant} 'gem install bundler --no-rdoc --no-ri'":
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['install_ruby']
}

package { 'vim':
    ensure => present
  }
  
exec {	"rvm_rubygems_current":
	command => "${as_vagrant} 'source ~/.rvm/scripts/rvm'",
	group => 'root',
	require => Exec['install_ruby']

}

exec { "rvm":
	command => "${as_vagrant} '${home}/.rvm/bin/rvm rubygems current'",
	require => Exec['rvm_rubygems_current']

}

exec { 'passenger':
	command => "${as_vagrant} 'gem install passenger'",
	require => Exec['rvm']
	}
#include nginx


# -- Local
   $passenger_deps = [ 'libcurl4-openssl-dev' ]

    

    package { $passenger_deps: ensure => present }
exec { 'nginx-install':

      command => "${as_vagrant} 'rvmsudo  passenger-install-nginx-module --auto --auto-download  --prefix=/opt/nginx'",
      group   => 'root',
      unless  => "/usr/bin/test -d ${installdir}",
      require => Exec['passenger']
    }
#     -------------------------------------------------------------------

# Needed for docs generation.
exec { 'update-locale':
  command => 'update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8'
}


  define vhostfile($server_name, $environment, $app_directory){

    file { "/opt/nginx/nginx/${server_name}":
        require => Package["nginx"],
        ensure => "file",
        source =>"puppet:///templates/nginx.conf",
        notify => Service["nginx"]
    }
  }
