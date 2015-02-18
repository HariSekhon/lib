#
#  Author: Hari Sekhon
#  Date: 2015-02-01 21:07:37 +0000 (Sun, 01 Feb 2015)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#

package HariSekhon::Solr;

$VERSION = "0.6.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use URI::Escape;
use Carp;
use Data::Dumper;
use Math::Round;
use Time::HiRes 'time';
use LWP::UserAgent;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $collection
                    $list_collections
                    $no_warn_replicas
                    $num_found
                    $query_qtime
                    $query_status
                    $query_time
                    $rows
                    $show_settings
                    $solr_admin
                    $start
                    $ua
                    $url
                    %solroptions
                    %solroptions_collection
                    Dumper
                    check_collections
                    curl_solr
                    isSolrCollection
                    list_solr_collections
                    msg_shard_status
                    query_solr
                    validate_base_and_znode
                    validate_solr_collection
                )
);
our @EXPORT_OK = ( @EXPORT );

set_port_default(8983);

env_creds("Solr");

our $ua = LWP::UserAgent->new;

our $solr_admin = "solr/admin";

our $url;

our $collection;
our $list_collections;
our $start = 0;
our $rows  = 3;

our $query_time;
our $query_qtime;
our $query_status;
our $num_found;

our %solroptions = (
    %hostoptions,
    #%useroptions,
    %ssloptions,
);

env_vars("SOLR_COLLECTION", \$collection);

our %solroptions_collection = (
    "C|collection=s"    => [ \$collection,          "Solr Collection name (\$SOLR_COLLECTION)" ],
    "list-collections"  => [ \$list_collections,    "List Collections for which there are loaded cores on given Solr instance (Solr 4 onwards)" ],
);

sub curl_solr_err_handler($){
    my $response = shift;
    my $content  = $response->content;
    my $json;
    my $additional_information = "";
    if($json = isJson($content)){
        if(defined($json->{"error"})){
            $additional_information = ". " . get_field2($json, "error.msg");
            $additional_information =~ s/\n/,/g;
        }
    }
    unless($response->code eq "200"){
        #<title>Error 500 {msg=SolrCore 'collection1_shard1_replica2' is not available due to init failure: Index locked for write for core collection1_shard1_replica2,trace=org.apache.solr.common.SolrException: SolrCore 'collection1_shard1_replica2' is not available due to init failure: Index locked for write for core collection1_shard1_replica2
        if(not $additional_information and $response->content =~ /<title>Error\s+\d+\s*\{?([^\n]+)/){
            $additional_information = $1;
            $additional_information =~ s/<\/title>.*//;
            # Solr's responses change weirdly, sometimes it returns the error in server message as well as body instead of a normal 500 Server Error. In these cases ignore the additional info since it's simply a duplication of information and adds volume without value
            if($response->message =~ /\Q$additional_information/){
                $additional_information = "";
            } else {
                $additional_information = ". $additional_information";
            }
        }
        my $response_msg = $response->message;
        $response_msg =~ s/^{//;
        $response_msg =~ s/\s+at org\.apache\.solr\..*// unless $verbose;
        quit "CRITICAL", $response->code . " " . $response_msg . $additional_information;
    }
    unless($content){
        quit "CRITICAL", "blank content returned by Solr";
    }
}


sub curl_solr($;$$){
    my $url     = shift() || code_error "no url argument passed to curl_solr()";
    my $type    = shift;
    my $content = shift;
    my $protocol = "http";
    $protocol .= "s" if($ssl);
    $url = "$protocol://$host:$port/$url";
    $url =~ /\?/ and $url .= "&" or $url .= "?";
    $url .= "omitHeader=off"; # we need the response header for query time, status and num found
    $url .= "&wt=json"; # xml is lame
    $url .= "&start=$start&rows=$rows";
    $url .= "&indent=true" if $verbose > 2;
    $url .= "&debugQuery=true" if $debug;
    my $start = time;
    my $json = curl_json $url, "Solr", undef, undef, \&curl_solr_err_handler, $type, $content;
    $query_time   = round((time - $start) * 1000); # secs => ms
    # just use NTP check, if doing this logic in every plugin then everything would alarm at the same time drowning out the real problem
    #$query_time < 0 and quit "UNKNOWN", "Solr query time < 0 ms - NTP problem?";
    $query_qtime  = get_field_int("responseHeader.QTime");
    $query_status = get_field("responseHeader.status");
    $num_found    = get_field_int("response.numFound", 1);
    if($query_status ne 0){
        #critical;
        #vlog2 "critical - query status from header was '$query_status' (expected 0)";
        $type = ( $type ? "POST" : "query" );
        quit "CRITICAL", "$type status from header was '$query_status' (expected 0)";
    }
    return $json;
}

sub query_solr($$){
    my $collection = shift() || code_error "no collection argument passed to query_solr()";
    my $query      = shift() || code_error "no query argument passed to query_solr()";
    # should be validated before this function call
    #$collection = validate_solr_collection($collection);
    # must be URL encoded before passing to Solr
    # XXX: is this uri escaped later?
    $query = uri_escape($query);
    curl_solr "solr/$collection/select?q=$query";
}

sub list_solr_collections(){
    if($list_collections){
        # not using this as it lists all collections, whereas it's more useful to only list collections for which there are cores on the given Solr server
        #$json = curl_solr "$solr_admin/collections?action=LIST&distrib=false";
        $json = curl_solr "$solr_admin/cores?distrib=false";
        print "Solr Collections loaded on this Solr instance:\n\n";
        #my @collections = get_field_array("collections");
        #foreach(sort @collections){
        #    print "$_\n";
        #}
        # more concise
        #print join("\n", get_field_array("collections")) . "\n";
        my %cores = get_field_hash("status");
        my %collections;
        foreach(sort keys %cores){
            my $collection = get_field2($cores{$_}, "name");
            $collection =~ s/_shard\d+_replica\d+$//;
            $collections{$collection} = 1;
        }
        foreach(sort keys %collections){
            print "$_\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub validate_base_and_znode($$$){
    my $base = shift;
    my $znode = shift;
    my $name = shift;
    $znode      = validate_filename($base, 0, "base znode") . "/$znode";
    $znode      =~ s/\/+/\//g;
    $znode      = validate_filename($znode, 0, "clusterstate znode");
}

my %inactive_shards;
#my %inactive_shard_states;
my %inactive_replicas;
#my %inactive_replica_states;
my %inactive_replicas_active_shards;
my %shards_without_active_replicas;
my %facts;
our $no_warn_replicas;
our $show_settings;

sub check_collection($){
    my $collection = shift;
    vlog2 "collection '$collection': ";
    my %shards = get_field_hash("$collection.shards");
    foreach my $shard (sort keys %shards){
        my $state = get_field("$collection.shards.$shard.state");
        vlog2 "\t\t\tshard '$shard' state '$state'";
        unless($state eq "active"){
            $inactive_shards{$collection}{$shard} = $state;
            #push(@{$inactive_shard_states{$collection}{$state}}, $shard);
        }
        my %replicas = get_field_hash("$collection.shards.$shard.replicas");
        my $found_active_replica = 0;
        foreach my $replica (sort keys %replicas){
            my $replica_name  = get_field("$collection.shards.$shard.replicas.$replica.node_name");
            my $replica_state = get_field("$collection.shards.$shard.replicas.$replica.state");
            $replica_name =~ s/_solr$//;
            vlog2 "\t\t\t\t\treplica '$replica_name' state '$replica_state'";
            if($replica_state eq "active"){
                $found_active_replica++;
            } else {
                $inactive_replicas{$collection}{$shard}{$replica_name} = $replica_state;
                #push(@{$inactive_replica_states{$collection}{$shard}{$replica_state}}, $replica_name);
                if($state eq "active"){
                    $inactive_replicas_active_shards{$collection}{$shard}{$replica_name} = $replica_state;
                }
            }
        }
        if(not $found_active_replica and not defined($inactive_shards{$collection}{$shard})){
            $shards_without_active_replicas{$collection}{$shard} = $state;
            delete $inactive_replicas_active_shards{$collection}{$shard};
            delete $inactive_replicas_active_shards{$collection} unless %{$inactive_replicas_active_shards{$collection}};
        }
    }
    if($inactive_shards{$collection} and not %{$inactive_shards{$collection}}){
        delete $inactive_shards{$collection};
    }
    $facts{$collection}{"maxShardsPerNode"}  = get_field_int("$collection.maxShardsPerNode");
    $facts{$collection}{"router"}            = get_field("$collection.router.name");
    $facts{$collection}{"replicationFactor"} = get_field_int("$collection.replicationFactor");
    $facts{$collection}{"autoAddReplicas"}   = get_field("$collection.autoAddReplicas", 1);
    vlog2;
}

sub check_collections(){
    my $found = 0;
    foreach(keys %$json){
        if($collection){
            if($collection eq $_){
                $found++;
                check_collection($_);
            }
        } else {
            check_collection($_);
        }
    }
    if($collection and not $found){
        quit "CRITICAL", "collection '$collection' not found, did you specify the correct name? See --list-collections for list of known collections";
    }
}

sub msg_replicas_down($){
    my $hashref = shift;
    foreach my $collection (sort keys %$hashref){
        $msg .= "collection '$collection' ";
        foreach my $shard (sort keys %{$$hashref{$collection}}){
            $msg .= "shard '$shard'";
            if($verbose){
                $msg .= " (" . join(",", sort keys %{$$hashref{$collection}{$shard}}) . ")";
            }
            $msg .= ", ";
        }
        $msg =~ s/, $//;
    }
    $msg =~ s/, $//;
}

sub msg_additional_replicas_down(){
    unless($no_warn_replicas){
        if(%inactive_replicas_active_shards){
            $msg .= ". Additional backup shard replicas down (shards still up): ";
            msg_replicas_down(\%inactive_replicas_active_shards);
        }
    }
}

sub msg_shards($){
    my $hashref = shift;
    foreach my $collection (sort keys %$hashref){
        my $num_inactive = scalar keys(%{$$hashref{$collection}});
        plural $num_inactive;
        #next unless $num_inactive > 0;
        $msg .= "collection '$collection' => $num_inactive shard$plural down";
        if($verbose){
            $msg .= " (";
            foreach my $shard (sort keys %{$$hashref{$collection}}){
                $msg .= "$shard,";
            }
            $msg =~ s/,$//;
        }
        $msg .= "), ";
    }
    $msg =~ s/, $//;
}

sub msg_shard_status(){
    # Initially used inverted index hashes to display uniquely all the different shard states, but then when extending to replica states this really became too much, simpler to just call shards and replicas 'down' if not active
    if(%inactive_shards){
        critical;
        $msg = "SolrCloud shards down: ";
        msg_shards(\%inactive_shards);
        if(%shards_without_active_replicas){
            $msg .= ". SolrCloud shards 'active' but with no active replicas: ";
            msg_shards(\%shards_without_active_replicas);
        }
        msg_additional_replicas_down();
    } elsif(%shards_without_active_replicas){
        critical;
        $msg = "SolrCloud shards 'active' but with no active replicas: ";
        msg_shards(\%shards_without_active_replicas);
        msg_additional_replicas_down();
    } elsif(%inactive_replicas and not $no_warn_replicas){
        warning;
        $msg = "SolrCloud shard replicas down: ";
        msg_replicas_down(\%inactive_replicas);
    } else {
        my $collections;
        if($collection){
            $plural = "";
            $collections = $collection;
        } else {
            plural keys %$json;
            $collections = join(", ", sort keys %$json);
        }
        $msg = "all SolrCloud shards " . ( $no_warn_replicas ? "" : "and replicas " ) . "active for collection$plural: $collections";
    }
    if($show_settings){
        $msg .= ". Replication Settings: ";
        foreach my $collection (sort keys %facts){
            $msg .= "collection '$collection'";
            # made autoAddReplicas optional since it wasn't found on my SolrCloud 4.7.2 cluster, must have been added after since it was on another cluster of mine
            foreach(qw/maxShardsPerNode replicationFactor router autoAddReplicas/){
                $msg .= " $_=" . $facts{$collection}{$_} if $facts{$collection}{$_};
            }
            $msg .= ", ";
        }
        $msg =~ s/, $//;
    }
}

sub isSolrCollection($){
    my $collection = shift;
    defined($collection) or return undef;
    $collection =~ /^([A-Za-z0-9]+)$/ or return undef;
    return $1;
}

sub validate_solr_collection($){
    my $collection = shift;
    defined($collection) or quit "CRITICAL", "collection not specified";
    $collection = isSolrCollection($collection) or quit "CRITICAL", "invalid Solr collection specified";
    vlog_options "collection", $collection;
    return $collection;
}

1;
