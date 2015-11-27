#
#  Author: Hari Sekhon
#  Date: 2015-06-28 14:05:33 +0100 (Sun, 28 Jun 2015)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

use diagnostics;
use strict;
use warnings;
use Test::More;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__) . "..";
    use_ok('HariSekhon::Ambari');
}
require_ok('HariSekhon::Ambari');

is(validate_ambari_cluster("PoC_Cluster1"), "PoC_Cluster1", 'validate_ambari_cluster()');
is(validate_ambari_component("pig"), "PIG", 'validate_ambari_component()');
is(validate_ambari_node("myHost.domain.com"), "myHost.domain.com", 'validate_ambari_node()');
is(validate_ambari_service("Kafka"), "KAFKA", 'validate_ambari_service()');

done_testing();
