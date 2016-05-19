#
#  Author: Hari Sekhon
#  Date: 2013-07-03 01:58:10 +0100 (Wed, 03 Jul 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#

# Split off from Nagios plugin check_zookeeper.pl I wrote in 2011

package HariSekhon::ZooKeeper;

$VERSION = "0.8.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils qw/:DEFAULT :time/;
use Carp;
use IO::Socket;
# This would prevent check_zookeeper_config.pl and similar programs only requiring 4lw support from running without full ZooKeeper C to Perl module build
#use Net::ZooKeeper qw/:DEFAULT :errors :log_levels/;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $DATA_READ_LEN
                    $ZK_DEFAULT_PORT
                    $default_zk_timeout
                    $random_conn_order
                    $zk_conn
                    $zkh
                    $zk_stat
                    $zk_timeout
                    $znode_age_secs
                    %zookeeper_options
                    @zk_valid_states
                    check_znode_age_positive
                    check_znode_exists
                    connect_zookeepers
                    get_znode_age
                    get_znode_contents
                    get_znode_contents_json
                    get_znode_contents_xml
                    translate_zoo_error
                    zoo_cmd
                    zoo_debug
                    zookeeper_random_conn_order
                    isZnode
                    validate_base_and_znode
                    validate_znode
                    isZookeeperEnsemble
                    validate_zookeeper_ensemble
                )
);
our @EXPORT_OK = ( @EXPORT );

# Max num of chars to read from znode contents
our $DATA_READ_LEN = 500;

# ZooKeeper Client Port
our $ZK_DEFAULT_PORT = 2181;
set_port_default($ZK_DEFAULT_PORT);
our @zk_valid_states = qw/leader follower standalone/;

env_creds("ZOOKEEPER");

our $default_zk_timeout = 2;
our $zk_timeout = $default_zk_timeout;
our $random_conn_order = 0;
our $zkh;
our $zk_stat;
our $znode_age_secs;
my $zookeepers;
my @zookeepers;

our %zookeeper_options = (
    "H|host=s"          => [ \$host,                  "ZooKeeper node(s) to connect to (\$ZOOKEEPER_HOST, \$HOST), should be a comma separated list of ZooKeepers the same as are configured on the ZooKeeper servers themselves with optional individual ports per server (node1:$ZK_DEFAULT_PORT,node2:$ZK_DEFAULT_PORT,node3:$ZK_DEFAULT_PORT). It takes longer to connect to 3 ZooKeepers than just one of them (around 5 secs per ZooKeeper specified + (session-timeout x any offline ZooKeepers) so you will need to increase --timeout). Connection order is deterministic and will be tried in the order specified unless --random-conn-order" ],
    "P|port=s"          => [ \$port,                  "Port to connect to on ZooKeepers for any nodes not suffixed with :<port> (defaults to $ZK_DEFAULT_PORT, set to 5181 for MapR, \$ZOOKEEPER_PORT, \$PORT)" ],
    # %useroptions,
    "u|user=s"          => [ \$user,                  "User to connect with (\$ZOOKEEPER_USER environment variable. Not tested. YMMV. optional)" ],
    "p|password=s"      => [ \$password,              "Password to connect with (\$ZOOKEEPER_PASSWORD environment variable. Not tested. YMMV. optional)" ],
    "random-conn-order" => [ \$random_conn_order,     "Randomize connection order to provided zookeepers (otherwise tries in order given)" ],
    "session-timeout=s" => [ \$zk_timeout,            "ZooKeeper session timeout in secs (default: $default_zk_timeout). This determines how long to wait for connection to downed ZooKeepers and affects total execution time" ],
);
splice @usage_order, 6, 0, qw/random-conn-order session-timeout/;

sub zookeeper_random_conn_order(){
    require Net::ZooKeeper;
    if($random_conn_order){
        vlog2 "using random connection order";
        Net::ZooKeeper::set_deterministic_conn_order(0); # default
    } else {
        vlog2 "setting deterministic connection order";
        Net::ZooKeeper::set_deterministic_conn_order(1);
    }
}

sub zoo_debug(){
    require Net::ZooKeeper;
    import Net::ZooKeeper qw/:log_levels/;
    if($debug){
        vlog2 "setting ZooKeeper log level => debug";
        #Net::ZooKeeper::set_log_level(&Net::ZooKeeper::ZOO_LOG_LEVEL_DEBUG);
        Net::ZooKeeper::set_log_level(&ZOO_LOG_LEVEL_DEBUG);
    } elsif($verbose > 3){
        vlog2 "setting ZooKeeper log level => info";
        #Net::ZooKeeper::set_log_level(&Net::ZooKeeper::ZOO_LOG_LEVEL_INFO);
        Net::ZooKeeper::set_log_level(&ZOO_LOG_LEVEL_INFO);
    } elsif($verbose > 1){
        vlog2 "setting ZooKeeper log level => warn";
        #Net::ZooKeeper::set_log_level(&Net::ZooKeeper::ZOO_LOG_LEVEL_WARN);
        Net::ZooKeeper::set_log_level(&ZOO_LOG_LEVEL_WARN);
    }
}

sub check_znode_age_positive(){
    if($znode_age_secs < 0){
        my $clock_mismatch_msg = "clock synchronization problem, modified timestamp on znode is in the future!";
        if($status eq "OK"){
            $msg = "$clock_mismatch_msg $msg";
        } else {
            $msg .= ". Also, $clock_mismatch_msg";
        }
        warning;
    }
}

sub get_znode_age($){
    my $znode = shift;
    if(defined($zk_stat)){
        my $mtime = $zk_stat->{mtime} / 1000;
        isFloat($mtime) or quit "UNKNOWN", "invalid mtime returned for znode '$znode', got '$mtime'";
        vlog3 sprintf("znode '%s' mtime = %s", $znode, $mtime);
        $znode_age_secs = time - int($mtime);
        vlog2 "znode last modified $znode_age_secs secs ago";
        check_znode_age_positive();
        return $znode_age_secs;
    } else {
        quit "UNKNOWN", "no stat object returned by ZooKeeper exists call for znode '$znode', try re-running with -vvvvD to see full debug output";
    }
}

sub get_znode_contents($){
    my $znode = shift;
    my $data = $zkh->get($znode, 'data_read_len' => $DATA_READ_LEN);
                               # 'stat' => $zk_stat, 'watch' => $watch)
                               # || quit "CRITICAL", "failed to read data from znode $znode: $!";
    plural @zookeepers;
    defined($data) or quit "CRITICAL", "no data returned for znode '$znode' from zookeeper$plural '$zookeepers': " . $zkh->get_error();
    # /hadoop-ha/logicaljt/ActiveStandbyElectorLock contains carriage returns which messes up the output in terminal by causing the second line to overwrite the first
    $data =~ s/\r//g;
    $data = trim($data);
    vlog3 "znode '$znode' data:\n\n$data\n";
    return $data;
}

sub get_znode_contents_json($){
    my $znode = shift;
    my $data  = get_znode_contents($znode);
    $data     = isJson($data) or quit "CRITICAL", "znode '$znode' data is not JSON as expected, got '$data'";
    return $data;
}

sub get_znode_contents_xml($){
    my $znode = shift;
    my $data  = get_znode_contents($znode);
    $data     = isXml($data) or quit "CRITICAL", "znode '$znode' data is not XML as expected, got '$data'";
    return $data;
}

sub check_znode_exists($;$){
    my $znode  = shift;
    my $noquit = shift;
    vlog2 "checking znode '$znode' exists";
    if($noquit){
        $zkh->exists($znode, 'stat' => $zk_stat) or return 0;
    } else {
        $zkh->exists($znode, 'stat' => $zk_stat) or quit "CRITICAL", "znode '$znode' does not exist! ZooKeeper returned: " . translate_zoo_error($zkh->get_error());
        $zk_stat or quit "UNKNOWN", "failed to get stats from znode $znode";
    }
    vlog2 "znode '$znode' exists";
    return 1;
}

sub connect_zookeepers(@){
    require Net::ZooKeeper;
    @zookeepers = @_;
    plural @zookeepers;
    $zookeepers = join(", ", @zookeepers);

    vlog2 "trapping SIGPIPE in case of lost zookeeper connection";
    # API may raise SIG PIPE on connection failure
    local $SIG{'PIPE'} = sub { quit "UNKNOWN", "lost connection to ZooKeeper$plural '$zookeepers'"; };

    zoo_debug();
    zookeeper_random_conn_order();

    $zk_timeout = validate_float($zk_timeout, "zookeeper session timeout", 0.001, 100);

    vlog2 "connecting to ZooKeeper node$plural: $zookeepers";
    $zkh = Net::ZooKeeper->new( $zookeepers,
                                "session_timeout" => $zk_timeout * 1000
                              )
        || quit "CRITICAL", "failed to create connection object to ZooKeepers within $zk_timeout secs: $!";
    vlog2 "ZooKeeper connection object created, won't be connected until we issue a call";
    # Not tested auth yet
    if(defined($user) and defined($password)){
        $zkh->add_auth('digest', "$user:$password");
    }
    my $session_timeout = ($zkh->{session_timeout} / 1000) or quit "UNKNOWN", "invalid session timeout determined from ZooKeeper handle, possibly not connected to ZooKeeper?";
    vlog2 sprintf("session timeout is %.2f secs\n", $zk_timeout);

    vlog2 "checking znode '/' exists to determine if we're properly connected to ZooKeeper";
    my $connection_succeeded = 0;
# the last attempt will retry all zookeepers two more times if that zookeeper fails to connect
# to see this use -vv --session-timeout 0.001
    for(my $i=0; $i < scalar @zookeepers; $i++){
        $zkh->exists("/") and $connection_succeeded = 1 and last;
    }
    $connection_succeeded or quit "CRITICAL", "connection error, failed to find znode '/': " . translate_zoo_error($zkh->get_error());
    vlog2 "found znode '/', connection to zookeeper succeeded\n";

    vlog3 "creating ZooKeeper stat object";
    $zk_stat = $zkh->stat();
    $zk_stat or quit "UNKNOWN", "failed to create ZooKeeper stat object";
    vlog3 "stat object created";

    return $zkh;
}

sub translate_zoo_error($){
    require Net::ZooKeeper;
    import Net::ZooKeeper qw/:errors/;
    my $errno = shift;
    isInt($errno, 1) or code_error "non int passed to translate_zoo_error()";
    # this makes me want to cry, if anybody knows a better way of getting some sort of error translation out of this API please let me know!
    no strict 'refs';
    foreach(qw(
        ZOK
        ZSYSTEMERROR
        ZRUNTIMEINCONSISTENCY
        ZDATAINCONSISTENCY
        ZCONNECTIONLOSS
        ZMARSHALLINGERROR
        ZUNIMPLEMENTED
        ZOPERATIONTIMEOUT
        ZBADARGUMENTS
        ZINVALIDSTATE
        ZAPIERROR
        ZNONODE
        ZNOAUTH
        ZBADVERSION
        ZNOCHILDRENFOREPHEMERALS
        ZNODEEXISTS
        ZNOTEMPTY
        ZSESSIONEXPIRED
        ZINVALIDCALLBACK
        ZINVALIDACL
        ZAUTHFAILED
        ZCLOSING
        ZNOTHING
    )){
        # This is a tricky workaround to runtime require to avoid forcing the annoying Net::ZooKeeper dependency where client code only needs 4lw support
        #if(eval "Net::ZooKeeper::$_" == $errno){
        if(&$_ == $errno){
            use strict 'refs';
            return "$errno $_";
        }
    }
    use strict 'refs';
    return "<failed to translate zookeeper error for error code: $errno>";
}

sub isZnode($){
    my $znode = shift;
    defined($znode) or undef;
    $znode =~ /^(\/(?:(?:[\w\._-]+\/)*[\w:\._-]+)?)$/ or undef;
    $znode = $1;
    return $znode;
}

sub validate_znode($;$){
    my $znode = shift;
    my $name  = shift() || "";
    $name .= " " if $name;
    defined($znode) or usage "${name}znode not defined";
    $znode = isZnode($znode) or usage "invalid ${name}znode";
    return $znode;
}

sub validate_base_and_znode($$$){
    my $base = shift;
    my $znode = shift;
    my $name = shift;
    $znode = validate_znode($base, "base") . "/$znode";
    $znode =~ s/\/+/\//g;
    $znode = validate_znode($znode, $name);
}

sub isZookeeperEnsemble($){
    my $zookeeper_ensemble = shift;
    my $znode_chroot = $zookeeper_ensemble;
    $znode_chroot =~ s/[^\/]+//;
    $zookeeper_ensemble =~ s/\/.*$//;
    #my @zookeeper_ensemble = validate_hosts($zookeeper_ensemble, $port);
    my @zookeeper_ensemble = split(/\s*,\s*/, $zookeeper_ensemble);
    foreach(my $i=0; $i < scalar @zookeeper_ensemble; $i++){
        $zookeeper_ensemble[$i] = validate_hostport($zookeeper_ensemble[$i], "zookeeper index $i");
    }
    $zookeeper_ensemble = join(",", @zookeeper_ensemble);
    if($znode_chroot){
        $znode_chroot = isZnode($znode_chroot) or return undef;
        $zookeeper_ensemble .= $znode_chroot;
    }
    return $zookeeper_ensemble;
}

sub validate_zookeeper_ensemble($){
    my $zookeeper_ensemble = shift;
    defined($zookeeper_ensemble) or usage "zookeeper ensemble not defined";
    $zookeeper_ensemble = isZookeeperEnsemble($zookeeper_ensemble) or usage "invalid zookeeper ensemble";
    return $zookeeper_ensemble;
}


# ============================================================================ #
#                               Zoo 4lw support
# ============================================================================ #

our $zk_conn;
# TODO: ZooKeeper closes connection after 1 cmd, see if I can work around this, as having to use several TCP connections is inefficient
sub zoo_cmd ($;$) {
    my $cmd     = shift;
    my $timeout = shift;
    unless(defined($cmd)){
        carp "no cmd arg defined for zoo_cmd()";
        exit get_status_code("UNKNOWN");
    }
    if(defined($timeout)){
        unless(isFloat($timeout)){
            carp "non-float timeout passed as zoo_cmd() 2nd arg";
            exit get_status_code("UNKNOWN");
        }
    }
    validate_resolvable($host);
    vlog3 "connecting to $host:$port";
    $zk_conn = IO::Socket::INET->new (
                                        Proto    => "tcp",
                                        PeerAddr => $host,
                                        PeerPort => $port,
                                        Timeout  => $timeout,
                                     ) or quit "CRITICAL", sprintf("Failed to connect to '%s:%s'%s: $!", $host, $port, (defined($timeout) and ($debug or $verbose > 2)) ? " within $timeout secs" : "");
    vlog3 "OK connected";
    vlog3 "sending request: '$cmd'";
    print $zk_conn $cmd or quit "CRITICAL", "Failed to send request '$cmd': $!";
    vlog3 "sent request:    '$cmd'";
}

1;
