#
#  Author: Hari Sekhon
#  Date: 2014-01-08 15:44:41 +0000 (Wed, 08 Jan 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

package HariSekhon::HBase;

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "..";
}
use HariSekhonUtils;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                        isHBaseColumnQualifier
                        isHBaseRowKey
                        isHBaseTable
                        validate_hbase_column_qualifier
                        validate_hbase_rowkey
                        validate_hbase_table
                )
);
our @EXPORT_OK = ( @EXPORT );

# copied from my std lib from isDatabase* and validate_database_*

sub isHBaseColumnQualifier ($) {
    my $column = shift;
    defined($column) or return undef;
    if($column =~ /^([\w\s\(\)\:#]+)$/){
        return $1;
    }
    return undef;
}

sub isHBaseRowKey ($) {
    my $rowkey = shift;
    defined($rowkey) or return undef;
    if($rowkey =~ /^([\w\:#]+)$/){
        return $1;
    }
    return undef;
}

sub isHBaseTable ($) {
    my $table = shift;
    defined($table) or return undef;
    if($table =~ /^([\w\:]+)$/){
        return $1;
    }
    return undef;
}

sub validate_hbase_column_qualifier ($) {
    my $column = shift;
    defined($column) || usage "hbase column not defined";
    $column = isHBaseColumnQualifier($column) || usage "invalid hbase column qualifier defined";
    vlog_options("column qualifier", $column);
    return $column;
}

sub validate_hbase_rowkey ($) {
    my $rowkey = shift;
    defined($rowkey) || usage "hbase rowkey not defined";
    $rowkey = isHBaseRowKey($rowkey) || usage "invalid hbase rowkey defined: must be alphanumeric, colons and # are allowed for compound keys";
    vlog_options("rowkey", $rowkey);
    return $rowkey;
}

sub validate_hbase_table ($) {
    my $table = shift;
    defined($table) || usage "hbase table not defined";
    $table = isHBasetable($table) || usage "invalid hbase table defined: must be alphanumeric, colons and # are allowed for compound keys";
    vlog_options("table", $table);
    return $table;
}

1;
