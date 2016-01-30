#
#  Author: Hari Sekhon
#  Date: 2014-07-27 15:20:09 +0100 (Sun, 27 Jul 2014)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

# Forked from check_ambari.pl from the Advanced Nagios Plugins Collection
#
# to share with other Ambari check programs

package HariSekhon::Ambari;

$VERSION = "0.4.0";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Carp;
use Data::Dumper;
use JSON 'decode_json';
use LWP::UserAgent;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $api
                    $cluster
                    $node
                    $list_clusters
                    $list_hosts
                    $list_components
                    $list_services
                    $list_users
                    $protocol
                    $component
                    $service
                    $ua
                    $url_prefix
                    %ambari_options
                    %ambari_options_list
                    %ambari_options_node
                    %ambari_options_service
                    %service_map
                    cluster_required
                    component_required
                    node_required
                    service_required
                    curl_ambari
                    hadoop_service_name
                    list_ambari_components
                    list_clusters
                    list_hosts
                    list_components
                    list_services
                    list_users
                    validate_ambari_cluster
                    validate_ambari_cluster_options
                    validate_ambari_node
                    validate_ambari_component
                    validate_ambari_service
                )
);
our @EXPORT_OK = ( @EXPORT );

our $ua = LWP::UserAgent->new;

our $protocol = "http";
our $api      = "/api/v1";
set_port_default(8080);

our $url_prefix;

our $cluster;
our $node;
our $component;
our $service;

our $list_nodes          = 0;
our $list_clusters       = 0;
our $list_svc_components = 0;
our $list_svc_nodes      = 0;
our $list_svcs           = 0;
our $list_svcs_nodes     = 0;
our $list_users          = 0;

our %service_map = (
    #"GANGLIA"       => "Ganglia",
    #"FALCON"        => "Falcon",
    "HBASE"         => "HBase",
    "HCATALOG"      => "HCatalog",
    "HDFS"          => "HDFS",
    #"HIVE"          => "Hive",
    "MAPREDUCE"     => "MapReduce",
    "MAPREDUCE2"    => "MapReduce2",
    #"NAGIOS"        => "Nagios",
    #"OOZIE"         => "Oozie",
    #"PIG"           => "Pig",
    #"STORM"         => "Storm",
    #"TEZ"           => "Tez",
    "WEBHCAT"       => "WebHCat",
    #"YARN"          => "Yarn",
    "ZOOKEEPER"     => "ZooKeeper",
);

env_creds("Ambari");

if($ENV{"AMBARI_CLUSTER"}){
    $cluster = $ENV{"AMBARI_CLUSTER"};
}

if($ENV{"AMBARI_SERVICE"}){
    $service = $ENV{"AMBARI_SERVICE"};
}

if($ENV{"AMBARI_COMPONENT"}){
    $component = $ENV{"AMBARI_COMPONENT"};
}

if($ENV{"AMBARI_NODE"}){
    $node = $ENV{"AMBARI_NODE"};
}

# Ambari REST API:
#
# /clusters                                                 - list clusters + version HDP-1.2.0
# /clusters/$cluster                                        - list svcs + host in cluster
# /clusters/$cluster/services                               - list svcs
# /clusters/$cluster/services/$service                      - service state + components
# /clusters/$cluster/services/$service/components/DATANODE  - state, hosts, TODO: metrics
# /clusters/$cluster/hosts                                  - list hosts
# /clusters/$cluster/host/$node                             - host_state, disks, rack, TODO: metrics
# /clusters/$cluster/host/$node/host_components             - list host components
# /clusters/$cluster/host/$node/host_components/DATANODE    - state + metrics

our %ambari_options_list = (
    "list-users"                => [ \$list_users,          "List Ambari users" ],
);

our %ambari_options = (
    %tlsoptions,
    "C|cluster=s"               => [ \$cluster,             "Cluster Name as shown in Ambari or --list-clusters (\$AMBARI_CLUSTER)" ],
    "list-clusters"             => [ \$list_clusters,       "Lists all the clusters managed by the Ambari server" ],
    %ambari_options_list,
);
our %ambari_options_node = (
    %ambari_options,
    "N|node=s"                  => [ \$node,                "Node in cluster as shown in Ambari or --list-nodes (\$AMBARI_NODE)" ],
    "list-nodes"                => [ \$list_nodes,          "Lists all the nodes managed by the Ambari server for given --cluster" ],
);
our %ambari_options_service = (
    %ambari_options,
    "S|service=s"               => [ \$service,             "Service Name as shown in Ambari or --list-services (eg. HDFS, HBASE, usually capitalized, \$AMBARI_SERVICE). Requires --cluster" ],
    "O|component=s"             => [ \$component,           "Service component to check, see --list-service-components (eg. DATANODE, \$AMBARI_COMPONENT)" ],
    "list-services"             => [ \$list_svcs,           "Lists all services in the given --cluster" ],
    "list-service-components"   => [ \$list_svc_components, "Lists all components of a given service. Requires --cluster, --service" ],
    "list-service-nodes"        => [ \$list_svc_nodes,      "Lists all nodes for a given service. Requires --cluster, --service, --component" ],
);

splice @usage_order, 6, 0, qw/cluster service node component list-clusters list-nodes list-services list-service-nodes list-service-components list-users/;

sub curl_ambari($){
    my $url = shift;
    # { status: 404, message: blah } handled in curl() in lib
    my $content = curl $url, ($debug ? "" : "Ambari"), $user, $password;

    my $json;
    try{
        $json = decode_json $content;
    };
    catch{
        quit "invalid json returned by Ambari at '$url_prefix', did you try to connect to the SSL port without --tls?";
    };
    return $json;
}

sub cluster_required(){
    $cluster or usage "--cluster required";
}
sub node_required(){
    $node or usage "--node required";
}
sub service_required(){
    $service or usage "--service required";
}
sub component_required(){
    $component or usage "--component required";
}

sub hadoop_service_name($){
    my $service = shift || code_error "no service name passed to hadoop_service_name()";
    if(grep { $service eq $_ } keys %service_map){
        $service = $service_map{$service};
    } else {
        $service = ucfirst lc $service;
    }
    return $service;
}

sub list_clusters(;$){
    my $quit = shift;
    my %clusters;
    $json = curl_ambari "$url_prefix/clusters";
    my @items = get_field_array("items");
    my $cluster_name;
    my $cluster_version;
    foreach(@items){
        $cluster_name    = get_field2($_, "Clusters.cluster_name");
        $cluster_version = get_field2($_, "Clusters.version");
        $clusters{$cluster_name} = $cluster_version;
        #vlog2   sprintf("%-19s %s\n", $cluster_name, $cluster_version);
        $msg .= sprintf("%s (%s), ",  $cluster_name, $cluster_version);
    }
    $msg =~ s/, $//;
    if($quit){
        my $num_clusters = scalar keys %clusters;
        plural $num_clusters;
        print "$num_clusters cluster$plural managed by Ambari:\n\n" . join("\n", sort keys %clusters) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return %clusters;
}

sub list_nodes(;$){
    my $quit = shift;
    cluster_required();
    $json = curl_ambari "$url_prefix/clusters/$cluster/hosts";
    my @items = get_field_array("items");
    my @nodes;
    my $node;
    foreach(@items){
        $node = get_field2($_, "Hosts.host_name");
        #vlog2 sprintf("node %s", $node);
        push(@nodes, $node);
    }
    @nodes = sort @nodes;
    if($quit){
        my $num_nodes = scalar @items;
        plural $num_nodes;
        print "$num_nodes node$plural in cluster '$cluster':\n\n" . join("\n", @nodes) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    #return %nodes;
    return @nodes;
}

sub list_services(;$){
    my $quit = shift;
    cluster_required();
    $json = curl_ambari "$url_prefix/clusters/$cluster/services";
    my @items = get_field_array("items");
    my @services;
    foreach(@items){
        push(@services, get_field2($_, "ServiceInfo.service_name"));
    }
    # comes sorted
    #@services = sort @services;
    if($quit){
        print "cluster '$cluster' services:\n\n" . join("\n", @services) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return @services;
}

sub list_service_components(;$){
    my $quit = shift;
    cluster_required();
    service_required();
    $json = curl_ambari "$url_prefix/clusters/$cluster/services/$service";
    my @items = get_field_array("components");
    my @components;
    foreach(@items){
        push(@components, get_field2($_, "ServiceComponentInfo.component_name"));
    }
    @components = sort @components;
    if($quit){
        print "cluster '$cluster', service '$service' components:\n\n" . join("\n", @components) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return @components;
}

sub list_service_nodes(;$){
    my $quit = shift;
    $cluster   or usage "--cluster required";
    $service   or usage "--service required";
    $component or usage "--component required";
    $json = curl_ambari "$url_prefix/clusters/$cluster/services/$service/components/$component";
    my @nodes;
    my $host;
    foreach (get_field_array("host_components")){
        $host = get_field2($_, "HostRoles.host_name");
        push(@nodes, $host);
    }
    if($quit){
        my $num_nodes = scalar @nodes;
        plural $num_nodes;
        print "$num_nodes node$plural in cluster '$cluster' service '$service' component '$component':\n\n" . join("\n", @nodes) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return @nodes;
}

sub list_users(;$){
    my $quit = shift;
    $json = curl_ambari "$url_prefix/users?fields=*";
    my %users;
    my $user;
    # older Ambari called it roles
    my @roles;
    # newer Ambari 2.1.0 calls it groups
    my @groups;
    foreach(get_field_array("items")){
        #@users{get_field2($_, "Users.user_name")} = get_field2_array($_, "Users.roles");
        if(defined($_->{"Users"}->{"roles"})){
            @roles = get_field2_array($_, "Users.roles");
            @users{get_field2($_, "Users.user_name")} = @roles;
        } elsif(defined($_->{"Users"}->{"groups"})){
            @groups = get_field2_array($_, "Users.groups");
            @users{get_field2($_, "Users.user_name")} = @groups;
        } else {
            code_error("could not find Users.roles or Users.groups. $nagios_plugins_support_msg_api");
        }
    }
    if($quit){
        print "Ambari users:\n\n";
        foreach(sort keys %users){
            print $_;
            if($verbose){
                if(@roles){
                    print " [roles: ";
                } elsif(@groups){
                    print " [groups: ";
                } else {
                    code_error("could not find Ambari roles or groups, caught late. $nagios_plugins_support_msg_api");
                }
                if($users{$_}){
                    print join(",", $users{$_})
                } else {
                    print "<none>";
                }
                print "]";
            }
            print "\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
    return %users;
}

sub listing_ambari_components(){
    $list_clusters       +
    $list_nodes          +
    $list_svc_nodes      +
    $list_svc_components +
    $list_svcs           +
    $list_users;
}

sub list_ambari_components(){
    if(listing_ambari_components() > 1){
        usage "cannot specify more than one --list operation";
    }
    list_clusters(1)           if($list_clusters);
    list_nodes(1)              if($list_nodes);
    list_service_components(1) if($list_svc_components);
    list_service_nodes(1)      if($list_svc_nodes);
    list_services(1)           if($list_svcs);
    list_users(1)              if($list_users);
}

sub validate_ambari_cluster($){
    my $cluster = shift;
    defined($cluster) or usage "cluster not defined";
    $cluster =~ /^\s*([\w\s\.-]+)\s*$/ or usage "Invalid cluster name given, may only contain alphanumeric, space, dash, dots or underscores";
    $cluster = $1;
    vlog_option "cluster", $cluster;
    return $cluster;
}

sub validate_ambari_component($){
    my $component = shift;
    defined($component) or usage "component not defined";
    $component =~ /^\s*([\w-]+)\s*$/ or usage "Invalid component given, use --list-components to see available components for a given cluster service";
    $component = uc $1;
    vlog_option "component", $component;
    return $component;
}

sub validate_ambari_node($){
    my $node = shift;
    defined($node) or usage "node not defined";
    $node = isHostname($node) || usage "invalid node given";
    vlog_option "node", $node;
    return $node;
}

sub validate_ambari_service($){
    my $service = shift;
    defined($service) or usage "service not defined";
    $service    =~ /^\s*([\w-]+)\s*$/ or usage "Invalid service name given, must be alphanumeric with dashes";
    $service = uc $1;
    vlog_option "service", $service;
    return $service;
}

1;
