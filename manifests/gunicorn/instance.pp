define python::gunicorn::instance($virtualenv,
                                  $src,
                                  $ensure=present,
                                  $wsgi_module="",
                                  $django=false,
                                  $django_settings="",
                                  $version=undef,
                                  $workers=1,
                                  $timeout_seconds=30) {
    $is_present = $ensure == "present"

    $rundir = $python::gunicorn::rundir
    $logdir = $python::gunicorn::logdir
    $owner = $python::gunicorn::owner
    $group = $python::gunicorn::group

    $initscript = "/etc/init.d/gunicorn-${name}"
    $pidfile = "$rundir/$name.pid"
    $socket = "unix:$rundir/$name.sock"
    $logfile = "$logdir/$name.log"

    if $wsgi_module == "" and !$django {
        fail("If you're not using Django you have to define a WSGI module.")
    }

    if $django_settings != "" and !$django {
        fail("If you're not using Django you can't define a settings file.")
    }

    if $wsgi_module != "" and $django {
        fail("If you're using Django you can't define a WSGI module.")
    }

    $gunicorn_package = $version ? {
        undef => "gunicorn",
        default => "gunicorn==${version}",
    }

    if $is_present {
        python::pip::install {
            "$gunicorn_package in $virtualenv":
                package => $gunicorn_package,
                ensure => $ensure,
                virtualenv => $virtualenv,
                owner => $owner,
                group => $group,
                require => Python::Virtaulenv::Instance[$virtualenv],
                before => File[$initscript];

            # for --name support in gunicorn:
            "setproctitle in $virtualenv":
                package => "setproctitle",
                ensure => $ensure,
                virtualenv => $virtualenv,
                owner => $owner,
                group => $group,
                require => Python::Virtualenv::Instance[$virtualenv],
                before => File[$initscript];
        }
    }

    file { $initscript:
        ensure => $ensure,
        content => template("python/gunicorn.init.erb"),
        mode => 744,
        require => File["/etc/logrotate.d/gunicorn-${name}"],
    }

    file { "/etc/logrotate.d/gunicorn-${name}":
        ensure => $ensure,
        content => template("python/gunicorn.logrotate.erb"),
    }

    service { "gunicorn-${name}":
        ensure => $is_present,
        enable => $is_present,
        hasstatus => $is_present,
        hasrestart => $is_present,
        subscribe => $ensure ? {
            'present' => File[$initscript],
            default => undef,
        },
        require => $ensure ? {
            'present' => File[$initscript],
            default => undef,
        },
        before => $ensure ? {
            'absent' => File[$initscript],
            default => undef,
        },
    }
}
