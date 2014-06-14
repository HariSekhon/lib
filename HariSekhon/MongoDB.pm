#
#  Author: Hari Sekhon
#  Date: 2014-06-14 13:42:34 +0100 (Sat, 14 Jun 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::MongoDB;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use MongoDB::MongoClient;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $hosts
                    @hosts
                    $ssl
                    $sasl
                    $sasl_mechanism
                    %mongo_host_option
                    %mongo_sasl_options
                    connect_mongo
                    validate_mongo_hosts
                    validate_mongo_sasl
                    @valid_concerns
                )
);
our @EXPORT_OK = ( @EXPORT );

# not used
#set_port_default(27017);

env_creds("MongoDB");

our $hosts;
our @hosts;

# 'all' gets rejected by the MongoDB Perl Library
#our @valid_concerns    = qw/1 2 majority all/;
our @valid_concerns    = qw/1 2 majority/;

our $sasl           = 0;
our $sasl_mechanism = "GSSAPI";

our %mongo_host_option = (
    "H|host=s"         => [ \$host,          "MongoDB host(s) to connect to, comma separated, with optional :<port> suffixes. Tries hosts in given order from left to right to find Primary for write. Specifying any one host is sufficient as the rest will be auto-determined to find the primary (\$MONGODB_HOST, \$HOST)" ],
);

our %mongo_sasl_options = (
    "ssl"                   => [ \$ssl,             "Enable SSL, MongoDB libraries must have been compiled with SSL and server must support it. Experimental" ],
    "sasl"                  => [ \$sasl,            "Enable SASL authentication, must be compiled in to the MongoDB perl driver to work. Experimental" ],
    "sasl-mechanism=s"      => [ \$sasl_mechanism,  "SASL mechanism (default: GSSAPI eg Kerberos on MongoDB Enterprise 2.4+ in which case this should be run from a valid kinit session, alternative PLAIN for LDAP using user/password against MongoDB Enterprise 2.6+ which is sent in plaintext so should be used over SSL). Experimental" ],
);

push(@usage_order, qw/ssl sasl sasl-mechanism/);

sub connect_mongo(;$){
    my %mongo_connect_options = shift() || ();
    my $client;
    try {
        $client = MongoDB::MongoClient->new(
                                            "host"           => $hosts,
                                            # hangs when giving only nodes of a replica set that aren't the Primary
                                            #"find_master"    => 1,
                                            "timeout"        => int($timeout * 1000 / 4), # connection timeout
                                            #"wtimeout"       => $wtimeout,
                                            "query_timeout"  => int($timeout * 1000 / 4),
                                            "ssl"            => $ssl,
                                            "sasl"           => $sasl,
                                            "sasl-mechanism" => $sasl_mechanism,
                                            %mongo_connect_options,
                                           ) || quit "CRITICAL", "$!";
    };
    catch_quit "failed to connect to MongoDB host '$hosts'";

    vlog2 "connection initiated to $host\n";
    return $client;
}


sub validate_mongo_hosts(){
    defined($host) or usage "MongoDB host(s) not specified";
    @hosts = split(",", $host);
    for(my $i=0; $i < scalar @hosts; $i++){
        $hosts[$i] = validate_hostport(strip($hosts[$i]), "Mongo");
    }
    $hosts  = "mongodb://" . join(",", @hosts);
#my $hosts  = join(",", @hosts);
    vlog_options "Mongo host list", $hosts;
}


sub validate_mongo_sasl(){
    grep { $sasl_mechanism eq $_ } qw/GSSAPI PLAIN/ or usage "invalid sasl-mechanism specified, must be either GSSAPI or PLAIN";
    vlog_options "ssl",  "enabled" if $ssl;
    vlog_options "sasl", "enabled" if $sasl;
    vlog_options "sasl-mechanism", $sasl_mechanism if $sasl;
}

1;
