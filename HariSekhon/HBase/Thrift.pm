#
#  Author: Hari Sekhon
#  Date: 2013-07-28 23:56:03 +0100 (Sun, 28 Jul 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

# Split off from my check_hbase_table.pl Nagios Plugin

package HariSekhon::HBase::Thrift;

$VERSION = "0.2.1";

use strict;
use warnings;

BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/../..";
}
use HariSekhonUtils;
use Thrift;
use Thrift::Socket;
use Thrift::BinaryProtocol;
use Thrift::BufferedTransport;
# Thrift generated bindings for HBase, provided in lib
use Hbase::Hbase;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw(
                    connect_hbase_thrift
                )
);
our @EXPORT_OK = ( @EXPORT );

# using custom try/catch from my HariSekhonUtils as it's necessary to disable the custom die handler for this to work

sub connect_hbase_thrift($$;$$){
    my $host = shift;
    my $port = shift;
    my $send_timeout = shift || 10000;
    my $recv_timeout = shift || 10000;
    my $client;
    my $protocol;
    my $socket;
    my $transport;
    validate_resolvable($host);
    vlog2 "connecting to HBase Thrift server at $host:$port\n";
    try {
        $socket    = new Thrift::Socket($host, $port);
    };
    catch_quit "failed to connect to Thrift server at '$host:$port'";
    try {
        $socket->setSendTimeout($send_timeout);
        $socket->setRecvTimeout($recv_timeout);
        $transport = new Thrift::BufferedTransport($socket,1024,1024);
    };
    catch_quit "failed to initiate Thrift Buffered Transport";
    try {
        $protocol  = new Thrift::BinaryProtocol($transport);
    };
    catch_quit "failed to initiate Thrift Binary Protocol";
    try {
        $client    = Hbase::HbaseClient->new($protocol);
    };
    catch_quit "failed to initiate HBase Thrift Client";

    $status = "OK";

    try {
        $transport->open();
    };
    catch_quit "failed to open Thrift transport to $host:$port";

    return $client;
}

1;
