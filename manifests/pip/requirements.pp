# Installs packages in a requirements file for a virtualenv.
# Pip tries to upgrade packages when the requirements file changes.
define python::pip::requirements($virtualenv,
                                 $owner=undef,
                                 $group=undef,
                                 $requirements_check=$python::virtualenv::requirements_check,
                                 $cache_dir='/var/cache/pip') {
    $requirements = $title
    
    Exec {
        path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        user => $owner,
        group => $group,
        logoutput => on_failure,
        cwd => "/tmp",
    }

    file { $requirements:
        ensure => present,
        owner => $owner,
        group => $group,
        content => "# Puppet will install packages listed here and update them if
# the the contents of this file changes.",
        replace => false,
    }

    exec { "update $name requirements":
        command => "$virtualenv/bin/pip install --download-cache=$cache_dir -r $requirements",
        cwd => $virtualenv,
        require => [
            File[$requirements],
            File[$requirements_check],
            Exec["python::virtualenv $virtualenv"],
        ],
        onlyif => "$virtualenv/bin/python $requirements_check $requirements",
    }
}
