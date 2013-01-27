#
#  Author: Hari Sekhon
#  Date: 2013-01-06 01:25:55 +0000 (Sun, 06 Jan 2013)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

# Unit Tests for HariSekhonUtils

#use diagnostics;
use warnings;
use strict;
use Test::More;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__) . "/..";
    use_ok('HariSekhonUtils');
}
require_ok('HariSekhonUtils');

ok($progname,   '$progname set');

# ============================================================================ #
#                           Status Codes
# ============================================================================ #

is($ERRORS{"OK"},        0, '$ERRORS{OK}        eq 0');
is($ERRORS{"WARNING"},   1, '$ERRORS{WARNING}   eq 1');
is($ERRORS{"CRITICAL"},  2, '$ERRORS{CRITICAL}  eq 2');
is($ERRORS{"UNKNOWN"},   3, '$ERRORS{UNKNOWN}   eq 3');
is($ERRORS{"DEPENDENT"}, 4, '$ERRORS{DEPENDENT} eq 4');
is($port, undef, "port is undef");

ok(set_timeout_max(200),     "set_timeout_max(200)");
is($timeout_max, 200, '$timeout_max eq 200');
ok(set_timeout_default(100), "set_timeout_default(100)");
is($timeout_default, 100, '$timeout_default eq 100');

is($status,      "UNKNOWN", '$status eq UNKNOWN');
is(get_status_code($status), 3, 'get_status_code($status) eq UNKNOWN');
is(get_status_code(),        3, 'get_status_code() eq UNKNOWN');

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
is(get_status_code("DEPENDENT"),  4, "get_status_code(DEPENDENT) eq 4");
# This code errors out now
#is(get_status_code("NONEXISTENT"),  undef, "get_status_code(NONEXISTENT) eq undef");

# This should cause compilation failure
#ok(critical("blah"), 'critical("blah")');

$verbose++;
# TODO: This only checks the sub runs and returns success, should really check it outputs the right thing but not sure how to check the stdout from this sub
ok(status(), "status()");

# ============================================================================ #

ok(cmd("ps"), 'cmd("ps");');
#ok(!cmd("unknown_fake_command"), 'cmd("unknown_fake_command");');

is_deeply([compact_array(( "one", "" , "two" ))], [ "one", "two" ], 'compact_array() remove blanks');
is_deeply([compact_array(( "one", "\t\r\n" , "two" ))], [ "one", "two" ], 'compact_array() remove ^\s*$');
is_deeply([compact_array(( "one", 0 , "two" ))], [ "one", 0, "two" ], 'compact_array() not remove zero');

# TODO: check_threshold{,s}, code_error

# TODO: curl onwards
#$verbose = 3;
#use_ok("LWP::Simple", 'get');
#like(curl("http://www.google.com/"), qr/google.com/, 'curl("www.google.com")');

#is(die(), 2, "die() returns 2");

$debug = 1;
ok(debug("debug stuff"), 'debug("debug stuff")');
$debug = 0;
ok(!debug("debug stuff"), '!debug("debug stuff") without \$debug set');

is(expand_units("10", "KB"), 10240, 'expand_units("10", "KB") eq 10240');
is(expand_units("10", "mB"), 10485760, 'expand_units("10", "mB") eq 10485760');
is(expand_units("10", "Gb"), 10737418240, 'expand_units("10", "Gb") eq 10737418240');
is(expand_units("10", "tb"), 10995116277760, 'expand_units("10", "tb") eq 10995116277760');
is(expand_units("10", "Pb"), 11258999068426240, 'expand_units("10", "Pb") eq 11258999068426240');

# TODO: get_options

is(get_path_owner("/etc/passwd"), "root", 'get_path_owner("/etc/passwd") eq "root"');

ok(go_flock_yourself(), "go_flock_yourself()");
ok(flock_off(), "flock_off()");

ok(inArray("one", qw/one two three/), 'inArray("one", qw/one two three/)');
ok(!inArray("four", qw/one two three/), '!inArray("four", qw/one two three/)');

ok(isArray([qw/one two/]), 'isArray([qw/one two/])');
ok(!isArray($verbose),  '!isArray(\$verbose)');

ok(HariSekhonUtils::isCode(sub{}), 'HariSekhonUtils::isCode(sub{})');
ok(HariSekhonUtils::isSub(sub{}), 'HariSekhonUtils::isCode(sub{})');

ok(!HariSekhonUtils::isCode(1), '!HariSekhonUtils::isCode(1)');
ok(!HariSekhonUtils::isSub(1), '!HariSekhonUtils::isSub(1)');

is(isDomain("harisekhon.com"),  "harisekhon.com",   'isDomain("harisekhon.com") eq harisekhon.com');
is(isDomain("harisekhon"),      0,                  '!isDomain("harisekhon") eq 0');
is(isDomain("a"x256),           0,                  '!isDomain("a"x256) eq 0');

is(isEmail('hari\'sekhon@gmail.com'),   'hari\'sekhon@gmail.com',   'isEmail("hari\'sekhon@gmail.com") eq hari\'sekhon@gmail.com');
is(isEmail("harisekhon"),               0,                          '!isEmail("harisekhon") eq 0');

ok(isFloat(1),          'isFloat(1)');
ok(!isFloat(-1),        '!isFloat(-1)');
ok(isFloat(-1, 1),      'isFloat(-1, 1)');

ok(isFloat(1.1),        'isFloat(1.1)');
ok(!isFloat(-1.1),      '!isFloat(-1.1)');
ok(isFloat(-1.1, 1),    'isFloat(-1.1, 1)');

ok(!isFloat("nan"),     '!isFloat("nan")');
ok(!isFloat("nan", 1),  '!isFloat("nan", 1)');

is(isFqdn("hari.sekhon.com"),   "hari.sekhon.com",  'isFqdn("hari.sekhon.com") eq harisekhon.com');
is(isFqdn("harisekhon.com"),    0,                  '!isFqdn("harisekhon.com") eq 0');

# TODO:
#ok(isHash(%{ ( "one" => 1 ) }), "isHash()");

ok(isHex("0xAf09b"), 'isHex');
ok(!isHex(9),        '!isHex(9)');
ok(!isHex("0xhari"), '!isHex("hari")');

is(isHost("harisekhon.com"),    "harisekhon.com",   'isHost("harisekhon.com") eq harisekhon.com');
ok(isHost("harisekhon"),        'isHost("harisekhon")');
ok(isHost("10.10.10.1"),        'isHost("10.10.10.1")');
is(isHost("10.10.10.10"),       "10.10.10.10",      'isHost("10.10.10.10") eq 10.10.10.10');
ok(isHost("10.10.10.100"),      'isHost("10.10.10.100")');
ok(!isHost("10.10.10.0"),       '!isHost("10.10.10.0")');
ok(!isHost("10.10.10.255"),     '!isHost("10.10.10.255")');
ok(!isHost("10.10.10.300"),     '!isHost("10.10.10.300")');
ok(!isHost("a"x256),            '!isHost("a"x256)');

is(isHostname("harisekhon.com"),    "harisekhon.com",   'isHostname("harisekhon.com") eq harisekon.com');
ok(isHostname("harisekhon"),        'isHostname("harisekhon")');
ok(!isHostname(1),                  '!isHostname(1)');
ok(!isHostname("a"x256),            '!isHostname("a"x256)');

ok(isInt(0),    'isInt(0)');
ok(isInt(1),    'isInt(1)');
ok(!isInt(-1),  '!isInt(-1)');
ok(!isInt(1.1), '!isInt(1.1)');
ok(!isInt("a"), '!isInt("a")');

is(isInterface("eth0"),     "eth0",     'isInterface("eth0")');
is(isInterface("bond3"),    "bond3",    'isInterface("bond3")');
is(isInterface("lo"),       "lo",       'isInterface("lo")');
ok(!isInterface('b@interface'),         '!isInterface(\'b@dinterface\'');

ok(isIP("10.10.10.1"),        'isIP("10.10.10.1")');
is(isIP("10.10.10.10"),       "10.10.10.10",      'isIP("10.10.10.10") eq 10.10.10.10');
ok(isIP("10.10.10.100"),      'isIP("10.10.10.100")');
ok(isIP("254.0.0.254"),       'isIP("254.0.0.254")');
ok(!isIP("10.10.10.0"),       '!isIP("10.10.10.0")');
ok(!isIP("10.10.10.255"),     '!isIP("10.10.10.255")');
ok(!isIP("10.10.10.300"),     '!isIP("10.10.10.300")');
ok(!isIP("x.x.x.x"),          '!isIP("x.x.x.x")');

is(isPort(80),          80,     'isPort(80)');
ok(!isPort(65536),              '!isPort(65536)');
ok(!isPort("a"),                'isPort("a")');

is(isLabel("st4ts_used(%)"),    "st4ts_used(%)",    'isLabel("st4ts_used(%)")');
ok(!isLabel('b@dlabel'),                            'isLabel(\'b@dlabel\')');

is(isProcessName("../my_program"),      "../my_program",        'isProcessName("../my_program")');
is(isProcessName("ec2-run-instances"),  "ec2-run-instances",    'isProcessName("ec2-run-instances")');
ok(isProcessName("sh <defunct>"),   'isProcessName("sh <defunct>")');
ok(!isProcessName("./b\@dfile"),    '!isProcessName("./b@dfile")');
ok(!isProcessName("[init] 3"),      '!isProcessName("[init] 3")');

ok(isScalar(\$status),          'isScalar(\$status)');
ok(!isScalar(\@usage_order),    '!isScalar(\@usage_order)');
ok(!isScalar(\%ERRORS),         '!isScalar(\%ERRORS)');
ok(!isScalar(1),                '!isScalar(1)');

is(isUrl("http://www.google.com"),  "http://www.google.com",    'isUrl("http://www.google.com")');
is(isUrl("https://gmail.com"),      "https://gmail.com",        'isUrl("https://gmail.com")');
ok(!isUrl("www.google.com"),                                    '!isUrl("www.google.com")');
ok(!isUrl(1),                                                   '!isUrl(1)');

is(isUser("hadoop"),    "hadoop",   'isUser("hadoop")');
is(isUser("hari1983"),  "hari1983", 'isUser("hari1983")');
ok(!isUser("-hari"),                '!isUser("-hari")');
ok(!isUser("1983hari"),             '!isUser("1983hari")');

ok(isOS($^O),    'isOS($^O)');

ok(HariSekhonUtils::loginit(),   'HariSekhonUtils::loginit()');
ok(HariSekhonUtils::loginit(),   'HariSekhonUtils::loginit() again since it should be initialized by first one');
ok(&HariSekhonUtils::log("hari testing"), '&HariSekhonUtils::log("hari testing")');

# TODO
# logdie

is(lstrip(" \t \n ha ri \t \n"),     "ha ri \t \n",   'lstrip()');
is(ltrim(" \t \n ha ri \t \n"),      "ha ri \t \n",   'ltrim()');

ok(msg_perf_thresholds(),   "msg_perf_thresholds()");

# TODO
#ok(HariSekhonUtils::msg_thresholds(),        "msg_thresholds()");

ok(open_file("/etc/hosts",1),           'open_file("/etc/hosts",1)');
# Not supporting mode right now
#ok(open_file("/etc/hosts",1,">>"),      'open_file("/etc/hosts",1,">>")');

ok(!pkill("nonexistentprogram"),         '!pkill("nonexistentprogram")');

is(plural(1),                       "",     'plural(1)');
is(plural(2),                       "s",    'plural(2)');
# code_error's out
#is(plural("string"),                "",     'plural("string")');
is(plural([qw/one/]),               "",     'plural(qw/one/)');
is(plural([qw/one two three/]),     "s",    'plural(qw/one two three/)');

# TODO
#ok(HariSekhonUtils::print_options(),       'print_options()');

# TODO
# quit

is(resolve_ip("a.resolvers.level3.net"),    "4.2.2.1",      'resolve_ip("a.resolvers.level3.net") returns 4.2.2.1');
is(resolve_ip("4.2.2.2"),                   "4.2.2.2",      'resolve_ip("4.2.2.2") returns 4.2.2.2');

is(rstrip(" \t \n ha ri \t \n"),     " \t \n ha ri",   'rstrip()');
is(rtrim(" \t \n ha ri \t \n"),      " \t \n ha ri",   'rtrim()');

is(set_sudo("hadoop"),      "echo | sudo -S -u hadoop ",    'set_sudo("hadoop")');
is(set_sudo(getpwuid($>)),  "",                             'set_sudo(getpwuid($>))');

# This is because the previous timer remaining time was 0
is(set_timeout(10),     0,      "set_timeout(10) eq 0");
is(set_timeout(10),     10,     "set_timeout(10) eq 10");

is(strip(" \t \n ha ri \t \n"),     "ha ri",   'strip()');
is(trim(" \t \n ha ri \t \n"),      "ha ri",   'trim()');

# TODO:
#ok(subtrace("test"), 'subtrace("test")');

is_deeply([uniq_array(("one", "two", "three", "", "one"))],     [ "", "one", "three", "two" ],    'uniq_array()');

# TODO:
# usage

ok(user_exists("root"),                 'user_exists("root")');
ok(!user_exists("nonexistentuser"),     '!user_exists("nonexistentuser")');

# TODO: can't actually test failure of these validation functions as they will error out
is(validate_database("mysql"),                  "mysql",        'validate_database("mysql")');
is(validate_database_fieldname(10),             10,             'validate_database_fieldname(10)');
is(validate_database_fieldname("count(*)"),     "count(*)",     'validate_database_fieldname("count(*)")');

is(validate_database_query_select_show("SELECT count(*) from database.field"),  "SELECT count(*) from database.field", 'validate_database_query_select_show("SELECT count(*) from database.field")');
# This should error out with invalid query msg. if it shows DML statement detected then it's fallen through to DML keyword match
#ok(!validate_database_query_select_show("SELECT count(*) from (DELETE FROM database.field)"),  'validate_database_query_select_show("SELECT count(*) from (DELETE FROM database.field)")');

is(validate_domain("harisekhon.com"),  "harisekhon.com",    'validate_domain("harisekhon.com") eq harisekhon.com');

is(validate_directory("/etc/"),     "/etc/",    'validate_directory("/etc/")');
is(validate_dir("/etc/"),           "/etc/",    'validate_dir("/etc/")');
is(validate_directory("/nonexistentdir", 1),    "/nonexistentdir",  'validate_directory("/nonexistentdir", 1)');
ok(!validate_directory('b@ddir', 1),            '!validate_directory(\'b@ddir\')');
# TODO: cannot validate dir not existing here as it terminates program

is(validate_email('harisekhon@gmail.com'),      'harisekhon@gmail.com',     'validate_email(\'harisekhon@gmail.com\')');

is(validate_file("/etc/passwd"),    "/etc/passwd",  'validate_file("/etc/passwd")');
is(validate_file("/etc/nonexistentfile", 1),   0,   'validate_file("/etc/nonexistentfile", 1) eq 0');

is(validate_filename("/etc/passwd"),                "/etc/passwd",              'validate_filename("/etc/passwd")');
is(validate_filename("/etc/nonexistentfile", 1),    "/etc/nonexistentfile",     'validate_filename("/etc/nonexistentfile", 1)');

is(validate_float(2,0,10,"two"),            2,      'validate_float(2,0,10,"two")');
is(validate_float(-2,-10,10,"minus-two"),   -2,     'validate_float(-2,-10,10,"minus-two")');
is(validate_float(2.1,0,10,"two-float"),    2.1,    'validate_float(2.1,0,10,"two-float")');
is(validate_float(6.8,5,10,"six-float"),    6.8,    'validate_float(6.8,5,10,"six")');
is(validate_float(-6,-6,0,"minus-six"),     -6,     'validate_float(-6,-6,0,"minus-six")');
# should error out
#is(validate_float(3,4,10,"three"),  0,  'validate_float(3,4,10,"three")');

is(validate_fqdn("www.harisekhon.com"),     "www.harisekhon.com",      'validate_fqdn("www.harisekhon.com")');
# should error out
#is(validate_fqdn("harisekhon.com"),     0,      'validate_fqdn("harisekhon.com")');


is(validate_int(2,0,10,"two"),    2,  'validate_int(2,0,10,"two")');
is(validate_int(-2,-10,10,"minus-two"),    -2,  'validate_int(-2,-10,10,"minus-two")');
# should error out
#is(validate_int(2.1,0,10,"two-float"),  0,  'validate_int(2.0,0,10,"two-float")');
is(validate_int(6,5,10,"six"),    6,  'validate_int(6,5,10,"six")');
is(validate_int(-6,-6,0,"minus-six"),    -6,  'validate_int(-6,-6,0,"minus-six")');
is(validate_integer(2,0,10,"two"),    2,  'validate_integer(2,0,10,"two")');
is(validate_integer(6,5,7,"six"),    6,  'validate_integer(6,5,7,"six")');
# should error out
#is(validate_int(3,4,10,"three"),  0,  'validate_int(3,4,10,"three")');

is(validate_interface("eth0"),     "eth0",     'validate_interface("eth0")');
is(validate_interface("bond3"),    "bond3",    'validate_interface("bond3")');
is(validate_interface("lo"),       "lo",       'validate_interface("lo")');

ok(validate_ip("10.10.10.1"),        'validate_ip("10.10.10.1")');
is(validate_ip("10.10.10.10"),       "10.10.10.10",      'validate_ip("10.10.10.10") eq 10.10.10.10');
ok(validate_ip("10.10.10.100"),      'validate_ip("10.10.10.100")');
ok(validate_ip("254.0.0.254"),       'validate_ip("254.0.0.254")');

is_deeply([validate_node_list("node1, node2 ,node3 , node4,,\t\nnode5")], [qw/node1 node2 node3 node4 node5/],    'validate_node_list($)');
# The , in node4, inside the qw array should be split out to just node4 and blank, blank shouldn't make it in to the array
is_deeply([validate_node_list("node1", qw/node2 node3 node4, node5/)], [qw/node1 node2 node3 node4 node5/],    'validate_node_list($@)');
# should error out with "node list empty"
#is(!validate_node_list(""), '!validate_node_list("")');

is(validate_port(80),          80,     'validate_port(80)');
is(validate_port(65535),       65535,  'validate_port(65535)');

is(validate_process_name("../my_program"),      "../my_program",        'validate_process_name("../my_program")');
is(validate_process_name("ec2-run-instances"),  "ec2-run-instances",    'validate_process_name("ec2-run-instances")');
ok(validate_process_name("sh <defunct>"),       'validate_process_name("sh <defunct>")');

is(validate_label("st4ts_used(%)"),    "st4ts_used(%)",    'validate_label("st4ts_used(%)")');

is(validate_regex("some[Rr]egex.*(capture)"),   "(?-xism:some[Rr]egex.*(capture))",  'validate_regex("some[Rr]egex.*(capture)")');
# Errors out still, should detect and fail gracefully
#is(validate_regex("some[Rr]egex.*(capture broken", 1),   0,  'validate_regex("some[Rr]egex.*(capture broken", 1)');
is(validate_regex("somePosix[Rr]egex.*(capture)", 0, 1),   "somePosix[Rr]egex.*(capture)",      'validate_regex("somePosix[Rr]egex.*(capture)", 0, 1)');
is(validate_regex("somePosix[Rr]egex.*(capture broken", 1, 1),  0,       'validate_regex("somePosix[Rr]egex.*(capture broken", 1, 1) eq 0');
is(validate_regex('somePosix[Rr]egex.*$(evilcmd)', 1, 1),       0,       'validate_regex("somePosix[Rr]egex.*$(evilcmd)", 1, 1) eq 0');
is(validate_regex('somePosix[Rr]egex.*$(evilcmd', 1, 1),        0,       'validate_regex("somePosix[Rr]egex.*$(evilcmd", 1, 1) eq 0');
is(validate_regex('somePosix[Rr]egex.*`evilcmd`', 1, 1),        0,       'validate_regex("somePosix[Rr]egex.*`evilcmd`", 1, 1) eq 0');
is(validate_regex('somePosix[Rr]egex.*`evilcmd', 1, 1),         0,       'validate_regex("somePosix[Rr]egex.*`evilcmd", 1, 1) eq 0');

is(validate_user("hadoop"),    "hadoop",   'validate_user("hadoop")');
is(validate_user("hari1983"),  "hari1983", 'validate_user("hari1983")');

is(validate_user_exists("root"),  "root", 'validate_user_exists("root")');

is(validate_password('wh@tev3r'),   'wh@tev3r',     'validate_password(\'wh@tev3r\')');

# This could do with a lot more unit testing
ok(HariSekhonUtils::validate_threshold("warning", 75), 'validate_threshold("warning", 75)');
ok(HariSekhonUtils::validate_threshold("critical", 90), 'validate_threshold("critical", 90)');
ok(validate_thresholds(), 'validate_thresholds()');

# Not sure if I can relax the case sensitivity on these according to the Nagios Developer guidelines
is(validate_units("s"),     "s",    'validate_units("s")');
is(validate_units("ms"),    "ms",   'validate_units("ms")');
is(validate_units("us"),    "us",   'validate_units("us")');
is(validate_units("B"),     "B",    'validate_units("B")');
is(validate_units("KB"),    "KB",   'validate_units("KB")');
is(validate_units("GB"),    "GB",   'validate_units("GB")');
is(validate_units("KB"),    "KB",   'validate_units("KB")');
is(validate_units("c"),     "c",    'validate_units("c")');
# should error out
#is(validate_units("a"),     "c",    'validate_units("c")');

is(validate_url("http://www.google.com"),  "http://www.google.com",    'validate_url("http://www.google.com")');
is(validate_url("https://gmail.com"),      "https://gmail.com",        'validate_url("https://gmail.com")');

ok(!verbose_mode(),  '!verbose_mode()');
$verbose = 2;
ok(verbose_mode(),  'verbose_mode()');

# TODO: errors out
#ok(version(),       'version()');

print "\n";
$verbose = 0;
ok(!vlog("testing vlog in \$verbose $verbose"),       "!vlog(\"testing vlog in \$verbose $verbose\")");
ok(!vlog2("testing vlog2 in \$verbose $verbose"),     "!vlog2(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog2("testing vlog3 in \$verbose $verbose"),     "!vlog3(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 1;
ok(vlog("testing vlog in \$verbose $verbose"),        "vlog(\"testing vlog in \$verbose $verbose\")");
ok(!vlog2("testing vlog2 in \$verbose $verbose"),     "!vlog2(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog2("testing vlog3 in \$verbose $verbose"),     "!vlog3(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 2;
ok(vlog("testing vlog in \$verbose $verbose"),        "vlog(\"testing vlog in \$verbose $verbose\")");
ok(vlog2("testing vlog2 in \$verbose $verbose"),      "vlog(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog3("testing vlog3 in \$verbose $verbose"),     "!vlog(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 3;
ok(vlog("testing vlog in \$verbose $verbose"),        "vlog(\"testing vlog in \$verbose $verbose\")");
ok(vlog2("testing vlog2 in \$verbose $verbose"),      "vlog(\"testing vlog2 in \$verbose $verbose\")");
ok(vlog3("testing vlog3 in \$verbose $verbose"),      "vlog(\"testing vlog3 in \$verbose $verbose\")");

$verbose = 1;
ok(HariSekhonUtils::vlog4("test1\ntest2"),   'vlog4("test1\ntest2")');

$verbose = 1;
ok(!vlog_options("option", "value"),         '!vlog_options("option", "value") in $verbose 1');
$verbose = 2;
ok(vlog_options("option", "value"),         'vlog_options("option", "value") in $verbose 2');

is(which("sh"),   "/bin/sh",        'which("sh") eq sh');
# TODO: not testing which("/explicit/path", 1) since it would error out
is(which("/explicit/path"),   "/explicit/path",        'which("/explicit/path") eq /explicit/path');
is(which("nonexistentprogram"),   0,        'which("nonexistentprogram") eq 0');

done_testing();
