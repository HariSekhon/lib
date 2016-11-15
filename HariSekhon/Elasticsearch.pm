#
#  Author: Hari Sekhon
#  Date: 2014-06-07 11:48:30 +0100 (Sat, 07 Jun 2014)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::Elasticsearch;

$VERSION = "0.6.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Carp;
use Data::Dumper;
use LWP::Simple '$ua';

set_port_default(9200);

env_creds("ElasticSearch");

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $index
                    $list_indices
                    $list_nodes
                    $list_types
                    $node
                    $type
                    $ua
                    %elasticsearch_index
                    %elasticsearch_node
                    %elasticsearch_type
                    %es_status_map
                    check_elasticsearch_status
                    check_es_status
                    curl_elasticsearch
                    curl_elasticsearch_raw
                    delete_elasticsearch_index
                    ESIndexExists
                    isElasticSearchCluster
                    isESCluster
                    isElasticSearchIndex
                    isElasticSearchType
                    isESIndex
                    isESType
                    get_elasticsearch_indices
                    get_ES_indices
                    get_elasticsearch_nodes
                    get_ES_nodes
                    list_elasticsearch_indices
                    list_es_indices
                    list_elasticsearch_nodes
                    list_es_nodes
                    validate_elasticsearch_alias
                    validate_es_alias
                    validate_elasticsearch_cluster
                    validate_es_cluster
                    validate_elasticsearch_index
                    validate_es_index
                    validate_elasticsearch_type
                    validate_es_type
                )
);
our @EXPORT_OK = ( @EXPORT );

our $index;
our $node;
our $type;
our $list_indices;
our $list_nodes;
our $list_types;

our %es_status_map = (
    "green"  => "all primary and replica shards are active",
    "yellow" => "all primary shards are active but not all replica shards are online",
    "red"    => "not all primary shards are active! Some data will be missing from search queries!!",
);

env_var("ELASTICSEARCH_INDEX", \$index);
env_var("ELASTICSEARCH_NODE",  \$node);
env_var("ELASTICSEARCH_TYPE",  \$type);

our %elasticsearch_index = (
    "I|index=s"     =>  [ \$index,          "Elasticsearch index (\$ELASTICSEARCH_INDEX)" ],
    "list-indices"  =>  [ \$list_indices,   "List Elasticsearch indices" ],
);

our %elasticsearch_type = (
    "Y|type=s"      =>  [ \$type,           "Elasticsearch type (\$ELASTICSEARCH_TYPE)" ],
    "list-types"    =>  [ \$list_types,     "List Elasticsearch types in given index" ],
);

our %elasticsearch_node = (
    "N|node=s"      =>  [ \$node,           "Elasticsearch node (\$ELASTICSEARCH_NODE)" ],
    "list-nodes"    =>  [ \$list_nodes,     "List Elasticsearch nodes" ],
);

splice @usage_order, 7, 0, qw/node index type shards replicas keys key value list-nodes list-indices list-types/;

sub elasticsearch_err_handler($){
    my $response = shift;
    unless($response->code eq "200"){
        my $info = "";
        my $json;
        if($json = isJson($response->content)){
            foreach(qw/status error message reason/){
                if(defined($json->{$_})){
                    $_ eq "status" and $json->{$_} eq $response->code and next;
                    my $tmp = $json->{$_};
                    $info .= ". " . ucfirst($_) . ": ";
                    if(isHash($tmp)){
                        my $reason            = get_field2($tmp, "reason", 1);
                        my $type              = get_field2($tmp, "type", 1);
                        my $root_cause_reason = get_field2($tmp, "root_cause.reason", 1);
                        my $root_cause_type   = get_field2($tmp, "root_cause.type", 1);
                        if($reason){
                            if($type){
                                $info .= "$type: ";
                            }
                            $info .= "$reason";
                            if($root_cause_type and $root_cause_type ne $type){
                                $info .= ": $root_cause_type";
                            }
                            if($root_cause_reason and $root_cause_reason ne $reason){
                                $info .= ": $root_cause_reason";
                            }
                        } else {
                            $info .= Dumper($tmp);
                        }
                    } else {
                        $info .= $json->{$tmp};
                    }
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
    # Elasticsearch 5.0 no longer accepts the timeout parameter everywhere
    if($url ne '?' and
       $url !~ /_cat|_settings|_stats|_cluster/){
        $url .= sprintf("timeout=%ds&", minimum_value($timeout - 1, 1));
    }
    $url .= "pretty=true" if $verbose >= 3 or $debug;
    $url =~ s/\&$//;
    #my $content = curl "http://$host:$port/$url", "Elasticsearch", undef, undef, undef, $type, $body;
    my $content = curl "http://$host:$port/$url", "Elasticsearch", undef, undef, \&elasticsearch_err_handler, $type, $body;
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

sub delete_elasticsearch_index($){
    my $index = shift;
    my $content = curl_elasticsearch_raw "/$index", "DELETE";
    #tprint $content;
    return $content;
}

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
    # must be lowercase, can't start with an underscore
    $index =~ /^([a-z0-9\.][a-z0-9\._-]+)$/ or return undef;
    $index = $1;
    return $index;
}
*isESIndex = \&isElasticSearchIndex;

# check but I think Elasticsearch types can have uppercase
#*isElasticSearchType = \&isElasticSearchIndex;
sub isElasticSearchType($){
    my $type = shift;
    defined($type) or return undef;
    # must be lowercase, can't start with an underscore
    $type =~ /^([A-Za-z0-9\.][A-Za-z0-9\._-]+)$/ or return undef;
    $type = $1;
    return $type;
}
*isESType = \&isElasticSearchType;

sub ESIndexExists($) {
    my $index = shift;
    isESIndex($index) or code_error "passed invalid index name to doesESIndexExist";
    # This rest API call doesn't seem to be available in 1.2.1, but works in 1.4.1
    # TODO: test this on newer elasticsearch
    #my $content = curl_elasticsearch_raw("/$index");
    #return $content =~ /^\A$index\Z$/m;
    return grep { $index eq $_ } get_ES_indices();
}

sub get_elasticsearch_indices {
    my $content = curl_elasticsearch_raw("/_cat/indices?h=index");
    return map { strip($_) } sort split(/\n/, $content);
}
*get_ES_indices = \&get_elasticsearch_indices;

sub list_elasticsearch_indices {
    if($list_indices){
        my @indices = get_elasticsearch_indices();
        print "Elasticsearch Indices:\n\n";
        print "<none>\n" unless @indices;
        foreach(@indices){
            #my @parts = split(/\s+/, $_);
            #print "$parts[1]\n";
            print "$_\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub get_elasticsearch_nodes {
    # could use /_nodes instead but it's more cleanup of ip etc
    #my $content = curl_elasticsearch_raw("/_cat/nodes?h=host,ip,name");
    curl_elasticsearch("/_nodes");
    my @node_array;
    my %nodes = get_field_hash("nodes");
    foreach my $node_random_id(sort keys %nodes){
        my @node = (
            get_field("nodes.$node_random_id.host"),
            get_field("nodes.$node_random_id.ip"),
            get_field("nodes.$node_random_id.name")
        );
        push(@node_array, [@node]);
    }
#    foreach my $line (split(/\n/, $content)){
#        my @node_array = map { strip($_) } split(/\s+/, $line, 3);
#        if(scalar @node_array == 3){
#            push(@node_array, @node_array);
#        } else {
#            quit "UNKNOWN", "invalid node array length after parsing node list";
#        }
#    }
    return sort @node_array;
}
*get_ES_nodes = \&get_elasticsearch_nodes;

sub list_elasticsearch_nodes {
    if($list_nodes){
        my @nodes = get_elasticsearch_nodes();
        print "Elasticsearch Nodes:\n\n";
        if(@nodes){
            printf "%-50s %-20s %s\n\n", "hostname", "ip", "name";
            foreach my $arr_ref (@nodes){
                printf "%-50s %-20s %s\n", $$arr_ref[0], $$arr_ref[1], $$arr_ref[2];
            }
        } else {
            print "<none>\n"
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub validate_elasticsearch_alias($){
    my $alias = shift;
    defined($alias) or usage "Elasticsearch alias not defined";
    $alias = isESType($alias) or usage "invalid ElasticSearch alias name given, must be lowercase alphanumeric";
    vlog_option "alias", $alias;
    return $alias;
}
*validate_es_alias = \&validate_elasticsearch_alias;

sub validate_elasticsearch_cluster($){
    my $cluster = shift;
    defined($cluster) or usage "Elasticsearch cluster not defined";
    $cluster = isESCluster($cluster) or usage "invalid ElasticSearch cluster name given, must be lowercase alphanumeric";
    vlog_option "cluster", $cluster;
    return $cluster;
}
*validate_es_cluster = \&validate_elasticsearch_cluster;

sub validate_elasticsearch_index($){
    my $index = shift;
    defined($index) or usage "Elasticsearch index not defined";
    $index = isESIndex($index) or usage "invalid ElasticSearch index name given, must be lowercase alphanumeric";
    vlog_option "index", $index;
    return $index;
}
*validate_es_index = \&validate_elasticsearch_index;

sub validate_elasticsearch_type($){
    my $type = shift;
    defined($type) or usage "Elasticsearch type not defined";
    $type = isESType($type) or usage "invalid ElasticSearch type name given, must be lowercase alphanumeric";
    vlog_option "type", $type;
    return $type;
}
*validate_es_type = \&validate_elasticsearch_type;

1;
