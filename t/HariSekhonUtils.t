#
#   Author: Hari Sekhon
#   Date: 2013-01-06 01:25:55 +0000 (Sun, 06 Jan 2013)
#  $LastChangedBy$
#  $LastChangedDate$
#  $Revision$
#  $URL$
#  $Id$
#
#  vim:ts=4:sw=4:et

use diagnostics;
use warnings;
use strict;
use Test::More;
use lib ".";

BEGIN{ use_ok('HariSekhonUtils'); }
require_ok('HariSekhonUtils');

ok($progname,   '$progname set');
is($status,      "UNKNOWN", '$status eq UNKNOWN');
is($ERRORS{"OK"},        0, '$ERRORS{OK}       eq 0');
is($ERRORS{"WARNING"},   1, '$ERRORS{WARNING}  eq 1');
is($ERRORS{"CRITICAL"},  2, '$ERRORS{CRITICAL} eq 2');
is($ERRORS{"UNKNOWN"},   3, '$ERRORS{UNKNOWN}  eq 3');
is($ERRORS{"DEPENDENT"}, 4, '$ERRORS{DEPENDEN} eq 4');
is($port, undef, "port is undef");

ok(set_timeout_max(100),     "set_timeout_max(100)");
ok(set_timeout_default(100), "set_timeout_default(100)");

$status = "OK";
ok(is_ok,        "is_ok()");
ok(!is_warning,  "is_warning() fail on OK");
ok(!is_critical, "is_critical() fail on OK");
ok(!is_unknown,  "is_unknown() fail on OK");

is(unknown, "UNKNOWN", "unknown()");
ok(is_unknown,   "is_unknown()");
ok(!is_ok,       "is_ok() fail on UNKNOWN");
ok(!is_warning,  "is_warning() fail on UNKNOWN");

ok(!is_critical, "is_critical() fail on UNKNOWN");
is(warning, "WARNING", "warning()");
is(unknown, "",  "unknown() doesn't set \$status when WARNING");
ok(is_warning,   "is_warning()");
ok(!is_ok,       "is_ok() fail on WARNING");
ok(!is_critical, "is_critical() fail on WARNING");
ok(!is_unknown,  "is_unknown() fail on WARNING");

is(critical, "CRITICAL", "critical()");
is(unknown, "",  "unknown() doesn't set \$status when CRITICAL");
is(warning, "",  "warning() doesn't set \$status when CRITICAL");
ok(is_critical,  "is_critical()");
ok(!is_ok,       "is_ok() fail on CRITICAL");
ok(!is_warning,  "is_warning() fail on CRITICAL");
ok(!is_unknown,  "is_unknown() fail on CRITICAL");

is(get_status_code("OK"),       0, "get_status_code(OK) eq 0");
is(get_status_code("WARNING"),  1, "get_status_code(WARNING) eq 1");
is(get_status_code("CRITICAL"), 2, "get_status_code(OK) eq 2");
is(get_status_code("UNKNOWN"),  3, "get_status_code(UNKNOWN) eq 3");

$verbose++;
ok(status, "status()");

ok(cmd("ps"), 'cmd("ps");');
#ok(!cmd("unknown_fake_command"), 'cmd("unknown_fake_command");');

is_deeply([compact_array(( "one", "" , "two" ))], [ "one", "two" ], 'compact_array() remove blanks');
is_deeply([compact_array(( "one", 0 , "two" ))], [ "one", 0, "two" ], 'compact_array() not remove zero');

# TODO: check_threshold{,s}, code_error

# TODO: curl onwards
#$verbose = 3;
#use_ok("LWP::Simple", 'get');
#like(curl("http://www.google.com/"), qr/google.com/, 'curl("www.google.com")');

#is(die(), 2, "die() returns 2");

done_testing();
