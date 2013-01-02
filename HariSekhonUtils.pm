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
#  PLEASE DO NOT TOUCH THIS!
#
#  You may use this library at your own risk. You may not change it.
#  If you import this library then at the very minimum I recommend that you add
#  one or more regression tests to cover all usage scenarios for your code to
#  validate when this library is updated.
#
#  Upon library updates, I always run
#
#  ./testplugins.exp tests/*.exptest
#
#   or
#
#  ./testall.sh
#
#  to run full suite of regression tests against all my Nagios plugins to make sure
#  everything still works as expected before releasing to production. The latter will
#  also check for plugins that are importing this library but don't have any test files
#
#  You don't want your Nagios screen to suddenly go all red because you haven't done QA!
#
#  If you've added some code and don't have a corresponding suite of test files
#  in the ./tests directory then they may well break when I update this library.

package HariSekhonUtils;
use warnings;
use strict;
use 5;
use Carp;
use Cwd 'abs_path';
use Fcntl ':flock';
use File::Basename;
use Getopt::Long qw(:config bundling);
#use Sys::Hostname;

our $VERSION = "1.3.25";

#BEGIN {
# May want to refactor this so reserving ISA, update: 5.8.3 onwards
#use Exporter "import";
#require Exporter;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    $critical
    $debug
    $default_email
    $default_timeout
    $domain_regex
    $email
    $email_regex
    $fqdn_regex
    $host
    $hostname_regex
    $ip_regex
    $msg
    $msg_err
    $msg_threshold
    $password
    $plural
    $port
    $progname
    $status
    $status_prefix
    $sudo
    $timeout
    $timeout_max
    $timeout_min
    $tld_regex
    $url_regex
    $url_suffix_regex
    $usage_line
    $user
    $user_regex
    $verbose
    $version
    $warning
    %ERRORS
    %emailoptions
    %hostoptions
    %options
    %options2
    %thresholdoptions
    %thresholds
    %useroptions
    @ENV
    @usage_order
    add_options
    autoflush
    check_array
    check_thresholds
    cmd
    code_error
    compact_array
    critical
    curl
    debug
    expand_units
    flock_off
    get_options
    get_path_owner
    get_status_code
    go_flock_yourself
    isArray
    isDigit
    isDomain
    isFloat
    isFqdn
    isHash
    isHost
    isHostname
    isIP
    isInt
    isLinux
    isMac
    isOS
    isProcessName
    isScalar
    isUser
    is_critical
    is_ok
    is_unknown
    is_warning
    linux_mac_only
    linux_only
    lstrip
    ltrim
    mac_only
    msg_perf_thresholds
    open_file
    pkill
    plural
    quit
    resolve_ip
    rstrip
    rtrim
    set_timeout
    status
    strip
    set_sudo
    trim
    unknown
    uniq_array
    usage
    user_exists
    validate_database
    validate_database_fieldname
    validate_database_query_select_show
    validate_dir
    validate_directory
    validate_domain
    validate_domainname
    validate_email
    validate_file
    validate_filename
    validate_fqdn
    validate_host
    validate_hostname
    validate_int
    validate_integer
    validate_ip
    validate_label
    validate_password
    validate_port
    validate_process_name
    validate_regex
    validate_thresholds
    validate_units
    validate_url
    validate_user
    validate_username
    validate_user_exists
    verbose_mode
    version
    vlog
    vlog2
    vlog3
    vlog_options
    warning
    which
);
our @EXPORT_OK = @EXPORT;

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
    
    $SIG{__DIE__} = sub {
        my $str = $_[0] || "Died";
        if(substr($str, -1, 1) eq "\n"){
            print STDERR $str;
        } else {
            carp $str;
        }
        exit 2;
    };
}

our $progname = basename $0;
$progname =~ /^([\w\.\/_-]+)$/ or quit("UNKNOWN", "Invalid program name - does not adhere to strict regex validation, you should name the program simply and sanely");
$progname = $1;

# Std Nagios Exit Codes. Not using weak nagios utils.pm
our %ERRORS = (
    "OK"        => 0,
    "WARNING"   => 1,
    "CRITICAL"  => 2,
    "UNKNOWN"   => 3,
    "DEPENDENT" => 4
);

# Validation Regex - maybe should qr// here but it makes the vlog option output messy
my  $domain_component   = '\b(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\b';
# validated against http://data.iana.org/TLD/tlds-alpha-by-domain.txt which lists all possible TLDs assigned by IANA
# this matches everything except the XN--\w{6,10} TLDs as of 8/10/2012
our $tld_regex          = '\b(?:[A-Za-z]{2,4}|(?i:local|museum|travel))\b';
our $domain_regex       = '(?:' . $domain_component . '\.)+' . $tld_regex;
our $hostname_component = '\b(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9_\-]{0,61}[a-zA-Z0-9])\b';
our $hostname_regex     = $hostname_component . '(?:\.' . $domain_regex . ')?';
our $fqdn_regex         = $hostname_component . '\.' . $domain_regex;
# I'm intentionally not allowing ' in email regex as although it is valid it is safer not to allow it since I have no use cases where it's come up and it's safer not to allow it
our $email_regex        = '\b[A-Za-z0-9\._\%\+-]{1,64}@[A-Za-z0-9\.-]{2,251}\.[A-Za-z]{2,4}\b';
our $ip_regex           = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b';
our $mac_regex          = '\b[0-9A-F-af]{1,2}([:-])(?:[0-9A-Fa-f]{1,2}\2){4}[0-9A-Fa-f]{1,2}\b';
# I did a scan of registered running process names across several hundred linux servers of a diverse group of enterprise applications with 500 unique process names (58k individual processes) to determine that there are cases with spaces, slashes, dashes, underscores, chevrons (<defunct>), dots (script.p[ly], in.tftpd etc) to determine what this regex should be. Incidentally it appears that Linux truncates registered process names to 15 chars.
our $process_name_regex = '\b[\w\s\.\/\<\>-]+\b';
our $url_suffix_regex   = '/[\w\.\/_\+-]+';
our $url_regex          = '\b(?i:https?://' . $hostname_regex . '(?:' . $url_suffix_regex . ')?)\b';
our $user_regex         = '\b[A-Za-z][A-Za-z0-9]+\b';

our $critical;
our $default_timeout = 10;
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
our $status = "UNKNOWN";
our $status_prefix = "";
our $syslog_initialized = 0;
our $sudo = "";
our $timeout = $default_timeout;
our $timeout_max = 60;
our $timeout_min = 1;
our $usage_line  = "usage: $progname [ options ]";
our $user;
our %thresholds;
# Standard ordering of usage options for help. Exported and overridable inside plugin to customize usage()
our @usage_order = qw(host port user users groups password database query field regex warning critical);
my @valid_units = qw/% s ms us B KB MB TB c/;
our $verbose = 0;
our $version;
our $warning;

# universal options added automatically when using get_options()
my %options2 = (
    "D|debug+"     => [ \$debug,    "Debug code" ],
    "t|timeout=i"  => [ \$timeout,  "Timeout in secs (default: $default_timeout)" ],
    "v|verbose+"   => [ \$verbose,  "Verbose mode" ],
    "V|version"    => [ \$version,  "Print version and exit" ],
    "h|help"       => [ \$help,     "Print this help" ],
);

# Optional options
our %hostoptions = (
    "H|host=s"      => [ \$host, "Host or IP address to connect to" ],
    "p|port=s"      => [ \$port, "Port to connect to" ],
);
our %useroptions = (
    "U|user=s"      => [ \$user,     "User"      ],
    "P|password=s"  => [ \$password, "Password"  ],
);
our %thresholdoptions = (
    "w|warning=s"   => [ \$warning,  "Warning threshold or ran:ge (inclusive)"  ],
    "c|critical=s"  => [ \$critical, "Critical threshold or ran:ge (inclusive)" ],
);
our %emailoptions = (
    "E|email=s"     => [ \$email,   "Email address" ],
);
my $short_options_len = 0;
my $long_options_len  = 0;

############################
# Nagios Exit Code Functions
#
# there is no ok func since behaviour
# needs to be determined by plugin/scenario

sub unknown {
    if($status eq "OK"){
        $status = "UNKNOWN";
    }
}

sub warning {
    if($status ne "CRITICAL"){
        $status = "WARNING";
    }
}

sub critical {
    $status = "CRITICAL";
}

############################
sub is_ok {
    ($status eq "OK");
}

sub is_warning {
    ($status eq "WARNING");
}

sub is_critical {
    ($status eq "CRITICAL");
}

sub is_unknown {
    ($status eq "UNKNOWN");
}

sub get_status_code {
    if($_[0]){
        return $ERRORS{$_[0]};
    } else {
        return $ERRORS{$status};
    }
}

sub status {
    vlog("status: $status");
}

sub status2 {
    vlog2("status: $status");
}

sub status3 {
    vlog3("status: $status");
}

############################


sub option_present {
    my $new_option = shift;
    grep {
        my @option_switches = split("|", $_);
        my @new_option_switches = split("|", $new_option);
    } (keys %options);
}


# TODO: consider calling this from get_options and passing hashes we want options for straight to that sub

# TODO: fix this to use option_present
sub add_options {
    my $options_hash = shift;
    isHash($options_hash, 1);
    #@options2{keys %options} = values %options;
    #@options2{keys %{$_[0]}} = values %{$options_hash};
    foreach my $option (keys %{$options_hash}){
        unless(option_present($option)){
            print "want to add $option\n";
            #$options2{$option} = ${$options_hash{$option}};
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


sub autoflush {
    select(STDERR);
    $| = 1;
    select(STDOUT);
    $| = 1;
}


sub check_array {
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


sub check_threshold {
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
        return 0;
    }
    return 1;
}


sub check_thresholds {
    #subtrace(@_);
    check_threshold("critical", $_[0]) and
    check_threshold("warning",  $_[0]);
    msg_thresholds();
}


#sub checksum {
#    my $file = shift;
#    my $algo = shift;
#    $algo or $algo = "md5";
#    my $fh;
#    unless(open($fh, $file)){
#        vlog "Failed to read file '$file': $!\n";
#        return 0;
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


sub cmd {
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
            $err .= " $_";
        }
        quit("CRITICAL", "'$cmd' returned $returncode -$err");
    }
    # TODO: extend to return result and output and not check returncode in func or use wrapper func to throw error on non zero return code
    return @output;
}


sub code_error {
    use Carp;
    #quit("UNKNOWN", "Code Error - @_");
    $! = $ERRORS{"UNKNOWN"};
    croak "UNKNOWN: Code Error - @_";
}


sub compact_array {
    return grep { defined } @_;
}


sub curl {
    unless(defined(&main::get)){
        # inefficient, it'll import for each curl call, instead force top level author to 
        # use LWP::Simple 'get'
        #debug("importing LWP::Simple 'get'\n");
        #require LWP::Simple;
        #import LWP::Simple "get";
        code_error "called curl() without declaring \"use LWP::Simple 'get'\"";
    }
    my $url = shift;
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


sub debug {
    return unless $debug;
    my ( $package, $filename, $line ) = caller;
    my $debug_msg = "@_" || "";
    $debug_msg =~ s/^(\n+)//;
    my $prefix_newline = $1 || "";
    my $sub = (caller(1))[3];
    if($sub){
        $sub .= "()";
    } else {
        $filename = basename $filename;
        $sub = "global $filename line $line";
    }
    printf "${prefix_newline}debug: %s => %s\n", $sub, $debug_msg;
}


sub expand_units {
    my $num   = shift;
    my $units = shift;
    my $name  = shift;
    my $power;
    defined($num)   || code_error "no num passed to expand_units()";
    isFloat($num)   || code_error "non-float arg 1 passed to expand_units()";
    defined($units) || code_error "no units passed to expand_units()";
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
    #@options2{ keys %options } = values %options;
    foreach my $option2 (keys %options2){
        # Check that the %options given don't clash with any existing or in-built options
        foreach my $option (keys %options){
            foreach my $switch (split(/\s*\|\s*/, $option)){
                if(grep({$_ eq $switch} split(/\s*\|\s*/, $option2))){
                    code_error("Key clash on switch '$switch' with in-built option '$option2' vs provided option '$option'");
                }
            }
        }
        $options{$option2} = $options2{$option2}; #unless exists $options{$option2}; # check above is stronger
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


sub get_path_owner {
    my $path = shift if defined($_[0]) || code_error "no path passed to get_path_owner()";
    open my $fh, $path || return 0;
    my @stats = stat($fh);
    close $fh;
    defined($stats[4]) || return 0;
    return getpwuid($stats[4]) || 0;
}


# go flock ur $self ;)
sub go_flock_yourself {
    my $there_can_be_only_one = shift;
    if($there_can_be_only_one){
        open  *{0} or die "Failed to open *{0} for lock: $!\n";
        flock *{0}, LOCK_EX|LOCK_NB or die "Failed to acquire global lock, related code is already running somewhere!\n";
    } else {
        open our $selflock, $0 or die "Failed to open $0 for lock: $!\n";
        flock $selflock, LOCK_EX|LOCK_NB or die "Another instance of " . abs_path($0) . " is already running!\n";
    }
}
sub flock_off {
    my $there_can_be_only_one = shift;
    if($there_can_be_only_one){
        open  *{0} or die "Failed to open *{0} for lock: $!\n";
        flock *{0}, LOCK_UN;
    } else {
        our $selflock = open $0 or die "Failed to open $0 for lock: $!\n";
        flock $selflock, LOCK_UN;
    }
}


sub isArray {
    my $isArray = ref $_[0] eq "ARRAY";
    if($_[1]){
        unless($isArray){
            code_error "non array reference passed";
        }
    }
    return $isArray;
}


sub isCode {
    my $isCode = ref $_[0] eq "CODE";
    return $isCode;
}


sub isDigit {
    isInt(@_);
}


sub isDomain {
    my $domain = shift;
    defined($domain) or return 0;
    return 0 if(length($domain) > 255);
    $domain =~ /^($domain_regex)$/ or return 0;
    return $1;
}


sub isFloat {
    my $number = shift;
    defined($number) or code_error("no number passed to isFloat subroutine");
    #my $allow_negative = shift;
    my $negative = "";
    #$negative = "-?" if $allow_negative;
    $negative = "-?" if shift;
    $number =~ /^$negative\d+(?:\.\d+)?$/;
}


sub isFqdn {
    my $fqdn = shift;
    defined($fqdn) or return 0;
    return 0 if(length($fqdn) > 255);
    $fqdn =~ /^($fqdn_regex)$/ or return 0;
    return $1;
}


sub isHash {
    my $isHash = ref $_[0] eq "HASH";
    if($_[1]){
        unless($isHash){
            code_error "non hash reference passed";
        }
    }
    return $isHash;
}


sub isHost {
    my $host = shift;
    isHostname($host) or isIP($host) or 0;
}


sub isHostname {
    my $hostname = shift;
    defined($hostname) or return 0;
    return 0 if(length($hostname) > 255);
    $hostname =~ /^($hostname_regex)$/ or return 0;
    return $1;
}


sub isInt {
    my $number = shift;
    my $signed = shift() ? "-?" : "";
    defined($number) or code_error("no number passed to isInt()");
    $number =~ /^$signed\d+$/ or return 0;
    return 1;
}


sub isIP {
    my $ip = shift;
    defined($ip) or return 0;
    $ip =~ /^($ip_regex)$/ or return 0;
    return $1;
}


sub isProcessName {
    my $process = shift;
    defined($process) or return 0;
    $process =~ /%($process_name_regex)$/ or return 0;
    return $1;
}


# TODO FIXME: doesn't catch error before Perl errors out right now, not using it yet
#sub isRegex {
#    my $regex = shift;
#    defined($regex) || code_error "no regex arg passed to isRegex()";
#    #defined($regex) || return 0;
#    vlog3("testing regex '$regex'");
#    if(eval { qr/$regex/ }){
#        return $regex;
#    } else {
#        return 0;
#    }
#}


sub isScalar {
    my $isScalar = ref $_[0] eq "SCALAR";
    if($_[1]){
        unless($isScalar){
            code_error "non scalar reference passed";
        }
    }
    return $isScalar;
}


sub isSub {
    isCode(@_);
}


sub isUser {
    #subtrace(@_);
    my $user = shift if $_[0];
    defined($user) || code_error "user arg not passed to isUser()";
    $user =~ /^($user_regex)$/ || return 0;
    return $1;
}


# =============================== OS CHECKS ================================== #
sub isOS {
    $^O eq shift;
}

sub isMac {
    isOS "darwin";
}

sub isLinux {
    isOS "linux";
}

my $supported_os_msg = "this program is only supported on %s at this time";
sub mac_only {
    isMac or quit("UNKNOWN", sprintf($supported_os_msg, "Mac/Darwin") );
}

sub linux_only {
    isLinux or quit("UNKNOWN", sprintf($supported_os_msg, "Linux") );
}

sub linux_mac_only {
    isLinux or isMac or quit("UNKNOWN", sprintf($supported_os_msg, "Linux or Mac/Darwin") );
}
# ============================================================================ #


sub loginit {
    # This can cause plugins to fail if there is no connection to syslog available at plugin INIT
    # Let's only use this for something that really needs it
    #INIT {
        #require Sys::Syslog;
        #import Sys::Syslog qw(:standard :macros);
        # Can't actually require/import optimize here because barewards aren't recognized early enough which breaks strict
        use Sys::Syslog qw(:standard :macros);
        openlog $progname, "ndelay,nofatal,nowait,perror,pid", LOG_LOCAL0;
        $syslog_initialized = 1;
    #}
}


sub log {
    loginit() unless $syslog_initialized;
    # For some reason perror doesn't seem to print so do it manually here
    print strftime("%F %T", localtime) . "  $progname\[$$\]: @_\n";
    syslog LOG_INFO, "%s", "@_";
}


sub logdie {
    &log("ERROR: @_");
    exit get_status_code("CRITICAL");
}


sub lstrip {
    my $string = shift;
    defined($string) or code_error "no arg passed to lstrip()";
    $string =~ s/^\s+//o;
    return $string;
}
#sub ltrim { lstrip(@_) }
*ltrim = \&ltrim;


sub msg_perf_thresholds {
    $msg .= ";";
    $msg .= $warning if $warning;
    $msg .= ";";
    $msg .= $critical if $critical;
    $msg .= ";";
}


sub msg_thresholds {
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


sub open_file{
    my $filename = shift;
    my $lock = shift;
    my $mode = shift;
    my $tmpfh;
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


# parsing ps aux is more portable than pkill -f command. Useful for alarm sub
# Be careful to validate and make sure you use taint mode before calling this sub
sub pkill {
    my $search    = $_[0] || code_error "No search arg specified for pkill sub";
    my $kill_args = $_[1] || "";
    return `ps aux | awk '/$search/ {print \$2}' | while read pid; do kill $kill_args \$pid >/dev/null 2>&1; done`;
}


sub plural {
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
    ( $var == 1 ) ? ( $plural = "" ) : ( $plural = "s" );
}


sub print_options {
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
                printf "%-${short_options_len}s  %-${long_options_len}s \t%s\n", $options{$_}{"short"}, $options{$_}{"long"}, $options{$_}{"desc"};
                delete $options{$_};
                last;
            }
        }
    }
}


sub quit {
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
        code_error "invalid number of arguments passed to quit function";
    }
}


sub resolve_ip {
    require Socket;
    import Socket;
    return inet_ntoa(inet_aton($_[0]));
}


sub rstrip {
    my $string = shift;
    defined($string) or code_error "no arg passed to rstrip()";
    $string =~ s/\s+$//o;
    return $string;
}
#sub rtrim { rstrip(@_) }
*rtrim = \&rstrip;


sub set_sudo {
    local $user = $_[0] if defined($_[0]);
    if(getpwuid($>) eq $user){
        $sudo = "";
    } else {
        vlog2("EUID doesn't match user $user, using sudo");
        $sudo = "echo | sudo -S -u $user";
    }
}


sub set_timeout {
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
    alarm($timeout);
}


#sub sub_noarg {
#    quit "UNKNOWN", "Code Error: no arg supplied to subroutine " . (caller(1))[3];
#}


sub strip {
    my $string = shift;
    defined($string) or code_error "no arg passed to strip()";
    $string =~ s/^\s+//o;
    $string =~ s/\s+$//o;
    return $string;
}
*trim = \&strip;


sub subtrace {
    @_ || code_error("\@_ not passed to subtrace");
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
#    return 0;
#}


sub uniq_array {
    my @array = @_; # or code_error "no arg passed to uniq_array";
    isArray(\@array) or code_error "uniq_array was passed a non-array";
    scalar @array or code_error "uniq_array was passed an empty array";
    return ( keys %{{ map { $_ => 1 } @array }} );
}


sub usage {
    print "@_\n\n" if (@_ > 0);
    print "$usage_line\n\n";
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
        if(grep($_ =~ /\b$option\b/, keys %options2)){
            #debug "skipping $option cos it matched \%options2";
            next;
        }
        print_options($option);
        #printf "%-${short_options_len}s  %-${long_options_len}s \t%s\n", $options{$option}{"short"}, $options{$option}{"long"}, $options{$option}{"desc"};
    }
    print_options(sort { lc($a) cmp lc($b) } keys %options2);
    exit $ERRORS{"UNKNOWN"};
}


sub user_exists {
    my $user = shift if $_[0];
    defined($user) or code_error("no user passed to user_exists()");
    #$user = isUser($user) || return 0;

    # using id command since this should exist on most unix systems
    #which("id", 1);
    #`id "$user" >/dev/null 2>&1`;
    #return 1 if ( $? eq 0 );
    #return 0;
    
    # More efficient
    return defined(getpwnam($user));
}


sub validate_database {
    my $database = shift;
    defined($database)      || usage "database name not specified";
    $database =~ /^(\w*)$/  || usage "invalid database name given, must be alphanumeric";
    vlog_options("database", "'$database'");
    return $1;
}


sub validate_database_fieldname {
    my $field = shift;
    defined($field) || usage "field not specified";
    $field  =~ /^(\d+)$/ or $field =~/^([\w\(\)\*\,\._-]+)$/ || usage "invalid field number given, must be a positive integer, or a valid field name";
    $field = $1;
    ($field eq "0") && usage "field cannot be zero";
    vlog_options("field", "$field");
    return $field;
}


sub validate_database_query_select_show {
    my $query = shift;
    defined($query) || usage "query not specified";
    #$query =~ /^\s*((?i:SHOW|SELECT)\s[\w\s;:,\.\?\(\)*='"-]+)$/ || usage "invalid query supplied";
    # TODO: add subquery regex protection to ensure selects
    #debug("regex validating query: $query");
    $query =~ /^\s*((?i:SHOW|SELECT)\s.+)$/ || usage "invalid query supplied, must be a SELECT or SHOW only for safety";
    $query = $1;
    vlog_options("query", "$query");
    return $query;
}


sub validate_domain {
    my $domain = shift;
    defined($domain) || usage "domain name not specified";
    vlog_options("domain", "'$domain'");
    return validate_domainname($domain) || usage "invalid domain name given '$domain'";
}


sub validate_domainname {
    my $domain = shift;
    defined($domain) || return 0;
    return 0 if(length($domain) > 253);
    $domain =~ /^($domain_regex)$/ || return 0;
    return $1;
}


sub validate_dir {
    validate_directory(@_);
}


sub validate_directory {
    my $dir     = shift;
    my $noquit  = shift;
    if($noquit){
        return validate_filename($dir, 1);
    }
    defined($dir) || usage "directory not specified";
    $dir = validate_filename($dir, 1) || usage "Invalid directory given (does not match regex criteria): '$dir'";
    ( -d $dir) || usage "cannot find directory: '$dir'";
    return $dir;
}


sub validate_email {
    my $email = shift;
    defined($email) || return 0;
    return 0 if(length($email) > 256);
    $email =~ /^($email_regex)$/ || return 0;
    return $1;
}


sub validate_file {
    my $filename = shift;
    my $noquit   = shift;
    $filename = validate_filename($filename, $noquit) or return 0;
    unless( -f $filename ){
        usage "file not found: '$filename' ($!)" unless $noquit;
        return 0
    }
    return $filename;
}


sub validate_filename {
    my $filename = shift;
    my $noquit   = shift;
    defined($filename) || usage "filename not specified";
    unless($filename =~ /^([\/\w\s_\.\*\+-]+)$/){
        usage "invalid filename given (does not match regex critera): '$filename'" unless $noquit;
        return 0;
    }
    return $1;
}


#sub validate_int {
#    validate_integer(@_);
#}
*validate_int = \&validate_integer;

sub validate_integer {
    my $integer = $_[0] if defined($_[0]);
    my $min     = $_[1] || 0;
    my $max     = $_[2] || code_error "no max value given for validate_integer()";
    my $name    = $_[3] || code_error "no name passed to validate_integer()";
    defined($integer) || usage "integer not specified";
    isInt($integer,1) or usage "invalid value given for $name, must be an integer";
    ($integer >= $min && $integer <= $max) or usage "invalid value given for $name, must be integer between $min and $max";
    return $integer;
}


sub validate_fqdn {
    my $fqdn = shift;
    defined($fqdn) || return 0;
    return 0 if(length($fqdn) > 255);
    $fqdn =~ /^($fqdn_regex)$/ || return 0;
    return $1;
}


sub validate_host {
    my $host = shift;
    defined($host) || usage "host not specified";
    vlog_options("host", "'$host'");
    return (isHost($host) or usage "invalid host given, not a validate hostname or IP address");
}


sub validate_hostname {
    my $hostname = shift;
    defined($hostname) || usage "hostname not specified";
    vlog_options("host", "'$hostname'");
    return ( isHostname($hostname) or usage "invalid hostname given");
}


sub validate_ip {
    my $ip = shift;
    defined($ip) || usage "ip not specified";
    vlog_options("IP", "'$ip'");
    return (isIP($ip) || usage "invalid IP given");
}


sub validate_port {
    my $port = shift;
    defined($port)      || usage "port not specified";
    $port  =~ /^(\d+)$/ || usage "invalid port number given, must be a positive integer";
    $port = $1;
    ($port >= 1 && $port <= 65535) || usage "invalid port number given, must be between 1-65535)";
    vlog_options("port", "'$port'");
    return $port;
}


sub validate_process_name {
    my $process = shift;
    defined($process) || usage "no process name given";
    $process = isProcessName($process) || usage "invalid process name, failed regex validation";
    vlog_options("process name", '$process');
    return $process;
}


sub validate_label {
    my $label  = shift;
    my $noexit = shift;
    defined($label) || usage "label not specified";
    unless($label =~ /^[\%\(\)\/\*\w\s-]+$/){
        usage "Label must be an alphanumeric identifier" unless $noexit;
        return 0;
    }
    vlog_options("label", $label);
    return $label;
}

sub validate_regex {
    my $regex  = shift;
    my $noquit = shift;
    my $posix  = shift;
    my $regex2;
    if($noquit){
        defined($regex) || return 0;
    } else {
        defined($regex) || usage "regex not specified";
    }
    if($posix){
        if($regex =~ /\$\(|\`/){
            quit "UNKNOWN", "invalid posix regex supplied: contains sub shell metachars ( \$( / ` ) that would be dangerous to pass to shell" unless $noquit;
            return 0;
        } else {
            my @output = cmd("egrep '$regex' < /dev/null");
            if(grep({$_ =~ "Unmatched"} @output)){
                quit "UNKNOWN", "invalid posix regex supplied: contains unbalanced () or []" unless $noquit;
                return 0;
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
            return 0;
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


sub validate_user {
    #subtrace(@_);
    my $user = shift if $_[0];
    defined($user) || usage "username not specified";
    $user = isUser($user) || usage "invalid username given, must be alphanumeric";
    vlog_options("user", "'$user'");
    return $user;
}
*validate_username = \&validate_user;


sub validate_user_exists {
    #subtrace(@_);
    my $user = shift if $_[0];
    $user = validate_user($user);
    user_exists($user) || usage "invalid user given, not found on local system";
    return $user;
}


sub validate_password {
    my $password = shift if $_[0];
    defined($password) || usage "password not specified";
    # Do not do anything stupid with this password like passing it to cmd() since we have to pass it through here as is
    $password =~ /^(.+)$/ || usage "invalid password given";
    vlog_options("password", "'$password'");
    return $1;
}


sub validate_threshold {
    #subtrace(@_);
    my $name        = $_[0];
    my $threshold   = $_[1];
    my $options_ref = $_[2] || {};
    isHash($options_ref) or code_error "3rd arg to validate_threshold() must be a hash ref of options";
    $options_ref->{"positive"} = 1 unless defined($options_ref->{"positive"});
    $options_ref->{"simple"} = "upper" unless $options_ref->{"simple"};
    my @valid_options = qw/simple positive integer/;
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
    }
    $thresholds{"defined"} = 1 if (defined($thresholds{$name}{"upper"}) or defined($thresholds{$name}{"lower"}));
    vlog_options(sprintf("%-8s lower", $name), $thresholds{"$name"}{"lower"}) if defined($thresholds{"$name"}{"lower"});
    vlog_options(sprintf("%-8s upper", $name), $thresholds{"$name"}{"upper"}) if defined($thresholds{"$name"}{"upper"});
    vlog_options(sprintf("%-8s range inversion", $name), "on") if $thresholds{$name}{"invert_range"};
}


# 1st/2nd arg determines if warning/critical are mandatory respectively
# 3rd arg must be "upper" or "lower" to specify to only allow single threshold used as the upper or lower boundary
sub validate_thresholds {
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
}


sub validate_units {
    my $units = shift;
    $units or usage("units not defined");
    foreach(@valid_units){
        if($units eq $_){
            vlog_options("units", $units);
            return $_;
        }
    }
    usage("invalid unit specified, must be one of: " . join(" ", @valid_units));
}


sub validate_url {
    my $url  = $_[0] if $_[0];
    my $name = $_[1] || "";
    $name .= " " if $name;
    defined($url) || usage "${name}url not specified";
    $url =~ /^($url_regex)$/ || usage "invalid ${name}url given: '$url'";
    return $1;
}


sub verbose_mode {
    vlog2("verbose mode on\n");
}


sub version {
    defined($main::VERSION) or $main::VERSION = "unset";
    usage "$progname version $main::VERSION  =>  Nagios Utils Hari Sekhon version $HariSekhonUtils::VERSION";
}


sub vlog {
    print STDERR "@_\n" if $verbose;
}

sub vlog2 {
    print STDERR "@_\n" if ($verbose >= 2);
}

sub vlog3 {
    print STDERR "@_\n" if ($verbose >= 3);
}

# $progname: prefixed
sub vlog4{
    if($verbose){
        foreach (split(/\n/, $_[0])){
            print STDERR "$progname\[$$\]: $_\n";
        }
    }
}

sub vlog_options {
    scalar @_ eq 2 or code_error "incorrect number of args passed to vlog_options()";
    vlog2 sprintf("%-25s %s", "$_[0]:", $_[1]);
}

#my %download_tries;
#my %lock_tries;
#sub wget {
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
#            return 0;
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
#            return 0;
#        }
#        vlog "sleeping for $DOWNLOAD_RETRY_INTERVAL secs before trying again";
#        sleep $DOWNLOAD_RETRY_INTERVAL;
#        return wget($url, $local_file);
#    }
#    return 0;
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


sub which {
    my $bin  = $_[0] || code_error "no arg supplied to which() subroutine";
    my $quit = $_[1] || 0;
    $bin = validate_filename($bin);
    if($bin =~ /^[\.\/]/){
        (-f $bin) or quit "UNKNOWN", "couldn't find executable '$bin': $!" if $quit;
        (-x $bin) or quit "UNKNOWN", "'$bin' is not executable" if $quit;
        return $bin;
    } else {
        foreach(split(":", $ENV{"PATH"})){
            (-x "$_/$bin") && return "$_/$bin";
        }
        quit "UNKNOWN", "couldn't find '$bin' in \$PATH ($ENV{PATH})" if $quit;
    }
    return 0;
}


1;
