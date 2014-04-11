#
#  Author: Hari Sekhon
#  Date: 2014-04-11 20:21:20 +0100 (Fri, 11 Apr 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

# Forked from check_cloudera_manager_metrics.pl (2013) from the Advanced Nagios Plugins Collection
#
# to share with various newer Cloudera Manager check programs

package HariSekhon::ClouderaManager;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;
use LWP::UserAgent;
use JSON 'decode_json';

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $api
                    $cluster
                    $default_port
                    $hostid
                    $json
                    $nameservice
                    $protocol
                    $role
                    $service
                    $ssl_ca_path
                    $ssl_port
                    $tls
                    $tls_noverify
                    $ua
                    $url
                    $url_prefix
                    %cm_options
                    cm_tls
                )
);
our @EXPORT_OK = ( @EXPORT );

our $ua = LWP::UserAgent->new;

our $protocol     = "http";
our $api          = "/api/v1";
our $default_port = 7180;
$port            = $default_port;
our $ssl_port     = 7183;

our $cluster;
our $hostid;
our $json;
our $nameservice;
our $role;
our $service;
our $ssl_ca_path;
our $tls = 0;
our $tls_noverify;
our $url;
our $url_prefix;

env_creds("CM", "Cloudera Manager");

our %cm_options = (
    "T|tls"            => [ \$tls,          "Use TLS connection to Cloudera Manager (automatically updates port to $ssl_port if still set to $default_port to save one 302 redirect round trip)" ],
    "ssl-CA-path=s"    => [ \$ssl_ca_path,  "Path to CA certificate directory for validating SSL certificate (automatically enables --tls)" ],
    "tls-noverify"     => [ \$tls_noverify, "Do not verify SSL certificate from Cloudera Manager (automatically enables --tls)" ],
    "C|cluster=s"      => [ \$cluster,      "Cluster Name as shown in Cloudera Manager (eg. \"Cluster - CDH4\")" ],
    "S|service=s"      => [ \$service,      "Service Name as shown in Cloudera Manager (eg. hdfs1, mapreduce4). Requires --cluster" ],
    "I|hostId=s"       => [ \$hostid,       "HostId to collect metric for (eg. datanode1.domain.com)" ],
    "N|nameservice=s"  => [ \$nameservice,  "Nameservice to collect metric for (as specified in your HA configuration under dfs.nameservices). Requires --cluster and --service" ],
    "R|roleId=s"       => [ \$role,         "RoleId to collect metric for (eg. hdfs4-NAMENODE-73d774cdeca832ac6a648fa305019cef - use --list-roleIds to find CM's role ids for a given service). Requires --cluster and --service" ],
);

@usage_order = qw/host port user password tls ssl-CA-path tls-noverify metrics all-metrics cluster service hostId activityId nameservice roleId list-roleIds warning critical/;

sub cm_query() {
    $tls = 1 if(defined($ssl_ca_path) or defined($tls_noverify));
    if(defined($tls_noverify)){
        $ua->ssl_opts( verify_hostname => 0 );
        $tls = 1;
    }
    if(defined($ssl_ca_path)){
        $ssl_ca_path = validate_directory($ssl_ca_path, undef, "SSL CA directory", "no vlog");
        $ua->ssl_opts( SSL_ca_path => $ssl_ca_path );
        $tls = 1;
    }
    if($tls){
        vlog_options "TLS enabled",  "true";
        vlog_options "SSL CA Path",  $ssl_ca_path  if defined($ssl_ca_path);
        vlog_options "TLS noverify", $tls_noverify ? "true" : "false";
    }
    if($tls){
        $protocol = "https";
        if($port == 7180){
            vlog2 "overriding default http port 7180 to default tls port 7183";
            $port = $ssl_port;
        }
    }
    $host = validate_resolvable($host);
    $url_prefix = "$protocol://$host:$port";

    # Doesn't work
    #$ua->credentials("$host:$port", "Cloudera Manager", $user, $password);
    #$ua->credentials($host, "Cloudera Manager", $user, $password);
    $ua->show_progress(1) if $debug;

    $url = "$url_prefix$url";
    vlog2 "querying $url";
    my $req = HTTP::Request->new('GET', $url);
    $req->authorization_basic($user, $password);
    my $response = $ua->request($req);
    my $content  = $response->content;
    chomp $content;
    vlog3 "returned HTML:\n\n" . ( $content ? $content : "<blank>" ) . "\n";
    vlog2 "http code: " . $response->code;
    vlog2 "message: " . $response->message; 
    if(!$response->is_success){
        my $err = "failed to query Cloudera Manager at '$url_prefix': " . $response->code . " " . $response->message;
        if($content =~ /"message"\s*:\s*"(.+)"/){
            $err .= ". Message returned by CM: $1";
        }
        if($response->message =~ /Can't verify SSL peers without knowing which Certificate Authorities to trust/){
            $err .= ". Do you need to use --ssl-CA-path or --tls-noverify?";
        }
        quit "CRITICAL", $err;
    }
    unless($content){
        quit "CRITICAL", "blank content returned by Cloudera Manager at '$url_prefix'";
    }

    vlog2 "parsing output from Cloudera Manager\n";

    # give a more user friendly message than the decode_json's die 'malformed JSON string, neither array, object, number, string or atom, at character offset ...'
    #isJson() used recursive regex which broke older clients
    # is_valid_json give ugly errors
    #try{
    #    is_valid_json($content) or quit "CRITICAL", "invalid json returned by Cloudera Manager at '$url_prefix', did you try to connect to the SSL port without --tls?";
    #};
    try{
        $json = decode_json $content;
    };
    catch{
        quit "invalid json returned by Cloudera Manager at '$url_prefix', did you try to connect to the SSL port without --tls?";
    };
}
