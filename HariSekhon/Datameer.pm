#
#  Author: Hari Sekhon
#  Date: 2013-12-05 21:28:36 +0000 (Thu, 05 Dec 2013)
#
#  http://github.com/harisekhon
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

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                     $DATAMEER_DEFAULT_PORT
                     %datameer_options
                )
);
our @EXPORT_OK = ( @EXPORT );

our $DATAMEER_DEFAULT_PORT = 8080;
$port = $default_port;

env_creds("DATAMEER");

our %datameer_options = (
    "H|host=s"         => [ \$host,         "Datameer server" ],
    "P|port=s"         => [ \$port,         "Datameer port (default: $DATAMEER_DEFAULT_PORT)" ],
    "u|user=s"         => [ \$user,         "Datameer user     (\$DATAMEER_USER)" ],
    "p|password=s"     => [ \$password,     "Datameer password (\$DATAMEER_PASSWORD)" ],
);
