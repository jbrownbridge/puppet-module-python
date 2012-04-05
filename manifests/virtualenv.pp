class python::virtualenv($python='/usr/bin/python2.7',
                         $ensure=present,
                         $owner='root',
                         $group='root',
                         $cache_dir='/var/cache/pip') {
    include packages::python
    include dirs::virtualenv

    $requirements_check = "/usr/local/bin/pip-check-requirements.py" 

    file { $requirements_check:
        source => "puppet:///modules/python/pip-check-requirements.py",
        owner => 'root',
        group => 'root',
    }
}
