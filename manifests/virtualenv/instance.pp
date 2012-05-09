define python::virtualenv::instance($python=$python::virtualenv::python,
                                    $ensure=present,
                                    $requirements=undef,
                                    $packages=undef,
                                    $owner=$python::virtualenv::owner,
                                    $group=$python::virtualenv::group,
                                    $cache_dir=$python::virtualenv::cache_dir) {
    $virtualenv = $title

    if $ensure == 'present' {
        # Parent directory of virtualenv directory. /var/www for /var/www/blog
        $virtualenv_parent = inline_template("<%= virtualenv.match(%r!(.+)/.+!)[1] %>")
        # If parent directory doesn't exist create it with root as owner and group
        if !defined(File[$virtualenv_parent]) {
            file { $virtualenv_parent:
                ensure => directory,
                owner => 'root',
                group => 'root',
            }
        }
        
        # Create directory for virtualenv this needs to be done here as we change
        # user and group Exec runs as below which could result in not being able
        # to create directory if Exec has insufficient permissions
        file { $virtualenv:
            ensure => directory,
            owner => $owner,
            group => $group,
            require => File[$virtualenv_parent],
            before => Exec["python::virtualenv $virtualenv"],
        }

        Exec {
            user => $owner,
            group => $group,
            logoutput => on_failure,
            cwd => "/tmp",
        }

        # Does not successfully run as www-data on Debian:
        exec { "python::virtualenv $virtualenv":
            command => "/usr/bin/virtualenv --no-site-packages -p `which ${python}` ${virtualenv}",
            notify => Exec["update distribute and pip in $virtualenv"],
            # Don't run this command if this file exists
            creates => "$virtualenv/bin/pip",
            require => [
                File[$virtualenv],
                Package["python-virtualenv"]
            ],
        }
       
        if !defined(File[$cache_dir]) {
            file { $cache_dir:
                ensure    => directory,
                owner     => $owner,
            }
        }

        # Some newer Python packages require an updated distribute
        # from the one that is in repos on most systems:
        exec { "update distribute and pip in $virtualenv":
            command     => "$virtualenv/bin/pip install --download-cache=$cache_dir -U distribute pip",
            refreshonly => true,
            require     => File[$cache_dir],
        }

        if $requirements {
        #    Exec["update distribute and pip in $virtualenv"] -> Python::Pip::Requirements[$requirements]

            python::pip::requirements { $requirements:
                virtualenv => $virtualenv,
                owner => $owner,
                group => $group,
                cache_dir => $cache_dir,
                require => [
                    File[$cache_dir],
         #           Exec["python::virtualenv $virtualenv"],
                ]
            }
        }

        if $packages {
         #   Exec["update distribute and pip in $virtualenv"] -> Python::Pip::Install[$packages]

            # now install each package; we use regsubst to qualify the resource
            # name with the virtualenv; a similar regsubst will be used to get
            # the package and version out.
            $qualified_packages = regsubst($packages, "^", "$virtualenv||")
            python::pip::install { $qualified_packages:
                package => regsubst($title, "^.*\\|\\|", ""),
                virtualenv => $virtualenv,
                owner => $owner,
                group => $group,
                cache_dir => $cache_dir,
                require => [
                    File[$cache_dir],
                    Exec["python:virtualenv $virtualenv"],
                ],
            }
        }
    } elsif $ensure == 'absent' {
        file { $virtualenv:
            ensure => $ensure,
            owner => $owner,
            group => $group,
            recurse => true,
            purge => true,
            force => true,
            backup => false,
        }
    }
}
