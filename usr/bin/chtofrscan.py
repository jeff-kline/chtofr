#!/usr/bin/env python


DEFAULT_FRCHAN="/usr/bin/FrChannels"
DEFAULT_STEP=10800 # 8 hours

# expected use pattern:
#   chtofrscan PATHLIST [options] | chtofr [options]

# scan each PATH in PATHLIST, use cache as optimization, write to
# stdout as we go...

# if GPS is none, set to  int(now())/STEP*STEP.
# 
# get info from file with largest gpsstart in [GPS-STEP, GPS]


if __name__ == "__main__":
    from optparse import OptionParser

    usage = "usage: %prog PATHLIST [options]"
    description = """Scan PATHLIST for files, write output in chtofr-format to FILE
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
                      help="Path to FrChannels binary", default=DEFAULT_FRCHAN)
    (opts, args) = parser.parse_args()

    
