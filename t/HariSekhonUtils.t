#
#  Author: Hari Sekhon
#  Date: 2013-01-06 01:25:55 +0000 (Sun, 06 Jan 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#

# Unit Tests for HariSekhonUtils

#use diagnostics;
use warnings;
use strict;
use Test::More;
use File::Basename;
note("Testing on perl $]");
BEGIN {
    use lib dirname(__FILE__) . "/..";
    use_ok('HariSekhonUtils', qw/:DEFAULT :time/);
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

# ============================================================================ #
is(set_timeout_range(5,50),   50,   "set_timeout_range(1,50)");
is($timeout_min, 5,  '$timeout_min eq 5');
is($timeout_max, 50, '$timeout_max eq 50');
ok(set_timeout_max(200),     "set_timeout_max(200)");
is($timeout_max, 200, '$timeout_max eq 200');
ok(set_timeout_default(100), "set_timeout_default(100)");
is($timeout_default, 100, '$timeout_default eq 100');

# ============================================================================ #
is($status,      "UNKNOWN", '$status eq UNKNOWN');
is(get_status_code($status), 3, 'get_status_code($status) eq UNKNOWN');
is(get_status_code(),        3, 'get_status_code() eq UNKNOWN');

# ============================================================================ #
$status = "OK";
is(status(),  0, "status() eq 0");
is(status2(), 0, "status() eq 0");
is(status3(), 0, "status() eq 0");
ok(is_ok,        "is_ok()");
ok(!is_warning,  "is_warning() fail on OK");
ok(!is_critical, "is_critical() fail on OK");
ok(!is_unknown,  "is_unknown() fail on OK");

# ============================================================================ #
is(unknown, "UNKNOWN", "unknown()");
is(status(),  3, "status() eq 3");
is(status2(), 3, "status() eq 3");
is(status3(), 3, "status() eq 3");
ok(is_unknown,   "is_unknown()");
ok(!is_ok,       "is_ok() fail on UNKNOWN");
ok(!is_warning,  "is_warning() fail on UNKNOWN");
ok(!is_critical, "is_critical() fail on UNKNOWN");

# ============================================================================ #
is(warning, "WARNING", "warning()");
is(status(),  1, "status() eq 1");
is(status2(), 1, "status() eq 1");
is(status3(), 1, "status() eq 1");
is(unknown, "",  "unknown() doesn't set \$status when WARNING");
ok(is_warning,   "is_warning()");
ok(!is_ok,       "is_ok() fail on WARNING");
ok(!is_critical, "is_critical() fail on WARNING");
ok(!is_unknown,  "is_unknown() fail on WARNING");

# ============================================================================ #
is(critical, "CRITICAL", "critical()");
is(status(),  2, "status() eq 2");
is(status2(), 2, "status() eq 2");
is(status3(), 2, "status() eq 2");
is(unknown, "",  "unknown() doesn't set \$status when CRITICAL");
is(warning, "",  "warning() doesn't set \$status when CRITICAL");
ok(is_critical,  "is_critical()");
ok(!is_ok,       "is_ok() fail on CRITICAL");
ok(!is_warning,  "is_warning() fail on CRITICAL");
ok(!is_unknown,  "is_unknown() fail on CRITICAL");

# ============================================================================ #
is(get_status_code("OK"),         0, "get_status_code(OK) eq 0");
is(get_status_code("WARNING"),    1, "get_status_code(WARNING) eq 1");
is(get_status_code("CRITICAL"),   2, "get_status_code(OK) eq 2");
is(get_status_code("UNKNOWN"),    3, "get_status_code(UNKNOWN) eq 3");
is(get_status_code("DEPENDENT"),  4, "get_status_code(DEPENDENT) eq 4");
# This code errors out now
#is(get_status_code("NONEXISTENT"),  undef, "get_status_code(NONEXISTENT) eq undef");

# This should cause compilation failure
#ok(critical("blah"), 'critical("blah")');

# ============================================================================ #
$verbose++;
# TODO: This only checks the sub runs and returns success, should really check it outputs the right thing but not sure how to check the stdout from this sub
ok(status(), "status()");

# ============================================================================ #
ok(!try { print "try\n"; }, "try{}");
ok(!catch { print "caught\n"; }, "catch{}");
ok(catch_quit("catch quit"), "catch_quit()"); 

# ============================================================================ #
ok(autoflush(), "autoflush()");

# ============================================================================ #
ok(assert_array([1,2,3], "test array"), "assert_array()");
ok(assert_float(1.1, "test float"), "assert_floatt(1.1)");
ok(assert_hash({"one" => 1, "two" => 2}, "test hash"), "assert_hash()");
ok(assert_int(10, "test int"), "assert_int(10)");

# ============================================================================ #
#                           O S   H e l p e r s
# ============================================================================ #
ok(isOS($^O),    'isOS($^O)');

if(isLinux()){
    ok($^O eq "linux", 'isLinux()');
}
if(isMac()){
    ok($^O eq "darwin", 'isMac()');
}
if(isLinuxOrMac()){
    ok(($^O eq "linux" or $^O eq "darwin"), "isLinuxOrMac()");
}

if($^O eq "linux"){
    ok(isLinux(), 'isLinux()');
    ok(!isMac(),  'isMac()');
    ok(linux_only());
    ok(linux_mac_only());
}
if($^O eq "darwin"){
    ok(isMac(),     'isMac()');
    ok(!isLinux(),  '!isLinux()');
    ok(mac_only());
    ok(linux_mac_only());
}
if($^O eq "linux" or $^O eq "darwin"){
    ok(isLinuxOrMac(), "isLinuxOrMac()");
    ok(linux_mac_only());
}

# ============================================================================ #

is($port, undef, "\$port starts undef");
ok(set_port_default(80), "set_port_default(80)");
is($port, 80, "\$port eq 80");

# ============================================================================ #
is($warning, undef, "\$warning starts undef");
is($critical, undef, "\$critical starts undef");
ok(set_threshold_defaults(5,10), "set_threshold_defaults(5,10)");
is($warning,   5, "\$warning  eq 5");
is($critical, 10, "\$critical eq 10");

# ============================================================================ #
ok(env_cred("TEST"), "env_cred(TEST)");
ok(env_creds(["TEST","TEST2"], "Testing"), "env_creds([TEST,TEST2], Testing)");

# ============================================================================ #
my $var;
my $var2;
is($var, undef, "\$var starts undef");
is($var2, undef, "\$var2 starts undef");
ok(env_var("HOSTNAME", \$var),   "env_var(HOSTNAME, \\\$var)");
ok(env_vars(["PWD", "HOME", "HOSTNAME"], \$var2),   "env_vars([PWD, HOME, HOSTNAME], \\\$var2)");
is($var,  $ENV{"HOSTNAME"}, "\$var eq \$ENV{HOSTNAME}");
is($var2, $ENV{"PWD"},    "\$var2 eq \$ENV{PWD}");

# ============================================================================ #
ok(cmd("ps"), 'cmd("ps");');
#ok(!cmd("unknown_fake_command"), 'cmd("unknown_fake_command");');

# ============================================================================ #
is_deeply([compact_array(( "one", "" , "two" ))], [ "one", "two" ], 'compact_array() remove blanks');
is_deeply([compact_array(( "one", "\t\r\n" , "two" ))], [ "one", "two" ], 'compact_array() remove ^\s*$');
is_deeply([compact_array(( "one", 0 , "two" ))], [ "one", 0, "two" ], 'compact_array() not remove zero');

# ============================================================================ #
$warning  = 5;
$critical = 10;
ok(validate_thresholds(), 'validate_thresholds()');
ok(check_threshold("warning", 5),   'check_threshold("warning", 5)');
ok(!check_threshold("warning", 6),  '!check_threshold("warning", 6)');
ok(check_threshold("critical", 10),   'check_threshold("critical", 10)');
ok(!check_threshold("critical", 11),   'check_threshold("critical", 11)');
# TODO: check_threshold{,s}, code_error
ok(check_thresholds(4), 'check_thresholds(4)');

ok(check_threshold("these nodes critical", 10),  'check_threshold("these nodes critical", 10)');

# ============================================================================ #
is(check_string("test", "test"),    1,      'check_string("test", "test") eq 1');
is(check_string("test", "testa"),    undef,  '!check_string("test", "testa") eq undef');
is(check_regex("test", '^test$'),   1,      'check_regex("test", "^test$") eq 1');
is(check_regex("test", '^tes$'),    undef,  'check_regex("test", "^tes$") eq undef');

# ============================================================================ #
# TODO: curl onwards
#$verbose = 3;
use_ok("LWP::Simple", 'get');
use LWP::Simple '$ua';
ok(HariSekhonUtils::defined_main_ua(), "defined_main_ua()");
ok(set_http_timeout(5), 'set_http_timeout(5)');
#like(curl("http://www.google.com/"), qr/google.com/, 'curl("www.google.com")');

#is(die(), 2, "die() returns 2");

# ============================================================================ #
$debug = 1;
ok(debug("debug stuff"), 'debug("debug stuff")');
$debug = 0;
ok(!debug("debug stuff"), '!debug("debug stuff") without \$debug set');

# ============================================================================ #
use HariSekhonUtils ':regex';
ok(escape_regex("(.*)\\["), 'escape_regex()');

# ============================================================================ #
is(expand_units("10", "KB"), 10240, 'expand_units("10", "KB") eq 10240');
is(expand_units("10", "mB"), 10485760, 'expand_units("10", "mB") eq 10485760');
is(expand_units("10", "Gb"), 10737418240, 'expand_units("10", "Gb") eq 10737418240');
is(expand_units("10", "tb"), 10995116277760, 'expand_units("10", "tb") eq 10995116277760');
is(expand_units("10", "Pb"), 11258999068426240, 'expand_units("10", "Pb") eq 11258999068426240');

# ============================================================================ #
is(minimum_value(1, 4), 4, 'minimum_value(1,4)');
is(minimum_value(3, 1), 3, 'minimum_value(3,1)');
is(minimum_value(3, 4), 4, 'minimum_value(3,4)');

# ============================================================================ #
$json = {
    "one"    => 1,
    "two"    => 2.2,
    "three"  => [3,2,1],
    "sub"    => { "val" => 4 }
};
my $testHashRef = $json;

# ============================================================================ #
is(get_field("one"),     1,   "get_field(one)");
is(get_field("sub.val"), 4,   "get_field(sub.val)");
is(get_field("sub.nonexistent", "noquit"), undef,   "get_field(sub.nonexistent)");
is(get_field("four", "noquit"), undef,   "get_field(four)");

# ============================================================================ #
is(get_field2($testHashRef,  "one"),     1,   "get_field2(one)");
is(get_field2($testHashRef,  "sub.val"), 4,   "get_field2(four)");
is(get_field2($testHashRef, "sub.nonexistent", "noquit"), undef,   "get_field2(sub.nonexistent)");
is(get_field2($testHashRef, "four", "noquit"), undef,   "get_field2(four)");

# ============================================================================ #
is(get_field_int("one"),                     1,   "get_field_int(one)");
is(get_field2_int($testHashRef,  "one"),     1,   "get_field2_int(one)");
is(get_field_int("two", "noquit"),           undef,   "get_field_int(two)");
is(get_field2_int($testHashRef,  "two", "noquit"), undef,   "get_field2_int(two)");

# ============================================================================ #
is(get_field_float("one"),                     1,   "get_field_float(one)");
is(get_field2_float($testHashRef,  "one"),     1,   "get_field2_float(one)");
is(get_field_float("two"),                     2.2,   "get_field_float(two)");
is(get_field2_float($testHashRef,  "two"),     2.2,   "get_field2_float(two)");
is(get_field_float("three", "noquit"),                     undef,   "get_field_float(two)");
is(get_field2_float($testHashRef,  "three", "noquit"),     undef,   "get_field2_float(two)");

# ============================================================================ #
is_deeply([get_field_array("three")],                     [3,2,1]);# ,   "get_field_array(three)");
is_deeply([get_field2_array($testHashRef,  "three")],     [3,2,1]); #,   "get_field2_array(three)");
is(get_field_array("four", "noquit"),                     undef,   "get_field_array(four)");
is(get_field2_array($testHashRef,  "four", "noquit"),     undef,   "get_field2_array(four)");

# ============================================================================ #
is_deeply({get_field_hash("sub")},                     { "val" => 4 });#,   "get_field_hash(four)");
is_deeply({get_field2_hash($testHashRef,  "sub")},     { "val" => 4 });#,   "get_field2_hash(four)");
is(get_field_hash("one", "noquit"),           undef,   "get_field_hash(one)");
is(get_field2_hash($testHashRef,  "one", "noquit"),  undef,   "get_field2_hash(one)");

# ============================================================================ #
is(human_units(1023),               "1023 bytes",   'human_units(1023) eq "1023 bytes"');
is(human_units(1023*(1024**1)),     "1023KB",       'human_units KB');
is(human_units(1023.1*(1024**2)),   "1023.1MB",    'human_units MB');
is(human_units(1023.2*(1024**3)),   "1023.2GB",    'human_units GB');
is(human_units(1023.31*(1024**4)),  "1023.31TB",    'human_units TB');
is(human_units(1023.012*(1024**5)), "1023.01PB",    'human_units PB');
is(human_units(1023*(1024**6)), "1023EB", 'human_units EB"');

# ============================================================================ #
is(month2int("Jan"),  0, 'month2int(Jan)');
is(month2int("Feb"),  1, 'month2int(Feb)');
is(month2int("Mar"),  2, 'month2int(Mar)');
is(month2int("Apr"),  3, 'month2int(Apr)');
is(month2int("May"),  4, 'month2int(May)');
is(month2int("Jun"),  5, 'month2int(Jun)');
is(month2int("Jul"),  6, 'month2int(Jul)');
is(month2int("Aug"),  7, 'month2int(Aug)');
is(month2int("Sep"),  8, 'month2int(Sep)');
is(month2int("Oct"),  9, 'month2int(Oct)');
is(month2int("Nov"), 10, 'month2int(Nov)');
is(month2int("Dec"), 11, 'month2int(Dec)');

# ============================================================================ #
ok(get_options());

# ============================================================================ #
is(get_path_owner("/etc/passwd"), "root", 'get_path_owner("/etc/passwd") eq "root"');

# ============================================================================ #

is(perf_suffix("blah_in_bytes"),    "b",    'perf_suffix("blah_in_bytes")');
is(perf_suffix("blah_in_millis"),   "ms",   'perf_suffix("blah_in_millis")');
is(perf_suffix("blah.bytes"),       "b",    'perf_suffix("blah.bytes")');
is(perf_suffix("blah.millis"),      "ms",   'perf_suffix("blah.millis")');
is(perf_suffix("blah.blah2"),       "",     'perf_suffix("blah.blah2")');

# ============================================================================ #
is(get_upper_threshold("warning"),   "5",     'get_upper_threshold(warning)');
is(get_upper_threshold("critical"),  "10",    'get_upper_threshold(critical)');
is(get_upper_thresholds(),           "5;10",  'get_upper_thresholds()');

# ============================================================================ #
ok(go_flock_yourself(), "go_flock_yourself()");
ok(flock_off(), "flock_off()");

ok(hr(), 'hr()');

# ============================================================================ #
ok(inArray("one", qw/one two three/), 'inArray("one", qw/one two three/)');
ok(!inArray("four", qw/one two three/), '!inArray("four", qw/one two three/)');

ok(isArray([qw/one two/]), 'isArray([qw/one two/])');
ok(!isArray($verbose),  '!isArray(\$verbose)');

# ============================================================================ #
ok(HariSekhonUtils::isCode(sub{}), 'HariSekhonUtils::isCode(sub{})');
ok(HariSekhonUtils::isSub(sub{}), 'HariSekhonUtils::isCode(sub{})');

ok(!HariSekhonUtils::isCode(1), '!HariSekhonUtils::isCode(1)');
ok(!HariSekhonUtils::isSub(1), '!HariSekhonUtils::isSub(1)');


# ============================================================================ #
is(isAlNum("ABC123efg"),    "ABC123efg",    'isAlNum("ABC123efg") eq "ABC123efg"');
is(isAlNum("0"),            0,              'isAlNum("0") eq 0');
is(isAlNum("1.2"),          undef,          'isAlNum("1.2") eq undef');
is(isAlNum(""),             undef,          'isAlNum("") eq undef');
is(isAlNum("hari\@domain.com"), undef,      'isAlNum("hari@domain.com") eq undef');

is(validate_alnum("Alnum2Test99", "alnum test"),    "Alnum2Test99",   'validate_alnum("Alnum2Test99", "alnum test") eq "Alnum2Test99"');
is(validate_alnum("0", "alnum zero"),    "0",   'validate_alnum("0", "alnum zero") eq "0"');


# ============================================================================ #
is(isAwsAccessKey("A"x20),             "A"x20,         'isAwsAccessKey("A"x20)  eq "A"  x20');
is(isAwsAccessKey("1"x20),             "1"x20,         'isAwsAccessKey("1"x20)  eq "1"  x20');
is(isAwsAccessKey("A1"x10),            "A1"x10,        'isAwsAccessKey("A1"x10) eq "A1" x10');
is(isAwsAccessKey("@"x20),             undef,          'isAwsAccessKey("@"x20)  eq undef');
is(isAwsAccessKey("A"x40),             undef,          'isAwsAccessKey("A"x40)  eq undef');
is(isAwsSecretKey("A"x40),             "A"x40,         'isAwsSecretKey("A"x40)  eq "A" x40');
is(isAwsSecretKey("1"x40),             "1"x40,         'isAwsSecretKey("1"x40)  eq "1" x40');
is(isAwsSecretKey("A1"x20),            "A1"x20,        'isAwsSecretKey("A1"x20) eq "A1"x20');
is(isAwsSecretKey("@"x40),             undef,          'isAwsSecretKey("@"x40)  eq undef');
is(isAwsSecretKey("A"x20),             undef,          'isAwsSecretKey("A"x20)  eq undef');

is(validate_aws_access_key("A"x20),     "A"x20,         'validate_aws_access_key("A"x20) eq "A"x20');
is(validate_aws_bucket("BucKeT63"),     "BucKeT63",     'validate_aws_bucket("BucKeT63") eq "BucKeT63"');
is(validate_aws_secret_key("A"x40),     "A"x40,         'validate_aws_secret_key("A"x40) eq "A"x40');
is(validate_aws_secret_key("1"x40),     "1"x40,         'validate_aws_secret_key("1"x40) eq "1"x40');
is(validate_aws_secret_key("A1"x20),    "A1"x20,        'validate_aws_secret_key("A1"x20) eq "A1"x20');

# ============================================================================ #
is(isChars("Alpha-01_", "A-Za-z0-9_-"), "Alpha-01_", 'isChars("Alpha-01_", "A-Za-z0-9_-"), eq Alpha-01_');
is(isChars("Alpha-01_*", "A-Za-z0-9_-"), undef,      'isChars("Alpha-01_", "A-Za-z0-9_-*"), eq undef');

is(validate_chars("log_date=2015-05-23_10", "validate chars", "A-Za-z0-9_=-"), "log_date=2015-05-23_10", 'validate_chars("log_date=2015-05-23_10", "validate chars", "A-Za-z0-9_=-") eq "log_date=2015-05-23_10"');

# ============================================================================ #
is(isCollection("students.grades"),    "students.grades",  'isCollection("students.grades") eq students.grades');
is(isCollection("wrong\@.grades"),     undef,              'isCollection("wrong@.grades") eq undef');

is(validate_collection("students.grades"),      "students.grades",  'validate_collection("students.grades")');

# ============================================================================ #
is(isDatabaseName("mysql1"),   "mysql1",       'isDatabaseName("mysql1") eq mysql1');
is(isDatabaseName("my\@sql"),  undef,          'isDatabaseName("my@sql") eq undef');

is(validate_database("mysql", "MySQL"),         "mysql",        'validate_database("mysql")');

# ============================================================================ #
is(isDatabaseColumnName("myColumn_1"),  "myColumn_1",   'isDatabaseColumnName("myColumn_1") eq myColumn_1');
is(isDatabaseColumnName("'column'"),    undef,          'isDatabaseColumnName("\'column\'") eq undef');

is(validate_database_columnname("myColumn_1"), "myColumn_1", 'validate_database_columnname()');

# ============================================================================ #
# rely on this for MySQL field by position
is(isDatabaseFieldName("age"),          "age",            'isDatabaseFieldName("age")');
is(isDatabaseFieldName(2),              "2",            'isDatabaseFieldName(2)');
is(isDatabaseFieldName("count(*)"),     "count(*)",     'isDatabaseFieldName("count(*)")');
is(isDatabaseFieldName("\@something"),  undef,          'isDatabaseFieldName("@something")');

is(validate_database_fieldname("age"),          "age",          'validate_database_fieldname(age)');
is(validate_database_fieldname(10),             10,             'validate_database_fieldname(10)');
is(validate_database_fieldname("count(*)"),     "count(*)",     'validate_database_fieldname("count(*)")');

# ============================================================================ #
is(isDatabaseTableName("myTable_1"),                "myTable_1",            'isDatabaseTableName("myTable_1") eq myTable_1');
is(isDatabaseTableName("'table'"),                  undef,                  'isDatabaseTableName("\'table\'") eq undef');
is(isDatabaseTableName("default.myTable_1", 1),     "default.myTable_1",    'isDatabaseTableName("default.myTable_1", 1) eq default.myTable_1');
is(isDatabaseTableName("default.myTable_1", 0),     undef,                  'isDatabaseTableName("default.myTable_1", 0) eq undef');
is(isDatabaseTableName("default.myTable_1"),        undef,                  'isDatabaseTableName("default.myTable_1")    eq undef');

is(validate_database_tablename("myTable", "Hive"), "myTable",   'validate_database_tablename("myTable", "Hive") eq myTable');
is(validate_database_tablename("default.myTable", "Hive", "allow qualified"), "default.myTable",     'validate_database_tablename("default.myTable", "Hive", "allow qualified") eq default.myTable');

# ============================================================================ #
is(isDatabaseViewName("myView_1"),                "myView_1",            'isDatabaseViewName("myView_1") eq myView_1');
is(isDatabaseViewName("'view'"),                  undef,                  'isDatabaseViewName("\'view\'") eq undef');
is(isDatabaseViewName("default.myView_1", 1),     "default.myView_1",    'isDatabaseViewName("default.myView_1", 1) eq default.myView_1');
is(isDatabaseViewName("default.myView_1", 0),     undef,                  'isDatabaseViewName("default.myView_1", 0) eq undef');
is(isDatabaseViewName("default.myView_1"),        undef,                  'isDatabaseViewName("default.myView_1")    eq undef');

is(validate_database_viewname("myView", "Hive"), "myView",      'validate_database_viewname("myView", "Hive") eq View');
is(validate_database_viewname("default.myTable", "Hive", "allow qualified"), "default.myTable",     'validate_database_viewname("default.myTable", "Hive", "allow qualified") eq default.myTable');

# ============================================================================ #

ok(validate_database_query_select_show("select * from myTable"));
ok(validate_database_query_select_show("select count(*) from db.MyTable"));
ok(validate_database_query_select_show("select count(*) from db.created_date"));
ok(validate_database_query_select_show("select count(*) from product_updates"));

# ============================================================================ #
is(isDirname("test_Dir"),  "test_Dir",  "isDirname(test_Dir)");
is(isDirname("/tmp/test"), "/tmp/test", "isDirname(/tmp/test");
is(isDirname("./test"),    "./test",    "isDirname(./test");
is(isDirname("\@me"),      undef,       "isDirname(\@me)");

is(validate_dirname("test_Dir"),    "test_Dir",      'validate_dirname("test_Dir")');
is(validate_dirname("/tmp/test"),    "/tmp/test",    'validate_dirname("/tmp/test")');
is(validate_dirname("/nonexistentdir", "name", "noquit"),    "/nonexistentdir",  'validate_dirname("/nonexistentdir", "noquit")');

is(validate_directory("./t"),       "./t",      'validate_directory("./t")');
if(isLinuxOrMac()){
    is(validate_directory("/etc"),      "/etc",     'validate_directory("/etc")');
    is(validate_directory("/etc/"),     "/etc/",    'validate_directory("/etc/")');
    is(validate_dir("/etc/"),           "/etc/",    'validate_dir("/etc/")');
}
is(validate_directory('b@ddir', "name", "noquit"), undef,      'validate_directory(b@ddir)');
# cannot validate dir not existing here as it terminates program

# ============================================================================ #
is(isDomain("localDomain"),     "localDomain",      'isDomain("localDomain") eq localDomain');
is(isDomain("domain.local"),    "domain.local",     'isDomain("domain.local") eq domain.local');
is(isDomain("harisekhon.com"),  "harisekhon.com",   'isDomain("harisekhon.com") eq harisekhon.com');
is(isDomain("1harisekhon.com"), "1harisekhon.com",  'isDomain("1harisekhon.com") eq 1harisekhon.com');
is(isDomain("com"),             "com",              'isDomain("com") eq "com"');
is(isDomain("a"x63 . ".com"),   "a"x63 . ".com",    'isDomain("a"x63 . ".com") eq "a"x63 . ".com"');
is(isDomain("a"x64),            undef,              'isDomain("a"x64) eq undef');
is(isDomain("harisekhon"),      undef,              'isDomain("harisekhon") eq undef'); # not a valid TLD
is(isDomain("compute.internal"),            'compute.internal',             'isDomain("compute.internal")');
is(isDomain("eu-west-1.compute.internal"),  'eu-west-1.compute.internal',   'isDomain("eu-west-1.compute.internal")');
# programs use isDomain2, keep until updating them
is(isDomain2("com"),            undef,              'isDomain2("com") eq undef');
is(isDomain2("123domain.com"),  "123domain.com",    'isDomain2("123domain.com") eq 123domain.com');
is(isDomain2("domain.local"),   "domain.local",     'isDomain2("domain.local") eq domain.local');
is(isDomainStrict("com"),            undef,              'isDomainStrict("com") eq undef');
is(isDomainStrict("domain.com"),     "domain.com",       'isDomainStrict("domain.com") eq domain.com');
is(isDomainStrict("domain.local"),   "domain.local",     'isDomainStrict("domain.local") eq domain.local');
is(isDomainStrict("domain.localDomain"), "domain.localDomain", 'isDomainStrict("domain.local") eq domain.localDomain');

is(validate_domain("harisekhon.com"),  "harisekhon.com",    'validate_domain("harisekhon.com") eq harisekhon.com');

# ============================================================================ #
is(isDnsShortname("myHost"),    "myHost",   'isDnsShortname("myHost") eq "myHost"');
is(isDnsShortname("myHost.domain.com"),    undef,   'isDnsShortname("myHost.domain.com") eq undef');

# ============================================================================ #
is(isEmail('hari\'sekhon@gmail.com'),   'hari\'sekhon@gmail.com',   'isEmail("hari\'sekhon@gmail.com") eq hari\'sekhon@gmail.com');
is(isEmail('hari@LOCALDOMAIN'),         'hari@LOCALDOMAIN',         'isEmail("hari@LOCALDOMAIN") eq hari@LOCALDOMAIN');
is(isEmail("harisekhon"),               undef,                      '!isEmail("harisekhon") eq undef');

is(validate_email('harisekhon@domain.com'),      'harisekhon@domain.com',     'validate_email(\'harisekhon@domain.com\')');

# ============================================================================ #
is(isFilename("some_File.txt"),  "some_File.txt",   "isFilename(some_File.txt");
is(isFilename("/tmp/te-st"),     "/tmp/te-st",      "isFilename(/tmp/te-st");
is(isFilename("\@me"),           undef,             "isFilename(\@me)");

# ============================================================================ #
is(validate_filename("/etc/passwd"),             "/etc/passwd",              'validate_filename("/etc/passwd")');
is(validate_filename("/etc/nonexistentfile"),    "/etc/nonexistentfile",     'validate_filename("/etc/nonexistentfile")');
is(validate_filename("/etc/passwd/", "name", "noquit"),            undef,    'validate_filename("/etc/passwd/", "name", "noquit")');

# ============================================================================ #
is(validate_file("HariSekhonUtils.pm"),        "HariSekhonUtils.pm",  'validate_file("HariSekhonUtils.pm")');
if(isLinuxOrMac()){
    is(validate_file("/etc/passwd"),           "/etc/passwd",   'validate_file("/etc/passwd")');
}
is(validate_file("/etc/nonexistentfile", "name", "noquit"),    undef,          'validate_file("/etc/nonexistentfile", 1) eq undef');

# ============================================================================ #

my $stats = {
    "one" => 1,
    "two" => "2",
    "three" => "three",
    "four" => {
        "five" => 6
    },
    "six" => ["0", 1, "one", 2]
};
my %expectedFlattenedStats = ( "one" => 1, "two" => 2, "four.five" => 6, "six.0" => 0, "six.1" => 1, "six.3" => 2 );
#my %flattenedStats = flattenStats( { "seven" => [qw/3 4 5/], "one" => "two", "three" => { "four" => "five" }, "six" => [0, 1, 2] } );
my %flattenedStats = flattenStats($stats);
#use Data::Dumper;
#print "flattened stats:\n";
#print Dumper(\%flattenedStats);
#print Dumper($stats);
is_deeply(\%flattenedStats, \%expectedFlattenedStats, 'flattenStats()');

# ============================================================================ #
ok(isFloat(1),          'isFloat(1)');
ok(!isFloat(-1),        '!isFloat(-1)');
ok(isFloat(-1, 1),      'isFloat(-1, 1)');

ok(isFloat(1.1),        'isFloat(1.1)');
ok(!isFloat(-1.1),      '!isFloat(-1.1)');
ok(isFloat(-1.1, 1),    'isFloat(-1.1, 1)');

ok(!isFloat("2a"),     '!isFloat("2a")');
ok(!isFloat("a2"),     '!isFloat("a2")');
ok(!isFloat("nan"),     '!isFloat("nan")');
ok(!isFloat("nan", 1),  '!isFloat("nan", 1)');

is(validate_float(2,"two",0,10),            2,      'validate_float(2,"two",0,10)');
is(validate_float(-2,"minus-two",-10,10),   -2,     'validate_float(-2,"minus-two",-10,10)');
is(validate_float(2.1,"two-float",0,10),    2.1,    'validate_float(2.1,"two-float",0,10)');
is(validate_float(6.8,"six-float",5,10),    6.8,    'validate_float(6.8,"six",5,10)');
is(validate_float(-6,"minus-six",-6,0),     -6,     'validate_float(-6,"minus-six",-6,0)');
# should error out
#is(validate_float(3,"three",4,10),  0,  'validate_float(3,"three",4,10)');

# ============================================================================ #
is(isFqdn("hari.sekhon.com"),   "hari.sekhon.com",  'isFqdn("hari.sekhon.com") eq harisekhon.com');
# denying this results in failing host.local as well
is(isFqdn("hari\@harisekhon.com"),    undef,        'isFqdn("hari\@harisekhon.com") eq undef');

is(validate_fqdn("www.harisekhon.com"),     "www.harisekhon.com",      'validate_fqdn("www.harisekhon.com")');
# permissive because of short tld style internal domains
is(validate_fqdn("myhost.local"),         "myhost.local",          'validate_fqdn("myhost.local")');

# ============================================================================ #
ok(isHash({ "one" => 1 }), "isHash({one=>1})");
ok(isHash({}), "isHash({})");
ok(!isHash(\{}), "isHash(\\{})");
ok(!isHash("one"),   "!isHash(one)");
ok(!isHash(1),       "!isHash(1)");

# ============================================================================ #
ok(isHex("0xAf09b"), 'isHex');
ok(!isHex("0xhari"), '!isHex("hari")');
ok(isHex(0),         'isHex(0)');
ok(!isHex("g"),       '!isHex(g)');

# ============================================================================ #
is(isHost("harisekhon.com"),    "harisekhon.com",   'isHost("harisekhon.com") eq harisekhon.com');
ok(isHost("harisekhon"),        'isHost("harisekhon")');
ok(isHost("ip-172-31-1-1"),     'isHost("ip-172-31-1-1")');
ok(isHost("10.10.10.1"),        'isHost("10.10.10.1")');
is(isHost("10.10.10.10"),       "10.10.10.10",      'isHost("10.10.10.10") eq 10.10.10.10');
ok(isHost("10.10.10.100"),      'isHost("10.10.10.100")');
ok(isHost("10.10.10.0"),        'isHost("10.10.10.0")');
ok(isHost("10.10.10.255"),      'isHost("10.10.10.255")');
ok(!isHost("NO_SERVER_AVAILABLE"), '!isHost("NO_SERVER_AVAILABLE")');
ok(!isHost("NO_HOST_AVAILABLE"), '!isHost("NO_HOST_AVAILABLE")');
ok(!isHost("10.10.10.256"),     '!isHost("10.10.10.256")');
ok(!isHost("a"x256),            '!isHost("a"x256)');

is(isAwsHostname("ip-172-31-1-1"),      "ip-172-31-1-1",    'isAwsHostname("ip-172-31-1-1")');
is(isAwsHostname("ip-172-31-1-1.eu-west-1.compute.internal"), "ip-172-31-1-1.eu-west-1.compute.internal", 'isAwsHostname("ip-172-31-1-1.eu-west-1.compute.internal")');
is(isAwsHostname("harisekhon"),        undef,              'isAwsHostname("harisekhon")');
is(isAwsHostname("10.10.10.1"),        undef,              'isAwsHostname("10.10.10.1")');

is(isAwsFqdn("ip-172-31-1-1.eu-west-1.compute.internal"),   "ip-172-31-1-1.eu-west-1.compute.internal", 'isAwsFqdn("ip-172-31-1-1.eu-west-1.compute.internal")');
is(isAwsFqdn("ip-172-31-1-1"),          undef,              'isAwsFqdn("ip-172-31-1-1")');

is(validate_host("10.10.10.10"),            "10.10.10.10",          'validate_host(10.10.10.10)');
is(validate_host("myHost"),                 "myHost",               'validate_host(myHost)');
is(validate_host("myHost.myDomain.com"),    "myHost.myDomain.com",  'validate_host(myHost.myDomain.com)');

# ============================================================================ #
is(isHostname("harisekhon.com"),  "harisekhon.com",   'isHostname("harisekhon.com") eq harisekhon.com');
is(isHostname("harisekhon"),      "harisekhon",       'isHostname("harisekhon")');
is(isHostname("a"),               "a", 'isHostname("a") eq a');
is(isHostname("1"),               "1", 'isHostname("1") eq 1');
is(isHostname("harisekhon1.com"), "harisekhon1.com", 'isHostname(harisekhon1.com) eq harisekhon1.com');
is(isHostname("1harisekhon.com"), "1harisekhon.com", 'isHostname(1harisekhon.com) eq 1harisekhon.com');
is(isHostname("NO_SERVER_AVAILABLE"), undef, '!isHostname("NO_SERVER_AVAILABLE")');
is(isHostname("NO_HOST_AVAILABLE"),   undef, '!isHostname("NO_HOST_AVAILABLE")');
is(isHostname("-help"),           undef, 'isHostname(-help) eq undef');
is(isHostname("a"x63),            "a"x63, 'isHostname("a"x63) eq "a"x63');
is(isHostname("a"x64),            undef, 'isHostname("a"x64) eq undef');
is(isHostname("hari~sekhon"),     undef, 'isHostname(hari~sekhon) eq undef');

is(validate_hostname("myHost"),              "myHost",                    'validate_hostname(myHost)');
is(validate_hostname("myHost.myDomain.com"), "myHost.myDomain.com",       'validate_hostname(myHost.myDomain.com)');
is(validate_hostname("harisekhon1.com"),     "harisekhon1.com",           'validate_hostname(harisekhon1.com) eq harisekhon1.com');
is(validate_hostname("a"x63),                "a"x63,                      'validate_hostname("a"x63) eq "a"x63');

# ============================================================================ #
ok(isInt(0),    'isInt(0)');
ok(isInt(1),    'isInt(1)');
ok(!isInt(-1),  '!isInt(-1)');
ok(!isInt(1.1), '!isInt(1.1)');
ok(!isInt("a"), '!isInt("a")');

is(validate_int(2,"two",0,10),    2,  'validate_int(2,"two",0,10)');
is(validate_int(-2,"minus-two",-10,10),    -2,  'validate_int(-2,"minus-two",-10,10)');
# should error out
#is(validate_int(2.1,0,10,"two-float"),  0,  'validate_int(2.0,"two-float",0,10)');
is(validate_int(6,"six",5,10),    6,  'validate_int(6,"six",5,10)');
is(validate_int(-6,"minus-six",-6,0),    -6,  'validate_int(-6,"minus-six",-6,0)');
is(validate_integer(2,"two",0,10),    2,  'validate_integer(2,"two",0,10)');
is(validate_integer(6,"six",5,7),    6,  'validate_integer(6,"six",5,7)');
# should error out
#is(validate_int(3,"three",4,10),  0,  'validate_int(3,"three",4,10)');

# ============================================================================ #
is(isInterface("eth0"),     "eth0",     'isInterface("eth0")');
is(isInterface("bond3"),    "bond3",    'isInterface("bond3")');
is(isInterface("lo"),       "lo",       'isInterface("lo")');
is(isInterface("docker0"),  "docker0",  'isInterface("docker0")');
is(isInterface("vethfa1b2c3"), "vethfa1b2c3", 'isInterface("vethfa1b2c3")');
ok(!isInterface("vethfa1b2z3"), 'isInterface("vethfa1b2z3")');
ok(!isInterface('b@interface'), '!isInterface(\'b@dinterface\'');

is(validate_interface("eth0"),     "eth0",     'validate_interface("eth0")');
is(validate_interface("bond3"),    "bond3",    'validate_interface("bond3")');
is(validate_interface("lo"),       "lo",       'validate_interface("lo")');
is(validate_interface("docker0"),    "docker0",    'validate_interface("docker0")');
is(validate_interface("vethfa1b2c3"), "vethfa1b2c3", 'validate_interface("vethfa1b2c3")');

# ============================================================================ #
is(isIP("10.10.10.1"),      "10.10.10.1",       'isIP("10.10.10.1") eq 10.10.10.1');
is(isIP("10.10.10.10"),     "10.10.10.10",      'isIP("10.10.10.10") eq 10.10.10.10');
is(isIP("10.10.10.100"),    "10.10.10.100",     'isIP("10.10.10.100") eq 10.10.10.100');
is(isIP("254.0.0.254"),     "254.0.0.254",      'isIP("254.0.0.254") eq 254.0.0.254');
is(isIP("255.255.255.254"), "255.255.255.254",  'isIP("255.255.255.254") eq 255.255.255.254');
# may be entirely valid depending on the CIDR subnet mask
is(isIP("10.10.10.0"),      "10.10.10.0",       'isIP("10.10.10.0") eq undef');
is(isIP("10.10.10.255"),    "10.10.10.255",     'isIP("10.10.10.255") eq 10.10.10.255');
is(isIP("10.10.10.256"),     undef,             'isIP("10.10.10.256") eq undef');
is(isIP("x.x.x.x"),          undef,             'isIP("x.x.x.x") eq undef');

is(validate_ip("10.10.10.1"),        "10.10.10.1",       'validate_ip("10.10.10.1")');
is(validate_ip("10.10.10.10"),       "10.10.10.10",      'validate_ip("10.10.10.10") eq 10.10.10.10');
is(validate_ip("10.10.10.100"),      "10.10.10.100",     'validate_ip("10.10.10.100")');
is(validate_ip("10.10.10.0"),        "10.10.10.0",       'validate_ip("10.10.10.0")');
is(validate_ip("10.10.10.255"),      "10.10.10.255",     'validate_ip("10.10.10.255")');
is(validate_ip("255.255.255.254"),   "255.255.255.254",  'validate_ip("255.255.255.254")');

# ============================================================================ #
is(isJavaBean("java.lang:type=Memory"), "java.lang:type=Memory", 'isJavaBean("java.lang:type=Memory") eq java.lang:type=Memory');
is(isJavaBean("Hadoop:service=NameNode,name=FSNamesystem"), "Hadoop:service=NameNode,name=FSNamesystem", 'isJavaBean("Hadoop:service=NameNode,name=FSNamesystem") eq Hadoop:service=NameNode,name=FSNamesystem');
is(isJavaBean("Hadoop:service=DataNode,name=DataNodeActivity-sandbox.hortonworks.com-50010"), "Hadoop:service=DataNode,name=DataNodeActivity-sandbox.hortonworks.com-50010", 'isJavaBean("Hadoop:service=DataNode,name=DataNodeActivity-sandbox.hortonworks.com-50010") eq Hadoop:service=DataNode,name=DataNodeActivity-sandbox.hortonworks.com-50010 ');
is(isJavaBean("1hari"),                 undef,                   'isJavaBean("1hari") eq undef');

is(validate_java_bean("java.lang:type=Memory"), "java.lang:type=Memory", 'validate_java_bean(java.lang:type=Memory) eq java.lang:type=Memory');
#is(validate_java_bean("hari:"), undef, 'validate_java_bean("hari:") eq undef');

# ============================================================================ #
ok(isJavaException("        at org.apache.ambari.server.api.services.stackadvisor.StackAdvisorRunner.runScript(StackAdvisorRunner.java:96)"), 'isJavaException(" at org.apache.ambari.server...."');
ok(!isJavaException("blah"), '!isJavaException("blah")');

# ============================================================================ #
ok(isJson('{ "test": "data" }'),   'isJson({ "test": "data" })');
ok(isJson('{}'),   'isJson({})');
ok(!isJson(' { "test": }'),        '!isJson({ "test": })');

# ============================================================================ #
is(isKrb5Princ('tgt/HARI.COM@HARI.COM'),        'tgt/HARI.COM@HARI.COM',        'isKrb5Princ("tgt/HARI.COM@HARI.COM") eq "tgt/HARI.COM@HARI.COM"');
is(isKrb5Princ('hari'),                         'hari',                         'isKrb5Princ("hari") eq "hari"');
is(isKrb5Princ('hari@HARI.COM'),                'hari@HARI.COM',                'isKrb5Princ("hari@HARI.COM") eq "hari@HARI.COM"');
is(isKrb5Princ('hari/my.host.local@HARI.COM'),  'hari/my.host.local@HARI.COM',  'isKrb5Princ("hari/my.host.local@HARI.COM") eq "hari/my.host.local@HARI.COM"');
is(isKrb5Princ('cloudera-scm/admin@REALM.COM'),  'cloudera-scm/admin@REALM.COM', 'isKrb5Princ("cloudera-scm/admin@REALM.COM")');
is(isKrb5Princ('cloudera-scm/admin@SUB.REALM.COM'),  'cloudera-scm/admin@SUB.REALM.COM', 'isKrb5Princ("cloudera-scm/admin@SUB.REALM.COM")');
is(isKrb5Princ('hari@hari.com'), 'hari@hari.com', 'isKrb5Princ("hari@hari.com")');
is(isKrb5Princ('hari$HARI.COM'), undef, 'isKrb5Princ("hari$HARI.COM")');

is(validate_krb5_princ('tgt/HARI.COM@HARI.COM'),        'tgt/HARI.COM@HARI.COM',        'validate_krb5_princ("tgt/HARI.COM@HARI.COM") eq "tgt/HARI.COM@HARI.COM"');
is(validate_krb5_princ('hari'),                         'hari',                         'validate_krb5_princ("hari") eq "hari"');
is(validate_krb5_princ('hari@HARI.COM'),                'hari@HARI.COM',                'validate_krb5_princ("hari@HARI.COM") eq "hari@HARI.COM"');
is(validate_krb5_princ('hari/my.host.local@HARI.COM'),  'hari/my.host.local@HARI.COM',  'validate_krb5_princ("hari/my.host.local@HARI.COM") eq "hari/my.host.local@HARI.COM"');
is(validate_krb5_princ('cloudera-scm/admin@REALM.COM'),  'cloudera-scm/admin@REALM.COM', 'validate_krb5_princ("cloudera-scm/admin@REALM.COM")');
is(validate_krb5_princ('cloudera-scm/admin@SUB.REALM.COM'),  'cloudera-scm/admin@SUB.REALM.COM', 'validate_krb5_princ("cloudera-scm/admin@SUB.REALM.COM")');
is(validate_krb5_princ('hari@hari.com'), 'hari@hari.com', 'validate_krb5_princ("hari@hari.com")');

is(validate_krb5_realm("harisekhon.com"),  "harisekhon.com",    'validate_krb5_realm("harisekhon.com") eq harisekhon.com');

# ============================================================================ #
is(isLabel("st4ts_used (%)"),    "st4ts_used (%)",    'isLabel("st4ts_used (%)")');
ok(!isLabel('b@dlabel'),                            'isLabel(\'b@dlabel\')');
ok(!isLabel(''));
ok(!isLabel(' '));

is(validate_label("st4ts_used (%)"),    "st4ts_used (%)",    'validate_label("st4ts_used (%)")');

# ============================================================================ #
is(isLdapDn("uid=hari,cn=users,cn=accounts,dc=local"),   "uid=hari,cn=users,cn=accounts,dc=local", 'isLdapDn()');
is(isLdapDn("hari\@LOCAL"), undef, '!isLdapDn()');

is(validate_ldap_dn("uid=hari,cn=users,cn=accounts,dc=local"),   "uid=hari,cn=users,cn=accounts,dc=local", 'validate_ldap_dn()');

# ============================================================================ #
is_deeply([validate_metrics("gauges.waiting.count,gauges.total.used,gauges.waiting.count")], [ "gauges.total.used", "gauges.waiting.count" ], 'validate_metrics()');

# ============================================================================ #

is(isMinVersion('1.3.0', '1.3'), '1.3'); #, 'isMinVersion(1.3.0)');
is(isMinVersion('1.3.0-alpha', '1.3'), '1.3', 'isMinVersion(1.3.0-alpha');
is(isMinVersion('1.3', '1.3'), '1.3', 'isMinVersion(1.3)');
is(isMinVersion('1.4', '1.3'), '1.4', 'isMinVersion(1.4)');
is(isMinVersion('1.3.1', '1.2'), '1.3', 'isMinVersion(1.3.1)');
is(isMinVersion('1.3.1', 1.2), '1.3', 'isMinVersion(1.3.1)');
is(isMinVersion('1.3.1', '1.4'), undef);
is(isMinVersion('1.2.99', '1.3'), undef);

# ============================================================================ #
is(isNagiosUnit("s"),   "s",    'isNagiosUnit(s) eq s');
is(isNagiosUnit("ms"),  "ms",   'isNagiosUnit(s) eq ms');
is(isNagiosUnit("us"),  "us",   'isNagiosUnit(us) eq us');
is(isNagiosUnit("B"),   "B",    'isNagiosUnit(B) eq B');
is(isNagiosUnit("KB"),  "KB",   'isNagiosUnit(s) eq KB');
is(isNagiosUnit("MB"),  "MB",   'isNagiosUnit(MB) eq MB');
is(isNagiosUnit("GB"),  "GB",   'isNagiosUnit(GB) eq GB');
is(isNagiosUnit("TB"),  "TB",   'isNagiosUnit(TB) eq TB');
is(isNagiosUnit("c"),   "c",    'isNagiosUnit(c) eq c');
is(isNagiosUnit("%"),   "%",    'isNagiosUnit(%) eq %');
is(isNagiosUnit("Kbps"), undef, 'isNagiosUnit(Kbps) eq undef');

# Not sure if I can relax the case sensitivity on these according to the Nagios Developer guidelines
is(validate_units("s"),     "s",    'validate_units("s")');
is(validate_units("ms"),    "ms",   'validate_units("ms")');
is(validate_units("us"),    "us",   'validate_units("us")');
is(validate_units("B"),     "B",    'validate_units("B")');
is(validate_units("KB"),    "KB",   'validate_units("KB")');
is(validate_units("MB"),    "MB",   'validate_units("MB")');
is(validate_units("GB"),    "GB",   'validate_units("GB")');
is(validate_units("TB"),    "TB",   'validate_units("TB")');
is(validate_units("c"),     "c",    'validate_units("c")');
is(validate_units("%"),     "%",    'validate_units("%")');
# should error out
#is(validate_units("a"),     "c",    'validate_units("c")');

# ============================================================================ #
is(isNoSqlKey("HariSekhon:check_riak_write.pl:riak1:1385226607.02182:20abc"), "HariSekhon:check_riak_write.pl:riak1:1385226607.02182:20abc", 'isNoSqlKey() eq $key');
is(isNoSqlKey("HariSekhon\@check_riak_write.pl"), undef, 'isNoSqlKey("...@...") eq undef');

# should error out with "node list empty"
is(validate_nosql_key("HariSekhon:check_riak_write.pl:riak1:1385226607.02182:20abc"), "HariSekhon:check_riak_write.pl:riak1:1385226607.02182:20abc", 'validate_nosql_key()');

# ============================================================================ #

ok(isPathQualified("./blah"), 'isPathQualified("./blah")');
ok(isPathQualified("/blah"),  'isPathQualified("/blah")');
ok(isPathQualified("./path/to/blah.txt"), 'isPathQualified("./path/to/blah")');
ok(isPathQualified("/path/to/blah.txt"),  'isPathQualified("/path/to/blah")');
ok(isPathQualified("/tmp/.blah"),  'isPathQualified("/tmp/.blah")');
ok(!isPathQualified("blah"),  'isPathQualified("blah")');
ok(!isPathQualified(".blah"),  'isPathQualified(".blah")');
ok(!isPathQualified("#tmpfile#"),  'isPathQualified("#tmpfile#")');
ok(!isPathQualified("Europe/London"),  'isPathQualified("Europe/London")');
# not supporting tilda home dirs
ok(!isPathQualified("~blah"),  'isPathQualified("~blah")');

# ============================================================================ #
is(isPort(1),       1,      'isPort(1)');
is(isPort(80),      80,     'isPort(80)');
is(isPort(65535),   65535,  'isPort(65535)');
is(isPort(65536),   undef,  '!isPort(65536)');
is(isPort("a"),     undef,  'isPort("a")');
is(isPort(-1),      undef,  'isPort(-1)');
is(isPort(0),       undef,  'isPort(0)');

is(validate_port(1),           1,      'validate_port(1)');
is(validate_port(80),          80,     'validate_port(80)');
is(validate_port(65535),       65535,  'validate_port(65535)');

# ============================================================================ #
my $obj = {};
#is(isObject(bless($obj)), bless($obj), 'isObject()');
#is(isObject(1), undef, '!isObject()');

#ok(isRef($obj), 'isRef()');
#is(isRef($obj, "noquit"), undef, 'isRef()');

# ============================================================================ #
is(isProcessName("../my_program"),      "../my_program",        'isProcessName("../my_program")');
is(isProcessName("ec2-run-instances"),  "ec2-run-instances",    'isProcessName("ec2-run-instances")');
ok(isProcessName("sh <defunct>"),   'isProcessName("sh <defunct>")');
ok(!isProcessName("./b\@dfile"),    '!isProcessName("./b@dfile")');
ok(!isProcessName("[init] 3"),      '!isProcessName("[init] 3")');
ok(!isProcessName("  "),      '!isProcessName("  ")');

is(validate_process_name("../my_program"),      "../my_program",        'validate_process_name("../my_program")');
is(validate_process_name("ec2-run-instances"),  "ec2-run-instances",    'validate_process_name("ec2-run-instances")');
is(validate_process_name("sh <defunct>"),       "sh <defunct>",         'validate_process_name("sh <defunct>")');

# ============================================================================ #
ok(isPythonTraceback('  File "/var/lib/ambari-server/resources/scripts/stack_advisor.py", line 154, in <module>'), 'isPythonTraceback(  File "/var/lib/ambari-server/resources/scripts/stack_advisor.py", line 154, in <module>)');
ok(isPythonTraceback('File "/var/lib/ambari-server/resources/scripts/stack_advisor.py", line 154, in <module>'), 'isPythonTraceback(File "/var/lib/ambari-server/resources/scripts/stack_advisor.py", line 154, in <module>)');
ok(isPythonTraceback('  File "/var/lib/ambari-agent/cache/common-services/RANGER/0.4.0/package/scripts/ranger_admin.py", line 124, in <module>'), 'isPythonTraceback(  File "/var/lib/ambari-agent/cache/common-services/RANGER/0.4.0/package/scripts/ranger_admin.py", line 124, in <module>)');
ok(isPythonTraceback('File "/var/lib/ambari-agent/cache/common-services/RANGER/0.4.0/package/scripts/ranger_admin.py", line 124, in <module>'), 'isPythonTraceback(File "/var/lib/ambari-agent/cache/common-services/RANGER/0.4.0/package/scripts/ranger_admin.py", line 124, in <module>)');
ok(isPythonTraceback('... Traceback (most recent call last):'), 'isPythonTraceback("... Traceback (most recent call last):")');
ok(!isPythonTraceback('blah'), 'isPythonTraceback("blah")');

# ============================================================================ #
is(isRegex(".*"),   ".*",   'isRegex(".*") eq ".*"');
is(isRegex("(.*)"), "(.*)", 'isRegex("(.*)") eq "(.*)"');
is(isRegex("(.*"),  undef,  'isRegex("(.*") eq undef');

#is(validate_regex("some[Rr]egex.*(capture)"),   "(?-xism:some[Rr]egex.*(capture))",  'validate_regex("some[Rr]egex.*(capture)")');
#is(validate_regex("some[Rr]egex.*(capture)"),   "(?^:some[Rr]egex.*(capture))",  'validate_regex("some[Rr]egex.*(capture)")');
# Satisfies different outputs on Linux and Mac OS X 10.9 Maverick
like(validate_regex("some[Rr]egex.*(capture)"),   qr/\(\?(?:\^|-xism):some\[Rr\]egex\.\*\(capture\)\)/,  'validate_regex("some[Rr]egex.*(capture)")');
# Errors out still, should detect and fail gracefully
#is(validate_regex("some[Rr]egex.*(capture broken", 1),   undef,  'validate_regex("some[Rr]egex.*(capture broken", 1)');
is(validate_regex("somePosix[Rr]egex.*(capture)", undef, 0, "posix"),   "somePosix[Rr]egex.*(capture)",      'validate_regex("somePosix[Rr]egex.*(capture)", undef, 0, 1)');
is(validate_regex("somePosix[Rr]egex.*(capture broken", undef, "noquit", "posix"),  undef,       'validate_regex("somePosix[Rr]egex.*(capture broken", undef, 1, 1) eq undef');
is(validate_regex('somePosix[Rr]egex.*$(evilcmd)', undef, "noquit", "posix"),       undef,       'validate_regex("somePosix[Rr]egex.*$(evilcmd)", undef, 1, 1) eq undef');
is(validate_regex('somePosix[Rr]egex.*$(evilcmd', undef, "noquit", "posix"),        undef,       'validate_regex("somePosix[Rr]egex.*$(evilcmd", undef, 1, 1) eq undef');
is(validate_regex('somePosix[Rr]egex.*`evilcmd`', undef, "noquit", "posix"),        undef,       'validate_regex("somePosix[Rr]egex.*`evilcmd`", undef, 1, 1) eq undef');
is(validate_regex('somePosix[Rr]egex.*`evilcmd', undef, "noquit", "posix"),         undef,       'validate_regex("somePosix[Rr]egex.*`evilcmd", undef, 1, 1) eq undef');

# ============================================================================ #
ok(!isScalar(1),                '!isScalar(1)');
ok(isScalar(\$status),          'isScalar(\$status)');
ok(!isScalar(\@usage_order),    '!isScalar(\@usage_order)');
ok(!isScalar(\%ERRORS),         '!isScalar(\%ERRORS)');

# ============================================================================ #
is(isScientific("1.2345E10"),   "1.2345E10",    'isScientific(1.2345E10)');
is(isScientific("1e-10"),       "1e-10",        'isScientific(1e-10)');
is(isScientific("-1e-10"),      undef,          'isScientific(-1e-10) eq undef');
is(isScientific("-1e-10", 1),   "-1e-10",       'isScientific(-1e-10, 1) eq -1e-10');

# ============================================================================ #
ok(isThreshold(5),      'isThreshold(5)');
ok(isThreshold("5"),    'isThreshold("5")');
ok(isThreshold(0),      'isThreshold(0)');
ok(isThreshold(-1),     'isThreshold(-1)');
ok(isThreshold("1:10"), 'isThreshold(1:10)');
ok(isThreshold("-1:0"), 'isThreshold(-1:0)');
ok(!isThreshold("a"),   '!isThreshold("a")');

# ============================================================================ #
is(isUrl("www.google.com"),         "http://www.google.com",    'isUrl("www.google.com") eq http://www.google.com');
is(isUrl("http://www.google.com"),  "http://www.google.com",    'isUrl("http://www.google.com")');
is(isUrl("https://gmail.com"),      "https://gmail.com",        'isUrl("https://gmail.com")');
is(isUrl(1),                        "http://1",                 'isUrl(1) eq http://1');
is(isUrl("-help"),                  undef,                      'isUrl(-help) eq undef');
is(isUrl("http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE"),  'http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE', 'isUrl(http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE)');
is(isUrl("http://namenode:50070/dfshealth.html#tab-overview"),  'http://namenode:50070/dfshealth.html#tab-overview', 'http://namenode:50070/dfshealth.html#tab-overview');

is(validate_url("www.google.com"),          "http://www.google.com",    'validate_url("www.google.com")');
is(validate_url("http://www.google.com"),   "http://www.google.com",    'validate_url("http://www.google.com")');
is(validate_url("https://gmail.com"),       "https://gmail.com",        'validate_url("https://gmail.com")');
is(validate_url("http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE"),       "http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE",        'validate_url("http://cdh43:50070/dfsnodelist.jsp?whatNodes=LIVE")');

# ============================================================================ #
is(isUrlPathSuffix("/"),                "/",                        'isUrlPathSuffix("/")');
is(isUrlPathSuffix("/?var=something"),  "/?var=something",          'isUrlPathSuffix("/?var=something")');
is(isUrlPathSuffix("/dir1/file.php?var=something+else&var2=more%20stuff"), "/dir1/file.php?var=something+else&var2=more%20stuff", 'isUrlPathSuffix("/dir1/file.php?var=something+else&var2=more%20stuff")');
is(isUrlPathSuffix("/*"),               "/*",                      'isUrlPathSuffix("/*") eq "/*"');
is(isUrlPathSuffix("/~hari"),           "/~hari",                  'isUrlPathSuffix("/~hari") eq "/~hari"');
is(isUrlPathSuffix("hari"),             undef,                     'isUrlPathSuffix("hari") eq undef');

is(validate_url_path_suffix("/"),                "/",                        'validate_url_path_suffix("/")');
is(validate_url_path_suffix("/?var=something"),  "/?var=something",          'validate_url_path_suffix("/?var=something")');
is(validate_url_path_suffix("/dir1/file.php?var=something+else&var2=more%20stuff"), "/dir1/file.php?var=something+else&var2=more%20stuff", 'validate_url_path_suffix("/dir1/file.php?var=something+else&var2=more%20stuff")');
is(validate_url_path_suffix("/*"),               "/*",                      'validate_url_path_suffix("/*") eq "/*"');
is(validate_url_path_suffix("/~hari"),           "/~hari",                  'validate_url_path_suffix("/~hari") eq "/~hari"');

# ============================================================================ #
is(isUser("hadoop"),    "hadoop",   'isUser("hadoop")');
is(isUser("hari1"),     "hari1",    'isUser("hari1")');
is(isUser("mysql_test"), "mysql_test", 'isUser("mysql_test")');
is(isUser('cloudera-scm'),  'cloudera-scm', 'isUser("cloudera-scm")');
ok(!isUser("-hari"),                '!isUser("-hari")');
ok(!isUser("9hari"),             '!isUser("9hari")');

is(validate_user("hadoop"),    "hadoop",   'validate_user("hadoop")');
is(validate_user("hari1"),     "hari1",    'validate_user("hari1")');
is(validate_user("cloudera-scm"),     "cloudera-scm",    'validate_user("cloudera-scm")');

# ============================================================================ #
is(validate_user_exists("root"),  "root", 'validate_user_exists("root")');

# ============================================================================ #
is(isVersion(1), 1, 'isVersion(1)');
is(isVersion("2.1.2"), "2.1.2", 'isVersion(2.1.2)');
is(isVersion("2.2.0.4"), "2.2.0.4", 'isVersion(2.2.0.4)');
is(isVersion("3.0"), "3.0", 'isVersion(3.0)');
is(isVersion("a"), undef, 'isVersion(a) eq undef');
is(isVersion("3a"), undef, 'isVersion(3a) eq undef');
is(isVersion("1.0-2"), undef, 'isVersion(1.0-2) eq undef');
is(isVersion("1.0-a"), undef, 'isVersion(1.0-a) eq undef');

is(isVersionLax(1), 1, 'isVersionLax(1)');
is(isVersionLax("2.1.2"), "2.1.2", 'isVersionLax(2.1.2)');
is(isVersionLax("2.2.0.4"), "2.2.0.4", 'isVersionLax(2.2.0.4)');
is(isVersionLax("3.0"), "3.0", 'isVersionLax(3.0)');
is(isVersionLax("a"), undef, 'isVersionLax(a) eq undef');
is(isVersionLax("3a"), 3, 'isVersionLax(3a) eq undef');
is(isVersionLax("1.0-2"), "1.0", 'isVersionLax(1.0-2) eq 1.0');
is(isVersionLax("1.0-a"), "1.0", 'isVersionLax(1.0-a) eq 1.0');
is(isVersionLax("hari"), undef, 'isVersionLax(hari) eq undef');

# ============================================================================ #
ok(isXml("<blah></blah>"), "isXML()");
ok(!isXml("<blah>"), "!isXml()");

# ============================================================================ #
ok(isYes("yEs"), 'isYes(yEs)');
ok(isYes("y"),   'isYes(y)');
ok(isYes("Y"),   'isYes(Y)');
ok(!isYes("yE", "name", "noquit"), '!isYes(yE)');
ok(!isYes("no"), '!isYes(no)');
ok(!isYes("n"),  '!isYes(n)');
ok(!isYes("N"),  '!isYes(N)');
ok(!isYes("", "name", "noquit"),   '!isYes()');

# ============================================================================ #
#ok(HariSekhonUtils::loginit(),   'HariSekhonUtils::loginit()');
#ok(HariSekhonUtils::loginit(),   'HariSekhonUtils::loginit() again since it should be initialized by first one');
#ok(&HariSekhonUtils::log("hari testing"), '&HariSekhonUtils::log("hari testing")');

# ============================================================================ #
is(lstrip(" \t \n ha ri \t \n"),     "ha ri \t \n",   'lstrip()');
is(ltrim(" \t \n ha ri \t \n"),      "ha ri \t \n",   'ltrim()');

# ============================================================================ #
$warning  = 5;
$critical = 10;
validate_thresholds();
is(msg_thresholds(),  " (w=5/c=10)",  "msg_thresholds()  w=5/c=10");
is(msg_thresholds(1), " (w=5/c=10)",  "msg_thresholds(1) w=5/c=10");
$warning = 0;
$critical = 0;
validate_thresholds();
is(msg_thresholds(),   " (w=0/c=0)",     "msg_thresholds()  w=0/c0");
is(msg_thresholds(1),  " (w=0/c=0)",     "msg_thresholds(1) w=0/c=0");

$warning = undef;
$critical = undef;
validate_thresholds();
$verbose = 0;
is(msg_thresholds(),    "",    "msg_thresholds() w=undef/c=undef");
is(msg_thresholds(1),   "",    "msg_thresholds(1) w=undef/c=undef");

# ============================================================================ #
ok(msg_perf_thresholds(),   "msg_perf_thresholds()");

# ============================================================================ #
ok(open_file("/etc/hosts",1),           'open_file("/etc/hosts",1)');
# Not supporting mode right now
#ok(open_file("/etc/hosts",1,">>"),      'open_file("/etc/hosts",1,">>")');

# ============================================================================ #
is(parse_file_option("/bin/sh"),      @{["/bin/sh"]},  'parse_file_options("/bin/sh")');
is(parse_file_option("/bin/sh", "args are files"),   @{["/bin/sh"]},  'parse_file_options("/bin/sh", "args are files")');
is(parse_file_option("/bin/sh, /bin/sh", "args are files"),   @{["/bin/sh","/bin/sh"]},  'parse_file_options("/bin/sh, /bin/sh", "args are files")');
is(parse_file_option("/bin/sh  /bin/sh", "args are files"),   @{["/bin/sh","/bin/sh"]},  'parse_file_options("/bin/sh  /bin/sh", "args are files")');

# ============================================================================ #
ok(!pkill("nonexistentprogram"),         '!pkill("nonexistentprogram")');

# ============================================================================ #
is(plural(1),                       "",     'plural(1)');
is(plural(2),                       "s",    'plural(2)');
# code_error's out
#is(plural("string"),                "",     'plural("string")');
is(plural([qw/one/]),               "",     'plural(qw/one/)');
is(plural([qw/one two three/]),     "s",    'plural(qw/one two three/)');

# ============================================================================ #
like(random_alnum(20),  qr/^[A-Za-z0-9]{20}$/,                      'random_alnum(20)');
like(random_alnum(3),  qr/^[A-Za-z0-9][A-Za-z0-9][A-za-z0-9]$/,     'random_alnum(3)');

# ============================================================================ #
is(sec2human(1),     "1 sec",                   'sec2human(1)');
is(sec2human(10),    "10 secs",                 'sec2human(10)');
is(sec2human(61),    "1 min 1 sec",            'sec2human(61)');
is(sec2human(3676),  "1 hour 1 min 16 secs",   'sec2human(3676)');

# ============================================================================ #
ok(skip_java_output("Class JavaLaunchHelper is implemented in both"), 'skip_java_output("Class JavaLaunchHelper is implemented in both")');
ok(skip_java_output("SLF4J"), 'skip_java_output("SLF4J")');
ok(!skip_java_output("aSLF4J"), '!skip_java_output("aSLF4J")');

# ============================================================================ #
ok(sub { subtrace(); }, 'subtrace()');
$debug = 2;
ok(sub { subtrace(); }, 'subtrace() at debug 2');

# ============================================================================ #
# if not on a decent OS assume I'm somewhere lame like a bank where internal resolvers don't resolve internet addresses
# this way my continous integration tests still run this one
# still applies to Hortonworks Sandbox running on a banking VM :-/
if(isLinuxOrMac()){
    if($ENV{"TRAVIS"} or `PATH=\$PATH:/usr/sbin dmidecode | grep -i virtual` eq "" ){
        is(resolve_ip("a.resolvers.level3.net"),    "4.2.2.1",      'resolve_ip("a.resolvers.level3.net") returns 4.2.2.1');
        is(validate_resolvable("a.resolvers.level3.net"),    "4.2.2.1",      'validate_resolvable("a.resolvers.level3.net")');
    }
}
is(resolve_ip("4.2.2.2"),                   "4.2.2.2",      'resolve_ip("4.2.2.2") returns 4.2.2.2');
is(validate_resolvable("4.2.2.2"),                   "4.2.2.2",      'validate_resolvable("4.2.2.2") returns 4.2.2.2');

# ============================================================================ #
is(rstrip(" \t \n ha ri \t \n"),     " \t \n ha ri",   'rstrip()');
is(rtrim(" \t \n ha ri \t \n"),      " \t \n ha ri",   'rtrim()');

# ============================================================================ #
is(sec2min(65),     "1:05",     'sec2min(65) eq "1:05"');
is(sec2min(30),     "0:30",     'sec2min(30) eq "0:30"');
is(sec2min(3601),   "60:01",    'sec2min(3601) eq "60:01"');
is(sec2min(-1),     undef,      'sec2min(-1) eq undef');
is(sec2min("aa"),   undef,      'sec2min("aa") eq undef');
is(sec2min(0),      "0:00",     'sec2min(0) eq 0:00');

# ============================================================================ #
is(set_sudo("hadoop"),      "echo | sudo -S -u hadoop ",    'set_sudo("hadoop")');
is(set_sudo(getpwuid($>)),  "",                             'set_sudo(getpwuid($>))');

# ============================================================================ #
ok(remove_timeout(), 'remove_timeout()');
# This is because the previous timer remaining time was 0
is(set_timeout(10),     0,      "set_timeout(10) eq 0");
is(set_timeout(100),     10,    "set_timeout(100) eq 10");

# ============================================================================ #

is(strBool("true"), "true", 'strBool("true") => true');
is(strBool("True"), "true", 'strBool("True") => true');
is(strBool("tRuE"), "true", 'strBool(tRuE) => true');
is(strBool(1), "true", 'strBool(1) => true');
is(strBool(-1), "true", 'strBool(-1) => true');
is(strBool(0), "false", 'strBool(0) => false');
is(strBool("false"), "false", 'strBool(false) => false');
is(strBool("False"), "false", 'strBool(False) => false');
is(strBool("fAlSe"), "false", 'strBool(FAlSe) => false');
is(strBool(" "), "false", 'strBool(" ") => false');
is(strBool(""), "false", 'strBool("") => false');

# ============================================================================ #
is(strip(" \t \n ha ri \t \n"),     "ha ri",   'strip()');
is(trim(" \t \n ha ri \t \n"),      "ha ri",   'trim()');

# ============================================================================ #
is(trim_float("0.10"), "0.1", 'trim_float("0.10") eq "0.1"');
is(trim_float("0.101"), "0.101", 'trim_float("0.101") eq "0.101"');

# ============================================================================ #
use POSIX 'strftime';
my @time_parts = split(/\s+/, strftime("%Y %b %d %H %M %S", localtime));
#is(timecomponents2days({split(/\s+/, strftime "%Y %b %d %H %M %S", localtime)}),    1,  'timecomponents2days');
# breaks on Mac without int() as it returns 0.0416666666666667 instead of 0
is(int(timecomponents2days($time_parts[0], $time_parts[1], $time_parts[2], $time_parts[3], $time_parts[4], $time_parts[5])),    0,  'timecomponents2days now');
# this works right now but because of the irregularity of the calendar will probably break in future
#is(timecomponents2days(
#    strftime("%Y", localtime),
#    strftime("%b", localtime),
#    strftime("%d", localtime) + 2,
#    strftime("%H", localtime),
#    strftime("%M", localtime),
#    strftime("%S", localtime)
#),    2,  'timecomponents2days');
# tiniest of condition when it might break 1 sec, will never really hit this temporal unit test failure
#is(timecomponents2days($time_parts[0], $time_parts[1], $time_parts[2], $time_parts[3], $time_parts[4], $time_parts[5] + 1),    1/86400,  'timecomponents2days');

# ============================================================================ #

is_deeply([sort_insensitive(("one", "Two", "three", "", "one"))],     [ "", "one", "one", "three", "Two" ],    'sort_insensitive()');

is_deeply([uniq_array(("one", "two", "three", "", "one"))],     [ "", "one", "three", "two" ],    'uniq_array()');
is_deeply([uniq_array2(("one", "two", "three", "", "one"))],     [ "one", "two", "three", "" ],    'uniq_array2()');
is_deeply([uniq_array_ordered(("one", "two", "three", "", "one"))],     [ "one", "two", "three", "" ],    'uniq_array_ordered()');

# TODO:
# usage
# logdie
# quit

# ============================================================================ #
ok(user_exists("root"),                 'user_exists("root")');
ok(!user_exists("nonexistentuser"),     '!user_exists("nonexistentuser")');

is(validate_database_query_select_show("SELECT count(*) from database.table"),  "SELECT count(*) from database.table", 'validate_database_query_select_show("SELECT count(*) from database.table")');
# This should error out with invalid query msg. if it shows DML statement detected then it's fallen through to DML keyword match
#ok(!validate_database_query_select_show("SELECT count(*) from (DELETE FROM database.field)"),  'validate_database_query_select_show("SELECT count(*) from (DELETE FROM database.field)")');

is(validate_hostport("myHost:8080"),              "myHost:8080",                    'validate_hostname(myHost:8080)');
is(validate_hostport("myHost.myDomain.com:8080"), "myHost.myDomain.com:8080",       'validate_hostname(myHost.myDomain.com:8080)');

is_deeply([validate_host_port_user_password("myHost.domain.com", 80, "myUser", "myPassword")],   ["myHost.domain.com", 80, "myUser", "myPassword"], 'validate_host_port_user_password()');

is_deeply([validate_hosts("localhost,127.0.0.1:443", 80)],   ["127.0.0.1:80","127.0.0.1:443"], 'validate_hosts()');

is_deeply([validate_node_list("node1, node2 ,node3 , node4,,\t\nnode5")], [qw/node1 node2 node3 node4 node5/],    'validate_node_list($)');
# The , in node4, inside the qw array should be split out to just node4 and blank, blank shouldn't make it in to the array
is_deeply([validate_node_list("node1", qw/node2 node3 node4, node5/)], [qw/node1 node2 node3 node4 node5/],    'validate_node_list($@)');
# should error out with "node list empty"
#is(!validate_node_list(""), '!validate_node_list("")');

is_deeply([validate_nodeport_list("node1:9200", qw/node2 node3 node4, node5/)], [qw/node1:9200 node2 node3 node4 node5/],    'validate_nodeport_list($@)');

if(isLinuxOrMac()){
    is(validate_program_path("/bin/sh", "sh"), "/bin/sh", 'validate_program_path()');
}

is(validate_password('wh@tev3r'),   'wh@tev3r',     'validate_password(\'wh@tev3r\')');
$ENV{'PASSWORD_DEBUG'} = 1;
is(validate_password('wh@tev3r'),   'wh@tev3r',     'validate_password(\'wh@tev3r\')');
delete $ENV{'PASSWORD_DEBUG'};

# ssl isn't set here
ok(!validate_ssl(), 'validate_ssl()');
ok(!validate_tls(), 'validate_tls()');
ok(!HariSekhonUtils::validate_ssl_opts(), 'validate_ssl_opts()');

# This could do with a lot more unit testing
ok(HariSekhonUtils::validate_threshold("warning", 75), 'validate_threshold("warning", 75)');
ok(HariSekhonUtils::validate_threshold("critical", 90), 'validate_threshold("critical", 90)');
ok(validate_thresholds(), 'validate_thresholds()');

$verbose = 0;
ok(!verbose_mode(),  '!verbose_mode()');
$verbose = 1;
ok(verbose_mode(),  'verbose_mode()');

ok(tstamp(), 'tstamp()');
ok(tprint("test"), 'tprint(test)');

use HariSekhonUtils ':log';
ok(loginit(), 'loginit()');

ok(HariSekhonUtils::get_terminal_size(), 'get_terminal_size()');
ok(HariSekhonUtils::check_terminal_size(), 'check_terminal_size()');
ok(HariSekhonUtils::print_options(), 'print_options()');

# Devel::Cover does not work with threads:
# """
# Unfortunately, Devel::Cover does not yet work with threads.  I have done
# some work in this area, but there is still more to be done.
# 
# Dubious, test returned 1 (wstat 256, 0x100)
# All 517 subtests passed
# """
#my $stdin; { local $/; $stdin = <STDIN>; }
#my $stdin = <STDIN>;
# can't use threads for either prompt of STDIN because of Devel::Cover erroring outand breaking the unit test exit code even though all subtests passed
#use threads;
#threads->create(sub { is(prompt("test question"), "test answer", 'prompt()'); });
#threads->create(sub { print STDIN "test answer"; });
#   Parse errors: Tests out of sequence.  Found (519) but expected (518)
#                 Tests out of sequence.  Found (520) but expected (519)
#                 Tests out of sequence.  Found (521) but expected (520)
#                 Tests out of sequence.  Found (522) but expected (521)
#                 Tests out of sequence.  Found (523) but expected (522)
# Displayed the first 5 of 34 TAP syntax errors.
# Re-run prove with the -p option to see them all.
#is(prompt("test question"), "test answer", 'prompt()');

ok(HariSekhonUtils::version_string(), 'version_string()');

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

print "\n";
$verbose = 0;
ok(!vlogt("testing vlog in \$verbose $verbose"),       "!vlogt(\"testing vlog in \$verbose $verbose\")");
ok(!vlog2t("testing vlog2 in \$verbose $verbose"),     "!vlog2t(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog2t("testing vlog3 in \$verbose $verbose"),     "!vlog3t(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 1;
ok(vlogt("testing vlog in \$verbose $verbose"),        "vlogt(\"testing vlog in \$verbose $verbose\")");
ok(!vlog2t("testing vlog2 in \$verbose $verbose"),     "!vlog2t(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog2t("testing vlog3 in \$verbose $verbose"),     "!vlog3t(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 2;
ok(vlogt("testing vlog in \$verbose $verbose"),        "vlogt(\"testing vlog in \$verbose $verbose\")");
ok(vlog2t("testing vlog2 in \$verbose $verbose"),      "vlogt(\"testing vlog2 in \$verbose $verbose\")");
ok(!vlog3t("testing vlog3 in \$verbose $verbose"),     "!vlogt(\"testing vlog3 in \$verbose $verbose\")");
print "\n";
$verbose = 3;
ok(vlogt("testing vlog in \$verbose $verbose"),        "vlogt(\"testing vlog in \$verbose $verbose\")");
ok(vlog2t("testing vlog2 in \$verbose $verbose"),      "vlogt(\"testing vlog2 in \$verbose $verbose\")");
ok(vlog3t("testing vlog3 in \$verbose $verbose"),      "vlogt(\"testing vlog3 in \$verbose $verbose\")");

$verbose = 1;
ok(HariSekhonUtils::vlog4("test1\ntest2"),   'vlog4("test1\ntest2")');

$verbose = 1;
ok(!vlog_option("option", "value"),         '!vlog_option("option", "value") in $verbose 1');
ok(!vlog_option_bool("option", "value"),    '!vlog_option_bool("option", "value") in $verbose 1');
$verbose = 2;
ok(vlog_option("option", "value"),         'vlog_option("option", "value") in $verbose 2');
ok(vlog_option_bool("option", "value"),    'vlog_option_bool("option", "value") in $verbose 2');

is(which("sh"),                             "/bin/sh",      'which("sh") eq /bin/sh');
is(which("/bin/bash"),                      "/bin/bash",    'which("bash") eq /bin/bash');
is(which("/explicit/nonexistent/path"),     undef,          'which("/explicit/nonexistent/path") eq undef');
is(which("nonexistentprogram"),             undef,          'which("nonexistentprogram") eq undef');

done_testing();
