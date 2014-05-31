#
#  Author: Hari Sekhon
#  Date: 2014-05-31 21:26:38 +0100 (Sat, 31 May 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::IBM::BigInsights;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;
use Data::Dumper;
use JSON;
use LWP::UserAgent;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $json
                    $api
                    $protocol
                    $ua
                    get_field
                    get_field2
                    curl_biginsights
                )
);
our @EXPORT_OK = ( @EXPORT );

set_port_default(8080);

our $ua = LWP::UserAgent->new;

env_creds("BIGINSIGHTS", "IBM BigInsights Console");

my $api = "data/controller";

our $protocol = "http";

our $json;

sub get_field($){
    get_field2($json, $_[0]);
}

sub get_field2($$){
    my $json  = shift;
    my $field = shift;
    defined($json->{$field}) or quit "UNKNOWN", "'$field' field not found in output from BigInsights Console. $nagios_plugins_support_msg_api";
    return $json->{$field};
}

sub curl_biginsights($$$){
    my $url_prefix = "$protocol://$host:$port";
    ($host and $port) or code_error "host and port not defined before calling curl_biginsights";
    my $url      = shift;
    my $user     = shift;
    my $password = shift;
    $url =~ s/\///;
    $url = "$url_prefix/$api/$url";
    my $content  = curl $url, "IBM BigInsights Console", $user, $password;
    try{
        $json = decode_json $content;
    };
    catch{
        quit "invalid json returned by IBM BigInsights Console at '$url_prefix', did you try to connect to the SSL port without --tls?";
    };
    vlog3(Dumper($json));
    return $json;
}

1;
