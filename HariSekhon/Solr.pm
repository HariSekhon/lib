#
#  Author: Hari Sekhon
#  Date: 2015-02-01 21:07:37 +0000 (Sun, 01 Feb 2015)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#

package HariSekhon::Solr;

$VERSION = "0.1";

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
                    $num_found
                    $qstatus
                    $query_status
                    $query_time
                    $rows
                    $solr_admin
                    $start
                    $ua
                    $url
                    Dumper
                    curl_solr
                    isSolrCollection
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
our $start = 0;
our $rows  = 3;

our $qstatus;
our $query_status;
our $query_time;
our $num_found;

sub curl_solr($){
    my $url = shift() || code_error "no url argument passed to curl_solr()";
    $url  = "http://$host:$port/$url";
    $url =~ /\?/ and $url .= "&" or $url .= "?";
    $url .= "omitHeader=off"; # we need the response header for query time, status and num found
    $url .= "&wt=json"; # xml is lame
    $url .= "&start=$start&rows=$rows";
    $url .= "&indent=true" if $verbose > 2;
    $url .= "&debugQuery=true" if $debug;
    my $json = curl_json $url, "Solr";
    $qstatus = get_field("status");
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
    $collection = validate_solr_collection($collection);
    # must be URL encoded before passing to Solr
    $query = uri_escape($query);
    curl_solr "solr/$collection/select?q=$query";
}

sub isSolrCollection($){
    my $collection = shift;
    $collection =~ /^([A-Za-z0-9]+)$/ or return undef;
    return $1;
}

sub validate_solr_collection($){
    my $collection = shift() || code_error "no collection argument passed to validate_solr_collection()";
    isSolrCollection($collection) or quit "CRITICAL", "invalid Solr collection specified";
}

1;
