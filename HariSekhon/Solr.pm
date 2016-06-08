#
#  Author: Hari Sekhon
#  Date: 2015-02-01 21:07:37 +0000 (Sun, 01 Feb 2015)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying Hari Sekhon LICENSE file
#

package HariSekhon::Solr;

$VERSION = "0.8.19";

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
                    $collections
                    $collection_alias
                    $core
                    $http_context
                    $list_collection_aliases
                    $list_collections
                    $list_cores
                    $list_nodes
                    $list_shards
                    $list_replicas
                    $no_warn_replicas
                    $num_found
                    $query_qtime
                    $query_status
                    $query_time
                    $replica
                    $rows
                    $shard
                    $show_settings
                    $solr_admin
                    $solr_node
                    $start
                    $ua
                    $url
                    %solroptions
                    %solroptions_collection
                    %solroptions_collections
                    %solroptions_collection_aliases
                    %solroptions_context
                    %solroptions_core
                    %solroptions_node
                    %solroptions_list_cores
                    %solroptions_shard
                    %solroptions_replica
                    check_collections
                    curl_solr
                    Dumper
                    get_solr_collections
                    get_solr_cores
                    get_solr_nodes
                    get_solr_replicas
                    get_solr_shards
                    find_solr_core
                    isSolrCollection
                    isSolrCore
                    isSolrShard
                    list_solr_collections
                    list_solr_collection_aliases
                    list_solr_cores
                    list_solr_nodes
                    list_solr_replicas
                    list_solr_shards
                    msg_shard_status
                    query_solr
                    validate_solr_collection
                    validate_solr_collections
                    validate_solr_collection_alias
                    validate_solr_context
                    validate_solr_core
                    validate_solr_shard
                )
);
our @EXPORT_OK = ( @EXPORT );

set_port_default(8983);

env_creds("Solr");

our $ua = LWP::UserAgent->new;

my  $default_http_context = "/solr";
our $http_context = $default_http_context;

my  $default_solr_admin = "$http_context/admin";
our $solr_admin = $default_solr_admin;

our $url;

our $collection;
our $collections;
our $collection_alias;
our $core;
our $shard;
our $replica,
our $solr_node;
our $list_collection_aliases = 0;
our $list_collections = 0;
our $list_shards      = 0;
our $list_replicas    = 0;
our $list_cores       = 0;
our $list_nodes       = 0;
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
env_vars("SOLR_CORE",       \$core);
env_vars("SOLR_COLLECTION_ALIAS", \$collection_alias);
env_vars("SOLR_COLLECTIONS",      \$collections);

our %solroptions_collection = (
    "C|collection=s"    => [ \$collection,          "Solr Collection name (\$SOLR_COLLECTION)" ],
    "list-collections"  => [ \$list_collections,    "List Collections (Solr 4 onwards)" ],
);

our %solroptions_collection_aliases = (
    "A|collection-alias=s"    => [ \$collection_alias,        "Collection Alias (\$SOLR_COLLECTION_ALIAS)" ],
    "list-collection-aliases" => [ \$list_collection_aliases, "List Collection Aliases (Solr 4.9 onwards)" ],
);
our %solroptions_collections = (
    "E|collections=s"   => [ \$collections,         "Collections, comma separated (\$SOLR_COLLECTIONS)" ],
);

our %solroptions_shard = (
    "s|shard=s"         => [ \$shard,               "Shard name, requires --collection" ],
    "list-shards"       => [ \$list_shards,         "List shards, requires --collection" ],
);

our %solroptions_replica = (
    "r|replica=s"       => [ \$replica,             "Replica name, requires --collection and --shard" ],
    "list-replicas"     => [ \$list_replicas,       "List replicas, requires --collection" ],
);

our %solroptions_list_cores = (
    "list-cores"        => [ \$list_cores,          "List Cores for which there are loaded cores on given Solr instance" ],
);

our %solroptions_core = (
    "C|core=s"          => [ \$core,                "Solr Core name (\$SOLR_CORE)" ],
    %solroptions_list_cores,
);

our %solroptions_node = (
    "N|node=s"          => [ \$solr_node,           "Solr node name" ],
    "list-nodes"        => [ \$list_nodes,          "List Solr nodes" ],
);

our %solroptions_context = (
    "http-context=s"    => [ \$http_context,        "Solr http context handler prefix for REST API url (defaults to $default_http_context)" ],
);

sub curl_solr_err_handler($){
    my $response = shift;
    my $content  = $response->content;
    my $json;
    my $additional_information = "";
    if($json = isJson($content)){
        if(defined($json->{"error"}->{"msg"})){
            $additional_information .= ". Error msg: " . $json->{"error"}->{"msg"};
            $additional_information =~ s/\n/,/g;
        }
        if(defined($json->{"error"}->{"trace"})){
            $additional_information .= ". Error trace: " . $json->{"error"}->{"trace"};
            $additional_information =~ s/\n/,/g;
        }
        # collection creation returns HTTP 200 and status 0 with only this error message :-/
        if(defined($json->{"failure"})){
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 0;
            $additional_information .= ". Failure " . Dumper($json->{"failure"});
        }
    }
    # must check for additional error or failure information having been collected since Solr collection creation returns HTTP 200 with header status 0 and only "failure" hash key message to detect the problem :-/
    if($response->code ne "200" or $additional_information){
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
    $url = "$protocol://$host:$port$url";
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

sub query_solr($$;$){
    my $collection = shift() || code_error "no collection argument passed to query_solr()";
    my $query      = shift() || code_error "no query argument passed to query_solr()";
    my $filter     = shift;
    # should be validated before this function call
    #$collection = validate_solr_collection($collection);
    # must be URL encoded before passing to Solr
    # XXX: is this uri escaped later?
    $query  = uri_escape($query);
    $filter = uri_escape($filter);
    curl_solr "$http_context/$collection/select?q=$query" . ( $filter ? "&fq=$filter" : "");
}

sub get_solr_collection_aliases(){
    $json = curl_solr "$solr_admin/collections?action=CLUSTERSTATUS";
    return get_field("cluster.aliases", 1);
}

sub list_solr_collection_aliases(){
    if($list_collection_aliases){
        my $collection_aliases = get_solr_collection_aliases();
        print "Solr Collection Aliases:\n\n";
        if($collection_aliases){
            foreach(sort keys %{$collection_aliases}){
                print "$_ => $$collection_aliases{$_}\n";
            }
        } else {
            print "<none>\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
}

sub get_solr_collections(){
    $json = curl_solr "$solr_admin/collections?action=LIST";
    return get_field_array("collections");
}

sub list_solr_collections(){
    if($list_collections){
        my @collections = get_solr_collections();
        print "Solr Collections:\n\n";
        print join("\n", @collections) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
}

sub get_solr_cores(){
    # not using this as it lists all cores, whereas it's more useful to only list cores for which there are cores on the given Solr server
    #$json = curl_solr "$solr_admin/cores?action=LIST&distrib=false";
    $json = curl_solr "$solr_admin/cores?distrib=false";
    my %results = get_field_hash("status");
    my %cores;
    foreach(sort keys %results){
        my $core = get_field2($results{$_}, "name");
        $cores{$core} = 1;
    }
    return sort keys %cores;
}

sub list_solr_cores(){
    if($list_cores){
        my @cores = get_solr_cores();
        print "Solr cores loaded on Solr instance '$host:$port':\n\n";
        print join("\n", @cores) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
}

sub find_solr_core($){
    my $core = shift;
    my @cores = get_solr_cores;
    if(grep { $_ eq $core } @cores){
        return $core;
    } else {
        foreach(@cores){
            if($_ =~ /^${core}_shard\d+_replica\d+$/){
                return $_;
            }
        }
    }
    return undef;
}

sub get_solr_nodes(){
    $json = curl_solr "$solr_admin/collections?action=CLUSTERSTATUS";
    return get_field_array("cluster.live_nodes");
}

sub list_solr_nodes(){
    if($list_nodes){
        my @nodes = get_solr_nodes();
        print "Solr nodes:\n\n";
        print join("\n", @nodes) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
}

sub get_solr_shards($){
    my $collection = shift;
    isSolrCollection($collection) or code_error "invalid collection passed to get_solr_shards()";
    $json = curl_solr "$solr_admin/collections?action=CLUSTERSTATUS";
    my %collections = get_field_hash("cluster.collections");
    unless(grep { $_ eq $collection } keys %collections){
        quit "UNKNOWN", "couldn't find collection '$collection' for which to get shards";
    }
    my %shards = get_field2_hash($collections{$collection}, "shards");
    return sort keys %shards;
}

sub list_solr_shards($){
    if($list_shards){
        my $collection = shift;
        isSolrCollection($collection) or code_error "invalid collection passed to list_solr_shards()";
        my @shards = get_solr_shards($collection);
        print "Solr shards in Solr collection '$collection':\n\n";
        print join("\n", @shards) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
}

sub get_solr_replicas($){
    my $collection = shift;
    isSolrCollection($collection) or code_error "invalid collection passed to get_solr_replicas()";
    $json = curl_solr "$solr_admin/collections?action=CLUSTERSTATUS";
    my %collections = get_field_hash("cluster.collections");
    unless(grep { $_ eq $collection } keys %collections){
        quit "UNKNOWN", "couldn't find collection '$collection' for which to get replicas";
    }
    my %shards = get_field2_hash($collections{$collection}, "shards");
    return %shards;
}

sub print_shard_replicas($$){
    my $shard_ref = shift;
    my $shard     = shift;
    isHash($shard_ref) or code_error "non-hashref passed to print_shard_replicas";
    my %shards = %{$shard_ref};
    my %replicas = get_field2_hash($shards{$shard}, "replicas");
    my $core;
    my $node;
    my $state;
    foreach my $replica (sort keys %replicas){
        $core  = get_field2($replicas{$replica}, "core");
        $node  = get_field2($replicas{$replica}, "node_name");
        $state = get_field2($replicas{$replica}, "state");
        printf "shard %-10s\treplica %-20s\tcore %-20s\tnode: %-20s\tstate %s\n", "'$shard'", "'$replica'", "'$core'", "'$node'", "'$state'";
    }
}

sub list_solr_replicas($;$){
    if($list_replicas){
        my $collection = shift;
        my $shard      = shift;
        isSolrCollection($collection) or code_error "invalid collection passed to list_solr_replicas()";
        my %shards = get_solr_replicas($collection);
        if($shard){
            defined($shards{$shard}) or quit "UNKNOWN", "no replicas found for shard '$shard'. Did you specify the correct shard name? See --list-shards\n";
            print "Solr replicas in Solr collection '$collection' shard '$shard':\n\n";
            my %replicas = get_field2_hash($shards{$shard}, "replicas");
            print_shard_replicas(\%shards, $shard);
        } else {
            print "Solr replicas in Solr collection '$collection':\n\n";
            foreach my $shard (sort keys %shards){
                print_shard_replicas(\%shards, $shard);
            }
        }
        exit $ERRORS{"UNKNOWN"};
    }
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
    my $collection2 = $collection;
    $collection2 =~ s/\./\\./g;
    my %shards = get_field_hash("$collection2.shards");
    foreach my $shard (sort keys %shards){
        my $shard2 = $shard;
        $shard2 =~ s/\./\\./g;
        my $state = get_field("$collection2.shards.$shard2.state");
        vlog2 "\t\t\tshard '$shard' state '$state'";
        unless($state eq "active"){
            $inactive_shards{$collection}{$shard} = $state;
            #push(@{$inactive_shard_states{$collection}{$state}}, $shard);
        }
        my %replicas = get_field_hash("$collection2.shards.$shard2.replicas");
        my $found_active_replica = 0;
        foreach my $replica (sort keys %replicas){
            $replica =~ s/\./\\./g;
            my $replica_name  = get_field("$collection2.shards.$shard2.replicas.$replica.node_name");
            my $replica_state = get_field("$collection2.shards.$shard2.replicas.$replica.state");
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
    $facts{$collection}{"maxShardsPerNode"}  = get_field_int("$collection2.maxShardsPerNode");
    $facts{$collection}{"router"}            = get_field("$collection2.router.name");
    $facts{$collection}{"replicationFactor"} = get_field_int("$collection2.replicationFactor");
    $facts{$collection}{"autoAddReplicas"}   = get_field("$collection2.autoAddReplicas", 1);
    vlog2;
}

sub check_collections(){
    my $found = 0;
    unless(%$json){
        quit "CRITICAL", "no collections found";
    }
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
            $msg .= "), ";
        }
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
    $collection =~ /^([\w\.-]+)$/ or return undef;
    return $1;
}
*isSolrCore  = \&isSolrCollection;
*isSolrShard = \&isSolrCollection;

sub validate_solr_collection($){
    my $collection = shift;
    defined($collection) or quit "CRITICAL", "Solr collection not specified";
    $collection = isSolrCollection($collection) or quit "CRITICAL", "invalid Solr collection specified";
    vlog_option "collection", $collection;
    return $collection;
}

sub validate_solr_collections($){
    my $collections = shift;
    defined($collections) or quit "CRITICAL", "Solr collections not specified";
    my @collections;
    $collections = trim($collections);
    $collections or quit "CRITICAL", "Solr collections are blank!";
    foreach my $collection (split(/\s*,\s*/, $collections)){
        $collection = isSolrCollection($collection) or quit "CRITICAL", "invalid Solr collection '$collection' specified";
        push(@collections, $collection);
    }
    $collections = join(",", @collections);
    vlog_option "collections", $collections;
    return $collections;
}

sub validate_solr_collection_alias($){
    my $collection_alias = shift;
    defined($collection_alias) or quit "CRITICAL", "Solr collection alias not specified";
    $collection_alias = isSolrCollection($collection_alias) or quit "CRITICAL", "invalid Solr collection alias specified";
    vlog_option "collection alias", $collection_alias;
    return $collection_alias;
}

sub validate_solr_core($){
    my $core = shift;
    defined($core) or quit "CRITICAL", "Solr core not specified";
    $core = isSolrCore($core) or quit "CRITICAL", "invalid Solr core specified";
    vlog_option "core", $core;
    return $core;
}

sub validate_solr_shard($){
    my $shard = shift;
    defined($shard) or quit "CRITICAL", "Solr shard not specified";
    $shard = isSolrShard($shard) or quit "CRITICAL", "invalid Solr shard specified";
    vlog_option "shard", $shard;
    return $shard;
}

sub validate_solr_context($){
    my $context = shift;
    defined($context) or quit "CRITICAL", "Solr http context not defined";
    $context =~ /^\/*([\/\w-]+)$/ or quit "CRITICAL", "invalid Solr http context, must be alphanumeric";
    $context = "/$1";
    if($solr_admin eq $default_solr_admin){
        $solr_admin = "$context/admin";
    }

    vlog_option "http context", $context;
    return $context;
}

1;
