#
#  Author: Hari Sekhon
#  Date: 2013-07-03 01:58:10 +0100 (Wed, 03 Jul 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

# Split off from Nagios plugin check_zookeeper.pl I wrote in 2011

package HariSekhon::ZooKeeper;

$VERSION = "0.3";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;
use IO::Socket;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $ZK_DEFAULT_PORT
                    $zk_conn
                    $zk_port
                    @zk_valid_states
                    zoo_cmd
                )
);
our @EXPORT_OK = ( @EXPORT );

# ZooKeeper Client Port
our $ZK_DEFAULT_PORT = 2181;
our $zk_port         = $ZK_DEFAULT_PORT;
our @zk_valid_states = qw/leader follower standalone/;

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
    vlog3 "connecting to $host:$zk_port";
    $zk_conn = IO::Socket::INET->new (
                                        Proto    => "tcp",
                                        PeerAddr => $host,
                                        PeerPort => $zk_port,
                                        Timeout  => $timeout,
                                     ) or quit "CRITICAL", "Failed to connect to '$host:$zk_port': $!";
    vlog3 "OK connected";
    vlog3 "sending request: '$cmd'";
    print $zk_conn $cmd or quit "CRITICAL", "Failed to send request '$cmd': $!";
    vlog3 "sent request:    '$cmd'";
}

1;
