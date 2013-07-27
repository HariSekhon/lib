#
#   Author: Hari Sekhon
#   Date: 2013-07-03 01:58:10 +0100 (Wed, 03 Jul 2013)
#  $LastChangedBy$
#  $LastChangedDate$
#  $Revision$
#  $URL$
#  $Id$
#
#  vim:ts=4:sts=4:et

package HariSekhon::ZooKeeper;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
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

our $ZK_DEFAULT_PORT = 2181;
our $zk_port         = $ZK_DEFAULT_PORT;
our @zk_valid_states = qw/leader follower standalone/;

our $zk_conn;
# TODO: ZooKeeper closes connection after 1 cmd, see if I can work around this, as having to use several TCP connections is inefficient
sub zoo_cmd {
    vlog3 "connecting to $host:$port";
    $zk_conn = IO::Socket::INET->new (
                                        Proto    => "tcp",
                                        PeerAddr => $host,
                                        PeerPort => $port,
                                     ) or quit "CRITICAL", "Failed to connect to '$host:$port': $!";
    vlog3 "OK connected";
    my $cmd = defined($_[0]) ? $_[0] : code_error "no cmd arg defined for zoo_cmd()";
    vlog3 "sending request: '$cmd'";
    print $zk_conn $_[0] or quit "CRITICAL", "Failed to send request '$cmd': $!";
    vlog3 "sent request:    '$cmd'";
}

1;
