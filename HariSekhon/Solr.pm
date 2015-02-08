#
#  Author: Hari Sekhon
#  Date: 2015-02-01 21:07:37 +0000 (Sun, 01 Feb 2015)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#

package HariSekhon::Solr;

$VERSION = "0.2";

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
use LWP::UserAgent;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $collection
                    $list_collections
                    $num_found
                    $query_status
                    $query_time
                    $rows
                    $solr_admin
                    $start
                    $ua
                    $url
                    %solroptions
                    %solroptions_collection
                    Dumper
                    curl_solr
                    isSolrCollection
                    list_solr_collections
                    query_solr
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

our $query_status;
our $query_time;
our $num_found;

our %solroptions = (
    %hostoptions,
    #%useroptions,
    %ssloptions,
);

env_vars("SOLR_COLLECTION", \$collection);

our %solroptions_collection = (
    "C|collection=s"    => [ \$collection,          "Solr Collection name (\$SOLR_COLLECTION)" ],
    "list-collections"  => [ \$list_collections,    "List Collections for which there are loaded cores on the given Solr instance and exit" ],
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
        quit "CRITICAL", $response->code . " " . $response->message . $additional_information;
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
    my $json = curl_json $url, "Solr", undef, undef, \&curl_solr_err_handler, $type, $content;
    $query_status = get_field("responseHeader.status");
    $query_time   = get_field_int("responseHeader.QTime");
    $num_found    = get_field("responseHeader.response.numFound", 1);
    if($query_status ne 0){
        critical;
        vlog2 "critical - query status from header was '$query_status' (expected 0)";
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
        foreach(sort keys %cores){
            print get_field2($cores{$_}, "name") . "\n";
        }
        exit $ERRORS{"UNKNOWN"};
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
    isSolrCollection($collection) or quit "CRITICAL", "invalid Solr collection specified";
    vlog_options "collection", $collection;
}

1;
