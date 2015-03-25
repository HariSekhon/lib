#
#  Author: Hari Sekhon
#  Date: 2015-03-25 21:33:08 +0000 (Wed, 25 Mar 2015)
#
#  vim:ts=4:sts=4:sw=4:et

use diagnostics;
use warnings;
use strict;
use Test::More;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__) . "/..";
    use_ok('HariSekhon::HBase');
}
require_ok('HariSekhon::HBase');

is(isHBaseColumnQualifier('cf1:q1'), 'cf1:q1', "isHBaseColumnQualifier('cf1') eq cf1:q1");
is(isHBaseColumnQualifier('?'), undef, "isHBaseColumnQualifier('cf1') eq undef");

is(isHBaseRowKey('one#two'), 'one#two', "isHBaseRowKey('one#two') eq one#two");
is(isHBaseRowKey('?'), undef, "isHBaseRowKey('?') eq undef");

is(isHBaseTable('hbase:meta'), 'hbase:meta', "isHBaseTable('hbase:meta') eq hbase:meta");
is(isHBaseTable('?'), undef, "isHBaseTable('?') eq undef");

done_testing();
