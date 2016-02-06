#
#  Author: Hari Sekhon
#  Date: 2015-06-13 22:40:31 +0100 (Sat, 13 Jun 2015)
#
#  vim:ts=4:sts=4:sw=4:et
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying Hari Sekhon LICENSE file
#  
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

package HariSekhon::Riak;

$VERSION = "0.2";

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
                    $riak_admin_path
                    %riak_admin_path_option
                    get_riak_admin_path
                )
);
our @EXPORT_OK = ( @EXPORT );

# default install path for riak-admin from packages
$ENV{"PATH"} .= ":/usr/sbin";
# this is the a convenient path to check too
$ENV{"PATH"} .= ":/usr/local/riak/bin";

our $riak_admin_path = "";

our %riak_admin_path_option = (
    "riak-admin-path=s"  => [ \$riak_admin_path, "Path to directory containing riak-admin command if differing from the default /usr/sbin" ],
);

sub get_riak_admin_path(){
    if($riak_admin_path){
        if(grep {$_ eq $riak_admin_path } split(":", $ENV{"PATH"})){
            usage "$riak_admin_path already in \$riak_admin_path ($ENV{PATH})";
        }
        $riak_admin_path = validate_directory($riak_admin_path, "riak-admin PATH", undef, "no vlog");
        $ENV{"PATH"} = "$riak_admin_path:$ENV{PATH}";
        vlog2 "\$riak_admin_path for riak-admin:",   $ENV{"PATH"};
        vlog2;
    }
}

1;
