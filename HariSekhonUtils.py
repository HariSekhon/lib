#
#  Author: Hari Sekhon
#  Date: 2008-03-06 15:20:22 +0000 (Thu, 06 Mar 2008)
#  Reinstantiated Date:
#        2013-07-04 00:08:32 +0100 (Thu, 04 Jul 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

""" Personal Library originally started to standardize Nagios Plugin development but superceded by Perl version """

#import os
import re
import sys
#import re
#import signal

__author__      = "Hari Sekhon"
__version__     = 0.5

# Standard Nagios return codes
ERRORS = {
    "OK"        : 0,
    "WARNING"   : 1,
    "CRITICAL"  : 2,
    "UNKNOWN"   : 3,
    "DEPENDENT" : 4
}

def printerr(msg, *indent):
    """ Print error message to stdout """

    if indent:
        print >> sys.stderr, ">>> ",
    print >> sys.stderr, "%s" % msg


def die(msg, *ec):
    """ Print error message and exit program """

    printerr(msg)
    if ec:
        exitcode = ec[0]
        if str(exitcode).isdigit():
            if exitcode > 255:
                sys.exit(exitcode % 256)
            else:
                sys.exit(exitcode)
        elif exitcode in ERRORS.keys():
            sys.exit(ERRORS[exitcode])
        else:
            printerr("Code error, non-digit and non-reconized error status passed as second arg to die()")
            sys.exit(ERRORS["CRITICAL"])
    sys.exit(ERRORS["CRITICAL"])


def quit(status, msg):
    """ Quit with status code from ERRORS dictionary after printing given msg """

    printerr(msg)
    sys.exit(ERRORS[status])


# ============================================================================ #
#                           Jython Utils
# ============================================================================ #

def isJython():
    """ Returns True if running in Jython interpreter """

    if  "JYTHON_JAR" in dir(sys):
        return True
    else:
        return False


def jython_only():
    """ Die unless we are inside Jython """

    if not isJython():
        die("not running in Jython!")


def print_jython_exception():
    """ Prints last Jython Exception """

    printerr("Error: %s" % sys.exc_info()[1].toString())
    if sys.exc_info()[1].toString() == java_oom:
        printerr(java_oom_fix)
    #import traceback; traceback.print_exc()


if isJython():
    java_oom     = "java.lang.OutOfMemoryError: Java heap space"
    java_oom_fix = "\nAdd/Increase -J-Xmx<value> command line argument\n"

# ============================================================================ #

verbose = False
def vprint(msg):
    """ Print if verbose """

    if verbose:
        print msg,


def read_file_without_comments(filename):
    return [ x.rstrip("\n").split("#")[0].strip() for x in open(filename).readlines() ]


# ============================================================================ #
#                                   REGEX
# ============================================================================ #
RE_NAME           = re.compile(r'^[A-Za-z\s\.\'-]+$')
RE_DOMAIN         = re.compile(r'\b(?:[A-Za-z][A-Za-z0-9]{0,62}|[A-Za-z][A-Za-z0-9_\-]{0,61}[a-zA-Z0-9])+\.(?:\b(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\b\.)*\b(?:[A-Za-z]{2,4}|(?:local|museum|travel))\b', re.I)
RE_EMAIL          = re.compile(r'\b[A-Za-z0-9\._\'\%\+-]{1,64}@[A-Za-z0-9\.-]{1,251}\.[A-Za-z]{2,4}\b')

# ============================================================================ #

#DEFAULT_TIMEOUT = 10
#CHECK_NAME      = ""
#
## Pythonic version of "which", inspired by my beloved *nix core utils
## although I've decided it makes more sense to fetch a non-executable
## program and alert on it rather than say it wasn't found in the path 
## at all from a user perspective.
#def which(executable):
#    """Takes an executable name as a string and tests if it is in the path.
#    Returns the full path of the executable if it exists in path, or None if it
#    does not"""
#
#    for basepath in os.environ['PATH'].split(os.pathsep):
#        path = os.path.join(basepath, executable)
#        if os.path.isfile(path):
#            if os.access(path, os.X_OK):
#                return path
#            else:
#                end(UNKNOWN, "utility '%s' is not executable" % path)
#
#    end(UNKNOWN, "'%s' cannot be found in path. Please install " % executable \
#               + "the %s program or fix your PATH environment " % executable  \
#               + "variable")
#
#
#def end(status, message):
#    """Prints a message and exits. First arg is the status code
#    Second Arg is the string message"""
#   
#    if CHECK_NAME in (None, ""):
#        check_name = ""
#    else:
#        check_name = str(CHECK_NAME).strip() + " "
#
#    if status == OK:
#        print "%sOK: %s" % (check_name, message)
#        sys.exit(OK)
#    elif status == WARNING:
#        print "%sWARNING: %s" % (check_name, message)
#        sys.exit(WARNING)
#    elif status == CRITICAL:
#        print "%sCRITICAL: %s" % (check_name, message)
#        sys.exit(CRITICAL)
#    else:
#        # This one is intentionally different
#        print "UNKNOWN: %s" % message
#        sys.exit(UNKNOWN)
#
## ============================================================================ #
#
#class NagiosTester(object):
#    """Holds state for the Nagios test"""
#
#    def __init__(self):
#        """Initializes all variables to their default states"""
#
#        try:
#            from subprocess import Popen, PIPE, STDOUT
#        except ImportError:
#            print "UNKNOWN: Failed to import python subprocess module.",
#            print "Perhaps you are using a version of python older than 2.4?"
#            sys.exit(CRITICAL)
#
#        self.server     = ""
#        self.timeout    = DEFAULT_TIMEOUT
#        self.verbosity  = 0
#
#
#    def validate_variables(self):
#        """Runs through the validation of all test variables
#        Should be called before the main test to perform a sanity check
#        on the environment and settings"""
#
#        self.validate_host()
#        self.validate_timeout()
#
#
#    def validate_host(self):
#        """Exits with an error if the hostname 
#        does not conform to expected format"""
#
#        # Input Validation - Rock my regex ;-)
#        re_hostname = re.compile("^[a-zA-Z0-9]+[a-zA-Z0-9-]*((([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})?$")
#        re_ipaddr   = re.compile("^((25[0-5]|2[0-4]\d|[01]\d\d|\d?\d)\.){3}(25[0-5]|2[0-4]\d|[01]\d\d|\d?\d)$")
#
#        if self.server == None:
#            end(UNKNOWN, "You must supply a server hostname or ip address. " \
#                       + "See --help for details")
#
#        if not re_hostname.match(self.server) and \
#           not re_ipaddr.match(self.server):
#            end(UNKNOWN, "Server given does not appear to be a valid " \
#                       + "hostname or ip address")
#    
#
##    def validate_port(self):
##        """Exits with an error if the port is not valid"""
##
##        if self.port == None:
##            self.port = ""
##        else:
##            try:
##                self.port = int(self.port)
##                if not 1 <= self.port <= 65535:
##                    raise ValueError
##            except ValueError:
##                end(UNKNOWN, "port number must be a whole number between " \
##                           + "1 and 65535")
#
#
#    def validate_timeout(self):
#        """Exits with an error if the timeout is not valid"""
#
#        if self.timeout == None:
#            self.timeout = DEFAULT_TIMEOUT
#        try:
#            self.timeout = int(self.timeout)
#            if not 1 <= self.timeout <= 65535:
#                end(UNKNOWN, "timeout must be between 1 and 3600 seconds")
#        except ValueError:
#            end(UNKNOWN, "timeout number must be a whole number between " \
#                       + "1 and 3600 seconds")
#
#        if self.verbosity == None:
#            self.verbosity = 0
#
#
#    def run(self, cmd):
#        """runs a system command and returns a tuple containing 
#        the return code and the output as a single text block"""
#
#        if cmd == "" or cmd == None:
#            end(UNKNOWN, "Internal python error - " \
#                       + "no cmd supplied for run function")
#        
#        self.vprint(3, "running command: %s" % cmd)
#
#        try:
#            process = Popen( cmd.split(), 
#                             shell=False, 
#                             stdin=PIPE, 
#                             stdout=PIPE, 
#                             stderr=STDOUT )
#        except OSError, error:
#            error = str(error)
#            if error == "No such file or directory":
#                end(UNKNOWN, "Cannot find utility '%s'" % cmd.split()[0])
#            else:
#                end(UNKNOWN, "Error trying to run utility '%s' - %s" \
#                                                      % (cmd.split()[0], error))
#
#        stdout, stderr = process.communicate()
#
#        if stderr == None:
#            pass
#
#        returncode = process.returncode
#        self.vprint(3, "Returncode: '%s'\nOutput: '%s'" % (returncode, stdout))
#
#        if stdout == None or stdout == "":
#            end(UNKNOWN, "No output from utility '%s'" % cmd.split()[0])
#        
#        return (returncode, str(stdout))
#
#
#    def set_timeout(self):
#        """Sets an alarm to time out the test"""
#
#        if self.timeout == 1:
#            self.vprint(2, "setting plugin timeout to 1 second")
#        else:
#            self.vprint(2, "setting plugin timeout to %s seconds"\
#                                                                % self.timeout)
#
#        signal.signal(signal.SIGALRM, self.sighandler)
#        signal.alarm(self.timeout)
#
#
#    def sighandler(self, discarded, discarded2):
#        """Function to be called by signal.alarm to kill the plugin"""
#
#        # Nop for these variables
#        discarded = discarded2
#        discarded2 = discarded
#
#        if self.timeout == 1:
#            timeout = "(1 second)"
#        else:
#            timeout = "(%s seconds)" % self.timeout
#
#        if CHECK_NAME == "" or CHECK_NAME == None:
#            check_name = ""
#        else:
#            check_name = CHECK_NAME.lower().strip() + " "
#
#        end(CRITICAL, "%splugin has self terminated after " % check_name
#                    + "exceeding the timeout %s" % timeout)
#
#
#    def vprint(self, threshold, message):
#        """Prints a message if the first arg is numerically greater than the
#        verbosity level"""
#
#        if self.verbosity >= threshold:
#            print "%s" % message
