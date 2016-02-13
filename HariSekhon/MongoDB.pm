#
#  Author: Hari Sekhon
#  Date: 2014-06-14 13:42:34 +0100 (Sat, 14 Jun 2014)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::MongoDB;

$VERSION = "0.2.0";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Carp;
use JSON;
use MongoDB;
use MongoDB::MongoClient;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $hosts
                    $sasl
                    $sasl_mechanism
                    $ssl
                    %mongo_host_option
                    %mongo_sasl_options
                    @hosts
                    @valid_concerns
                    connect_mongo
                    curl_mongo
                    validate_mongo_hosts
                    validate_mongo_sasl
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

sub connect_mongo($;$){
    my $hosts = shift;
    my $mongo_connect_options_hashref = shift() || {};
    my $client;
    if($user and $password){
        # doing it this way to avoid username/password fields which break unauthenticated even when supplying 'undef' values
        $hosts =~ s/mongodb:\/\///;
        $hosts = "mongodb://$user:$password\@$hosts";
    }
    try {
        $client = MongoDB::MongoClient->new(
                                            "host"           => $hosts,
                                            #"username"       => $user,
                                            #"password"       => $password,
                                            "db_name"        => "admin",
                                            # hangs when giving only nodes of a replica set that aren't the Primary
                                            #"find_master"    => 1,
                                            "timeout"        => int($timeout * 1000 / 4), # connection timeout
                                            #"wtimeout"       => $wtimeout,
                                            "query_timeout"  => int($timeout * 1000 / 4),
                                            "ssl"            => $ssl,
                                            "sasl"           => $sasl,
                                            "sasl-mechanism" => $sasl_mechanism,
                                            %{$mongo_connect_options_hashref},
                                           ) || quit "CRITICAL", "$!";
    };
    catch_quit "failed to connect to MongoDB host '$hosts'";

    vlog2 "connection initiated to $host\n";
    return $client;
}


sub curl_mongo($){
    my $path = shift;
    $path =~ s/^\///;
    my $url = "http://$host:$port/$path";
    my $content = curl $url, "MongoDB", $user, $password, \&curl_mongo_err_handler;
    try{
        $json = decode_json $content;
    };
    catch{
        my $additional_information = "";
        if($content =~ /It looks like you are trying to access MongoDB over HTTP on the native driver port/){
            chomp $content;
            $additional_information .= ". " . $content . " Try setting your --port to 1000 higher for the rest interface and ensure mongod --rest option is enabled";
        }
        quit "invalid json returned by MongoDB rest interface at '$url'$additional_information";
    };
    return $json;
}


sub curl_mongo_err_handler($){
    my $response = shift;
    my $content  = strip($response->content);
    my $json;
    my $additional_information = "";
    unless($response->code eq "200"){
        if(scalar split("\n", $content) < 2){
            $additional_information .= $content
        }
        if($response->code eq "500"){
            $additional_information .= ". Have you enabled the rest interface with the mongod --rest option?";
        }
        quit "CRITICAL", $response->code . " " . $response->message . $additional_information;
    }
    unless($content){
        quit "CRITICAL", "blank content returned by MongoDB rest interface";
    }
}


sub validate_mongo_hosts($){
    my $host = shift;
    defined($host) or usage "MongoDB host(s) not specified";
    @hosts = split(",", $host);
    for(my $i=0; $i < scalar @hosts; $i++){
        $hosts[$i] = validate_hostport(strip($hosts[$i]), "Mongo");
    }
    $hosts  = "mongodb://" . join(",", @hosts);
#my $hosts  = join(",", @hosts);
    vlog_option "Mongo host list", $hosts;
    return $hosts;
}


sub validate_mongo_sasl(){
    grep { $sasl_mechanism eq $_ } qw/GSSAPI PLAIN/ or usage "invalid sasl-mechanism specified, must be either GSSAPI or PLAIN";
    vlog_option "ssl",  "enabled" if $ssl;
    vlog_option "sasl", "enabled" if $sasl;
    vlog_option "sasl-mechanism", $sasl_mechanism if $sasl;
}

1;
