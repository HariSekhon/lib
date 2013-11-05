#
#  Author: Hari Sekhon
#  Date: 2011-09-15 11:30:24 +0100 (Thu, 15 Sep 2011)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

#  HARI SEKHON:
#
#  Library of personal stuff I use a lot, cobbled together from bits of my own
#  scripts over the last few years and a Nagios library I started in Python years ago
#
#  I welcome feedback on this. Currently this lib isn't designed for purity but rather convenience
#  and ease of maintenance.  If you have a better way of doing anything in this library that will
#  not significantly inconvenience me then let me know!
#
#  PLEASE DO NOT CHANGE ANYTHING IN HERE!
#
#  You may use this library at your own risk. You may not change it.
#
# ============================================================================ #
#  Unit Tests
#
#  make test
#
#  This will call a bunch of Test::More unit tests from t/
#
# ============================================================================ #
#  Functional Tests
#
#  If you import this library then at the very minimum I recommend that you add
#  one or more functional tests to cover all usage scenarios for your code to
#  validate when this library is updated.
#
#  ./testcmd.exp path_to_tests/*.exptest
#
#  One of the original purposes of this library was to be able to rapidly develop Nagios plugins.
#  If you use this to ease your development of Nagios plugins I strongly recommend that you add
#  functional tests and run them whenever either this library or your plugin changes
#
#  Running make test under nagios-plugins will run all unit and functional tests
#  to make sure everything still works as expected before releasing to production. It will
#  also check for plugins that are importing this library but don't have any test files
#
#  You don't want your Nagios screen to suddenly go all red because you haven't done your QA!
#
#  If you've added some code and don't have a corresponding suite of test files
#  in the ./tests directory then they may well break when I update this library.

package HariSekhonUtils;
use warnings;
use strict;
use 5.006_001;
use Carp;
use Cwd 'abs_path';
use Fcntl ':flock';
use File::Basename;
use Getopt::Long qw(:config bundling);
use POSIX;
#use Sys::Hostname;

our $VERSION = "1.5.19";

#BEGIN {
# May want to refactor this so reserving ISA, update: 5.8.3 onwards
#use Exporter "import";
#require Exporter;
use Exporter;
our @ISA = qw(Exporter);
# consider replacing the above with these two lines for compatibility with Perl 5.6 and then removing our from @EXPORT* below
#use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
#@ISA = qw(Exporter);
our %EXPORT_TAGS = (
    'array' =>  [   qw(
                        compact_array
                        inArray
                        uniq_array
                    ) ],
    'cmd'   =>  [   qw(
                        cmd
                        pkill
                        set_sudo
                        which
                    ) ],
    'file'  => [    qw(
                        open_file
                        get_path_owner
                    ) ],
    'io'    => [    qw(
                        autoflush
                    ) ],
    'is'    => [    qw(
                        isArray
                        isAlNum
                        isAwsAccessKey
                        isAwsSecretKey
                        isDatabaseColumnName
                        isDatabaseFieldName
                        isDatabaseTableName
                        isDigit
                        isDomain
                        isDnsShortname
                        isEmail
                        isFilename
                        isFloat
                        isFqdn
                        isHash
                        isHex
                        isHost
                        isHostname
                        isIP
                        isInt
                        isInterface
                        isKrb5Princ
                        isJson
                        isLabel
                        isLinux
                        isMac
                        isNagiosUnit
                        isOS
                        isPort
                        isProcessName
                        isScalar
                        isUrl
                        isUrlPathSuffix
                        isUser
                        user_exists
                    ) ],
    'lock'  =>  [   qw(
                        go_flock_yourself
                        flock_off
                    ) ],
    'log'   =>  [   qw(
                        log
                        loginit
                        logdie
                    ) ],
    'net'   =>  [   qw(
                        resolve_ip
                    ) ],
    'options' => [  qw(
                        add_options
                        get_options
                        check_thresholds
                        expand_units
                        msg_perf_thresholds
                        parse_file_option
                        plural
                        remove_timeout
                        usage
                        validate_thresholds
                        version
                    ) ],
    'os'    =>  [   qw(
                        isLinux
                        isMac
                        isOS
                        linux_mac_only
                        linux_only
                        mac_only
                    ) ],
    'regex' =>  [   qw(
                        $domain_regex
                        $email_regex
                        $filename_regex
                        $fqdn_regex
                        $host_regex
                        $hostname_regex
                        $ip_regex
                        $krb5_princ_regex
                        $mac_regex
                        $process_name_regex
                        $rwxt_regex
                        $subnet_mask_regex
                        $tld_regex
                        $url_path_suffix_regex
                        $url_regex
                        $user_regex
                    ) ],
    'status' =>  [  qw(
                        $status
                        status
                        critical
                        warning
                        unknown
                        is_critical
                        is_warning
                        is_unknown
                        is_ok
                        get_status_code
                        get_upper_threshold
                        get_upper_thresholds
                        msg_thresholds
                        try
                        catch
                        catch_quit
                        die_handler_on
                        die_handler_off
                        quit
                    ) ],
    'string' => [   qw(
                        lstrip
                        ltrim
                        rstrip
                        rtrim
                        strip
                        trim
                    ) ],
    'time'    => [  qw(
                        sec2min
                    ) ],
    'timeout' => [  qw(
                        set_timeout
                        set_timeout_default
                        set_timeout_max
                    ) ],
    'validate' => [ qw(
                        validate_alnum
                        validate_aws_access_key
                        validate_aws_bucket
                        validate_aws_secret_key
                        validate_database
                        validate_database_columnname
                        validate_database_fieldname
                        validate_database_query_select_show
                        validate_database_tablename
                        validate_dir
                        validate_directory
                        validate_domain
                        validate_domainname
                        validate_email
                        validate_file
                        validate_filename
                        validate_float
                        validate_fqdn
                        validate_host
                        validate_hostname
                        validate_int
                        validate_integer
                        validate_interface
                        validate_ip
                        validate_krb5_princ
                        validate_label
                        validate_node_list
                        validate_password
                        validate_port
                        validate_process_name
                        validate_regex
                        validate_resolvable
                        validate_thresholds
                        validate_units
                        validate_url
                        validate_url_path_suffix
                        validate_user
                        validate_user_exists
                        validate_username
                    ) ],
    'vars' =>   [   qw(
                        $critical
                        $debug
                        $email
                        $host
                        $msg
                        $msg_err
                        $msg_threshold
                        $nagios_plugins_support_msg
                        $password
                        $plural
                        $port
                        $progname
                        $status
                        $status_prefix
                        $sudo
                        $timeout
                        $timeout_default
                        $timeout_max
                        $timeout_min
                        $usage_line
                        $user
                        $verbose
                        $version
                        $warning
                        %ERRORS
                        %emailoptions
                        %hostoptions
                        %options
                        %thresholdoptions
                        %thresholds
                        %useroptions
                        @usage_order
                    ) ],
    'verbose' => [  qw(
                        code_error
                        debug
                        hr
                        verbose_mode
                        vlog
                        vlog2
                        vlog3
                        vlog_options
                    ) ],
    'web'   =>  [   qw(
                        curl
                        wget
                    ) ],
);
# same as below
#Exporter::export_tags('foo');
#Exporter::export_ok_tags('bar');
# TODO: move all of this from EXPORT to EXPORT_OK while validating all dependent code still works
our @EXPORT =   (
                    @{$EXPORT_TAGS{'array'}},
                    @{$EXPORT_TAGS{'cmd'}},
                    @{$EXPORT_TAGS{'io'}},
                    @{$EXPORT_TAGS{'is'}},
                    @{$EXPORT_TAGS{'file'}},
                    @{$EXPORT_TAGS{'lock'}},
                    @{$EXPORT_TAGS{'net'}},
                    @{$EXPORT_TAGS{'options'}},
                    @{$EXPORT_TAGS{'os'}},
                    @{$EXPORT_TAGS{'status'}},
                    @{$EXPORT_TAGS{'string'}},
                    @{$EXPORT_TAGS{'timeout'}},
                    @{$EXPORT_TAGS{'validate'}},
                    @{$EXPORT_TAGS{'vars'}},
                    @{$EXPORT_TAGS{'verbose'}},
                    @{$EXPORT_TAGS{'web'}},
                );
our @EXPORT_OK = (  @EXPORT,
                    @{$EXPORT_TAGS{'log'}},
                    @{$EXPORT_TAGS{'regex'}},
                    @{$EXPORT_TAGS{'time'}},
                 );
# could also do this:
#{ my %seen; push @{$EXPORT_TAGS{'all'}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS; }
$EXPORT_TAGS{'all'}         = [ @EXPORT_OK  ];
$EXPORT_TAGS{'most'}        = [ @EXPORT     ];
$EXPORT_TAGS{'EXPORT_OK'}   = [ @EXPORT_OK  ];
$EXPORT_TAGS{'EXPORT'}      = [ @EXPORT     ];

BEGIN {
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
    $ENV{'PATH'} = '/bin:/usr/bin';

    # If we're a Nagios plugin check_* then make stderr go to stdout
    if(substr(basename($0), 0, 6) eq "check_"){
        open STDERR, ">&STDOUT";
        select(STDERR);
        $| = 1; 
        select(STDOUT);
        $| = 1; 
    }

    sub die_sub {
        my $str = "@_" || "Died";
        # mimic original die behaviour by only showing code line when there is no newline at end of string
        if(substr($str, -1, 1) eq "\n"){
            print STDERR $str;
        } else {
            carp $str;
        }
        exit 2;
    };
    $SIG{__DIE__} = \&die_sub;

    # This is because the die handler causes program exit instead of return from eval {} block required for exception handling
    sub try(&) {
        undef $SIG{__DIE__};
        eval {$_[0]->()};
        $SIG{__DIE__} = \&die_sub;
    }

    sub catch(&) {
        $_[0]->($@) if $@;
    }
}

# quick prototype to allow me to use this just below
sub quit(@);

our $progname = basename $0;
$progname =~ /^([\w\.\/_-]+)$/ or quit("UNKNOWN", "Invalid program name - does not adhere to strict regex validation, you should name the program simply and sanely");
$progname = $1;

# Std Nagios Exit Codes. Not using weak nagios utils.pm. Also improves portability to not rely on it being present
our %ERRORS = (
    "OK"        => 0,
    "WARNING"   => 1,
    "CRITICAL"  => 2,
    "UNKNOWN"   => 3,
    "DEPENDENT" => 4
);

our $nagios_plugins_support_msg = "Please try latest version from https://github.com/harisekhon/nagios-plugins, re-run on command line with -vvv and if problem persists paste full output from -vvv mode in to a ticket requesting a fix/update at https://github.com/harisekhon/nagios-plugins/issues/new";

# ============================================================================ #
# Validation Regex - maybe should qr// here but it makes the vlog option output messy
# ============================================================================ #
# tried reversing these to be in $regex_blah format and not auto exporting but this turned out to be less intuitive from the perspective of a module caller and it was convenient to just use the regex in pieces of code without having to import them specially. This also breaks some code such as check_hadoop_jobtracker.pl which uses $domain_regex
my  $domain_component   = '\b(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\b';
# validated against http://data.iana.org/TLD/tlds-alpha-by-domain.txt which lists all possible TLDs assigned by IANA
# this matches everything except the XN--\w{6,10} TLDs as of 8/10/2012
our $tld_regex          = '\b(?:[A-Za-z]{2,4}|(?i:local|museum|travel))\b';
our $domain_regex       = '(?:' . $domain_component . '\.)+' . $tld_regex;
our $hostname_component = '\b(?:[A-Za-z0-9]{3,63}|[A-Za-z0-9][A-Za-z0-9_\-]{1,61}[a-zA-Z0-9])\b';
our $hostname_regex     = "(?:$hostname_component(?:\.$domain_regex)?|$domain_regex)";
our $filename_regex     = '[\/\w\s_\.:,\*\=\%\?\+-]+';
our $rwxt_regex         = '[r-][w-][x-][r-][w-][x-][r-][w-][xt-]';
our $fqdn_regex         = $hostname_component . '\.' . $domain_regex;
# SECURITY NOTE: I'm allowing single quote through as it's found in Irish email addresses. This makes the $email_regex non-safe without further validation. This regex only tests whether it's a valid email address, nothing more. DO NOT UNTAINT EMAIL or pass to cmd to SQL without further validation!!!
our $email_regex        = '\b[A-Za-z0-9](?:[A-Za-z0-9\._\%\'\+-]{0,62}[A-Za-z0-9\._\%\+-])?@[A-Za-z0-9\.-]{2,251}\.[A-Za-z]{2,4}\b';
# TODO: review this IP regex again
our $ip_regex           = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-4]|2[0-4][0-9]|[01]?[1-9][0-9]|[01]?0[1-9]|[12]00|[1-9])\b'; # not allowing 0 or 255 as the final octet
our $subnet_mask_regex  = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[1-9][0-9]|[01]?0[1-9]|[12]00|[0-9])\b';
our $mac_regex          = '\b[0-9A-F-af]{1,2}[:-](?:[0-9A-Fa-f]{1,2}[:-]){4}[0-9A-Fa-f]{1,2}\b';
our $host_regex         = "\\b(?:$hostname_regex|$ip_regex)\\b";
# I did a scan of registered running process names across several hundred linux servers of a diverse group of enterprise applications with 500 unique process names (58k individual processes) to determine that there are cases with spaces, slashes, dashes, underscores, chevrons (<defunct>), dots (script.p[ly], in.tftpd etc) to determine what this regex should be. Incidentally it appears that Linux truncates registered process names to 15 chars.
# This is not from ps -ef etc it is the actual process registered name, hence init not [init] as it appears in ps output
our $process_name_regex = '[\w\s_\.\/\<\>-]+';
our $url_path_suffix_regex = '/(?:[\w\.\/\%\&\?\=\+-]+)?';
our $url_regex          = '\b(?i:https?://' . $host_regex . '(?::\d{1,5})?(?:' . $url_path_suffix_regex . ')?)';
our $user_regex         = '\b[A-Za-z][A-Za-z0-9]+\b';
our $krb5_principal_regex = "$user_regex(?:(?:\/$hostname_regex)?\@$domain_regex)?";
# ============================================================================ #

our $critical;
our $debug = 0;
our $email;
our $help;
our $host;
our $msg = "";
our $msg_err = "";
our $msg_threshold = "";
my  @options;
our %options;
our $password;
our $port;
my  $selflock;
our $status = "UNKNOWN";
our $status_prefix = "";
our $sudo = "";
our $syslog_initialized = 0;
our $timeout_default = 10;
our $timeout_max     = 60;
our $timeout_min     = 1;
our $timeout         = $timeout_default;
our $usage_line      = "usage: $progname [ options ]";
our $user;
our %thresholds;
# Standard ordering of usage options for help. Exported and overridable inside plugin to customize usage()
our @usage_order = qw(host port user users groups password database query field regex warning critical);
# Not sure if I can relax the case sensitivity on these according to the Nagios Developer guidelines
my  @valid_units = qw/% s ms us B KB MB GB TB c/;
our $verbose = 0;
our $version;
our $warning;

# ============================================================================ #
#                                   Options
# ============================================================================ #
# universal options added automatically when using get_options()
our %default_options = (
    "D|debug+"     => [ \$debug,    "Debug code" ],
    "t|timeout=i"  => [ \$timeout,  "Timeout in secs (default: $timeout_default)" ],
    "v|verbose+"   => [ \$verbose,  "Verbose mode (-v, -vv, -vvv ...)" ],
    "V|version"    => [ \$version,  "Print version and exit" ],
    "h|help"       => [ \$help,     "Print description and usage options" ],
);

# These two subroutines are primarily for my other programs such as my spotify programs which have necessarily longer run times and need a good way to set this and have the %default_options auto updated for usage() to automatically stay in sync with the live options
sub set_timeout_max ($) {
    $timeout_max = shift;
    isInt($timeout_max) or code_error("must pass an integer to set_timeout_max()");
}


sub set_timeout_default ($) {
    $timeout_default = shift;
    isInt($timeout_default) or code_error("must pass an integer to set_timeout_default()");
    ($timeout_default > $timeout_max) and code_error("\$timeout_default ($timeout_default) may not be higher than \$timeout_max ($timeout_max)");
    ($timeout_default < $timeout_min) and code_error("\$timeout_default ($timeout_default) may not be lower than \$timeout_min ($timeout_min)");
    $timeout = $timeout_default;
    $default_options{"t|timeout=i"} = [ \$timeout, "Timeout in secs (default: $timeout_default)" ];
}


# Optional options
our %hostoptions = (
    "H|host=s"      => [ \$host, "Host to connect to" ],
    "p|port=s"      => [ \$port, "Port to connect to" ],
);
our %useroptions = (
    "U|user=s"      => [ \$user,     "User"      ],
    "P|password=s"  => [ \$password, "Password"  ],
);
our %thresholdoptions = (
    "w|warning=s"   => [ \$warning,  "Warning  threshold or ran:ge (inclusive)" ],
    "c|critical=s"  => [ \$critical, "Critical threshold or ran:ge (inclusive)" ],
);
our %emailoptions = (
    "E|email=s"     => [ \$email,   "Email address" ],
);
my $short_options_len = 0;
my $long_options_len  = 0;

# ============================================================================ #
#                           Nagios Exit Code Functions
# ============================================================================ #

# Set status safely - escalate only

# there is no ok() since that behaviour needs to be determined by scenario

sub unknown () {
    if($status eq "OK"){
        $status = "UNKNOWN";
    }
}

sub warning () {
    if($status ne "CRITICAL"){
        $status = "WARNING";
    }
}

sub critical () {
    $status = "CRITICAL";
}

############################
sub is_ok () {
    ($status eq "OK");
}

sub is_warning () {
    ($status eq "WARNING");
}

sub is_critical () {
    ($status eq "CRITICAL");
}

sub is_unknown () {
    ($status eq "UNKNOWN");
}

sub get_status_code (;$) {
    if($_[0]){
        defined($ERRORS{$_[0]}) || code_error("invalid status '$_[0]' passed to get_status_code()");
        return $ERRORS{$_[0]};
    } else {
        defined($ERRORS{$status}) || code_error("invalid status '$status' found in \$status variable used by get_status_code()");
        return $ERRORS{$status};
    }
}

sub status () {
    vlog("status: $status");
}

# status2/3 not exported/used at this time
sub status2 () {
    vlog2("status: $status");
}

sub status3 () {
    vlog3("status: $status");
}

# requires that you 'use Data::Dumper' in calling program, since not all programs will need this
sub catch_quit ($) {
    my $errmsg = $_[0];
    catch {
        if(defined($@->{"message"})){
            quit "CRITICAL", "$errmsg: " . ref($@) . ": " . $@->{"message"};
        } else {
            quit "CRITICAL", "$errmsg: " . Dumper($@);
        }
    }
}

# ============================================================================ #


sub option_present ($) {
    my $new_option = shift;
    grep {
        my @option_switches = split("|", $_);
        my @new_option_switches = split("|", $new_option);
    } (keys %options);
}


# TODO: consider calling this from get_options and passing hashes we want options for straight to that sub

# TODO: fix this to use option_present
sub add_options ($) {
    my $options_hash = shift;
    isHash($options_hash, 1);
    #@default_options{keys %options} = values %options;
    #@default_options{keys %{$_[0]}} = values %{$options_hash};
    foreach my $option (keys %{$options_hash}){
        unless(option_present($option)){
            print "want to add $option\n";
            #$default_options{$option} = ${$options_hash{$option}};
        }
    }

#    #my (%optionshash) = @_;
#    # by ref is faster
#    my $hashref = shift;
#    unless(isHash($hashref)){
#        #my ($package, $file, $line) = caller;
#        code_error("non hash ref passed to add_options subroutine"); # at " . $file . " line " . $line);
#    }
#    # TODO: consider replacing this with first position insertion in array in get_options for efficiency
#    foreach my $option (keys %options){
#        unless grep { grep($options keys %{$_} } @options){
#            push(@options, { $_ => $options{$_} }) 
#        };
#    }
#    #foreach(keys %hashref){
#    #    push(@options, { $_ => $hashref{$_} });
#    #}
}


#sub update_option_description {
#    my $option = 
#}


#sub add_thresholds {
#    our $range_inversion = 0;
#    foreach(keys %thresholds){
#        $options{$_} = $thresholds{$_};
#    }
#}


# For reference only, faster to just put this directly in to code
#sub isUserNameEUID(){
#    #my $user = shift;
#    #defined($user) or code_error "no user passed to amIuser()";
#    # checking EUID against arg
#    getpwuid($>) eq shift;
#}


sub autoflush () {
    select(STDERR);
    $| = 1;
    select(STDOUT);
    $| = 1;
}


sub check_threshold ($$) {
    #subtrace(@_);
    my $threshold = shift;
    my $result    = shift;

    $threshold =~ /^warning|critical$/ or code_error("invalid threshold name passed to check_threshold subroutine");
    isFloat($result, 1) or code_error("Non-float passed to check_threshold subroutine");

    my $upper = defined($thresholds{$threshold}{"upper"}) ? $thresholds{$threshold}{"upper"} : undef;
    my $lower = defined($thresholds{$threshold}{"lower"}) ? $thresholds{$threshold}{"lower"} : undef;
    my $invert_range = $thresholds{$threshold}{"invert_range"} || undef;
    my $error = 0;

    if(!$invert_range){
        debug("doing straight non range-inverted $threshold threshold checks");
        debug("if result $result > $threshold upper ($upper)") if defined($upper);
        debug("if result $result < $threshold lower ($lower)") if defined($lower);
        if(defined($upper) and $result > $upper){
            $error = "$result>$upper";
        }
        elsif(defined($lower) and $result < $lower){
            $error = "$result<$lower";
        }
    } else {
        debug("doing range-inverted $threshold threshold checks");
        debug("if result $result <= $threshold upper ($upper)") if defined($upper);
        debug("if result $result >= $threshold lower ($lower)") if defined($lower);
        if(defined($upper) and defined($lower)){
            if($lower <= $result and $result <= $upper ){
            #$error = " $result not within range $lower-$upper";
            $error = "not within range $lower-$upper";
            }
        } else {
            if(defined($upper) and $result <= $upper){
                $error = "$result<=$upper";
            }
            elsif(defined($lower) and $result >= $lower){
                $error = "$result>=$lower";
            }
        }
    }
    if($error){
        $thresholds{$threshold}{"error"} = $error;
        vlog2("result outside of $threshold thresholds: $error\n");
        eval $threshold;
        return undef;
    }
    return 1;
}


sub check_thresholds ($;$) {
    #subtrace(@_);
    my $no_msg_thresholds = (defined($_[1]) ? 1 : 0);
    my $status = check_threshold("critical", $_[0]) and
                 check_threshold("warning",  $_[0]);
    msg_thresholds() unless $no_msg_thresholds;
    return $status;
}


#sub checksum ($;$) {
#    my $file = shift;
#    my $algo = shift;
#    $algo or $algo = "md5";
#    my $fh;
#    unless(open($fh, $file)){
#        vlog "Failed to read file '$file': $!\n";
#        return undef;
#    }
#    binmode($fh);
#    my $checksum;
#    if($algo eq "md5"){
#        $checksum = Digest::MD5->new;
#    } elsif ($algo eq "sha1"){
#        $checksum = Digest::Sha->new("sha1");
#    } else {
#        croak "checksum passed unsupported algorithm type '$algo'";
#    }
#    $checksum->addfile($fh);
#    return $checksum->hexdigest;
#}
#sub sha1sum {
#    return checksum($_[0], "sha1");
#}
#
#sub md5sum {
#    return checksum($_[0], "md5");
#}


sub cmd ($;$$) {
    my $cmd       = shift;
    my $errchk    = shift;
    my $inbuilt   = shift;
    $cmd =~ s/^\s+//;
    my $prog      = (split(/\s+/, $cmd))[0];
    if($prog eq "exec"){
        $prog = (split(/\s+/, $cmd))[1];
    }
    if($inbuilt){
        # TODO: consider adding inbuilt check, however this means two shell calls per command, very inefficient, think it's better to just catch failure
        #type($prog, 1);
    } else {
        which($prog, 1);
    }
    # this would be if we were gonna support shell built-ins
    #unless(which($prog)){
    #    type($prog) or quit("UNKNOWN", "'$prog' command was not found in \$PATH and is not a shell built-in");
    #    $prog = (split(/\s+/, $cmd))[1];
    #    which($prog, 1);
    #}
    if($cmd =~ s/\|\s*$//){
        # return reference to filehandle for more efficient processing
        vlog2("opening cmd pipe");
        vlog3("cmd: $cmd");
        open my $fh, "$cmd |";
        return $fh;
    }
    vlog3("cmd: $cmd");
    my $return_output   = `$cmd 2>&1`;
    my $returncode      = $?;
    my @output          = split("\n", $return_output);
    $returncode         = $returncode >> 8;
    if ($verbose >= 3) {
        #foreach(@output){ print "output: $_\n"; }
        print "output:\n\n$return_output\n";
        print "returncode: $returncode\n\n";
    }
    if ($errchk and $returncode != 0) {
        my $err = "";
        foreach (@output) {
            $err .= " " . trim($_);
        }
        quit("CRITICAL", "'$cmd' returned $returncode -$err");
    }
    # TODO: extend to return result and output and not check returncode in func or use wrapper func to throw error on non zero return code
    return @output;
}


sub code_error (@) {
    use Carp;
    #quit("UNKNOWN", "Code Error - @_");
    $! = $ERRORS{"UNKNOWN"};
    if($debug){
        confess "UNKNOWN: Code Error - @_";
    } else {
        croak "UNKNOWN: Code Error - @_";
    }
}


# Remove blanks from array
sub compact_array (@) {
    return grep { $_ !~ /^\s*$/ } @_;
}


sub curl ($) {
    unless(defined(&main::get)){
        # inefficient, it'll import for each curl call, instead force top level author to 
        # use LWP::Simple 'get'
        #debug("importing LWP::Simple 'get'\n");
        #require LWP::Simple;
        #import LWP::Simple "get";
        code_error "called curl() without declaring \"use LWP::Simple 'get'\"";
    }
    my $url = shift;
    #debug("url passed to curl: $url");
    isUrl($url) or code_error "invalid url supplied to curl()";
    my $host = $url;
    $host =~ s/^https?:\/\///;
    $host =~ s/(?::\d+)?(?:\/.*)?$//;
    isHost($host) or die "Invalid host determined from URL in curl()";
    validate_resolvable($host);
    vlog2("HTTP GET $url");
    my $content = main::get $url;
    my ($result, $err) = ($?, $!);
    vlog3("returned HTML:\n\n" . ( $content ? $content : "<blank>" ) . "\n");
    vlog2("result: $result");
    vlog2("error:  " . ( $err ? $err : "<none>" ) . "\n");
    if($result ne 0 or $err){
        quit("CRITICAL", "failed to get '$url': $err");
    }
    unless($content){
        quit("CRITICAL", "blank content returned from '$url'");
    }
    return $content;
}


sub debug (@) {
    return undef unless $debug;
    my ( $package, $filename, $line ) = caller;
    my $debug_msg = "@_";
    $debug_msg =~ s/^(\n+)//;
    #my $prefix_newline = $1 || "";
    my $sub = (caller(1))[3];
    if($sub){
        $sub .= "()";
    } else {
        $filename = basename $filename;
        $sub = "global $filename line $line";
    }
    #printf "${prefix_newline}debug: %s => %s\n", $sub, $debug_msg;
    printf "debug: %s => %s\n", $sub, $debug_msg;
}


# For reference purposes at this point
#sub escape_regex ($) {
#    my $regex = shift;
#    defined($regex) or code_error "no regex arg passed to escape_regex() subroutine";
#    #$regex =~ s/([^\w\s\r\n])/\\$1/g;
#    # backslashes everything that isn't /[A-Za-z_0-9]/
#    $regex = quotemeta($regex); # $regex = \Q$regex\E;
#    return $regex;
#}


sub expand_units ($$;$) {
    my $num   = shift;
    my $units = shift;
    my $name  = shift;
    my $power;
    #defined($num)   || code_error "no num passed to expand_units()";
    isFloat($num)   || code_error "non-float arg 1 passed to expand_units()";
    #defined($units) || code_error "no units passed to expand_units()";
    if   ($units =~ /^KB$/i){ $power = 1; }
    elsif($units =~ /^MB$/i){ $power = 2; }
    elsif($units =~ /^GB$/i){ $power = 3; }
    elsif($units =~ /^TB$/i){ $power = 4; }
    elsif($units =~ /^PB$/i){ $power = 5; }
    else { code_error "unrecognized units " . ($name ? "for $name" : "passed to expand_units()" ) . ", code may need updating, run with -vvv to debug"; }
    return $num * (1024**$power);
}


sub get_options {
    my %options3;
    #@default_options{ keys %options } = values %options;
    foreach my $default_option (keys %default_options){
        # Check that the %options given don't clash with any existing or in-built options
        foreach my $option (keys %options){
            foreach my $switch (split(/\s*\|\s*/, $option)){
                if(grep({$_ eq $switch} split(/\s*\|\s*/, $default_option))){
                    code_error("Key clash on switch '$switch' with in-built option '$default_option' vs provided option '$option'");
                }
            }
        }
        $options{$default_option} = $default_options{$default_option}; #unless exists $options{$default_option}; # check above is stronger
    }
    foreach(keys %options){
        unless (isArray($options{$_})){
            code_error("invalid value for %options key '$_', should be an array not " . lc ref($options{$_}) );
        }
        $options3{$_} = $options{$_}[0];
    }
    GetOptions(%options3) or usage();
    # TODO: finish this debug code
#    if($debug){
#        foreach(sort keys %options3){
#            if(defined($options3{$_}[0])){
#                debug("var $options3{$_}[0] = $options3{$_}[0]");
#            }
#        }
#    }

    defined($help) and usage();
    defined($version) and version();
    verbose_mode();
    #vlog2("options:\n");
    # validation is done on an option by option basis
}


sub get_path_owner ($) {
    # defined($_[0]) || code_error "no path passed to get_path_owner()";
    my $path = shift;
    open my $fh, $path || return undef;
    my @stats = stat($fh);
    close $fh;
    defined($stats[4]) || return undef;
    return getpwuid($stats[4]) || 0;
}

sub get_upper_threshold ($) {
    my $type = shift;
    if($type eq "warning" or $type eq "critical"){
        if(defined($thresholds{$type}{"upper"})){
            return $thresholds{$type}{"upper"};
        } else {
            return "";
        }
    }
    code_error "invalid threshold type '$type' passed to get_upper_threshold(), must be one of: warning critical";
}

sub get_upper_thresholds () {
    return get_upper_threshold("warning") . ";" . get_upper_threshold("critical");
}

# go flock ur $self ;)
sub go_flock_yourself (;$$) {
    my $there_can_be_only_one = shift;
    my $wait = shift;
    my $locking_options;
    if($wait){
        vlog2("waiting to go flock myself");
        $locking_options = LOCK_EX;
    } else {
        $locking_options = LOCK_EX|LOCK_NB;
    }
    if($there_can_be_only_one){
        open  *{0} or die "Failed to open *{0} for lock: $!\n";
        flock *{0}, $locking_options or die "Failed to acquire global lock, related code is already running somewhere!\n";
    } else {
        open $selflock, $0 or die "Failed to open $0 for lock: $!\n";
        flock $selflock, $locking_options or die "Another instance of " . abs_path($0) . " is already running!\n";
    }
    vlog2("truly flocked now");
    1;
}

sub flock_off (;$) {
    my $there_can_be_only_one = shift;
    if($there_can_be_only_one){
        open  *{0} or die "Failed to open *{0} for lock: $!\n";
        flock *{0}, LOCK_UN;
    } else {
        open $selflock, $0 or die "Failed to open $0 for lock: $!\n";
        flock $selflock, LOCK_UN;
    }
}


sub hr() {
    print "# " . "="x76 . " #\n";
}


sub inArray ($@) {
    my $item  = shift;
    my @array = @_;
    my $found = 0;
    foreach(@array){
        #vlog("checking $item against $_");
        if($item eq $_){
            $found++;
        }
    }
    return $found;
}


sub isAlNum ($) {
    my $arg = shift;
    defined($arg) or return undef; #code_error("no arg passed to isAlNum()");
    $arg =~ /^([A-Za-z0-9]+)$/ or return undef;
    return $1;
}


sub isArray ($) {
    #defined($_[0]) or code_error "no arg passed to isArray()";
    my $isArray = ref $_[0] eq "ARRAY";
    if($_[1]){
        unless($isArray){
            code_error "non array reference passed to isArray()";
        }
    }
    return $isArray;
}


sub isAwsAccessKey($){
    my $aws_access_key = shift;
    defined($aws_access_key) or return undef;
    $aws_access_key =~ /^([A-Za-z0-9]{20})$/ or return undef;
    return $1;
}

sub isAwsSecretKey($){
    my $aws_secret_key = shift;
    defined($aws_secret_key) or return undef;
    $aws_secret_key =~ /^([A-Za-z0-9]{40})$/ or return undef;
    return $1;
}


# isSub/isCode is used by set_timeout() to determine if we were passed a valid function for the ALRM sub
sub isCode ($) {
    my $isCode = ref $_[0] eq "CODE";
    return $isCode;
}


#sub isDigit {
#    isInt(@_);
#}
*isDigit = \&isInt;


sub isDatabaseColumnName ($) {
    my $column = shift;
    defined($column) || return undef;
    $column =~ /^(\w+)$/ or return undef;
    return $1;
}


sub isDatabaseFieldName ($) {
    my $field = shift;
    defined($field) || return undef;
    ( $field  =~ /^(\d+)$/ or $field =~/^([\w\(\)\*\,\._-]+)$/ ) or return undef;
    return $1;
}


sub isDatabaseTableName ($;$) {
    my $table           = shift;
    my $allow_qualified = shift;
    defined($table) || return undef;
    if($allow_qualified){
        $table =~ /^((?:\w+\.)?\w+)$/i or return undef;
        return $1;
    } else {
        $table =~ /^(\w+)$/i or return undef;
        return $1;
    }
    return undef;
}


sub isDomain ($) {
    my $domain = shift;
    defined($domain) or return undef;
    return undef if(length($domain) > 255);
    $domain =~ /^($domain_regex)$/ or return undef;
    return $1;
}


sub isDnsShortname($){
    my $name = shift;
    defined($name) or return undef;
    return undef if(length($name) < 3 or length($name) > 63);
    $name =~ /^($hostname_component)$/ or return undef;
    return $1;
}


# SECURITY NOTE: this only checks if the email address is valid, it's doesn't make it safe to arbitrarily pass to commands or SQL etc!
sub isEmail ($) {
    my $email = shift;
    #defined($email) || return undef;
    return undef if(length($email) > 256);
    $email =~ /^$email_regex$/ || return undef;
    # Intentionally not untainting this as it's not safe given the addition of ' to the $email_regex to support Irish email addresses
    return $email;
}


sub isFilename($){
    my $filename = shift;
    return undef unless defined($filename);
    return undef if $filename =~ /^\s*$/;
    return undef unless($filename =~ /^($filename_regex)$/);
    return $1;
}


sub isFloat ($;$) {
    my $number = shift;
    my $negative = shift() ? "-?" : "";
    #defined($number) or code_error("no number passed to isFloat subroutine");
    $number =~ /^$negative\d+(?:\.\d+)?$/;
}


sub isFqdn ($) {
    my $fqdn = shift;
    #defined($fqdn) or return undef;
    return undef if(length($fqdn) > 255);
    $fqdn =~ /^($fqdn_regex)$/ or return undef;
    return $1;
}


sub isHash ($) {
    my $isHash = ref $_[0] eq "HASH";
    if($_[1]){
        unless($isHash){
            code_error "non hash reference passed";
        }
    }
    return $isHash;
}


sub isHex ($) {
    my $hex = shift;
    #defined($hex) or return undef;
    $hex =~ /^(0x[A-Fa-f\d]+)$/ or return undef;
    return 1;
}


sub isHost ($) {
    my $host = shift;
    #defined($host) or return undef;
    if(length($host) > 255){ # Can't be a hostname
        return isIP($host);
    } else {
        $host =~ /^($host_regex)$/ or return undef;
        return $1;
    }
    return undef;
}


sub isHostname ($) {
    my $hostname = shift;
    #defined($hostname) or return undef;
    return undef if(length($hostname) > 255);
    $hostname =~ /^($hostname_regex)$/ or return undef;
    return $1;
}


sub isInt ($;$) {
    my $number = shift;
    my $signed = shift() ? "-?" : "";
    defined($number) or return undef; # code_error("no number passed to isInt()");
    $number =~ /^($signed\d+)$/ or return undef;
    # can't return zero here as it would fail boolean tests for 0 which may be a valid int for purpose
    return 1;
}


sub isInterface ($) {
    my $interface = shift;
    defined($interface) || return undef;
    # TODO: consider checking if the interface actually exists on the system
    $interface =~ /^((?:eth|bond|lo)\d+|lo)$/ or return undef;
    return $1;
}


sub isIP ($) {
    my $ip = shift;
    #defined($ip) or return undef;
    $ip =~ /^($ip_regex)$/ or return undef;
    $ip = $1;
    my @octets = split(/\./, $ip);
    (@octets == 4) or return undef;
    $octets[3] eq 0 and return undef;
    foreach(@octets){
        $_ > 254 and return undef;
    }
    return $ip;
}


# wish there was a better way of validating the JSON returned but Test::JSON is_valid_json() also errored out badly from underlying JSON::Any module, similar to JSON's decode_json
sub isJson($){
    my $string = shift;
    # slightly modified from http://stackoverflow.com/questions/2583472/regex-to-validate-json
    my $json_regex = qr/
      (?(DEFINE)
         (?<number>   -? (?= [1-9]|0(?!\d) ) \d+ (\.\d+)? ([eE] [+-]? \d+)? )
         (?<boolean>   true | false | null )
         (?<string>    " ([^"\\\\]* | \\\\ ["\\\\bfnrt\/] | \\\\ u [0-9a-f]{4} )* " )
         (?<array>     \[  (?: (?&json)  (?: , (?&json)  )*  )?  \s* \] )
         (?<pair>      \s* (?&string) \s* : (?&json)  )
         (?<object>    \{  (?: (?&pair)  (?: , (?&pair)  )*  )?  \s* \} )
         (?<json>      \s* (?: (?&number) | (?&boolean) | (?&string) | (?&array) | (?&object) ) \s* )
      )
      \A (?&json) \Z
      /six;
    if($string =~ $json_regex){
        return 1;        
    }
    return 0;
}


sub isKrb5Princ ($) {
    my $principal = shift;
    defined($principal) or return undef;
    $principal =~ /^($krb5_principal_regex)$/ or return undef;
    return $1;
}


# Primarily for Nagios perfdata labels
sub isLabel ($) {
    my $label  = shift;
    defined($label) || return undef;
    $label =~ /^[\%\(\)\/\*\w\s-]+$/ or return undef;
    return $label;
}


sub isNagiosUnit ($) {
    my $units = shift;
    foreach(@valid_units){
        if(lc $units eq lc $_){
            return $_;
        }
    }
    return undef;
}


#sub isObject ($) {
#    my $object = shift;
#    ref $object eq "bless";
#}


sub isPort ($) {
    my $port = shift;
    $port  =~ /^(\d+)$/ || return undef;
    $port = $1;
    ($port >= 1 && $port <= 65535) || return undef;
    return $port;
}


sub isProcessName ($) {
    my $process = shift;
    #defined($process) or return undef;
    $process =~ /^($process_name_regex)$/ or return undef;
    return $1;
}


# TODO FIXME: doesn't catch error before Perl errors out right now, not using it yet
#sub isRegex ($) {
#    my $regex = shift;
#    defined($regex) || code_error "no regex arg passed to isRegex()";
#    #defined($regex) || return undef;
#    vlog3("testing regex '$regex'");
#    if(eval { qr/$regex/ }){
#        return $regex;
#    } else {
#        return undef;
#    }
#}


sub isScalar ($;$) {
    my $isScalar = ref $_[0] eq "SCALAR";
    if($_[1]){
        unless($isScalar){
            code_error "non scalar reference passed";
        }
    }
    return $isScalar;
}


#sub isSub {
#    isCode(@_);
#}
*isSub = \&isCode;


sub isUrl ($) {
    my $url = shift;
    defined($url) or return undef;
    #debug("url_regex: $url_regex");
    $url =~ /^($url_regex)$/ or return undef;
    return $1;
}


sub isUrlPathSuffix ($) {
    my $url = shift;
    defined($url) or return undef;
    $url =~ /^($url_path_suffix_regex)$/ or return undef;
    return $1;
}


sub isUser ($) {
    #subtrace(@_);
    my $user = shift;
    defined($user) or return undef; # code_error "user arg not passed to isUser()";
    $user =~ /^($user_regex)$/ || return undef;
    return $1;
}


# =============================== OS CHECKS ================================== #
sub isOS ($) {
    $^O eq shift;
}

sub isMac () {
    isOS "darwin";
}

sub isLinux () {
    isOS "linux";
}

our $supported_os_msg = "this program is only supported on %s at this time";
sub mac_only () {
    isMac or quit("UNKNOWN", sprintf($supported_os_msg, "Mac/Darwin") );
}

sub linux_only () {
    isLinux or quit("UNKNOWN", sprintf($supported_os_msg, "Linux") );
}

sub linux_mac_only () {
    isLinux or isMac or quit("UNKNOWN", sprintf($supported_os_msg, "Linux or Mac/Darwin") );
}
# ============================================================================ #


sub loginit () {
    # This can cause plugins to fail if there is no connection to syslog available at plugin INIT
    # Let's only use this for something that really needs it
    #INIT {
        #require Sys::Syslog;
        #import Sys::Syslog qw(:standard :macros);
        # Can't actually require/import optimize here because barewards aren't recognized early enough which breaks strict
        use Sys::Syslog qw(:standard :macros);
        # nofatal doesn't appear in earlier 5.x versions
        #openlog $progname, "ndelay,nofatal,nowait,perror,pid", LOG_LOCAL0;
        openlog $progname, "ndelay,nowait,perror,pid", LOG_LOCAL0;
        $syslog_initialized = 1;
    #}
}


sub log (@) {
    loginit() unless $syslog_initialized;
    # For some reason perror doesn't seem to print so do it manually here
    print strftime("%F %T", localtime) . "  $progname\[$$\]: @_\n";
    syslog LOG_INFO, "%s", "@_";
}


sub logdie (@) {
    &log("ERROR: @_");
    exit get_status_code("CRITICAL");
}


sub lstrip ($) {
    my $string = shift;
    #defined($string) or code_error "no arg passed to lstrip()";
    $string =~ s/^\s+//o;
    return $string;
}
#sub ltrim { lstrip(@_) }
*ltrim = \&lstrip;


sub msg_perf_thresholds () {
    $msg .= ";";
    $msg .= $thresholds{"warning"}{"upper"} if defined($thresholds{"warning"}{"upper"});
    $msg .= ";";
    $msg .= $thresholds{"critical"}{"upper"} if defined($thresholds{"critical"}{"upper"});
    $msg .= ";";
}


sub msg_thresholds () {
    my $msg2 = "";
    if ($thresholds{"critical"}{"error"} or
        $thresholds{"warning"}{"error"}  or
        ($verbose and (defined($warning) or defined($critical))) ) {
        $msg2 .= "(";
        if($thresholds{"critical"}{"error"}){
            $msg2 .= "$thresholds{critical}{error}, ";
        }
        elsif($thresholds{"warning"}{"error"}){
            $msg2 .= "$thresholds{warning}{error}, ";
        }
        if(defined($warning)){
            $msg2 .= "w=$warning";
        }
        if(defined($warning) and defined($critical)){
            $msg2 .= "/";
        }
        if(defined($critical)){
            $msg2 .= "c=$critical";
        }
        $msg2 .= ")";
    }
    $msg .= " $msg2" if $msg2;
}


sub open_file ($;$) {
    my $filename = shift;
    my $lock = shift;
    #my $mode = shift;
    my $tmpfh;
    defined($filename) or code_error "no filename given to open_file()";
    ( -e $filename ) or quit("CRITICAL", "file not found: '$filename'");
    ( -f $filename ) or quit("CRITICAL", "not a valid file: '$filename'");
    ( -r $filename ) or quit("CRITICAL", "file not readable: '$filename'");
    vlog2("opening file: '$filename'");
    open $tmpfh, "$filename" or quit("UNKNOWN", "Error: failed to open file '$filename': $!");
    if($lock){
        flock($tmpfh, LOCK_EX | LOCK_NB) or quit("UNKNOWN", "Failed to aquire a lock on file '$filename', another instance of this code may be running?");
    }
    return $tmpfh;
}


sub parse_file_option($;$){
    my $file      = shift;
    my $file_args = shift;
    my @files;
    my @tmp;
    if($file){
        my @tmp = split(/\s*[\s,]\s*/, $file);
        push(@files, @tmp);
    }

    if($file_args){
        # @ARGV should only be used after get_options()
        foreach(@ARGV){
            push(@files, $_);
        }
    }

    foreach my $f (@files){
        if(not -f $f ){
            print STDERR "File not found: '$f'\n";
            @files = grep { $_ ne $f } @files;
        }
    }
    if($file or ($file_args and @ARGV)){
        if(not @files){
            die "Error: no files found\n";
        }
    }

    vlog_options("files", "[ '" . join("', '", @files) . "' ]");

    return @files;
}


# parsing ps aux is more portable than pkill -f command. Useful for alarm sub
# Be careful to validate and make sure you use taint mode before calling this sub
sub pkill ($;$) {
    my $search    = $_[0] || code_error "No search arg specified for pkill sub";
    my $kill_args = $_[1] || "";
    return `ps aux | awk '/$search/ {print \$2}' | while read pid; do kill $kill_args \$pid >/dev/null 2>&1; done`;
}


sub plural ($) {
    our $plural;
    my $var = $_[0];
    #print "var = $var\n";
    #print "var ref = " . ref($var) . "\n";
    if(isArray($var)){
        $var = scalar(@{$var});
    } elsif (isHash($var)){
        $var = scalar keys %{$var};
    # TODO: enable this, currently doesn't work
    #} elsif (not isFloat($var)) {
    #    code_error "non-scalar, non-array ref and non-hash ref passed to plural()";
    }
    isInt($var) or code_error("arg passed to plural() is not an integer");
    ( $var == 1 ) ? ( $plural = "" ) : ( $plural = "s" );
}


sub print_options (@) {
    #subtrace(@_);
    foreach my $option (@_){
        my $option_regex = $option;
        $option_regex  =~ s/^\w\|//;
        $option_regex  =~ s/=.*$//;
        # pointless since this is hardcoded Perl interpreter will always error out first
        #$option_regex  = isRegex($option_regex) || code_error "invalid option regex '$option_regex' passed in \@options array to print_options()";
        #debug "\noption is $option";
        if($option =~ /debug/){
            #debug "skipping debug option";
            next;
        }
        foreach(keys %options){
            #debug $_;
            #debug $options{$_};
            #debug "options long value is $options{$_}{desc}";
            if($options{$_}{"long"} =~ /^.*--(?:$option_regex)\s*$/){
                printf STDERR "%-${short_options_len}s  %-${long_options_len}s \t%s\n", $options{$_}{"short"}, $options{$_}{"long"}, $options{$_}{"desc"};
                delete $options{$_};
                last;
            }
        }
    }
}


# Also prototyped at top to allow me to call it earlier
sub quit (@) {
    if($status_prefix ne ""){
        $status_prefix .= " ";
    }
    if(@_ eq 0){
        chomp $msg;
        # This ends up bit shifting to 255 instead of 0
        #$! = $ERRORS{$status};
        #die "$status: $msg\n";
        grep(/^$status$/, keys %ERRORS) or die "Code error: unrecognized exit code '$status' specified on quit call, not found in %ERRORS hash\n";
        print "${status_prefix}$status: $msg\n";
        exit $ERRORS{$status};
    } elsif(@_ eq 1){
        $msg = $_[0];
        chomp $msg;
        #$! = $ERRORS{"CRITICAL"};
        #die "CRITICAL: $msg\n";
        print "${status_prefix}CRITICAL: $msg\n";
        exit $ERRORS{"CRITICAL"};
    } elsif(@_ eq 2) {
        $status = $_[0];
        $msg    = $_[1];
        chomp $msg;
        grep(/^$status$/, keys %ERRORS) or die "Code error: unrecognized exit code '$status' specified on quit call, not found in %ERRORS hash\n";
        #$! = $ERRORS{$status};
        #die "$status: $msg\n";
        print "${status_prefix}$status: $msg\n";
        exit $ERRORS{$status};
    } else {
        #print "UNKNOWN: Code Error - Invalid number of arguments passed to quit function (" . scalar(@_). ", should be 0 - 2)\n";
        #exit $ERRORS{"UNKNOWN"};
        code_error("invalid number of arguments passed to quit function (" . scalar(@_) . ", should be 0 - 2)");
    }
}


sub remove_timeout(){
    delete $HariSekhonUtils::default_options{"t|timeout=i"};
}


sub resolve_ip ($) {
    require Socket;
    import Socket;
    my $tmp = inet_aton($_[0]) || return undef;
    return inet_ntoa($tmp);
}


sub rstrip ($) {
    my $string = shift;
    defined($string) or code_error "no arg passed to rstrip()";
    $string =~ s/\s+$//;
    return $string;
}
#sub rtrim { rstrip(@_) }
*rtrim = \&rstrip;


sub sec2min ($){
    my $secs = shift;
    isFloat($secs) or return undef;
    return sprintf("%d:%.2d", int($secs / 60), $secs % 60);
}


sub set_sudo (;$) {
    local $user = $_[0] if defined($_[0]);
    defined($user) or code_error "user arg not passed to set_sudo() and \$user not defined in outer scope";
    # Quit if we're not the right user to ensure we don't sudo command and hang or return with a generic timeout error message
    #quit "UNKNOWN", "not running as '$hadoop_user' user";
    # only Mac has -n switch for non-interactive :-/
    #$sudo = "sudo -n -u $hadoop_user ";
    if(getpwuid($>) eq $user){
        $sudo = "";
    } else {
        vlog2("EUID doesn't match user $user, using sudo\n");
        $sudo = "echo | sudo -S -u $user ";
    }
}


sub set_timeout (;$$) {
    $timeout = $_[0] if $_[0];
    my $sub_ref = $_[1] if $_[1];
    $timeout =~ /^\d+$/ || usage("timeout value must be a positive integer\n");
    ($timeout >= $timeout_min && $timeout <= $timeout_max) || usage("timeout value must be between $timeout_min - $timeout_max secs\n");
    if($sub_ref){
        isSub($sub_ref) or code_error "invalid sub ref passed to set_timeout()";
    }

    $SIG{ALRM} = sub {
        &$sub_ref if $sub_ref;
        quit("UNKNOWN", "self timed out after $timeout seconds");
    };
    #verbose_mode() unless $_[1];
    vlog2("setting timeout to $timeout secs\n");
    # alarm returns the time of the last timer, on first run this is zero so cannot die here
    alarm($timeout) ;#or die "Failed to set time to $timeout";
}


#sub sub_noarg {
#    quit "UNKNOWN", "Code Error: no arg supplied to subroutine " . (caller(1))[3];
#}


sub strip ($) {
    my $string = shift;
    defined($string) or code_error "no arg passed to strip()";
    $string =~ s/^\s+//o;
    $string =~ s/\s+$//o;
    return $string;
}
*trim = \&strip;


sub subtrace (@) {
    #@_ || code_error("\@_ not passed to subtrace");
    return unless ($debug >= 2);
    my ( $package, $filename, $line ) = caller;
    my $debug_msg = "entering with args: @_";
    $debug_msg =~ s/^(\n+)//;
    my $prefix_newline = $1 || "";
    # TODO: can improve this if we can go one level up, dedupe with debug, do this later
    printf "${prefix_newline}debug: %s() => $debug_msg\n", (caller(1))[3];
}


#sub type {
#    my $builtin = $_[0] || code_error "no arg supplied to which() subroutine";
#    my $quit    = $_[1] || 0;
#    $builtin =~ /^([\w-]+)$/ or quit "UNKNOWN", "invalid command/builtin passed to type subroutine";
#    $builtin = $1;
#   `type $builtin`;
#    return 1 if($? == 0);
#    quit "UNKNOWN", "$builtin is not a shell built-in" if $quit;
#    return undef;
#}


sub uniq_array (@) {
    my @array = @_; # or code_error "no arg passed to uniq_array";
    isArray(\@array) or code_error "uniq_array was passed a non-array";
    scalar @array or code_error "uniq_array was passed an empty array";
    return ( sort keys %{{ map { $_ => 1 } @array }} );
}


sub usage (;@) {
    print STDERR "@_\n\n" if (@_);
    if(not @_ and $main::DESCRIPTION){
        print STDERR "Hari Sekhon - https://github.com/harisekhon";
        if($main::DESCRIPTION =~ /Nagios/i){
            print STDERR "/nagios-plugins";
        }
        print STDERR "\n\n$progname\n\n";
        print STDERR "$main::DESCRIPTION\n\n";
    }
    print STDERR "$usage_line\n\n";
    foreach my $key_orig (sort keys %options){
        my $key = $key_orig;
        $key =~ s/=.*$//;
        $key =~ s/\+//;
        code_error("invalid array count in value for key '$key' in options hash") unless(scalar(@{$options{$key_orig}}) == 2);
        $options{$key} = $options{$key_orig}[1];
        #debug "key: $key  key_orig: $key_orig";
        delete $options{$key_orig} if($key ne $key_orig);
    }
    foreach(sort keys %options){
        my $option = "";
        my @short_options = ();
        my @long_options  = ();
        if($_ =~ /\|/){
            @_ = split('\|', $_);
            foreach(@_){
                if(length($_) == 1){
                    push(@short_options, "-$_");
                } else {
                    push(@long_options, "--$_");
                }
            }
        } else {
            if(length($_) == 1){
                push(@short_options, "-$_");
            } else {
                push(@long_options, "--$_");
            }
        }
        #debug "$_ short_options: " . join(",", @short_options) . "  long_options:" . join(",", @long_options) . "  desc: $options{$_}";
        $options{$_} = {
            "short" => join(" ", @short_options),
            "long"  => join(" ", @long_options),
            "desc"  => $options{$_}
        };
    }

    foreach(sort keys %options){
        $short_options_len = length($options{$_}{"short"}) if($short_options_len < length($options{$_}{"short"}));
        $long_options_len  = length($options{$_}{"long"} ) if($long_options_len  < length($options{$_}{"long"} ));
    }
    print_options(@usage_order);
    foreach my $option (sort keys %options){
        #debug "iterating over general options $option";
        # TODO: improve this matching for more than one long opt
        if(grep($_ =~ /\b$option\b/, keys %default_options)){
            #debug "skipping $option cos it matched \%default_options";
            next;
        }
        print_options($option);
        #printf "%-${short_options_len}s  %-${long_options_len}s \t%s\n", $options{$option}{"short"}, $options{$option}{"long"}, $options{$option}{"desc"};
    }
    print_options(sort { lc($a) cmp lc($b) } keys %default_options);
    exit $ERRORS{"UNKNOWN"};
}


sub user_exists ($) {
    my $user = shift; # if $_[0];
    #defined($user) or code_error("no user passed to user_exists()");
    #$user = isUser($user) || return undef;

    # using id command since this should exist on most unix systems
    #which("id", 1);
    #`id "$user" >/dev/null 2>&1`;
    #return 1 if ( $? eq 0 );
    #return undef;

    # More efficient
    return defined(getpwnam($user));
}


sub validate_alnum($$){
    my $arg  = shift;
    my $name = shift || croak "second argument (name) not defined when calling validate_alnum";
    defined($arg) or usage "$name not defined";
    $arg =~ /^([A-Za-z0-9]+)$/ or usage "invalid $name given, must be alphanumeric";
    $arg = $1;
    vlog_options($name, $arg);
    return $arg;
}


sub validate_aws_access_key($){
    my $aws_access_key = shift;
    defined($aws_access_key) || usage "aws access key not defined";
    $aws_access_key = isAwsAccessKey($aws_access_key) || usage "invalid aws access key given, must be 20 alphanumeric characters";
    vlog_options("aws_access_key", $aws_access_key);
    return $aws_access_key;
}


sub validate_aws_bucket($){
    my $bucket = shift;
    defined($bucket) or usage "no aws bucket specified";
    $bucket = isDnsShortname($bucket); # sets undef if not valid
    defined($bucket) or usage "invalid aws bucket name given, must be alphanumeric between 3 and 63 characters long";
    isIP($bucket) and usage "bucket names may not be formatted as an IP address";
    vlog_options("bucket", $bucket);
    return $bucket;
}


sub validate_aws_secret_key($){
    my $aws_secret_key = shift;
    defined($aws_secret_key) || usage "aws secret key not defined";
    $aws_secret_key = isAwsSecretKey($aws_secret_key) || usage "invalid aws secret key given, must be 40 alphanumeric characters";
    vlog_options("aws_secret_key", $aws_secret_key);
    return $aws_secret_key;
}


sub validate_database ($) {
    my $database = shift;
    defined($database)      || usage "database name not specified";
    $database =~ /^(\w*)$/  || usage "invalid database name given, must be alphanumeric";
    vlog_options("database", "'$database'");
    return $1;
}


sub validate_database_tablename ($;$) {
    my $table           = shift;
    my $allow_qualified = shift;
    defined($table) || usage "table not specified";
    $table = isDatabaseTableName($table, $allow_qualified) || usage "invalid table name, must be alphanumeric";
    vlog_options("table", "$table");
    return $table;
}


sub validate_database_columnname ($) {
    my $column = shift;
    defined($column) || usage "column not specified";
    $column = isDatabaseColumnName($column) || usage "invalid column name, must be alphanumeric";
    vlog_options("column", "$column");
    return $column;
}


sub validate_database_fieldname ($) {
    my $field = shift;
    defined($field) || usage "field not specified";
    $field = isDatabaseFieldName($field) || usage "invalid field number given, must be a positive integer, or a valid field name";
    ($field eq "0") && usage "field cannot be zero";
    vlog_options("field", "$field");
    return $field;
}


sub validate_database_query_select_show ($) {
    my $query = shift;
    defined($query) || usage "query not specified";
    #$query =~ /^\s*((?i:SHOW|SELECT)\s[\w\s;:,\.\?\(\)*='"-]+)$/ || usage "invalid query supplied";
    #debug("regex validating query: $query");
    $query =~ /^\s*((?:SHOW|SELECT)\s+(?!.*(?:INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|TRUNCATE|;|--)).+)$/i || usage "invalid query supplied, must be a SELECT or SHOW only for safety";
    $query = $1;
    $query =~ /insert|update|delete|create|drop|alter|truncate|;|--/i and usage "DML statement or suspect chars detected in query!";
    vlog_options("query", "$query");
    return $query;
}


sub validate_domain ($) {
    my $domain = shift;
    defined($domain) || usage "domain name not specified";
    $domain = isDomain($domain) || usage "invalid domain name given '$domain'";
    vlog_options("domain", "'$domain'");
    return $domain;
}


#sub validate_dir ($;$) {
#    validate_directory(@_);
#}


sub validate_directory ($;$$$) {
    my $dir     = shift;
    my $noquit  = shift;
    my $name    = shift || "directory";
    my $no_vlog = shift;
    if($noquit){
        return validate_filename($dir, 1);
    }
    defined($dir) || usage "directory not specified";
    $dir = validate_filename($dir, "noquit", $name, $no_vlog) || usage "Invalid directory given (does not match regex criteria): '$dir'";
    ( -d $dir) || usage "cannot find directory: '$dir'";
    return $dir;
}
*validate_dir = \&validate_directory;


# SECURITY NOTE: this only validates the email address is valid, it's doesn't make it safe to arbitrarily pass to commands or SQL etc!
sub validate_email ($) {
    my $email = shift;
    defined($email) || usage "email not specified";
    isEmail($email) || usage "invalid email address specified, failed regex validation";
    # Not passing it through regex as I don't want to untaint it due to the addition of the valid ' char in email addresses
    return $email;
}


sub validate_file ($;$$$) {
    my $filename = shift;
    my $noquit   = shift;
    my $name     = shift;
    my $no_vlog  = shift;
    $filename = validate_filename($filename, $noquit, $name, $no_vlog) or return undef;
    unless( -f $filename ){
        usage "file not found: '$filename' ($!)" unless $noquit;
        return undef
    }
    return $filename;
}


sub validate_filename ($;$$$) {
    my $filename = shift;
    my $noquit   = shift;
    my $name     = shift || "filename";
    my $no_vlog  = shift;
    if(not defined($filename) or $filename =~ /^\s*$/){
        usage "$name not specified";
        return undef;
    }
    my $filename2;
    unless($filename2 = isFilename($filename)){
        usage "invalid $name given (does not match regex critera): '$filename'" unless $noquit;
        return undef;
    }
    vlog_options($name, $filename2) unless $no_vlog;
    return $filename2;
}


sub validate_float ($$$$) {
#    my $float = $_[0] if defined($_[0]);
#    my $min     = $_[1] || 0;
#    my $max     = $_[2] || code_error "no max value given for validate_float()";
#    my $name    = $_[3] || code_error "no name passed to validate_float()";
    my ($float, $min, $max, $name) = @_;
    defined($float) || usage "$name not specified";
    isFloat($float,1) or usage "invalid $name given, must be a real number";
    ($float >= $min && $float <= $max) or usage "invalid $name given, must be real number between $min and $max";
    $float =~ /^(-?\d+(?:\.\d+)?)$/ or usage "invalid float $name passed to validate_float(), WARNING: caught LATE";
    $float = $1;
    vlog_options($name, $float);
    return $float;
}


sub validate_fqdn ($) {
    my $fqdn = shift;
    defined($fqdn) || usage "FQDN not defined";
    $fqdn = isFqdn($fqdn) || usage "invalidate FQDN given";
    vlog_options("fqdn", "'$fqdn'");
    return $fqdn
}


sub validate_host ($) {
    my $host = shift;
    defined($host) || usage "host not specified";
    $host = isHost($host) || usage "invalid host given, not a validate hostname or IP address";
    vlog_options("host", "'$host'");
    return $host;
}


sub validate_hostname ($) {
    my $hostname = shift;
    defined($hostname) || usage "hostname not specified";
    $hostname = isHostname($hostname) || usage "invalid hostname given";
    vlog_options("hostname", "'$hostname'");
    return $hostname;
}


sub validate_int ($$$$) {
#    my $integer = $_[0] if defined($_[0]);
#    my $min     = $_[1] || 0;
#    my $max     = $_[2] || code_error "no max value given for validate_int()";
#    my $name    = $_[3] || code_error "no name passed to validate_int()";
    my ($integer, $min, $max, $name) = @_;
    defined($integer) || usage "$name not specified";
    isInt($integer, 1) or usage "invalid $name given, must be an integer";
    isFloat($min, 1) or code_error "non-float value '$min' passed to validate_int() for 2nd arg min value";
    isFloat($max, 1) or code_error "non-float value '$max' passed to validate_int() for 3rd arg max value";
    ($integer >= $min && $integer <= $max) or usage "invalid $name given, must be integer between $min and $max";
    $integer =~ /^(-?\d+)$/ or usage "invalid integer $name passed to validate_int(), WARNING: caught LATE";
    $integer = $1;
    vlog_options($name, $integer);
    return $integer;
}
*validate_integer = \&validate_int;


sub validate_interface ($) {
    my $interface = shift;
    defined($interface) || usage "interface not specified";
    $interface = isInterface($interface) || usage "invalid interface specified, must be either ethN, bondN or loN";
    vlog_options("interface", $interface);
    return $interface;
}


sub validate_ip ($) {
    my $ip = shift;
    defined($ip) || usage "ip not specified";
    $ip = isIP($ip) || usage "invalid IP given";
    vlog_options("IP", "'$ip'");
    return $ip;
}


sub validate_krb5_princ ($) {
    my $principal = shift;
    $principal = isKrb5Princ($principal) || usage "invalid principal given";
    vlog_options("krb5 principal", $principal);
    return $principal;
}


sub validate_node_list (@) {
    my @nodes = @_;
    my @nodes2;
    foreach(@nodes){
        push(@nodes2, split(/[,\s]+/, $_));
    }
    # do this validate_node_list
    #push(@nodes, @ARGV);
    scalar @nodes2 or usage "node list empty";
    @nodes = uniq_array(@nodes2);
    foreach my $node (@nodes){
        $node = isHost($node) || usage "Node name '$node' invalid, must be hostname/FQDN or IP address";
    }
    vlog_options("node list", "[ '" . join("', '", @nodes) . "' ]");
    return @nodes;
}


sub validate_port ($) {
    my $port = shift;
    defined($port)      || usage "port not specified";
    $port  = isPort($port) || usage "invalid port number given, must be a positive integer";
    vlog_options("port", "'$port'");
    return $port;
}


sub validate_process_name ($) {
    my $process = shift;
    defined($process) || usage "no process name given";
    $process = isProcessName($process) || usage "invalid process name, failed regex validation";
    vlog_options("process name", $process);
    return $process;
}


sub validate_label ($) {
    my $label  = shift;
    defined($label) || usage "label not specified";
    $label = isLabel($label) || usage "Label must be an alphanumeric identifier";
    vlog_options("label", $label);
    return $label;
}


# TODO: unify with isRegex and do not allow noquit
sub validate_regex ($;$$) {
    my $regex  = shift;
    my $noquit = shift;
    my $posix  = shift;
    my $regex2;
    if($noquit){
        defined($regex) || return undef;
    } else {
        defined($regex) || usage "regex not specified";
    }
    if($posix){
        if($regex =~ /\$\(|\`/){
            quit "UNKNOWN", "invalid posix regex supplied: contains sub shell metachars ( \$( / ` ) that would be dangerous to pass to shell" unless $noquit;
            return undef;
        } else {
            my @output = cmd("egrep '$regex' < /dev/null");
            #if(grep({$_ =~ "Unmatched"} @output)){
            if(@output){
                #quit "UNKNOWN", "invalid posix regex supplied: contains unbalanced () or []" unless $noquit;
                quit "UNKNOWN", "invalid posix regex supplied: @output" unless $noquit;
                return undef;
            }
        }
    } else {
        #$regex2 = isRegex($regex);
        $regex2 = eval { qr/$regex/ };
        if($@){
            my $errstr = $@;
            $errstr =~ s/;.*?$//;
            $errstr =~ s/in regex m\/.*?$/in regex/;
            quit "UNKNOWN", "invalid regex supplied: $errstr" unless $noquit;
            return undef;
        }
    }
    if($regex2){
        vlog_options("regex", $regex2) unless $noquit;
        return $regex2;
    } else {
        vlog_options("regex", $regex) unless $noquit;
        return $regex;
    }
}


sub validate_user ($) {
    #subtrace(@_);
    my $user = shift;
    defined($user) || usage "username not specified";
    $user = isUser($user) || usage "invalid username given, must be alphanumeric";
    vlog_options("user", "'$user'");
    return $user;
}
*validate_username = \&validate_user;


sub validate_user_exists ($) {
    #subtrace(@_);
    my $user = shift;
    $user = validate_user($user);
    user_exists($user) || usage "invalid user given, not found on local system";
    return $user;
}


sub validate_password ($) {
    my $password  = shift;
    my $allow_all = shift;
    defined($password) || usage "password not specified";
    if($allow_all){
        # intentionally not untaining
        $password =~ /^(.+)$/ || usage "invalid password given";
    } else {
        $password =~ /^([^'"`]+)$/ or usage "invalid password given, may not contain quotes of backticks";
        $password = $1;
    }
    vlog_options("password", "'$password'");
    return $password;
}

sub validate_resolvable($){
    my $host = shift;
    #if(isIP($host)){
    #    return 1;
    #}
    resolve_ip($host) or quit "CRITICAL", "failed to resolve host '$host'";
    return 1;
}

sub validate_threshold ($$;$) {
    #subtrace(@_);
    my $name        = $_[0];
    my $threshold   = $_[1];
    my $options_ref = $_[2] || {};
    isHash($options_ref) or code_error "3rd arg to validate_threshold() must be a hash ref of options";
    $options_ref->{"positive"} = 1 unless defined($options_ref->{"positive"});
    $options_ref->{"simple"} = "upper" unless $options_ref->{"simple"};
    my @valid_options = qw/simple positive integer min max/;
    foreach my $option (sort keys %$options_ref){
        grep(/^$option$/, @valid_options) or code_error "invalid option '$option' passed to validate_threshold(), must be one of " . join("/", @valid_options);
    }
    unless ($options_ref->{"simple"} eq "upper" or $options_ref->{"simple"} eq "lower") {
        code_error "simple => '$options_ref->{simple}' option to validate_threshold() must be either 'upper' or 'lower', not '$options_ref->{simple}'";
    }
    #debug("validating $name threshold against $threshold");
    my $invert_range = 0;
    defined($threshold) or code_error "no threshold (arg 2) given to validate_threshold subroutine";
    $thresholds{"$name"}{"invert_range"} = 0;
    # Make this more flexible
    if ($threshold =~ /^(\@)?(-?\d+(?:\.\d+)?)(:)(-?\d+(?:\.\d+)?)?$/) {
        $thresholds{$name}{"invert_range"} = 1 if $1;
        if(defined($3)){
            $thresholds{$name}{"upper"} = $4 if defined($4);
            $thresholds{$name}{"lower"} = $2;
        } else {
            $thresholds{$name}{"upper"} = $2;
        }
        if(defined($thresholds{$name}{"upper"}) and defined($thresholds{$name}{"lower"})){
            $thresholds{$name}{"upper"} < $thresholds{$name}{"lower"} and usage "invalid args: upper $name threshold cannot be lower than lower $name threshold";
        }
    } elsif($threshold =~ /^(-?\d+(?:\.\d+)?)$/) {
        if($options_ref->{"simple"} eq "upper"){
            $thresholds{$name}{"upper"} = $1;
        } elsif($options_ref->{"simple"} eq "lower"){
            $thresholds{$name}{"lower"} = $1;
        }
    } else {
        usage "invalid $name threshold given, must be in standard nagios threshold format [@][start:]end";
    }
    foreach(qw/upper lower/){
        if($options_ref->{"positive"} and defined($thresholds{$name}{$_}) and $thresholds{$name}{$_} < 0){
            usage "$name threshold may not be less than zero";
        }
        if($options_ref->{"integer"} and defined($thresholds{$name}{$_}) and not isInt($thresholds{$name}{$_})){
            usage "$name threshold must be an integer";
        }
        if($options_ref->{"min"} and defined($thresholds{$name}{$_}) and $thresholds{$name}{$_} < $options_ref->{"min"}){
            usage "$name threshold cannot be less than $options_ref->{min}";
        }
        if($options_ref->{"max"} and defined($thresholds{$name}{$_}) and $thresholds{$name}{$_} > $options_ref->{"max"}){
            usage "$name threshold cannot be greater than $options_ref->{max}";
        }
    }
    $thresholds{"defined"} = 1 if (defined($thresholds{$name}{"upper"}) or defined($thresholds{$name}{"lower"}));
    vlog_options(sprintf("%-8s lower", $name), $thresholds{"$name"}{"lower"}) if defined($thresholds{"$name"}{"lower"});
    vlog_options(sprintf("%-8s upper", $name), $thresholds{"$name"}{"upper"}) if defined($thresholds{"$name"}{"upper"});
    vlog_options(sprintf("%-8s range inversion", $name), "on") if $thresholds{$name}{"invert_range"};
    1;
}


# 1st/2nd arg determines if warning/critical are mandatory respectively
# 3rd arg must be "upper" or "lower" to specify to only allow single threshold used as the upper or lower boundary
sub validate_thresholds (;$$$) {
    # TODO: CRITICAL vs WARNING threshold logic is only applied to simple thresholds, not to range ones, figure out if I can reasonably do range ones later
    if($_[0]){
        defined($warning)  || usage "warning threshold not defined";
    }
    if($_[1]){
        defined($critical) || usage "critical threshold not defined";
    }
    validate_threshold("warning",  $warning,  $_[2]) if(defined($warning));
    validate_threshold("critical", $critical, $_[2]) if(defined($critical));
    # sanity checking on thresholds for simple upper or lower thresholds only
    if(isHash($_[2]) and $_[2]->{"simple"} and $_[2]->{"simple"} eq "lower"){
        if (defined($thresholds{"warning"}{"lower"})
        and defined($thresholds{"critical"}{"lower"})
        and $thresholds{"warning"}{"lower"} < $thresholds{"critical"}{"lower"}){
            usage "warning threshold ($thresholds{warning}{lower}) cannot be lower than critical threshold ($thresholds{critical}{lower}) for lower limit thresholds";
        }
    } elsif(isHash($_[2]) and $_[2]->{"simple"} and $_[2]->{"simple"} eq "upper"){
        if (defined($thresholds{"warning"}{"upper"})
        and defined($thresholds{"critical"}{"upper"})
        and $thresholds{"warning"}{"upper"} > $thresholds{"critical"}{"upper"}){
            usage "warning threshold ($thresholds{warning}{upper}) cannot be higher than critical threshold ($thresholds{critical}{upper}) for upper limit thresholds";
        }
    }
    1;
}


# Not sure if I can relax the case sensitivity on these according to the Nagios Developer guidelines
sub validate_units ($) {
    my $units = shift;
    $units or usage("units not defined");
    $units = isNagiosUnit($units) || usage("invalid unit specified, must be one of: " . join(" ", @valid_units));
    vlog_options("units", $units);
    return $units;
}


sub validate_url ($;$) {
    my $url  = $_[0] if $_[0];
    my $name = $_[1] || "";
    $name .= " " if $name;
    defined($url) || usage "${name}url not specified";
    $url = isUrl($url) || usage "invalid ${name}url given: '$url'";
    vlog_options("${name}url", $url);
    return $url;
}


sub validate_url_path_suffix ($;$) {
    my $url  = $_[0] if $_[0];
    my $name = $_[1] || "";
    $name .= " " if $name;
    defined($url) || usage "${name}url not specified";
    $url = isUrlPathSuffix($url) || usage "invalid ${name}url given: '$url'";
    vlog_options("${name}url", $url);
    return $url;
}


sub verbose_mode () {
    vlog2("verbose mode on\n");
    vlog3(version_string() . "\n");
    return $verbose >= 1;
}

sub version_string () {
    my $version_str = "";
    $version_str .= "$progname version $main::VERSION  =>  " if defined($progname and $main::VERSION);
    $version_str .= "Hari Sekhon Utils version $HariSekhonUtils::VERSION";
    return $version_str;
}

sub version () {
    defined($main::VERSION) or $main::VERSION = "unset";
    usage version_string();
}


sub vlog (@) {
    if($debug){
        print strftime("%F %T %z  ", localtime);
    }
    print STDERR "@_\n" if $verbose;
}

sub vlog2 (@) {
    vlog @_ if ($verbose >= 2);
}

sub vlog3 (@) {
    vlog @_ if ($verbose >= 3);
}

# TODO: check this
# $progname: prefixed
sub vlog4 (@){
    if($verbose){
        foreach(@_){
            foreach (split(/\n/, $_)){
                vlog "$progname\[$$\]: $_";
            }
        }
        1;
    }
}


sub vlog_options ($$) {
    #scalar @_ eq 2 or code_error "incorrect number of args passed to vlog_options()";
    vlog2 sprintf("%-25s %s", "$_[0]:", $_[1]);
}


#my %download_tries;
#my %lock_tries;
#sub wget ($$) {
#    require LWP::Simple;
#    import LWP::Simple;
#    my $url        = shift;
#    my $local_file = shift;
#
#    $download_tries{$url}++;
#    $lock_tries{$url} = 0;
#    until(go_flock_yourself){
#        $lock_tries{$url}++;
#        if($lock_tries{$url} > $LOCK_TRY_ATTEMPTS){
#            vlog "Hit max lock attempts on url '$url' ($LOCK_TRY_ATTEMPTS attempts, $LOCK_TRY_INTERVAL secs apart) while waiting for download lock, aborting download...\n";
#            return undef;
#        }
#        vlog "sleeping for $LOCK_TRY_INTERVAL secs before retrying download lock for url '$url'";
#        sleep $LOCK_TRY_INTERVAL;
#    }
#    vlog "download lock acquired, fetcing '$url' (attempt $download_tries{$url}/$DOWNLOAD_TRIES)";
#    my $rc = mirror($url, $local_file);
#    if ($rc == RC_NOT_MODIFIED){
#        vlog "local file '$local_file' is up to date, not redownloaded";
#        return 1;
#    } elsif(is_success($rc)){
#        vlog "download successful";
#        return 1;
#    } else {
#        vlog "error downloading $url: return code is '$rc'";
#        flock_off;
#        if($download_tries{$url} >= $DOWNLOAD_TRIES){
#            vlog "failed to download url '$url' $DOWNLOAD_TRIES times";
#            return undef;
#        }
#        vlog "sleeping for $DOWNLOAD_RETRY_INTERVAL secs before trying again";
#        sleep $DOWNLOAD_RETRY_INTERVAL;
#        return wget($url, $local_file);
#    }
#    return undef;
#    #vlog "fetching $url.md5...";
#    #getstore("$url.md5", "$local_file.md5");
##    if(open(my $fh, "$local_file.md5")){
##        #vlog ".md5 file present, checking md5sum against '$local_file'";
##        $md5sum = do { local $/; <$fh> };
##        chomp $md5sum;
##        my $md5 = md5sum($local_file);
##        if($md5 eq $md5sum){
##            vlog "$local_file .md5 file matched '$md5' == '$md5sum', proceeding...";
##            last;
##        } else {
##            vlog "attempt $tries: $local_file did not match yet, file is '$md5' but .md5 file contains '$md5sum'";
##            wget($url, $local_file);
##        }
##    }
#}


sub which ($;$) {
    my $bin  = $_[0] || code_error "no arg supplied to which() subroutine";
    my $quit = $_[1] || 0;
    $bin = isFilename($bin) || quit "UNKNOWN", "invalid filename '$bin' supplied";
    if($bin =~ /^[\.\/]/){
        if(-f $bin){
            if(-x $bin){
                return $bin;
            } else {
                quit "UNKNOWN", "'$bin' is not executable" if $quit;
            }
        } else {
            quit "UNKNOWN", "couldn't find executable '$bin': $!" if $quit;
        }
    } else {
        foreach(split(":", $ENV{"PATH"})){
            (-x "$_/$bin") && return "$_/$bin";
        }
        quit "UNKNOWN", "couldn't find '$bin' in \$PATH ($ENV{PATH})" if $quit;
    }
    return undef;
}


1;
