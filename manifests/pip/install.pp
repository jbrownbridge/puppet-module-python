define python::pip::install($package,
                            $virtualenv,
                            $ensure=present,
                            $owner=undef,
                            $group=undef,
                            $cache_dir='/var/cache/pip') {
    # Match against whole line if we provide a given version:
    $grep_regex = $package ? {
        /==/ => "^${package}\$",
        default => "^${package}==",
    }

    Exec {
        user => $owner,
        group => $group,
        logoutput => on_failure,
        cwd => "/tmp",
    }

    if $ensure == 'present' {
        exec { "pip install $name":
            command => "$virtualenv/bin/pip install --download-cache=$cache_dir $package",
            require => [Class["packages::python"],
                        Package["python-virtualenv"]],
            unless => "$virtualenv/bin/pip freeze | grep -e $grep_regex"
        }
    } elsif $ensure == 'latest' {
        exec { "pip install $name":
            command => "$virtualenv/bin/pip install --download-cache=$cache_dir -U $package",
            require => [Class["packages::python"],
                        Package["python-virtualenv"]],
        }
    } elsif $ensure == 'absent' {
        exec { "pip install $name":
            command => "$virtualenv/bin/pip uninstall $package",
            require => [Class["packages::python"],
                        Package["python-virtualenv"]],
            onlyif => "$virtualenv/bin/pip freeze | grep -e $grep_regex"
        }
    }
}
