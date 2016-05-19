#
#  Author: Hari Sekhon
#  Date: 2015-03-07 11:41:16 +0000 (Sat, 07 Mar 2015)
#
#  vim:ts=4:sts=4:sw=4:et

use diagnostics;
use warnings;
use strict;
use Test::More;
use File::Basename;
note("Testing on perl $]");
BEGIN {
    use lib dirname(__FILE__) . "/..";
    use_ok('HariSekhon::ZooKeeper');
}
require_ok('HariSekhon::ZooKeeper');

is(isZnode('/'),        '/',        "isZnode('/')");
is(isZnode('/config'),  '/config',  "isZnode('/config')");
is(isZnode('/live_nodes/172.17.0.2:8983_solr'), '/live_nodes/172.17.0.2:8983_solr', "isZnode('/live_nodes/172.17.0.2:8983_solr')");
is(isZnode('/config/'), undef,      "isZnode('/config/') eq undef");
is(isZnode('/c@nfig'),  undef,      "isZnode('/c\@nfig') eq undef");

is(isZookeeperEnsemble('127.0.0.1'), '127.0.0.1', "isZookeeperEnsemble('127.0.0.1') eq '127.0.0.1'");
is(isZookeeperEnsemble('localhost'), 'localhost', "isZookeeperEnsemble('localhost') eq 'localhost'");
is(isZookeeperEnsemble('127.0.0.1:2181'), '127.0.0.1:2181', "isZookeeperEnsemble('127.0.0.1:2181') eq '127.0.0.1:2181'");
is(isZookeeperEnsemble('localhost:2181'), 'localhost:2181', "isZookeeperEnsemble('localhost:2181') eq 'localhost:2181'");
is(isZookeeperEnsemble('localhost,localhost'),   'localhost,localhost',     "isZookeeperEnsemble('localhost,localhost') eq 'localhost,localhost'");
is(isZookeeperEnsemble('localhost:,localhost:'),  'localhost,localhost',    "isZookeeperEnsemble('localhost:,localhost:') eq 'localhost:,localhost:'");
is(isZookeeperEnsemble('localhost,localhost/'),   'localhost,localhost/',   "isZookeeperEnsemble('localhost,localhost/') eq 'localhost,localhost/");
is(isZookeeperEnsemble('localhost:,localhost:/'), 'localhost,localhost/',   "isZookeeperEnsemble('localhost:,localhost:/') eq 'localhost:,localhost:/");
is(isZookeeperEnsemble('localhost:2181,localhost:2182'),      'localhost:2181,localhost:2182',      "isZookeeperEnsemble('localhost:2181,localhost:2182') eq 'localhost:2181,localhost:2182'");
is(isZookeeperEnsemble('localhost:2181,localhost:2182/'),     'localhost:2181,localhost:2182/',     "isZookeeperEnsemble('localhost:2181,localhost:2182/') eq 'localhost:2181,localhost:2182/");
is(isZookeeperEnsemble('localhost:2181,localhost:2182/solr'), 'localhost:2181,localhost:2182/solr', "isZookeeperEnsemble('localhost:2181,localhost:2182/solr') eq 'localhost:2181,localhost:2182/solr'");
is(isZookeeperEnsemble('localhost:2181,localhost:2182/s@lr'), undef, "isZookeeperEnsemble('localhost:2181,localhost:2182/solr') eq undef");

done_testing();
