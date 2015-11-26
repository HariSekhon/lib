#
#  Author: Hari Sekhon
#  Date: 2015-06-28 13:56:39 +0100 (Sun, 28 Jun 2015)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

#use diagnostics;
use strict;
use warnings;
use Test::More;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__) . "..";
    use_ok('HariSekhonUtils', qw/:DEFAULT/);
    use_ok('HariSekhon::MongoDB');
}

is(validate_mongo_hosts("host1,host2,host3"), "mongodb://host1,host2,host3",  'validate_mongo_hosts()');
is(validate_mongo_hosts("host1:8080,host2,host3:99"), "mongodb://host1:8080,host2,host3:99",  'validate_mongo_hosts()');
ok(!validate_mongo_sasl());

done_testing();
