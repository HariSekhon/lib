#
#  Author: Hari Sekhon
#  Date: 2013-11-03 03:58:28 +0000 (Sun, 03 Nov 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#

package HariSekhon::Cassandra::Nodetool;

$VERSION = "0.2.11";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/../..";
}
use HariSekhonUtils;
use HariSekhon::Cassandra;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                        $nodetool
                        $nodetool_errors_regex
                        $nodetool_status_header_regex
                        %nodetool_options
                        check_nodetool_errors
                        die_nodetool_unrecognized_output
                        nodetool_options
                        skip_nodetool_output
                        validate_nodetool
                        validate_nodetool_options
                )
);
our @EXPORT_OK = ( @EXPORT );

$ENV{"PATH"} .= ":/usr/bin:/usr/sbin:/usr/local/cassandra/bin:/opt/cassandra/bin:/cassandra/bin";

our $nodetool = "nodetool";

sub validate_nodetool ($) {
    my $nodetool = shift;
    defined($nodetool) or usage "nodetool not defined";
    $nodetool = validate_filename($nodetool, "nodetool");
    $nodetool =~ /(?:^|\/)nodetool$/ or usage "invalid nodetool path given, must be the path to the nodetool command";
    $nodetool = which($nodetool, 1);
    return $nodetool;
}

$port = set_cassandra_port("JMX");

our %nodetool_options = (
    %cassandra_options,
    "n|nodetool=s"     => [ \$nodetool, "Path to 'nodetool' command if not in \$PATH ($ENV{PATH})" ],
);
@usage_order = qw/nodetool host port user password warning critical/;

sub nodetool_options(;$$$$){
    my $host            = shift;
    my $port            = shift;
    my $user            = shift;
    my $password        = shift;
    my $options         = "";
    $host     = validate_resolvable($host)  if defined($host);
    $options .= "--host '$host' "           if defined($host);
    $options .= "--port '$port' "           if defined($port);
    $options .= "--username '$user' "       if defined($user);
    $options .= "--password '$password' "   if defined($password);
    return $options;
}

sub validate_nodetool_options($$$$$){
    my $nodetool = shift;
    my $host     = shift;
    my $port     = shift;
    my $user     = shift;
    my $password = shift;
    $nodetool = validate_nodetool($nodetool);
    $host     = validate_host($host)         if defined($host);
    $port     = validate_port($port)         if defined($port);
    $user     = validate_user($user)         if defined($user);
    $password = validate_password($password) if defined($password);
    return ($nodetool, $host, $port, $user, $password);
}

                                #You must set the CASSANDRA_CONF and CLASSPATH vars
our $nodetool_errors_regex = qr/
                                You\s+must\s+set |
                                Cannot\s+resolve |
                                unknown\s+host   |
                                connection\s+refused  |
                                failed\s+to\s+connect |
                                error |
                                user  |
                                password |
                                Exception(?!s\s*:\s*\d+) |
                                in thread
                             /xi;

sub check_nodetool_errors($){
    @_ or code_error "no input passed to check_nodetool_errors()";
    my $str = join(" ", @_);
    quit "CRITICAL", $str if $str =~ /$nodetool_errors_regex/;
}

sub skip_nodetool_output($){
    @_ or code_error "no input passed to skip_nodetool_output()";
    my $str = join(" ", @_);
    return 1 if $str =~ /^\s*$/;
    if(skip_java_output($str)){
        return 1;
    }
    return 0;
}

# Cassandra 2.0 DataStax Community Edition (nodetool version gives 'ReleaseVersion: 2.0.2')
our $nodetool_status_header_regex = qr/
                                       ^Note |
                                       ^Datacenter |
                                       ^========== |
                                       ^Status=Up\/Down |
                                       ^\|\/\s+State=Normal\/Leaving\/Joining\/Moving |
                                       ^--\s+Address\s+
                                    /xi;
sub die_nodetool_unrecognized_output($){
    @_ or code_error "no input passed to die_nodetool_unrecognized_output to check";
    my $str = join(" ", @_);
    quit "UNKNOWN", sprintf("unrecognized output '%s', nodetool output format may have changed, aborting, $nagios_plugins_support_msg", $str);
}

1;
