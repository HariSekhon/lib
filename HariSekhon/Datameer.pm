#
#  Author: Hari Sekhon
#  Date: 2013-12-05 21:28:36 +0000 (Thu, 05 Dec 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::Datameer;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Carp;
use JSON::XS;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                     $DATAMEER_DEFAULT_PORT
                     %datameer_options
                     %datameer_job_state
                     datameer_curl
                )
);
our @EXPORT_OK = ( @EXPORT );

our $DATAMEER_DEFAULT_PORT = 8080;
$port = $DATAMEER_DEFAULT_PORT;

env_creds("DATAMEER");

our %datameer_options = (
    "H|host=s"         => [ \$host,         "Datameer server (\$DATAMEER_HOST, \$HOST)" ],
    "P|port=s"         => [ \$port,         "Datameer port   (\$DATAMEER_PORT, \$PORT, default: $DATAMEER_DEFAULT_PORT)" ],
    %useroptions,
);

our %datameer_job_state;
$datameer_job_state{"OK"}       = [qw/RUNNING WAITING_FOR_OTHER_JOB COMPLETED QUEUED/];
$datameer_job_state{"WARNING"}  = [qw/COMPLETED_WITH_Warnings CANCELED CANCELLED/];
$datameer_job_state{"CRITICAL"} = [qw/ERROR/];

sub datameer_curl($$$){
    # curl takes care of the error handling in HariSekhonUtils
    my $content = curl $_[0], "Datameer", $_[1], $_[2];

    my $json;
    try{
        $json = decode_json $content;
    };
    catch{
        quit "CRITICAL", "invalid json returned by '$host:$port'";
    };
    if(isHash($json) and defined($json->{"error"})){
	quit "CRITICAL", $json->{"error"};
    }

    return $json;
}
