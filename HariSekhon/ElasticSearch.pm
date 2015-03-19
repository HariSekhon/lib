#
#  Author: Hari Sekhon
#  Date: 2014-06-07 11:48:30 +0100 (Sat, 07 Jun 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::ElasticSearch;

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;
use LWP::Simple '$ua';

set_port_default(9200);

env_creds("ElasticSearch");

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $ua
                    %es_status_map
                    check_elasticsearch_status
                    check_es_status
                    curl_elasticsearch
                    isElasticsearchCluster
                    isElasticsearchIndex
                    validate_elasticsearch_cluster
                    validate_elasticsearch_index
                )
);
our @EXPORT_OK = ( @EXPORT );

our %es_status_map = (
    "green"  => "all primary and replica shards are active",
    "yellow" => "all primary shards are active but not all replica shards are online",
    "red"    => "not all primary shards are active! Some data will be missing from search queries!!",
);

sub curl_elasticsearch($){
    my $url = shift;
    $url =~ s/^\///;
    if($url =~ /\?/){
        $url .= "&";
    } else {
        $url .= "?";
    }
    $url .= "timeout=" . minimum_value($timeout - 1, 1);
    $url .= "&pretty=true" if $verbose >= 3 or $debug;
    my $content = curl "http://$host:$port/$url";
    $json = isJson($content) or quit "CRITICAL", "non-json returned by ElasticSearch!";
    # probably not a good idea - lacks flexibility, may still be able to get partial information from returned json
    #if(get_field("timed_out")){
    #    quit "CRITICAL", "timed_out: true";
    #}
    return $json;
}

sub check_elasticsearch_status($;$){
    my $es_status = shift;
    my $msg .= ", status: '$es_status'";
    if($es_status eq "green"){
        # ok
    } elsif($es_status eq "yellow"){
        warning;
    } else {
        critical;
    }
    if($verbose){
        if(grep { $_ eq $es_status } keys %es_status_map){
            $msg .= " (" . $es_status_map{$es_status} . ")";
        }
    }
    return $msg;
}
#*check_es_status = \&check_elasticsearch_status;

sub isElasticSearchCluster($){
    my $cluster = shift;
    return isAlNum($cluster);
    #defined($cluster) or return undef;
    ## must be lowercase
    #$cluster =~ /^([a-z0-9]+)$/ or return undef;
    #$cluster = $1;
    #return $cluster;
}
#*isESCluster = \&isElasticSearchCluster;

sub isElasticSearchIndex($){
    my $index = shift;
    defined($index) or return undef;
    # must be lowercase
    $index =~ /^([a-z0-9]+)$/ or return undef;
    $index = $1;
    return $index;
}
#*isESIndex = \&isElasticSearchIndex;

sub validate_elasticsearch_cluster($){
    my $cluster = shift;
    $cluster = isESCluster($cluster) or usage "invalid ElasticSearch cluster name given, must be lowercase alphanumeric";
    vlog_options "cluster", $cluster;
    return $cluster;
}
#*validate_es_cluster = \&validate_elasticsearch_cluster;

sub validate_elasticsearch_index($){
    my $index = shift;
    $index = isESIndex($index) or usage "invalid ElasticSearch index name given, must be lowercase alphanumeric";
    vlog_options "index", $index;
    return $index;
}
#*validate_es_index = \&validate_elasticsearch_index;
