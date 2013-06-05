#!/usr/bin/env python


DEFAULT_FRCHAN="/usr/bin/FrChannels"
DEFAULT_STEP=10800 # 8 hours
DEFAULT_OUTPUT="-"

# dirpath: last read time
# only put dirpath here if dirpath contains frames or is empty
CACHE={}

# expected use pattern:
#   chtofrscan PATHLIST [options] | chtofr [options]

# scan each PATH in PATHLIST, use cache as optimization, write to
# stdout as we go...

def _output(path, gps, step=DEFAULT_STEP, frchannels=DEFAULT_FRCHAN, 
            output=DEFAULT_OUTPUT):
    # walk path, skipping all paths that we have seen on interesting
    # directories, list them, parse filenames, get the latest gps in
    # interval [gps-step, gps], write info to filehandle output
    pass

# if GPS is none, set to  int(now())/STEP*STEP.
# 
# get info from file with largest gpsstart in [GPS-STEP, GPS]


if __name__ == "__main__":
    from optparse import OptionParser

    usage = "usage: %prog PATH0 PATH1 ... PATHn [options]"
    description = """Scan each PATH for files, write output in chtofr-format to OUTPUT
                     until done."""
    version = "%prog 0.1"

    parser = OptionParser(usage, version=version, description=description)

    helpstr="""[default: None] GPS time to scan. If None, use current time."""
    parser.add_option("-g", "--gps",
                      help=helpstr, default=None, type="int")
    helpstr="""[default: %d] GPS step size. This is for debugging.""" % (DEFAULT_STEP)
    parser.add_option("-s", "--step",
                      help=helpstr, default=DEFAULT_STEP, type="int")
    parser.add_option("-c", "--cache",
                      help="[default: None] cache file", default=None)
    parser.add_option("-f", "--frchannels",
                      help="[default: %s ] Path to FrChannels binary" % DEFAULT_FRCHAN, 
                      default=DEFAULT_FRCHAN)
    parser.add_option("-o", "--output",
                      help="[default: %s ] write to OUTPUT" % DEFAULT_OUTPUT, 
                      default=DEFAULT_OUTPUT)
    (opts, args) = parser.parse_args()

    kwargs={"step": opts.step, "frchannels": opts.frchannels, "output": opts.output}
    for path in args:
        _output(path, **kwargs)

