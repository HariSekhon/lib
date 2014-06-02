#
#  Author: Hari Sekhon
#  Date: 2014-05-31 21:26:38 +0100 (Sat, 31 May 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::IBM::BigInsights;

$VERSION = "0.3.2";

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
                    $bigsheets_api
                    $protocol
                    $ua
                    %biginsights_options
                    get_field
                    get_field2
                    curl_biginsights
                    curl_bigsheets
                )
);
our @EXPORT_OK = ( @EXPORT );

set_port_default(8080);

our $ua = LWP::UserAgent->new;

env_creds("BIGINSIGHTS", "IBM BigInsights Console");

our %biginsights_options = (
    %hostoptions,
    %useroptions,
    %tlsoptions,
);
@usage_order = qw/host port user password tls ssl-CA-path tls-noverify warning critical/;

our $api           = "data/controller";
our $bigsheets_api = "bigsheets/api";

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


sub curl_biginsights($$$;$$){
    ($host and $port) or code_error "host and port not defined before calling curl_biginsights()";
    my $url_prefix = "$protocol://$host:$port";
    my $url      = shift;
    my $user     = shift;
    my $password = shift;
    my $err_sub  = shift   || \&curl_biginsights_err_handler;
    my $api      = shift() || $api;
    $url =~ s/^\///;
    $url = "$url_prefix/$api/$url";
    isUrl($url) or code_error "invalid URL '$url' supplied to curl_biginsights/bigsheets";
    my $content  = curl $url, "IBM BigInsights Console", $user, $password, $err_sub;
    try{
        $json = decode_json $content;
    };
    catch{
        quit "invalid json returned by IBM BigInsights Console at '$url_prefix', did you try to connect to the SSL port without --tls?";
    };
    vlog3(Dumper($json));
    return $json;
}


sub curl_bigsheets($$$){
    curl_biginsights $_[0], $_[1], $_[2], \&curl_bigsheets_err_handler, $bigsheets_api;
}


sub curl_biginsights_err_handler($){
    my $response = shift;
    my $content  = $response->content;
    my $json;
    my $additional_information = "";
    if($json = isJson($content)){
        if(defined($json->{"result"}{"error"})){
            quit "CRITICAL", "Error: " . $json->{"result"}{"error"};
        }
    }
    unless($response->code eq "200"){
        quit "CRITICAL", $response->code . " " . $response->message . $additional_information;
    }
    unless($content){
        quit "CRITICAL", "blank content returned from by BigInsights Console";
    }
}

# http://www-01.ibm.com/support/knowledgecenter/SSPT3X_2.1.2/com.ibm.swg.im.infosphere.biginsights.analyze.doc/doc/bigsheets_restapi.html
sub curl_bigsheets_err_handler($){
    my $response = shift;
    my $content  = $response->content;
    my $json;
    my $additional_information = "";
    if($json = isJson($content)){
        if(defined($json->{"errorMsg"})){
            $additional_information .= ". errorMsg: " . $json->{"errorMsg"};
        }
        if(defined($json->{"error"})){
            isHash($json->{"error"}) or quit "UNKNOWN", "error occurred but error field is not a hash as expected to obtain further information. $nagios_plugins_support_msg_api";
            if(defined($json->{"error"}{"errorCode"})){
                $additional_information .= ". ErrorCode: " . $json->{"error"}{"errorCode"};
            }
            if(defined($json->{"error"}{"message"})){
                $additional_information .= ". Message: " . $json->{"error"}{"message"};
            }
        }
    }
    unless($response->code eq "200" or $response->code eq "201"){
        quit "CRITICAL", $response->code . " " . $response->message . $additional_information;
    }
    if(defined($json->{"errorMsg"})){
        if($json->{"errorMsg"} eq "Could not get Job status: null"){
            quit "UNKNOWN", "worksheet job run status: null (workbook not been run yet?)";
        }
        $additional_information =~ s/^\.\s+//;
        quit "CRITICAL", $additional_information;
    }
    unless($content){
        quit "CRITICAL", "blank content returned from by BigInsights Console";
    }
}

1;
