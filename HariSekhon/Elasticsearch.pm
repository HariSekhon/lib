#
#  Author: Hari Sekhon
#  Date: 2014-06-07 11:48:30 +0100 (Sat, 07 Jun 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::Elasticsearch;

$VERSION = "0.3.1";

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
                    $index
                    $list_indices
                    $list_types
                    $types
                    $ua
                    %elasticsearch_index
                    %elasticsearch_type
                    %es_status_map
                    check_elasticsearch_status
                    check_es_status
                    curl_elasticsearch
                    curl_elasticsearch_raw
                    isElasticsearchCluster
                    isElasticsearchIndex
                    list_elasticsearch_indices
                    validate_elasticsearch_cluster
                    validate_elasticsearch_index
                )
);
our @EXPORT_OK = ( @EXPORT );

our $index;
our $list_indices;
our $type;
our $list_types;

our %es_status_map = (
    "green"  => "all primary and replica shards are active",
    "yellow" => "all primary shards are active but not all replica shards are online",
    "red"    => "not all primary shards are active! Some data will be missing from search queries!!",
);

env_var("ELASTICSEARCH_INDEX", \$index);
env_var("ELASTICSEARCH_TYPE",  \$type);

our %elasticsearch_index = (
    "I|index=s"     =>  [ \$index,          "Elasticsearch index (\$ELASTICSEARCH_INDEX)" ],
    "list-indices"  =>  [ \$list_indices,   "List Elasticsearch indices" ],
);

our %elasticsearch_type = (
    "Y|type=s"      =>  [ \$type,           "Elasticsearch type (\$ELASTICSEARCH_TYPE)" ],
    "list-types"    =>  [ \$list_types,     "List Elasticsearch types in given index" ],
);

splice @usage_order, 6, 0, qw/index type shards replicas keys key value list-indices list-types/;

sub elasticsearch_err_handler($){
    my $response = shift;
    unless($response->code eq "200"){
        my $info = "";
        my $json;
        if($json = isJson($response->content)){
            foreach(qw/status error message reason/){
                if(defined($json->{$_})){
                    $_ eq "status" and $json->{$_} eq $response->code and next;
                    $info .= ". " . ucfirst($_) . ": " . $json->{$_};
                }
            }
        }
        #$info =~ s/\. $//;
        #if($info){
        #    quit "CRITICAL", $info;
        #} else {
        #    quit "CRITICAL", $response->code . " " . $response->message;
        #}
        quit("CRITICAL", $response->code . " " . $response->message . $info);
    }
}

sub curl_elasticsearch_raw($;$$){
    my $url  = shift;
    my $type = shift() || "GET";
    my $body = shift;
    $url =~ s/^\///;
    if($url =~ /\?/){
        $url .= "&";
    } else {
        $url .= "?";
    }
    $url .= "timeout=" . minimum_value($timeout - 1, 1);
    $url .= "&pretty=true" if $verbose >= 3 or $debug;
    #my $content = curl "http://$host:$port/$url", "Elasticsearch", undef, undef, \&elasticsearch_err_handler, $type;
    my $content = curl "http://$host:$port/$url", "Elasticsearch", undef, undef, undef, $type;
    return $content;
}

sub curl_elasticsearch($;$$){
    my $content = curl_elasticsearch_raw $_[0], $_[1], $_[2];
    # _cat doesn't return json
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
*check_es_status = \&check_elasticsearch_status;

sub isElasticSearchCluster($){
    my $cluster = shift;
    return isAlNum($cluster);
    #defined($cluster) or return undef;
    ## must be lowercase
    #$cluster =~ /^([a-z0-9]+)$/ or return undef;
    #$cluster = $1;
    #return $cluster;
}
*isESCluster = \&isElasticSearchCluster;

sub isElasticSearchIndex($){
    my $index = shift;
    defined($index) or return undef;
    # must be lowercase, can't start with an underscore but can start with numbers
    $index =~ /^([a-z0-9][a-z0-9\._-]+)$/ or return undef;
    $index = $1;
    return $index;
}
*isESIndex = \&isElasticSearchIndex;

sub list_elasticsearch_indices {
    if($list_indices){
        my $content = curl "http://$host:$port/_cat/indices?h=index", "Elasticsearch", undef, undef, sub {}, "GET";
        print "Elasticsearch Indices:\n\n";
        print "<none>\n" unless $content;
        foreach(split(/\n/, $content)){
            #my @parts = split(/\s+/, $_);
            #print "$parts[1]\n";
            print "$_\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub validate_elasticsearch_cluster($){
    my $cluster = shift;
    defined($cluster) or usage "Elasticsearch cluster not defined";
    $cluster = isESCluster($cluster) or usage "invalid ElasticSearch cluster name given, must be lowercase alphanumeric";
    vlog_options "cluster", $cluster;
    return $cluster;
}
*validate_es_cluster = \&validate_elasticsearch_cluster;

sub validate_elasticsearch_index($){
    my $index = shift;
    defined($index) or usage "Elasticsearch index not defined";
    $index = isESIndex($index) or usage "invalid ElasticSearch index name given, must be lowercase alphanumeric";
    vlog_options "index", $index;
    return $index;
}
*validate_es_index = \&validate_elasticsearch_index;

1;
