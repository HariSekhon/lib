#
#  Author: Hari Sekhon
#  Date: 2014-06-07 11:48:30 +0100 (Sat, 07 Jun 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::ElasticSearch;

$VERSION = "0.1";

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
                    curl_elasticsearch
                )
);
our @EXPORT_OK = ( @EXPORT );

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
    return $json;
}
