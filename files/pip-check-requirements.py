import sys
import pkg_resources
import traceback

# check for the package, exiting with 1 if found, and 0 otherwise -- note that
# this is the reverse of what you might think, but works with the 'onlyif'
# parameter in modules/python/manifests/virtualenv.pp.

# For background on the Python stuff, see
# http://peak.telecommunity.com/DevCenter/PkgResources#basic-workingset-methods

requirements = sys.argv[1]
with open(requirements, 'r') as f:
    try:
        for line in f:
            if not line.strip()[0] == '#':
                # use find() instead of require(), since it does not follow dependencies
                req = pkg_resources.Requirement.parse(line)
                dist = pkg_resources.working_set.find(req)
                if not dist:
                    print "not found - exit status 0"
                    sys.exit(0) # found!
        print "found - exit status 1"
        sys.exit(1)
    except (pkg_resources.DistributionNotFound, pkg_resources.VersionConflict):
        traceback.print_exc()
    except Exception:
        # exit with 0 on any other exceptions, too - this will cause pip to try to
        # install the package, which will hopefully lead to a failure that puppet
        # will report on
        traceback.print_exc()

    print "not found - exit status 0"
