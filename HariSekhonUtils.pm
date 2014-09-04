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
use JSON 'decode_json';
use Scalar::Util 'blessed';
#use Sys::Hostname;
use Time::Local;

our $VERSION = "1.8.8";

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
                        get_field
                        get_field_array
                        get_field_float
                        get_field_hash
                        get_field_int
                        get_field2
                        get_field2_array
                        get_field2_float
                        get_field2_hash
                        get_field2_int
                        inArray
                        uniq_array
                        uniq_array2
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
                        isObject
                        isOS
                        isPort
                        isProcessName
                        isRef
                        isScalar
                        isScientific
                        isThreshold
                        isUrl
                        isUrlPathSuffix
                        isUser
                        isVersion
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
                        add_host_options
                        add_user_options
                        get_options
                        check_regex
                        check_string
                        check_threshold
                        check_thresholds
                        env_creds
                        expand_units
                        human_units
                        msg_perf_thresholds
                        minimum_value
                        month2int
                        parse_file_option
                        plural
                        remove_timeout
                        set_port_default
                        set_threshold_defaults
                        timecomponents2days
                        usage
                        validate_ssl
                        validate_tls
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
                        escape_regex
                        $domain_regex
                        $email_regex
                        $filename_regex
                        $fqdn_regex
                        $host_regex
                        $hostname_regex
                        $ip_regex
                        $krb5_principal_regex
                        $mac_regex
                        $process_name_regex
                        $rwxt_regex
                        $subnet_mask_regex
                        $tld_regex
                        $url_path_suffix_regex
                        $url_regex
                        $user_regex
                        $version_regex
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
                        quit
                    ) ],
    'string' => [   qw(
                        lstrip
                        ltrim
                        random_alnum
                        rstrip
                        rtrim
                        strip
                        trim
                        trim_float
                    ) ],
    'time'    => [  qw(
                        sec2min
                    ) ],
    'timeout' => [  qw(
                        set_http_timeout
                        set_timeout
                        set_timeout_default
                        set_timeout_max
                        set_timeout_range
                    ) ],
    'validate' => [ qw(
                        skip_java_output
                        validate_alnum
                        validate_aws_access_key
                        validate_aws_bucket
                        validate_aws_secret_key
                        validate_collection
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
                        validate_host_port_user_password
                        validate_host
                        validate_hostname
                        validate_hostport
                        validate_int
                        validate_integer
                        validate_interface
                        validate_ip
                        validate_krb5_princ
                        validate_krb5_realm
                        validate_label
                        validate_node_list
                        validate_nosql_key
                        validate_password
                        validate_port
                        validate_process_name
                        validate_program_path
                        validate_regex
                        validate_resolvable
                        validate_ssl
                        validate_tls
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
                        $expected_version
                        $host
                        $json
                        $msg
                        $msg_err
                        $msg_threshold
                        $nagios_plugins_support_msg
                        $nagios_plugins_support_msg_api
                        $password
                        $plural
                        $port
                        $progname
                        $status
                        $status_prefix
                        $sudo
                        $ssl
                        $ssl_ca_path
                        $tls
                        $ssl_noverify
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
                        %expected_version_option
                        %hostoptions
                        %options
                        %ssloptions
                        %thresholdoptions
                        %thresholds
                        %tlsoptions
                        %useroptions
                        @usage_order
                    ) ],
    'verbose' => [  qw(
                        code_error
                        debug
                        hr
                        tprint
                        verbose_mode
                        vlog
                        vlog2
                        vlog3
                        vlog_options
                    ) ],
    'web'   =>  [   qw(
                        curl
                        curl_json
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

# This now needs to be before BEGIN{} so we can reference it in die_sub()
#
# Std Nagios Exit Codes. Not using weak nagios utils.pm. Also improves portability to not rely on it being present
our %ERRORS = (
    "OK"        => 0,
    "WARNING"   => 1,
    "CRITICAL"  => 2,
    "UNKNOWN"   => 3,
    "DEPENDENT" => 4
);

our $status_prefix = "";

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
        # this is auto-translated in to equivalent system error string, we're not interested in system interpretation
        # so explicitly cast back to int so we can compare with std error codes
        my $exit_code = $?;
        $exit_code = (defined($exit_code) and $exit_code ne "" ? int($exit_code) : $ERRORS{"CRITICAL"});
        my $str   = "@_" || "Died";
        # better to add the status prefix in here instead of in quit calls
        #my $status_prefixes = join("|", keys %ERRORS);
        #$str =~ s/:\s+(?:$status_prefixes):/:/g;
        #if(substr(basename($0), 0, 6) eq "check_"){
            my $prefix = "";
            foreach(keys %ERRORS){
                if($exit_code == $ERRORS{$_}){
                    $prefix = $_;
                    last;
                }
            }
            $prefix = "CRITICAL" unless $prefix;
            $str = "${status_prefix}${prefix}: $str";
        #}
        # mimic original die behaviour by only showing code line when there is no newline at end of string
        if(substr($str, -1, 1) eq "\n"){
            print STDERR $str;
        } else {
            carp $str;
        }
        if(grep(/^$exit_code$/, values %ERRORS)){
            exit $exit_code;
        }
        exit $ERRORS{"CRITICAL"};
    };
    if(substr(basename($0), 0, 6) eq "check_"){
        $SIG{__DIE__} = \&die_sub;
    }

    # This is because the die handler causes program exit instead of return from eval {} block required for exception handling
    sub try(&) {
        my $old_die = $SIG{__DIE__};
        undef $SIG{__DIE__};
        eval {$_[0]->()};
        #$SIG{__DIE__} = \&die_sub;
        $SIG{__DIE__} = $old_die;
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

our $nagios_plugins_support_msg = "Please try latest version from https://github.com/harisekhon/nagios-plugins, re-run on command line with -vvv and if problem persists paste full output from -vvv mode in to a ticket requesting a fix/update at https://github.com/harisekhon/nagios-plugins/issues/new";
our $nagios_plugins_support_msg_api = "API may have changed. $nagios_plugins_support_msg";

# ============================================================================ #
# Validation Regex - maybe should qr// here but it makes the vlog option output messy
# ============================================================================ #
# tried reversing these to be in $regex_blah format and not auto exporting but this turned out to be less intuitive from the perspective of a module caller and it was convenient to just use the regex in pieces of code without having to import them specially. This also breaks some code such as check_hadoop_jobtracker.pl which uses $domain_regex
my  $domain_component   = '\b[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\b';
# validated against http://data.iana.org/TLD/tlds-alpha-by-domain.txt which lists all possible TLDs assigned by IANA
# this matches everything except the XN--\w{6,10} TLDs as of 8/10/2012
our $tld_regex          = '\b(?:[A-Za-z]{2,4}|london|museum|travel|local|localdomain|intra)\b';
our $domain_regex       = '(?:' . $domain_component . '\.)*' . $tld_regex;
our $hostname_component = '\b[A-Za-z](?:[A-Za-z0-9_\-]{1,61}[a-zA-Z0-9])?\b';
our $hostname_regex     = "$hostname_component(?:\.$domain_regex)?";
our $filename_regex     = '[\/\w\s_\.:,\*\(\)\=\%\?\+-]+';
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
our $url_path_suffix_regex = '/(?:[\w\.,:\/\%\&\?\!\=\*\|\+-]+)?';
our $url_regex          = '\b(?i:https?://' . $host_regex . '(?::\d{1,5})?(?:' . $url_path_suffix_regex . ')?)';
our $user_regex         = '\b[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9]\b';
our $krb5_principal_regex = "$user_regex(?:(?:\/$hostname_regex)?\@$domain_regex)?";
our $threshold_range_regex  = qr/^(\@)?(-?\d+(?:\.\d+)?)(:)(-?\d+(?:\.\d+)?)?$/;
our $threshold_simple_regex = qr/^(-?\d+(?:\.\d+)?)$/;
our $version_regex      = '\d(\.\d+)*';
# ============================================================================ #

our $critical;
our $debug = 0;
our $email;
our $expected_version;
our $help;
our $host;
our $json;
our $msg = "";
our $msg_err = "";
our $msg_threshold = "";
my  @options;
our %options;
our $password;
our $port;
my  $selflock;
our $status = "UNKNOWN";
our $sudo = "";
our $syslog_initialized = 0;
our $ssl;
our $ssl_ca_path;
our $ssl_noverify;
our $tls;
our $timeout_default = 10;
our $timeout_max     = 60;
our $timeout_min     = 1;
our $timeout         = $timeout_default;
our $usage_line      = "usage: $progname [ options ]";
our $user;
our %thresholds;
# Standard ordering of usage options for help. Exported and overridable inside plugin to customize usage()
our @usage_order = qw/host port user users groups password database query field regex warning critical ssl tls ssl-CA-path ssl-noverify/;
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

sub set_timeout_range($$){
    my $min = shift;
    my $max = shift;
    isInt($min) or code_error("non-integer passed to set_timeout_range for min (first arg)");
    isInt($max) or code_error("non-integer passed to set_timeout_range for max (second arg)");
    $timeout_min = $min;
    $timeout_max = $max;
}

# ============================================================================ #
# Optional options
our %hostoptions = (
    "H|host=s"      => [ \$host, "Host to connect to" ],
    "P|port=s"      => [ \$port, "Port to connect to" ],
);
our %useroptions = (
    "u|user=s"      => [ \$user,     "User     to connect with" ],
    "p|password=s"  => [ \$password, "Password to connect with" ],
);
our %thresholdoptions = (
    "w|warning=s"   => [ \$warning,  "Warning  threshold or ran:ge (inclusive)" ],
    "c|critical=s"  => [ \$critical, "Critical threshold or ran:ge (inclusive)" ],
);
our %emailoptions = (
    "E|email=s"     => [ \$email,   "Email address" ],
);
our %expected_version_option = (
    "e|expected=s"     => [ \$expected_version,     "Expected version regex, raises CRITICAL if not matching, optional" ]
);
our %ssloptions = (
    "S|ssl"            => [ \$ssl,          "Use SSL connection" ],
    "ssl-CA-path=s"    => [ \$ssl_ca_path,  "Path to CA certificate directory for validating SSL certificate (automatically enables --ssl)" ],
    "ssl-noverify"     => [ \$ssl_noverify, "Do not verify SSL certificate (automatically enables --ssl)" ],
);
our %tlsoptions = (
    "T|tls"            => [ \$tls,          "Use TLS connection" ],
    "ssl-CA-path=s"    => [ \$ssl_ca_path,  "Path to CA certificate directory for validating SSL certificate (automatically enables --tls)" ],
    "tls-noverify"     => [ \$ssl_noverify, "Do not verify SSL certificate (automatically enables --tls)" ],
);
my $short_options_len = 0;
my $long_options_len  = 0;


sub add_host_options($){
    my $name = shift;
    defined($name) or code_error("no name arg passed to add_host_options()");
    if(length($name) >= 4){
        $name = join " ", map {ucfirst} split " ", lc $name;
    }
    foreach(keys %hostoptions){
        $hostoptions{$_}[1] =~ s/^(.)/$name \L$1/;
    }
    %options = ( %options, %hostoptions );
}

sub add_user_options($){
    my $name = shift;
    defined($name) or code_error("no name arg passed to add_user_options()");
    if(length($name) >= 4){
        $name = join " ", map {ucfirst} split " ", lc $name;
    }
    foreach(keys %useroptions){
        $useroptions{$_}[1] =~ s/^(.)/$name \L$1/;
    }
    %options = ( %options, %useroptions );
}

my $default_port;
sub set_port_default($){
    defined($default_port) and code_error("default port cannot be set twice");
    $default_port = shift;
    isPort($default_port) or code_error("invalid port passed as first arg to set_port_default");
    $port = $default_port;
    $hostoptions{"P|port=s"}[1] =~ s/\)$/, default: $default_port\)/;
}

sub set_threshold_defaults($$){
    my $default_warning  = shift;
    my $default_critical = shift;
    isThreshold($default_warning)  or code_error("invalid warning threshold passed as first arg to set_threshold_defaults()");
    isThreshold($default_critical) or code_error("invalid critical threshold passed as second arg to set_threshold_defaults()");
    $warning  = $default_warning;
    $critical = $default_critical;
    $thresholdoptions{"w|warning=s"}[1]  =~ s/\)$/, default: $default_warning\)/;
    $thresholdoptions{"c|critical=s"}[1] =~ s/\)$/, default: $default_critical\)/;
}

# ============================================================================ #
# Environment Host/Port and User/Password Credentials

my @host_envs;
my @port_envs;
my @user_envs;
my @password_envs;

my $port_env_found = 0;

sub env_cred($){
    my $name = shift;
    $name = uc $name;
    $name =~ s/[^A-Za-z0-9]/_/g;
    $name .= "_" if $name;
    push(@host_envs,     "\$${name}HOST");
    push(@port_envs,     "\$${name}PORT");
    push(@user_envs,     "\$${name}USERNAME");
    push(@user_envs,     "\$${name}USER");
    push(@password_envs, "\$${name}PASSWORD");
    # Can't vlog here since verbose mode and debug mode aren't set until after option processing
    if($ENV{"${name}HOST"} and not $host){
        #vlog2("reading host from \$${name}HOST environment variable");
        $host = $ENV{"${name}HOST"};
    }
    if($ENV{"${name}PORT"} and not $port_env_found){
        #vlog2("reading port from \$${name}PORT environment variable");
        $port = $ENV{"${name}PORT"};
        $port_env_found++;
    }
    if($ENV{"${name}USERNAME"} and not $user){
        #vlog2("reading user from \$${name}USERNAME environment variable");
        $user = $ENV{"${name}USERNAME"};
    } elsif($ENV{"${name}USER"} and not $user){
        #vlog2("reading user from \$${name}USER environment variable");
        $user = $ENV{"${name}USER"};
    }
    if($ENV{"${name}PASSWORD"} and not $password){
        #vlog2("reading password from \$${name}PASSWORD environment variable");
        $password = $ENV{"${name}PASSWORD"};
    }
}

sub env_creds($;$){
    my $name     = shift;
    my $longname = shift;
    ( defined($name) and $name ) or code_error("no name arg passed to env_creds()");
    unless($longname){
        unless(isScalar(\$name)){
            code_error("must supply longname second arg to env_creds() if first arg for ENV is not a scalar");
        }
        if($name ne uc $name){
            $longname = $name;
        } elsif(length($name) < 5){
            $longname = $name;
        } else {
            $longname = join " ", map {ucfirst} split " ", lc $name;
        }
    }

    if(isScalar(\$name)){
        env_cred($name);
    } elsif(isArray($name)){
        foreach (@{$name}){
            env_cred($_);
        }
    } else {
        code_error("non-scalar/non-array ref passed as first arg to env_creds()");
    }

    env_cred("");
#    if($ENV{"HOST"}){
#        $host = $ENV{"HOST"} unless $host;
#    }
#    if($ENV{"PORT"}){
#        $port = $ENV{"PORT"} unless $port;
#    }
#    if($ENV{"USERNAME"}){
#        $user = $ENV{"USERNAME"} unless $user;
#    } elsif($ENV{"USER"}){
#        $user = $ENV{"USER"} unless $user;
#    }
#    if($ENV{"PASSWORD"}){
#        $password = $ENV{"PASSWORD"} unless $password;
#    }

    $hostoptions{"H|host=s"}[1]     = "$longname host (" . join(", ", @host_envs) . ")";
    $hostoptions{"P|port=s"}[1]     = "$longname port (" . join(", ", @port_envs) . ( defined($port) ? ", default: $port)" : ")");
    $useroptions{"u|user=s"}[1]     = "$longname user     (" . join(", ", @user_envs) . ")";
    $useroptions{"p|password=s"}[1] = "$longname password (" . join(", ", @password_envs) . ")";
}

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
    my $my_errmsg = $_[0];
    catch {
        if(isObject($@) and defined($@->{"message"})){
            $my_errmsg .= ": " . ref($@) . ": " . $@->{"message"};
        }
        if($!) {
            $my_errmsg .= ": $!";
            chomp $my_errmsg;
        }
        if($@ and not isObject($@)) {
            $my_errmsg .= ": $@";
            chomp $my_errmsg;
        }
        quit "CRITICAL", $my_errmsg;
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


sub check_regex ($$;$) {
    my $string = shift;
    my $regex  = shift;
    my $no_msg = shift;
    if($regex and $string !~ /$regex/){
        critical;
        $msg .= " (expected regex: '$regex')" unless $no_msg;
        return undef;
    }
    return 1;
}


sub check_string ($$;$) {
    my $string           = shift;
    my $expected_string  = shift;
    my $no_msg           = shift;
    if($expected_string and $string ne $expected_string){
        critical;
        $msg .= " (expected: '$expected_string')" unless $no_msg;
        return undef;
    }
    return 1;
}


sub check_threshold ($$) {
    #subtrace(@_);
    my $threshold = shift;
    my $result    = shift;

    $threshold =~ /(?:warning|critical)$/ or code_error("invalid threshold name passed to check_threshold subroutine");
    isFloat($result, 1) or isScientific($result, 1) or code_error("Non-float passed to check_threshold subroutine");

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
        if($threshold =~ /warning/){
            warning;
        } else {
            critical;
        }
        # $threshold_ok false
        return 0;
    }
    # $threshold_ok true
    return 1;
}


sub check_thresholds ($;$$) {
    #subtrace(@_);
    my $result            = shift;
    my $no_msg_thresholds = shift || 0;
    my $name              = shift() || "";
    $name .= " " if $name;
    defined($result) or code_error("no result passed to check_thresholds()");
    my $status_ok = check_threshold("${name}critical", $result) and
                    check_threshold("${name}warning",  $result);
    #msg_thresholds() unless $no_msg_thresholds;
    return ($status_ok, msg_thresholds($no_msg_thresholds, $name));
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
        if(substr($progname, 0, 6) eq "check_"){
            foreach (@output) {
                $err .= " " . trim($_);
            }
        } else {
            $err = join("\n", @output);
        }
        quit("CRITICAL", "'$cmd' returned $returncode -$err");
    }
    # TODO: extend to return result and output and not check returncode in func or use wrapper func to throw error on non zero return code
    return @output;
}


sub code_error (@) {
    use Carp;
    #quit("UNKNOWN", "Code Error - @_");
    $? = $! = $ERRORS{"UNKNOWN"};
    if($debug){
        confess "Code Error - @_";
    } else {
        croak "Code Error - @_";
    }
}


# Remove blanks from array
sub compact_array (@) {
    return grep { $_ !~ /^\s*$/ } @_;
}


sub curl ($;$$$$) {
    my $url      = shift;
    my $name     = shift;
    my $user     = shift;
    my $password = shift;
    my $err_sub  = shift;
    #debug("url passed to curl: $url");
    defined($url)      or code_error "no url passed to curl()";
    $url = isUrl($url) or code_error "invalid url supplied to curl()";
    my $host = $url;
    $host =~ s/^https?:\/\///;
    $host =~ s/(?::\d+)?(?:\/.*)?$//;
    isHost($host) or die "Invalid host determined from URL in curl()";
    my $auth = (defined($user) and defined($password));
    # Don't replace $host with resolved host as this changes the vlog output and also affects proxy exceptions
    validate_resolvable($host);
    if($name){
        vlog2("querying $name");
        vlog3("HTTP GET $url" . ( $auth ? " (basic authentication)" : "") );
    } else {
        vlog2("HTTP GET $url" . ( $auth ? " (basic authentication)" : "") );
    }
    #unless(defined(&main::get)){
        # inefficient, it'll import for each curl call, instead force top level author to 
        # use LWP::Simple 'get'
        #debug("importing LWP::Simple 'get'\n");
        #require LWP::Simple;
        #import LWP::Simple "get";
        #code_error "called curl() without declaring \"use LWP::Simple 'get'\"";
    #}
    #$content = main::get $url;
    #my ($result, $err) = ($?, $!);
    #vlog2("result: $result");
    #vlog2("error:  " . ( $err ? $err : "<none>" ) . "\n");
    #if($result ne 0 or $err){
    #    quit("CRITICAL", "failed to get '$url': $err");
    #}
    defined_main_ua();
    $main::ua->show_progress(1) if $debug;
    my $req = HTTP::Request->new('GET', $url);
    # Doesn't work
    #$ua->credentials($host, '', $user, $password);
    $req->authorization_basic($user, $password) if (defined($user) and defined($password));
    my $response = $main::ua->request($req);
    my $content  = $response->content;
    vlog3("returned HTML:\n\n" . ( $content ? $content : "<blank>" ) . "\n");
    vlog2("http status code:     " . $response->code);
    vlog2("http status message:  " . $response->message . "\n");
    if($err_sub){
        isCode($err_sub) or code_error "invalid subroutine passed to curl() as error handler";
        &$err_sub($response);
    } else {
        unless($response->code eq "200"){
            my $additional_information = "";
            my $json;
            if($json = isJson($content)){
                if(defined($json->{"status"})){
                    $additional_information .= ". Status: " . $json->{"status"};
                }
                if(defined($json->{"reason"})){
                    $additional_information .= ". Reason: " . $json->{"reason"};
                } elsif(defined($json->{"message"})){
                    $additional_information .= ". Message: " . $json->{"message"};
                }
            }
            quit("CRITICAL", $response->code . " " . $response->message . $additional_information);
        }
        unless($content){
            quit("CRITICAL", "blank content returned from '$url'");
        }
    }
    return $content;
}


sub curl_json ($;$$$$) {
    my $url         = shift;
    my $name        = shift;
    my $user        = shift;
    my $password    = shift;
    my $err_handler = shift;
    my $content = curl $url, $name, $user, $password, $err_handler;
    $json = isJson($content) or quit "CRITICAL", "invalid json returned " . ( $name ? "by $name at $url" : "from $url");
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


sub defined_main_ua(){
    unless(defined($main::ua)){
        code_error "LWP useragent \$ua not defined (or inaccessibly defined with my instead of our), must import to main before calling curl(), do either \"use LWP::Simple '\$ua'\" or \"use LWP::UserAgent; our \$ua = LWP::UserAgent->new\"";
    }
}


sub escape_regex ($) {
    my $regex = shift;
    defined($regex) or code_error "no regex arg passed to escape_regex() subroutine";
    #$regex =~ s/([^\w\s\r\n])/\\$1/g;
    # backslashes everything that isn't /[A-Za-z_0-9]/
    $regex = quotemeta($regex); # $regex = \Q$regex\E;
    return $regex;
}


sub expand_units ($;$$) {
    my $num   = shift;
    my $units = shift;
    my $name  = shift;
    my $power;
    defined($num)   || code_error "no num arg 1 passed to expand_units()";
    if((!defined($units)) and $num =~ /^(\d+(?:\.\d+)?)([A-Za-z]{1,2})$/){
        $num   = $1;
        $units = $2;
    }
    defined($units) || code_error "no units arg 2 passed to expand_units()";
    isFloat($num)   || code_error "non-float num arg 1 passed to expand_units()";
    if   ($units =~ /^B?$/i) { return $num; }
    elsif($units =~ /^KB?$/i){ $power = 1; }
    elsif($units =~ /^MB?$/i){ $power = 2; }
    elsif($units =~ /^GB?$/i){ $power = 3; }
    elsif($units =~ /^TB?$/i){ $power = 4; }
    elsif($units =~ /^PB?$/i){ $power = 5; }
    else { code_error "unrecognized units " . ($name ? "for $name" : "passed to expand_units()" ) . ". $nagios_plugins_support_msg"; }
    return $num * (1024**$power);
}


sub get_field($){
    get_field2($json, $_[0]);
}

sub get_field_array($){
    get_field2_array($json, $_[0]);
}

sub get_field_float($){
    get_field2_float($json, $_[0]);
}

sub get_field_hash($){
    get_field2_hash($json, $_[0]);
}

sub get_field_int($){
    get_field2_int($json, $_[0]);
}

sub get_field2($$){
    my $hash_ref  = shift;
    isHash($hash_ref) or code_error "non-hash ref passed to get_field2()";
    my $field     = shift || code_error "field not passed to get_field2()";
    # negative lookbehind allows for escaping dot in the field name
    my @parts     = split(/(?<!\\)\./, $field);
    $field =~ s/\\\././g;
    if(scalar(@parts) > 1){
        my $ref = $hash_ref;
        foreach(@parts){
            s/\\\././g;
            defined($ref->{$_}) or quit "UNKNOWN", "'$_' field not found. $nagios_plugins_support_msg_api";
            $ref = $ref->{$_};
        }
        return $ref;
    } else {
        defined($hash_ref->{$field}) or quit "UNKNOWN", "'$field' field not found. $nagios_plugins_support_msg_api";
        return $hash_ref->{$field};
    }
    code_error "hit end of get_field2 sub";
}

sub get_field2_array($$){
    my $value = get_field2($_[0], $_[1]);
    require_array($value, $_[1]);
    return @{$value};
}

sub get_field2_float($$){
    my $value = get_field2($_[0], $_[1]);
    require_float($value, $_[1]);
    return $value;
}

sub get_field2_hash($$){
    my $value = get_field2($_[0], $_[1]);
    require_hash($value, $_[1]);
    return %{$value};
}

sub get_field2_int($$){
    my $value = get_field2($_[0], $_[1]);
    require_int($value, $_[1]);
    return $value;
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
    my %option_count;
    foreach my $option (keys %options3){
        foreach my $switch (split(/\s*\|\s*/, $option)){
            $option_count{$switch}++;
        }
    }
    foreach(keys %option_count){
        $option_count{$_} > 1 and code_error("Duplicate option key detected '$_'");
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


sub human_units ($) {
    my $num = shift;
    my $units;
    defined($num) or code_error "no arg passed to human_units()";
    isFloat($num) or isScientific($num) or code_error "non-float passed to human_units()";
    if(     $num >= (1024**7)){
        code_error "determine suspicious units for number $num, larger than Exabytes??!!";
    } elsif($num >= (1024**6)){
        $num = sprintf("%.2f", $num / (1024**6));
        $units = "EB";
    } elsif($num >= (1024**5)){
        $num = sprintf("%.2f", $num / (1024**5));
        $units = "PB";
    } elsif($num >= (1024**4)){
        $num = sprintf("%.2f", $num / (1024**4));
        $units = "TB";
    } elsif($num >= (1024**3)){
        $num = sprintf("%.2f", $num / (1024**3));
        $units = "GB";
    } elsif($num >= (1024**2)){
        $num = sprintf("%.2f", $num / (1024**2));
        $units = "MB";
    } elsif($num >= (1024**1)){
        $num = sprintf("%.2f", $num / (1024**1));
        $units = "KB";
    } elsif($num < 1024){
        return "$num bytes";
    } else {
        code_error "unable to determine units for number $num";
    }
    return trim_float($num) . $units;
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
    $column =~ /^([\w:]+)$/ or return undef;
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
        $table =~ /^([A-Za-z0-9][\w\.]*[A-Za-z0-9])$/i or return undef;
        return $1;
    } else {
        $table =~ /^([A-Za-z0-9]\w*[A-Za-z0-9])$/i or return undef;
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
    defined($email) or return undef;
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
    defined($number) or return undef;
    $number =~ /^$negative\d+(?:\.\d+)?$/;
}


sub isFqdn ($) {
    my $fqdn = shift;
    defined($fqdn) or return undef;
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
    defined($hex) or return undef;
    $hex =~ /^(0x[A-Fa-f\d]+)$/ or return undef;
    return 1;
}


sub isHost ($) {
    my $host = shift;
    defined($host) or return undef;
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
    defined($hostname) or return undef;
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
    $interface =~ /^((?:em|eth|bond|lo)\d+|lo)$/ or return undef;
    return $1;
}


sub isIP ($) {
    my $ip = shift;
    defined($ip) or return undef;
    $ip =~ /^($ip_regex)$/ or return undef;
    $ip = $1;
    my @octets = split(/\./, $ip);
    (@octets == 4) or return undef;
    foreach(@octets){
        $_ > 255 and return undef;
    }
    $octets[3] eq 0  and return undef;
    $octets[3] > 254 and return undef;
    return $ip;
}


# wish there was a better way of validating the JSON returned but Test::JSON is_valid_json() also errored out badly from underlying JSON::Any module, similar to JSON's decode_json
#sub isJson($){
#    my $data = shift;
#    defined($data) or return undef;
#    # slightly modified from http://stackoverflow.com/questions/2583472/regex-to-validate-json
#    # XXX: Unfortunately this only work on RHEL6's version of Perl and parse failure breaks all dependent code on RHEL5 now
##    my $json_regex = qr/
##      (?(DEFINE)
##         (?<number>   -? (?= [1-9]|0(?!\d) ) \d+ (\.\d+)? ([eE] [+-]? \d+)? )
##         (?<boolean>   true | false | null )
##         (?<string>    " ([^"\\\\]* | \\\\ ["\\\\bfnrt\/] | \\\\ u [0-9a-f]{4} )* " )
##         (?<array>     \[  (?: (?&json)  (?: , (?&json)  )*  )?  \s* \] )
##         (?<pair>      \s* (?&string) \s* : (?&json)  )
##         (?<object>    \{  (?: (?&pair)  (?: , (?&pair)  )*  )?  \s* \} )
##         (?<json>      \s* (?: (?&number) | (?&boolean) | (?&string) | (?&array) | (?&object) ) \s* )
##      )
##      \A (?&json) \Z
##      /six;
#    # TODO: reinvestigate if this can be made to work
##    my $json;
##    my $number  = qr/(-? (?= [1-9]|0(?!\d) ) \d+ (\.\d+)? ([eE] [+-]? \d+)?)/six;
##    my $boolean = qr/(true | false | null)/six;
##    my $string  = qr/(" ([^"\\\\]* | \\\\ ["\\\\bfnrt\/] | \\\\ u [0-9a-f]{4} )* ")/six;
##    my $array   = qr/(\[  (?: (&$json)  (?: , (&$json)  )*  )?  \s* \])/six;
##    my $pair    = qr/\s* ($string) \s* : ($json)/six;
##    my $object  = qr/(\{  (?: ($pair)  (?: , ($pair)  )*  )?  \s* \})/six;
##    $json    = qr/(\s* (?: ($number) | ($boolean) | ($string) | ($array) | ($object) ) \s*)/six;
##    my $json_regex = qr/\A ($json) \Z/six;
#    #if($data =~ $json_regex){
#    #    return 1;
#    #}
#    return 0;
#}

sub isJson($){
    my $string = shift;
    defined($string) or return undef;
    my $json = undef;
    try {
        $json = decode_json($string);
    };
    return $json;
}


sub isKrb5Princ ($) {
    my $principal = shift;
    defined($principal) or return undef;
    $principal =~ /^($krb5_principal_regex)$/ or return undef;
    return $1;
}


# Primarily for Nagios perfdata labels
sub isLabel ($) {
    my $label = shift;
    defined($label) or return undef;
    $label =~ /^[\%\(\)\/\*\w\s-]+$/ or return undef;
    return $label;
}


sub isNagiosUnit ($) {
    my $units = shift;
    defined($units) or return undef;
    foreach(@valid_units){
        if(lc $units eq lc $_){
            return $_;
        }
    }
    return undef;
}


sub isObject ($) {
    my $object = shift;
    return blessed($object);
}


sub isPort ($) {
    my $port = shift;
    defined($port) or return undef;
    $port  =~ /^(\d+)$/ || return undef;
    $port = $1;
    ($port >= 1 && $port <= 65535) || return undef;
    return $port;
}


sub isProcessName ($) {
    my $process = shift;
    defined($process) or return undef;
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


sub isRef ($;$) {
    my $isRef = ref $_[0] eq "REF";
    if($_[1]){
        unless($isRef){
            code_error "non REF reference passed";
        }
    }
    return $isRef;
}


sub isScalar ($;$) {
    my $isScalar = ref $_[0] eq "SCALAR";
    if($_[1]){
        unless($isScalar){
            code_error "non scalar reference passed";
        }
    }
    return $isScalar;
}


sub isScientific($;$){
    my $num      = shift;
    my $negative = shift() ? "-?" : "";
    defined($num) or code_error "no arg passed to isScientific()";
    $num =~ /^$negative\d+(?:\.\d+)?e[+-]?\d+$/i or return undef;
    return $num;
}


#sub isSub {
#    isCode(@_);
#}
*isSub = \&isCode;


sub isThreshold($){
    my $threshold = shift;
    defined($threshold) or code_error "threshold arg to isThreshold() not defined";
    if($threshold =~ $threshold_range_regex){
        return 1;
    } elsif($threshold =~ $threshold_simple_regex){
        return 1;
    }
    return 0;
}


sub isUrl ($) {
    my $url = shift;
    defined($url) or return undef;
    #debug("url_regex: $url_regex");
    $url = trim($url);
    $url = "http://$url" unless $url =~ /:\/\//i;
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


sub isVersion($){
    my $version = shift;
    defined($version) or return undef;
    $version =~ /^($version_regex)$/ || return undef;
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


sub minimum_value ($$) {
    my $value = shift;
    my $min   = shift;
    isFloat($value) or code_error "invalid first arg passed to minimum_value(), must be float";
    isFloat($min)   or code_error "invalid second arg passed to minimum_value(), must be float";
    if($value < $min){
        return $min;
    }
    return $value;
}


# TODO: upper/lower perf threshold flag
sub msg_perf_thresholds (;$$) {
    my $return = shift;
    my $type   = shift() ? "lower" : "upper";
    my $tmp = ";";
    $tmp .= $thresholds{"warning"}{$type}  if defined($thresholds{"warning"}{$type});
    $tmp .= ";";
    $tmp .= $thresholds{"critical"}{$type} if defined($thresholds{"critical"}{$type});
    $tmp .= ";";
    if(defined($return) and $return){
        return $tmp;
    } else {
        $msg .= $tmp;
    }
}


sub msg_thresholds (;$$) {
    my $no_msg_thresholds = shift || 0;
    my $name = shift() || "";
    my $msg2 = "";
    if (defined($thresholds{"${name}critical"}{"error"}) or
        defined($thresholds{"${name}warning"}{"error"})  or
            ($verbose and (
                            defined($thresholds{"${name}warning"}{"range"}) or
                            defined($thresholds{"${name}critical"}{"range"})
                          )
            ) 
        ) {
        $msg2 .= " (";
        if(defined($thresholds{"${name}critical"}{"error"})){
            $msg2 .= $thresholds{"${name}critical"}{"error"} . ", ";
        }
        elsif(defined($thresholds{"${name}warning"}{"error"})){
            $msg2 .= $thresholds{"${name}warning"}{"error"} . ", ";
        }
        if(defined($thresholds{"${name}warning"}{"range"})){
            $msg2 .= "w=" . $thresholds{"${name}warning"}{"range"};
        }
        if(defined($thresholds{"${name}warning"}{"range"}) and defined($thresholds{"${name}critical"}{"range"})){
            $msg2 .= "/";
        }
        if(defined($thresholds{"${name}critical"}{"range"})){
            $msg2 .= "c=" . $thresholds{"${name}critical"}{"range"};
        }
        $msg2 .= ")";
    }
    unless($no_msg_thresholds){
        $msg .= $msg2 if $msg2;
    }
    return $msg2;
}


sub month2int($){
    my $month = shift;
    defined($month) or code_error "no arg passed to month2int";
    my %months = (
        "Jan" => 0,
        "Feb" => 1,
        "Mar" => 2,
        "Apr" => 3,
        "May" => 4,
        "Jun" => 5,
        "Jul" => 6,
        "Aug" => 7,
        "Sep" => 8,
        "Oct" => 9,
        "Nov" => 10,
        "Dec" => 11
    );
    grep { $month eq $_ } keys %months or code_error "non-month passed to month2int()";
    return $months{$month};
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
    $search =~ s/(\/)/\\$1/g;
    $search =~ s/'/./g;
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
    isFloat($var) or code_error("arg passed to plural() is not a float");
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
            if($options{$_}{"long"} =~ /^.*--(?:$option_regex)\s*$/ or $options{$_}{"short"} =~ /^-(?:$option_regex)\s*$/){
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
        grep(/^$status$/, keys %ERRORS) or die "Code error: unrecognized exit code '$status' specified on quit call, not found in %ERRORS hash\n";
        $? = $ERRORS{$status};
        #die "${status_prefix}$status: $msg\n";
        die "$msg\n";
        #print "${status_prefix}$status: $msg\n";
        #exit $ERRORS{$status};
    } elsif(@_ eq 1){
        $msg = $_[0];
        chomp $msg;
        $? = $ERRORS{"CRITICAL"};
        #die "${status_prefix}CRITICAL: $msg\n";
        die "$msg\n";
        #print "${status_prefix}CRITICAL: $msg\n";
        #exit $ERRORS{"CRITICAL"};
    } elsif(@_ eq 2) {
        $status = $_[0];
        $msg    = $_[1];
        chomp $msg;
        grep(/^$status$/, keys %ERRORS) or die "Code error: unrecognized exit code '$status' specified on quit call, not found in %ERRORS hash\n";
        $? = $ERRORS{$status};
        #die "${status_prefix}$status: $msg\n";
        die "$msg\n";
        #print "${status_prefix}$status: $msg\n";
        #exit $ERRORS{$status};
    } else {
        #print "UNKNOWN: Code Error - Invalid number of arguments passed to quit function (" . scalar(@_). ", should be 0 - 2)\n";
        #exit $ERRORS{"UNKNOWN"};
        code_error("invalid number of arguments passed to quit function (" . scalar(@_) . ", should be 0 - 2)");
    }
}


sub random_alnum($){
    my $length = shift;
    isInt($length) or code_error "invalid length passed to random_alnum";
    my @chars  = ("A".."Z", "a".."z", 0..9);
    my $string = "";
    $string .= $chars[rand @chars] for 1..$length;
    return $string;
}


sub remove_timeout(){
    delete $HariSekhonUtils::default_options{"t|timeout=i"};
}


sub require_array($$) {
    my $array = shift;
    my $name  = shift;
    isArray($array) or quit "UNKNOWN", "$name is not an array! $nagios_plugins_support_msg";
}

sub require_float($$) {
    my $float = shift;
    my $name  = shift;
    isFloat($float) or quit "UNKNOWN", "$name is not a float! $nagios_plugins_support_msg";
}

sub require_hash($$) {
    my $hash = shift;
    my $name = shift;
    isHash($hash) or quit "UNKNOWN", "$name is not a hash! $nagios_plugins_support_msg";
}

sub require_int($$) {
    my $int  = shift;
    my $name = shift;
    isInt($int) or quit "UNKNOWN", "$name is not an integer! $nagios_plugins_support_msg";
}


sub resolve_ip ($) {
    require Socket;
    import Socket;
    my $ip;
    defined($_[0]) or return undef;
    # returns packed binary address
    $ip = inet_aton($_[0])  || return undef;
    # returns human readable x.x.x.x - only supporting IPv4 for now
    $ip = inet_ntoa($ip)    || return undef;
    # validate what we have is a correct IP address
    $ip = isIP($ip)         || return undef;
    return $ip;
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


sub set_http_timeout($){
    my $http_timeout = shift;
    isFloat($http_timeout) or code_error "invalid arg passed to set_http_timeout(), must be float";
    defined_main_ua();
    $http_timeout = sprintf("%.2f", minimum_value($http_timeout, 1) );
    vlog2("setting http per request timeout to $http_timeout secs\n");
    $main::ua->timeout($http_timeout);
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
    $timeout    = $_[0] if $_[0];
    my $sub_ref;
    $sub_ref = $_[1] if $_[1];
    $timeout =~ /^\d+$/ || usage("timeout value must be a positive integer\n");
    ($timeout >= $timeout_min && $timeout <= $timeout_max) || usage("timeout value must be between $timeout_min - $timeout_max secs\n");
    if(defined($sub_ref)){
        isSub($sub_ref) or code_error "invalid sub ref passed to set_timeout()";
    }

    $SIG{ALRM} = sub {
        &$sub_ref if defined($sub_ref);
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

sub skip_java_output($){
    @_ or code_error "no input passed to skip_java_output()";
    my $str = join(" ", @_);
    # warning due to Oracle 7 JDK bug fixed in 7u60
    # objc[54213]: Class JavaLaunchHelper is implemented in both /Library/Java/JavaVirtualMachines/jdk1.7.0_45.jdk/Contents/Home/bin/java and /Library/Java/JavaVirtualMachines/jdk1.7.0_45.jdk/Contents/Home/jre/lib/libinstrument.dylib. One of the two will be used. Which one is undefined.
    if($str =~ /Class JavaLaunchHelper is implemented in both|^SLF4J/){
        return 1;
    }
    return 0;
}

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


sub timecomponents2days($$$$$$){
    my $year  = shift;
    my $month = shift;
    my $day   = shift;
    my $hour  = shift;
    my $min   = shift;
    my $sec   = shift;
    my $month_int;
    if(isInt($month)){
        $month_int = $month;
    } else {
        $month_int = month2int($month);
    }
    my $epoch = timegm($sec, $min, $hour, $day, $month_int, $year-1900) || code_error "failed to convert timestamp $year-$month-$day $hour:$min:$sec";
    my $now   = time || code_error "failed to get epoch timestamp";
    return ($epoch - $now) / (86400);
}


sub tprint ($) {
    my $msg = shift;
    defined($msg) or code_error "tprint msg arg not defined";
    print strftime("%F %T %z  ", localtime) . "$msg\n";
}


sub trim_float ($) {
    my $num = shift;
    defined($num) or code_error "no arg passed to trim_float()";
    $num =~ s/\.0+$//;
    $num =~ s/\.([1-9]*)0+$/\.$1/;
    return $num;
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


sub uniq_array2(@){
    my @array = @_; # or code_error "no arg passed to uniq_array";
    isArray(\@array) or code_error "uniq_array2 was passed a non-array";
    scalar @array or code_error "uniq_array2 was passed an empty array";
    my @array2;
    my $item;
    foreach $item (@array){
        grep { $item eq $_ } @array2 and next;
        push(@array2, $item);
    }
    return @array2;
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
        my $option_regex = escape_regex($option);
        if(grep($_ =~ /\A$option_regex\Z/, keys %default_options)){
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
    my $name = shift || croak "second argument (name) not defined when calling validate_alnum()";
    defined($arg) or usage "$name not defined";
    $arg =~ /^([A-Za-z0-9]+)$/ or usage "invalid $name defined: must be alphanumeric";
    $arg = $1;
    vlog_options($name, $arg);
    return $arg;
}


sub validate_aws_access_key($){
    my $aws_access_key = shift;
    defined($aws_access_key) || usage "aws access key not defined";
    $aws_access_key = isAwsAccessKey($aws_access_key) || usage "invalid aws access key defined: must be 20 alphanumeric characters";
    vlog_options("aws_access_key", $aws_access_key);
    return $aws_access_key;
}


sub validate_aws_bucket($){
    my $bucket = shift;
    defined($bucket) or usage "no aws bucket specified";
    $bucket = isDnsShortname($bucket) || usage "invalid aws bucket name defined: must be alphanumeric between 3 and 63 characters long";
    isIP($bucket) and usage "invalid aws bucket name defined: may not be formatted as an IP address";
    vlog_options("bucket", $bucket);
    return $bucket;
}


sub validate_aws_secret_key($){
    my $aws_secret_key = shift;
    defined($aws_secret_key) || usage "aws secret key not defined";
    $aws_secret_key = isAwsSecretKey($aws_secret_key) || usage "invalid aws secret key defined: must be 40 alphanumeric characters";
    vlog_options("aws_secret_key", $aws_secret_key);
    return $aws_secret_key;
}


sub validate_collection ($;$) {
    my $collection = shift;
    my $name       = shift || "";
    $name .= " " if $name;
    defined($collection) || usage "${name}collection not defined";
    $collection =~ /^(\w(?:[\w\.]*\w)?)$/  || usage "invalid ${name}collection defined: must be alphanumeric, with optional periods in the middle";
    $collection = $1;
    vlog_options("${name}collection", $collection);
    return $collection;
}


sub validate_database ($;$) {
    my $database = shift;
    my $name     = shift || "";
    $name .= " " if $name;
    defined($database)      || usage "${name}database not defined";
    $database =~ /^(\w*)$/  || usage "invalid ${name}database defined: must be alphanumeric";
    $database = $1;
    vlog_options("${name}database", $database);
    return $database;
}


sub validate_database_tablename ($;$) {
    my $table           = shift;
    my $allow_qualified = shift;
    defined($table) || usage "table not defined";
    $table = isDatabaseTableName($table, $allow_qualified) || usage "invalid table defined: must be alphanumeric";
    vlog_options("table", $table);
    return $table;
}


sub validate_database_columnname ($) {
    my $column = shift;
    defined($column) || usage "column not defined";
    $column = isDatabaseColumnName($column) || usage "invalid column defined: must be alphanumeric";
    vlog_options("column", $column);
    return $column;
}


sub validate_database_fieldname ($) {
    my $field = shift;
    defined($field) || usage "field not defined";
    $field = isDatabaseFieldName($field) || usage "invalid field defined: must be a positive integer, or a valid field name";
    ($field eq "0") and usage "invalid field defined: cannot be zero";
    vlog_options("field", $field);
    return $field;
}


sub validate_database_query_select_show ($;$) {
    my $query = shift;
    my $name  = shift || "";
    $name .= " " if $name;
    defined($query) || usage "${name}query not defined";
    #$query =~ /^\s*((?i:SHOW|SELECT)\s[\w\s;:,\.\?\(\)*='"-]+)$/ || usage "invalid query supplied";
    #debug("regex validating query: $query");
    $query =~ /^\s*((?:SHOW|SELECT)\s+(?!.*(?:INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|TRUNCATE|;|--)).+)$/i || usage "invalid ${name}query defined: may only be a SELECT or SHOW statement";
    $query = $1;
    $query =~ /insert|update|delete|create|drop|alter|truncate|;|--/i and usage "invalid ${name}query defined: DML statement or suspect chars detected in query!";
    vlog_options("${name}query", $query);
    return $query;
}


sub validate_domain ($;$) {
    my $domain = shift;
    my $name   = shift || "";
    $name .= " " if $name;
    defined($domain) || usage "${name}domain name not defined";
    $domain = isDomain($domain) || usage "invalid ${name}domain name defined ('$domain')";
    vlog_options("${name}domain", $domain);
    return $domain;
}


#sub validate_dir ($;$) {
#    validate_directory(@_);
#}


sub validate_directory ($;$$$) {
    my $dir     = shift;
    my $noquit  = shift;
    my $name    = shift || "";
    my $no_vlog = shift;
    $name .= " " if $name;
    if($noquit){
        return validate_filename($dir, 1);
    }
    defined($dir) || usage "${name}directory not defined";
    $dir = validate_filename($dir, "noquit", "${name}directory", $no_vlog) || usage "invalid ${name}directory (does not match regex criteria): '$dir'";
    ( -d $dir) || usage "cannot find ${name}directory: '$dir'";
    return $dir;
}
*validate_dir = \&validate_directory;


# SECURITY NOTE: this only validates the email address is valid, it's doesn't make it safe to arbitrarily pass to commands or SQL etc!
sub validate_email ($) {
    my $email = shift;
    defined($email) || usage "email not defined";
    isEmail($email) || usage "invalid email address defined: failed regex validation";
    # Not passing it through regex as I don't want to untaint it due to the addition of the valid ' char in email addresses
    return $email;
}


sub validate_file ($;$$$) {
    my $filename = shift;
    my $noquit   = shift;
    my $name     = shift || "";
    my $no_vlog  = shift;
    $filename = validate_filename($filename, $noquit, $name, $no_vlog) or return undef;
    unless( -f $filename ){
        $name .= " " if $name;
        usage "${name}file not found: '$filename' ($!)" unless $noquit;
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
        usage "$name not defined";
        return undef;
    }
    my $filename2;
    unless($filename2 = isFilename($filename)){
        usage "invalid $name (does not match regex critera): '$filename'" unless $noquit;
        return undef;
    }
    vlog_options($name, $filename2) unless $no_vlog;
    return $filename2;
}


sub validate_float ($$$$) {
    my ($float, $name, $min, $max) = @_;
    defined($float) || usage "$name not defined";
    isFloat($float,1) or usage "invalid $name defined: must be a real number";
    ($float >= $min && $float <= $max) or usage "invalid $name defined: must be real number between $min and $max";
    $float =~ /^(-?\d+(?:\.\d+)?)$/ or usage "invalid float $name passed to validate_float(), WARNING: caught LATE";
    $float = $1;
    vlog_options($name, $float);
    return $float;
}


sub validate_fqdn ($;$) {
    my $fqdn = shift;
    my $name = shift || "";
    $name .= " " if $name;
    defined($fqdn) || usage "${name}FQDN not defined";
    $fqdn = isFqdn($fqdn) || usage "invalid ${name}FQDN defined";
    vlog_options("${name}fqdn", $fqdn);
    return $fqdn
}


sub validate_host_port_user_password($$$$){
    return (validate_host($host), validate_port($port), validate_user($user), validate_password($password));
}


sub validate_host ($;$) {
    my $host = shift;
    my $name = shift || "";
    $name = "$name " if $name;
    defined($host) || usage "${name}host not defined";
    $host = isHost($host) || usage "invalid ${name}host defined: not a validate hostname or IP address";
    vlog_options("${name}host", $host);
    return $host;
}


sub validate_hostport ($;$) {
    my $hostport      = shift;
    my $name          = shift || "";
    my $port_required = shift;
    my $no_vlog       = shift;
    $name .= " " if $name;
    defined($hostport) || usage "${name}host:port option not defined";
    my ($host, $port) = split(":", $hostport, 2);
    $host = isHost($host) || usage "invalid ${name}host defined: not a validate hostname or IP address";
    if($port){
        $port = isPort($port) || usage "invalid ${name}port defined: must be a positive integer";
    } elsif($port_required){
        usage "':port' is required for ${name}host:port option";
    }
    $hostport = $host;
    $hostport .= ":$port" if $port;
    vlog_options("${name}host:port", $hostport) unless $no_vlog;
    return $hostport;
}


sub validate_hostname ($;$) {
    my $hostname = shift;
    my $name     = shift || "";
    $name = "$name " if $name;
    defined($hostname) || usage "${name}hostname not defined";
    $hostname = isHostname($hostname) || usage "invalid ${name}hostname defined";
    vlog_options("${name}hostname", $hostname);
    return $hostname;
}


sub validate_int ($$;$$) {
    my ($integer, $name, $min, $max) = @_;
    defined($name) || code_error "name not defined when calling validate_int()";
    defined($integer) || usage "$name not defined";
    isInt($integer, 1) or usage "invalid $name defined: must be an integer";
    if(defined($min)){
        isFloat($min, 1) or code_error "invalid min value '$min' passed to validate_int() for 2nd arg (min value): must be float value";
        $integer < $min and usage "invalid $name defined: cannot be lower than $min";
    }
    if(defined($max)){
        isFloat($max, 1) or code_error "invalid max value '$max' passed to validate_int() for 3rd arg (max value): must be float value";
        $integer > $max and usage "invalid $name defined: cannot be greater than $max";
    }
    $integer =~ /^(-?\d+)$/ or usage "invalid integer $name passed to validate_int() - WARNING: caught LATE code may need updating";
    $integer = $1;
    vlog_options($name, $integer);
    return $integer;
}
*validate_integer = \&validate_int;


sub validate_interface ($) {
    my $interface = shift;
    defined($interface) || usage "interface not defined";
    $interface = isInterface($interface) || usage "invalid interface defined: must be either ethN, bondN or loN";
    vlog_options("interface", $interface);
    return $interface;
}


sub validate_ip ($;$) {
    my $ip   = shift;
    my $name = shift || "";
    $name   .= " " if $name;
    defined($ip) || usage "${name}IP not defined";
    $ip = isIP($ip) || usage "invalid ${name}IP defined";
    vlog_options("${name}IP", $ip);
    return $ip;
}


sub validate_krb5_princ ($;$) {
    my $principal = shift;
    my $name      = shift || "";
    $name .= " " if $name;
    $principal = isKrb5Princ($principal) || usage "invalid ${name}krb5 principal defined";
    vlog_options("${name}krb5 principal", $principal);
    return $principal;
}


sub validate_krb5_realm ($;$) {
    my $realm = shift;
    my $name   = shift || "";
    $name .= " " if $name;
    defined($realm) || usage "${name}realm name not defined";
    $realm = isDomain($realm) || usage "invalid ${name}realm name defined";
    vlog_options("${name}realm", $realm);
    return $realm;
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
        $node = isHost($node) || usage "invalid node name '$node': must be hostname/FQDN or IP address";
    }
    vlog_options("node list", "[ '" . join("', '", @nodes) . "' ]");
    return @nodes;
}


sub validate_nosql_key($;$){
    my $key  = shift;
    my $name = shift || "";
    $name .= " " if $name;
    defined($key) or usage "${name}key not defined";
    $key =~ /^([\w\_\,\.\:\+\-]+)$/ or usage "invalid ${name}key name defined: may only contain characters: alphanumeric, commas, colons, underscores, pluses, dashes";
    $key = $1;
    vlog_options("${name}key", $key);
    return $key;
}


sub validate_port ($;$) {
    my $port = shift;
    my $name = shift || "";
    $name    = "$name " if $name;
    defined($port)         || usage "${name}port not defined";
    $port  = isPort($port) || usage "invalid ${name}port number defined: must be a positive integer";
    vlog_options("${name}port", $port);
    return $port;
}


sub validate_process_name ($;$) {
    my $process = shift;
    my $name    = shift || "";
    $name .= " " if $name;
    defined($process) or usage "${name}process name not defined";
    $process = isProcessName($process) || usage "invalid ${name}process name defined";
    vlog_options("${name}process name", $process);
    return $process;
}


sub validate_program_path ($$;$) {
    my $path  = shift;
    my $name  = shift;
    my $regex = shift() || $name;
    defined($path) or usage "$name program path not defined";
    defined($name) or usage "$path program name not defined";
    validate_regex($regex, "program path regex", 1) or code_error "invalid regex given to validate_program_path()";
    $path = validate_filename($path, undef, undef, "no vlog") or usage "invalid path given for $name, failed filename regex";
    $path =~ /(?:^|\/)$regex$/ || usage "invalid path given for $name, is not a path to the $name command";
    vlog_options("${name} program path", $path);
    return $path;
}


sub validate_label ($) {
    my $label  = shift;
    defined($label) or usage "label not defined";
    $label = isLabel($label) || usage "invalid label defined: must be an alphanumeric identifier";
    vlog_options("label", $label);
    return $label;
}


# TODO: unify with isRegex and do not allow noquit
sub validate_regex ($;$$$) {
    my $regex  = shift;
    my $name   = shift || "";
    my $noquit = shift;
    my $posix  = shift;
    $name = "${name} " if $name;
    my $regex2;
    if($noquit){
        defined($regex) or return undef;
    } else {
        defined($regex) or usage "${name}regex not defined";
    }
    if($posix){
        if($regex =~ /\$\(|\`/){
            quit "UNKNOWN", "invalid ${name}posix regex supplied: contains sub shell metachars ( \$( / ` ) that would be dangerous to pass to shell" unless $noquit;
            return undef;
        } else {
            my @output = cmd("egrep '$regex' < /dev/null");
            #if(grep({$_ =~ "Unmatched"} @output)){
            if(@output){
                #quit "UNKNOWN", "invalid posix regex supplied: contains unbalanced () or []" unless $noquit;
                quit "UNKNOWN", "invalid ${name}posix regex defined: @output" unless $noquit;
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
            quit "UNKNOWN", "invalid ${name}regex defined: $errstr" unless $noquit;
            return undef;
        }
    }
    if($regex2){
        vlog_options("${name}regex", $regex2) unless $noquit;
        return $regex2;
    } else {
        vlog_options("${name}regex", $regex) unless $noquit;
        return $regex;
    }
}


sub validate_user ($;$) {
    #subtrace(@_);
    my $user = shift;
    my $name = shift || "";
    $name .= " " if $name;
    defined($user) or usage "${name}username not defined";
    $user = isUser($user) || usage "invalid ${name}username defined: must be alphanumeric";
    vlog_options("${name}user", $user);
    return $user;
}
*validate_username = \&validate_user;


sub validate_user_exists ($;$) {
    #subtrace(@_);
    my $user = shift;
    my $name = shift || "";
    $name .= " " if $name;
    $user = validate_user($user);
    user_exists($user) or usage "invalid ${name}user defined, not found on local system";
    return $user;
}


sub validate_password ($;$$) {
    my $password  = shift;
    my $name      = shift || "";
    my $allow_all = shift;
    $name = "$name " if $name;
    defined($password) or usage "${name}password not defined";
    if($allow_all){
        # intentionally not untaining
        $password =~ /^(.+)$/ || usage "invalid ${name}password defined";
    } else {
        $password =~ /^([^'"`]+)$/ or usage "invalid ${name}password defined: may not contain quotes of backticks";
        $password = $1;
    }
    vlog_options("${name}password", "<omitted>");
    return $password;
}


sub validate_resolvable($;$){
    my $host = shift;
    my $name = shift || "";
    $name .= " " if $name;
    defined($host) or code_error "${name}host not defined";
    return resolve_ip($host) || quit "CRITICAL", "failed to resolve ${name}host '$host'";
}


sub validate_ssl_opts(){
    if(defined($ssl_noverify)){
        $main::ua->ssl_opts( verify_hostname => 0 );
    }
    if(defined($ssl_ca_path)){
        $ssl_ca_path = validate_directory($ssl_ca_path, undef, "SSL CA directory", "no vlog");
        $main::ua->ssl_opts( SSL_ca_path => $ssl_ca_path );
    }
    if($ssl or $tls){
        vlog_options("SSL CA Path",  $ssl_ca_path) if defined($ssl_ca_path);
        vlog_options("SSL noverify", $ssl_noverify ? "true" : "false");
        $main::protocol = "https" if defined($main::protocol);
    }
}

sub validate_ssl(){
    defined_main_ua();
    $ssl = 1 if(defined($ssl_ca_path) or defined($ssl_noverify));
    if($ssl){
        vlog_options("SSL enabled",  "true");
    }
    validate_ssl_opts();
}

sub validate_tls(){
    defined_main_ua();
    $tls = 1 if(defined($ssl_ca_path) or defined($ssl_noverify));
    if($tls){
        vlog_options("TLS enabled",  "true");
    }
    validate_ssl_opts();
}


sub validate_threshold ($$;$) {
    #subtrace(@_);
    my $name        = shift;
    my $threshold   = shift;
    my $options_ref = shift() || {};
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
    if ($threshold =~ $threshold_range_regex) {
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
    } elsif($threshold =~ $threshold_simple_regex) {
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
        if($options_ref->{"integer"} and defined($thresholds{$name}{$_}) and not isInt($thresholds{$name}{$_}, 1)){
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
    $thresholds{$name}{"range"} = "";
    $thresholds{$name}{"range"} .= $thresholds{$name}{"lower"} if defined($thresholds{$name}{"lower"});
    $thresholds{$name}{"range"} .= ":" if (defined($thresholds{$name}{"lower"}) and defined($thresholds{$name}{"upper"}));
    $thresholds{$name}{"range"}.= $thresholds{$name}{"upper"} if defined($thresholds{$name}{"upper"});
    vlog_options(sprintf("%-8s lower", $name), $thresholds{"$name"}{"lower"}) if defined($thresholds{"$name"}{"lower"});
    vlog_options(sprintf("%-8s upper", $name), $thresholds{"$name"}{"upper"}) if defined($thresholds{"$name"}{"upper"});
    vlog_options(sprintf("%-8s range inversion", $name), "on") if $thresholds{$name}{"invert_range"};
    1;
}


sub validate_thresholds (;$$$$$) {
    # TODO: CRITICAL vs WARNING threshold logic is only applied to simple thresholds, not to range ones, figure out if I can reasonably do range ones later
    my $require_warning  = shift;
    my $require_critical = shift;
    my $options          = shift;
    my $name             = shift() || "";
    my $dual_threshold   = shift;
    my $warning          = $warning;
    my $critical         = $critical;
    if($name){
        $name .= " ";
        if(defined($dual_threshold)){
            ($warning, $critical) = split(",", $dual_threshold, 2);
            if(defined($warning) and not defined($critical)){
                $critical = $warning;
                $warning  = undef;
            }
        } else {
            if($require_warning or $require_critical){
                usage "no threshold given for $name";
            }
        }
    }
    if($require_warning){
        defined($warning)  || usage "${name}warning threshold not defined";
    }
    if($require_critical){
        defined($critical) || usage "${name}critical threshold not defined";
    }
    # replace $warning and $critical with $name options somehow
    validate_threshold("${name}warning",  $warning,  $options) if(defined($warning));
    validate_threshold("${name}critical", $critical, $options) if(defined($critical));
    # sanity checking on thresholds for simple upper or lower thresholds only
    if(isHash($options) and $options->{"simple"} and $options->{"simple"} eq "lower"){
        if (defined($thresholds{"${name}warning"}{"lower"})
        and defined($thresholds{"${name}critical"}{"lower"})
        and $thresholds{"${name}warning"}{"lower"} < $thresholds{"${name}critical"}{"lower"}){
            usage "${name}warning threshold (" . $thresholds{"${name}warning"}{"lower"} . ") cannot be lower than ${name}critical threshold (" . $thresholds{"${name}critical"}{"lower"} . ") for lower limit thresholds";
        }
    } elsif(isHash($options) and $options->{"simple"} and $options->{"simple"} eq "upper"){
        if (defined($thresholds{"${name}warning"}{"upper"})
        and defined($thresholds{"${name}critical"}{"upper"})
        and $thresholds{"${name}warning"}{"upper"} > $thresholds{"${name}critical"}{"upper"}){
            usage "${name}warning threshold (" . $thresholds{"${name}warning"}{"upper"} . ") cannot be higher than ${name}critical threshold (" . $thresholds{"${name}critical"}{"upper"} . ") for upper limit thresholds";
        }
    }
    1;
}


# Not sure if I can relax the case sensitivity on these according to the Nagios Developer guidelines
sub validate_units ($;$) {
    my $units = shift;
    my $name  = shift || "";
    $name .= " " if $name;
    $units or usage("${name}units not defined");
    $units = isNagiosUnit($units) || usage("invalid ${name}units defined, must be one of: " . join(" ", @valid_units));
    vlog_options("${name}units", $units);
    return $units;
}


sub validate_url ($;$) {
    my $url  = $_[0] if $_[0];
    my $name = $_[1] || "";
    $name .= " " if $name;
    defined($url) or usage "${name}url not defined";
    $url = isUrl($url) || usage "invalid ${name}url defined: '$url'";
    vlog_options("${name}url", $url);
    return $url;
}


sub validate_url_path_suffix ($;$) {
    my $url  = $_[0] if $_[0];
    my $name = $_[1] || "";
    $name .= " " if $name;
    defined($url) or usage "${name}url not defined";
    $url = isUrlPathSuffix($url) || usage "invalid ${name}url defined: '$url'";
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
        print STDERR strftime("%F %T %z  ", localtime);
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
