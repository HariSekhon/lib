#
#  Author: Hari Sekhon
#  Date: 2014-01-08 15:44:41 +0000 (Wed, 08 Jan 2014)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

package HariSekhon::HBase;

$VERSION = "0.1";

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
                        validate_hbase_column_qualifier
                        validate_hbase_rowkey
                )
);
our @EXPORT_OK = ( @EXPORT );

# copied from my std lib from isDatabase* and validate_database_*

sub isHBaseColumnQualifier ($) {
    my $column = shift;
    defined($column) or code_error "no column passed to isHBaseColumnQualifier()";
    if($column =~ /^([\w\s\(\)\:#]+)$/){
        return $1;
    }
    return undef;
}

sub isHBaseRowKey ($) {
    my $rowkey = shift;
    defined($rowkey) or code_error "no row key passed to isHBaseRowKey()";
    if($rowkey =~ /^([\w\:#]+)$/){
        return $1;
    }
    return undef;
}

sub validate_hbase_column_qualifier ($) {
    my $column = shift;
    defined($column) || usage "column not defined";
    $column = isHBaseColumnQualifier($column) || usage "invalid column qualifier defined";
    vlog_options("column qualifier", $column);
    return $column;
}

sub validate_hbase_rowkey ($) {
    my $rowkey = shift;
    defined($rowkey) || usage "rowkey not defined";
    $rowkey = isHBaseRowKey($rowkey) || usage "invalid rowkey defined: must be alphanumeric, colons and # are allowed for compound keys";
    vlog_options("rowkey", $rowkey);
    return $rowkey;
}

1;
