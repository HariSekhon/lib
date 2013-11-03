#
#  Author: Hari Sekhon
#  Date: 2013-11-03 03:58:28 +0000 (Sun, 03 Nov 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#  

package HariSekhon::Cassandra;

$VERSION = "0.1";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                        $nodetool_nodetool_default_port
                        $nodetool
                        $nodetool_errors_regex
                        %nodetool_options
                        nodetool_options
                        validate_nodetool
                )
);
our @EXPORT_OK = ( @EXPORT );

our $nodetool = "nodetool";
our $nodetool_default_port = 7199;
our $nodetool_port = $nodetool_default_port;

sub validate_nodetool ($) {
    my $nodetool = shift;
    defined($nodetool) or usage "nodetool not defined";
    $nodetool =~ /(?:^|\/)nodetool$/ or usage "invalid nodetool path given, must be the path to the nodetool command";
    $nodetool = validate_filename($nodetool, 0, "nodetool");
    $nodetool = which($nodetool, 1);
    return $nodetool;
}

our %nodetool_options = (
    "n|nodetool=s"     => [ \$main::nodetool,     "Path to 'nodetool' command" ],
    "H|host=s"         => [ \$main::host,         "Remote node to query (optional, defaults to local node)" ],
    "P|port=s"         => [ \$main::port,         "Remote node's JMX port (default: $nodetool_default_port)" ],
    "u|user=s"         => [ \$main::user,         "JMX User (optional)" ],
    "p|password=s"     => [ \$main::password,     "JMX Password (optional)" ],
);

sub nodetool_options(;$$$$){
    my $host     = shift;
    my $nodetool_port     = shift;
    my $user     = shift;
    my $password = shift;
    my $options = "";
    $options .= "--host '$host' "           if defined($host);
    $options .= "--port '$nodetool_port' "           if defined($nodetool_port);
    $options .= "--username '$user' "       if defined($user);
    $options .= "--password '$password' "   if defined($password);
    return $options;
}

our $nodetool_errors_regex = qr/
                                Cannot\s+resolve |
                                unknown\s+host   |
                                connection\s+refused  |
                                failed\s+to\s+connect |
                                error    |
                                user     |
                                password
                             /xi;
