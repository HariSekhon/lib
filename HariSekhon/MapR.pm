#
#  Author: Hari Sekhon
#  Date: 2014-09-30 21:54:01 +0100 (Tue, 30 Sep 2014)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#  

package HariSekhon::MapR;

$VERSION = "0.4.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Data::Dumper;
use LWP::UserAgent;

our $ua = LWP::UserAgent->new;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $cluster
                    $list_clusters
                    $list_nodes
                    $list_services
                    $node
                    $protocol
                    $service
                    $ssl
                    $ssl_ca_path
                    $ssl_noverify
                    $ua
                    %mapr_option_cluster
                    %mapr_option_node
                    %mapr_option_service
                    %mapr_options
                    curl_mapr
                    list_clusters
                    list_nodes
                    list_services
                    validate_cluster
                    validate_mapr_options
                    validate_service
                )
);
our @EXPORT_OK = ( @EXPORT );

set_port_default(8443);

env_creds("MAPR", "MapR Control System");

our $cluster;
our $node;
our $service;
our $list_clusters;
our $list_nodes;
our $list_services;

env_vars(["MAPR_CLUSTER", "CLUSTER"], \$cluster);

my $no_ssl;

our %mapr_options = (
    %hostoptions,
    %useroptions,
    %ssloptions,
    "no-ssl"   =>  [ \$no_ssl,  "Don't use SSL, newer versions of MCS seem to only use SSL, use this only on older versions of MCS if you don't have SSL (you may need to also change the port to 8080 instead of 8443)" ],
);
delete $mapr_options{"S|ssl"};

our %mapr_option_cluster = (
    "C|cluster=s"   => [ \$cluster,       "Cluster Name as shown in MapR Control System (eg. \"my.cluster.com\", see --list-clusters, \$MAPR_CLUSTER, \$CLUSTER)" ],
    "list-clusters" => [ \$list_clusters, "Lists clusters managed by MapR Control System" ],
);

our %mapr_option_node = (
    "N|node=s"      => [ \$node,        "Node to check (see --list-nodes)" ],
    "list-nodes"    => [ \$list_nodes,  "Lists nodes managed by MapR Control System" ],
);

our %mapr_option_service = (
    "s|service=s"   => [ \$service,         "Check the specified service (see --list-services)" ],
    "list-services" => [ \$list_services,   "List services" ],
);

splice @usage_order, 6, 0, qw/cluster node service list-clusters list-nodes list-services ssl ssl-CA-path ssl-noverify no-ssl/;


sub validate_mapr_options(){
    $host       = validate_host($host);
    $port       = validate_port($port);
    $user       = validate_user($user);
    $password   = validate_password($password);
    validate_ssl();
}

our $protocol = "https";

sub curl_mapr($$$;$){
    ($host and $port) or code_error "host and port not defined before calling curl_mapr()";
    my $url      = shift() || code_error "no url suffix passed to curl_mapr()";
    my $user     = shift;
    my $password = shift;
    my $err_sub  = shift() || \&curl_mapr_err_handler;
    $url =~ s/^\/*//;
    $url or code_error "invalid url passed to curl_mapr()";
    $protocol = "http" if $no_ssl;
    my $url_prefix = "$protocol://$host:$port";
    $url = "$url_prefix/rest/$url";
    isUrl($url) or code_error "invalid URL '$url' supplied to curl_mapr()";
    my $content = curl $url, "MapR Control System", $user, $password, $err_sub;
    vlog2("parsing output from MapR Control System\n");
    $json = isJson($content) or quit "CRITICAL", "invalid json returned by MapR Control System, perhaps you tried --no-ssl and SSL was used on that port?";
    vlog3 Dumper($json);
    return $json;
}


sub curl_mapr_err_handler($){
    my $response = shift;
    my $content  = $response->content;
    my $additional_information = "";
    if(!$response->is_success){
        my $err = "failed to query MapR Control System: " . $response->code . " " . $response->message;
        if($content =~ /"message"\s*:\s*"(.+)"/){
            $err .= ". Message returned by MapR Control System: $1";
        }
        if($response->code eq 401 and $response->message eq "Unauthorized"){
            $err .= ". Invalid --user/--password?";
        }
        if($response->code eq 404 and $response->request->{"_uri"} =~ /blacklist\/listusers/){
            $err .= ". Blacklist users API endpoint is not implemented as of MCS 3.1. This has been confirmed with MapR, trying updating to a newer version of MCS";
        }
        if($response->message =~ /Can't verify SSL peers without knowing which Certificate Authorities to trust/ or
           $response->message =~ /certificate verify failed/){
            $err .= ". Do you need to use --ssl-CA-path or --ssl-noverify?";
        }
        quit "CRITICAL", $err;
    } elsif($json = isJson($response->content)){
        my $status = get_field2($json, "status");
        unless($status eq "OK"){
            my $err = "";
            foreach(get_field2_array($json, "errors")){
                $err .= ". " . get_field2($_, "desc");
                if($err =~ /Obtaining rlimit for resource disk failed with error - Unknown cluster parameter provided/){
                    $err .= ". You have supplied an invalid cluster name, see --list-clusters for the right cluster name";
                }
            }
            quit "CRITICAL", "MapR Control System returned status='$status'$err";
        }
    }
    unless($content){
        quit "CRITICAL", "blank content returned by MapR Control System";
    }
}


sub list_clusters(){
    if($list_clusters){
        $json = curl_mapr("/dashboard/info", $user, $password);
        my @data = get_field_array("data");
        print "MapR Control System Clusters:\n\n";
        foreach(@data){
            print get_field2($_, "cluster.name") . "\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}


sub list_nodes(){
    if($list_nodes){
        $json = curl_mapr("/node/list?columns=hostname", $user, $password);
        my @data = get_field_array("data");
        print "MapR Control System nodes:\n\n";
        foreach(@data){
            print get_field2($_, "hostname") . "\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub list_services(){
    if($list_services){
        if($node){
            $json = curl_mapr("/service/list?node=$node", $user, $password);
        } else {
            my $url = "/dashboard/info";
            $url .= "?cluster=$cluster" if $cluster;
            $json = curl_mapr($url, $user, $password);
        }
        print "MapR Services";
        print " on node '$node'" if $node;
        print " on cluster '$cluster'" if $cluster;
        print ":\n\n";
        my %services;
        if($node){
            foreach(get_field_array("data")){
                $services{get_field2($_, "displayname")} = 1;
            }
        } else {
            foreach(get_field_array("data")){
                my %services2 = get_field2_hash($_, "services");
                foreach(keys %services2){
                    $services{$_} = 1;
                }
            }
        }
        foreach(sort keys %services){
            print "$_\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}


sub validate_cluster($){
    my $cluster = shift;
    defined($cluster) or usage "cluster not specified";
    $cluster =~ /^([\w\.]+)$/ or usage "invalid cluster name given, must be alphanumeric with dots and underscores permitted";
    $cluster = $1;
    vlog_options "cluster", $cluster;
    return $cluster;
}


sub validate_service($){
    my $service = shift;
    defined($service) or usage "service not specified";
    $service =~ /^(\w[\w\s-]+\w)$/ or usage "invalid service name, must be alphanumeric, may contain spaces/dashes";
    $service = $1;
    vlog_options "service", $service;
    return $service;
}


1;
