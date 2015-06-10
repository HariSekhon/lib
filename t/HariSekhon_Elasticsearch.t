#
#  Author: Hari Sekhon
#  Date: 2015-03-25 23:06:45 +0000 (Wed, 25 Mar 2015)
#
#  vim:ts=4:sts=4:sw=4:et

use diagnostics;
use warnings;
use strict;
use Test::More;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__) . "/..";
    use_ok('HariSekhon::Elasticsearch');
}
require_ok('HariSekhon::Elasticsearch');

is(isElasticSearchCluster('HDP'), 'HDP', "isElasticSearchCluster('HDP') eq HDP");
is(isElasticSearchCluster('?'), undef, "isElasticSearchCluster('?') eq undef");

is(isElasticSearchIndex('.kibana'),     '.kibana',      "isElasticSearchIndex('.kibana') eq .kibana");
is(isESIndex('.kibana'),                '.kibana',      "isESIndex('.kibana') eq .kibana");
is(isElasticSearchIndex('kibana-int'),  'kibana-int',   "isElasticSearchIndex('kibana-int') eq kibana-int");
is(isElasticSearchIndex('HDP'),         undef,          "isElasticSearchIndex('HDP') eq undef");
is(isElasticSearchIndex('?'),           undef,          "isElasticSearchIndex('?') eq undef");
is(isElasticSearchType('.kibana'),      '.kibana',      "isElasticSearchType('.kibana') eq .kibana");
is(isESType('.kibana'),                 '.kibana',      "isESType('.kibana') eq .kibana");
is(isElasticSearchType('kibana-int'),   'kibana-int',   "isElasticSearchType('kibana-int') eq kibana-int");
is(isElasticSearchType('myType'),       'myType',       "isElasticSearchType('myType') eq myType");
is(isElasticSearchType('?'),            undef,          "isElasticSearchType('?') eq undef");

done_testing();
