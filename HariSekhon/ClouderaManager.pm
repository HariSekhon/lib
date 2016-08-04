#
#  Author: Hari Sekhon
#  Date: 2014-04-11 20:21:20 +0100 (Fri, 11 Apr 2014)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying LICENSE file
#  

# Forked from check_cloudera_manager_metrics.pl (2013) from the Advanced Nagios Plugins Collection
#
# to share with various newer Cloudera Manager check programs

package HariSekhon::ClouderaManager;

$VERSION = "0.5.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/..";
}
use HariSekhonUtils;
use Carp;
use JSON 'decode_json';
use LWP::UserAgent;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ( qw (
                    $api
                    $activity
                    $cluster
                    $cm_mgmt
                    $default_port
                    $hostid
                    $json
                    $list_activities
                    $list_clusters
                    $list_hosts
                    $list_nameservices
                    $list_roles
                    $list_services
                    $nameservice
                    $protocol
                    $role
                    $service
                    $ssl_ca_path
                    $ssl_port
                    $tls
                    $tls_noverify
                    $ua
                    $url
                    $url_prefix
                    %cm_options
                    %cm_option_cluster
                    %cm_options_tls
                    %cm_options_list
                    %cm_options_list_basic
                    cm_query
                    check_cm_field
                    list_activities
                    list_clusters
                    list_hosts
                    list_nameservices
                    list_roles
                    list_services
                    list_cm_components
                    listing_cm_components
                    validate_cm_activity
                    validate_cm_cluster
                    validate_cm_cluster_options
                    validate_cm_hostid
                    validate_cm_nameservice
                    validate_cm_role
                    validate_cm_service
                )
);
our @EXPORT_OK = ( @EXPORT );

our $ua = LWP::UserAgent->new;

our $protocol     = "http";
our $api          = "/api/v1";
our $default_port = 7180;
$port             = $default_port;
our $ssl_port     = 7183;

our $activity;
our $cluster;
our $cm_mgmt;
our $hostid;
our $json;
our $nameservice;
our $role;
our $service;
our $ssl_ca_path;
our $tls = 0;
our $tls_noverify;
our $url;
our $url_prefix;

our $list_activities    = 0;
our $list_clusters      = 0;
our $list_hosts         = 0;
our $list_nameservices  = 0;
our $list_roles         = 0;
our $list_services      = 0;

env_creds("CM", "Cloudera Manager");

env_var("CM_CLUSTER", \$cluster);

our %cm_options_tls = (
    "T|tls"            => [ \$tls,          "Use TLS connection to Cloudera Manager (automatically updates port to $ssl_port if still set to $default_port to save one 302 redirect round trip)" ],
    "ssl-CA-path=s"    => [ \$ssl_ca_path,  "Path to CA certificate directory for validating SSL certificate (automatically enables --tls)" ],
    "tls-noverify"     => [ \$tls_noverify, "Do not verify SSL certificate from Cloudera Manager (automatically enables --tls)" ],
);

our %cm_option_cluster = (
    "C|cluster=s"      => [ \$cluster,      "Cluster Name as shown in Cloudera Manager (eg. \"Cluster - CDH4\", \$CM_CLUSTER)" ],
);

our %cm_options = (
    %cm_options_tls,
    %cm_option_cluster,
    "S|service=s"      => [ \$service,      "Service Name as shown in Cloudera Manager (eg. hdfs1, mapreduce4). Requires --cluster" ],
    "I|hostId=s"       => [ \$hostid,       "FQDN or HostId of node, see --list-hosts" ],
    "N|nameservice=s"  => [ \$nameservice,  "Nameservice (as specified in your HA configuration under dfs.nameservices). Requires --cluster and --service, see --list-nameservices" ],
    "R|roleId=s"       => [ \$role,         "RoleId (eg. hdfs4-NAMENODE-73d774cdeca832ac6a648fa305019cef). Requires --cluster and --service, or --CM-mgmt, see --list-roles for what to pass this option" ],
    "M|CM-mgmt"        => [ \$cm_mgmt,      "Cloudera Manager Management services" ],
);

our %cm_options_list_basic = (
    "list-clusters"     => [ \$list_clusters,           "List clusters for a given cluster service. Requires --cluster and --service" ],
    "list-hosts"        => [ \$list_hosts,              "List host id of nodes managed my Cloudera Manager" ],
    "list-services"     => [ \$list_services,           "List services for a given cluster. Convenience switch to find the serviceId to query, prints service ids and exits immediately. Requires --cluster" ],
);

our %cm_options_list = (
    "list-activities"   => [ \$list_activities,          "List activities for a given cluster service. Requires --cluster and --service" ],
    "list-nameservices" => [ \$list_nameservices,       "List nameservices for a given cluster service. Requires --cluster and --service. Service should be an HDFS service id" ],
    "list-roles"        => [ \$list_roles,              "List roles for a given cluster service. Requires --cluster and --service" ],
    %cm_options_list_basic,
);

@usage_order = qw/host port user password tls ssl-CA-path tls-noverify metrics all-metrics cluster service hostId activityId nameservice roleId CM-mgmt list-activities list-clusters list-hosts list-nameservices list-roles list-services warning critical/;

sub cm_query(;$) {
    my $no_items;
    $tls = 1 if(defined($ssl_ca_path) or defined($tls_noverify));
    if(defined($tls_noverify)){
        $ua->ssl_opts( verify_hostname => 0 );
        $tls = 1;
    }
    if(defined($ssl_ca_path)){
        $ssl_ca_path = validate_directory($ssl_ca_path, "SSL CA directory", undef, "no vlog");
        $ua->ssl_opts( SSL_ca_path => $ssl_ca_path );
        $tls = 1;
    }
    if($tls){
        vlog_option "TLS enabled",  "true";
        vlog_option "SSL CA Path",  $ssl_ca_path  if defined($ssl_ca_path);
        vlog_option "TLS noverify", $tls_noverify ? "true" : "false";
    }
    if($tls){
        $protocol = "https";
        if($port == 7180){
            vlog2 "overriding default http port 7180 to default tls port 7183";
            $port = $ssl_port;
        }
    }
    $host = validate_resolvable($host);
    $url_prefix = "$protocol://$host:$port";

    # Doesn't work
    #$ua->credentials("$host:$port", "Cloudera Manager", $user, $password);
    #$ua->credentials($host, "Cloudera Manager", $user, $password);
    $ua->show_progress(1) if $debug;

    $url = "$url_prefix$url";
    vlog2 "querying $url";
    my $req = HTTP::Request->new('GET', $url);
    $req->authorization_basic($user, $password);
    my $response = $ua->request($req);
    my $content  = $response->content;
    chomp $content;
    vlog3 "returned HTML:\n\n" . ( $content ? $content : "<blank>" ) . "\n";
    vlog2 "http code: " . $response->code;
    vlog2 "message: " . $response->message; 
    if(!$response->is_success){
        my $err = "failed to query Cloudera Manager at '$url_prefix': " . $response->code . " " . $response->message;
        if($content =~ /"message"\s*:\s*"(.+)"/){
            $err .= ". Message returned by CM: $1";
        }
        if($content =~ /java\.net\.NoRouteToHostException/i){
            $err .= " (Cluster host on which the required components are deployment must be down)";
        } elsif($content =~ /org\.apache\.avro\.AvroRemoteException: java\.net\.ConnectException: Connection refused/i){
            $err .= " (Mgmt services stopped?)";
        } elsif($response->message =~ /Can't verify SSL peers without knowing which Certificate Authorities to trust/){
            $err .= ". Do you need to use --ssl-CA-path or --tls-noverify?";
        }
        quit "CRITICAL", $err;
    }
    unless($content){
        quit "CRITICAL", "blank content returned by Cloudera Manager at '$url_prefix'";
    }

    vlog2 "parsing output from Cloudera Manager\n";

    # give a more user friendly message than the decode_json's die 'malformed JSON string, neither array, object, number, string or atom, at character offset ...'
    #isJson() used recursive regex which broke older clients
    # is_valid_json give ugly errors
    #try{
    #    is_valid_json($content) or quit "CRITICAL", "invalid json returned by Cloudera Manager at '$url_prefix', did you try to connect to the SSL port without --tls?";
    #};
    try{
        $json = decode_json $content;
    };
    catch{
        quit "invalid json returned by Cloudera Manager at '$url_prefix', did you try to connect to the SSL port without --tls?";
    };
    return $json;
}

sub check_cm_field($){
    my $field = shift;
    defined($json->{$field}) or quit "UNKNOWN", "field '$field' not returned from Cloudera Manager. $nagios_plugins_support_msg_api";
    $json->{$field} =~ /^\s*$/ and quit "UNKNOWN", "field '$field' is empty";
}

# XXX: maybe could do something more with these, such as N out of M failed
sub list_activities(;$){
    my $quit = shift;
    unless(defined($cluster) and defined($service)){
        usage "must define cluster and service to be able to list activities";
    }
    $url = "$api/clusters/$cluster/services/$service/activities";
    cm_query();
    my %activities;
    my @activities;
    foreach my $item (@{$json->{"items"}}){
        foreach(qw/name id/){
            code_error "no '$_' field returned in item from activity listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api" unless defined($item->{$_});
        }
        push(@activities, $item->{"id"} . " => " . $item->{"name"});
        $activities{$item->{"name"}} = $item->{"id"};
    }
    @activities = sort @activities;
    if($quit){
        print "activities available for cluster '$cluster', service '$service':\n\n" . join("\n", @activities) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return %activities;
}

sub list_clusters(;$){
    my $quit = shift;
    $url = "$api/clusters";
    cm_query();
    my %clusters;
    foreach my $item (@{$json->{"items"}}){
        foreach(qw/name version/){
            defined($item->{$_}) or quit "UNKNOWN", "'$_' field not returned in item from cluster listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api";
        }
        $clusters{$item->{"name"}} = $item->{"version"};
    }
    if($quit){
        print "CM clusters available:\n\n";
        printf("%-20s => CDH version\n\n", "cluster name");
        foreach(sort keys %clusters){
            printf("%-20s => %s\n", $_, $clusters{$_});
        }
        exit $ERRORS{"UNKNOWN"};
    }
    return %clusters;
}

sub list_hosts(;$){
    my $quit = shift;
    $url = "$api/hosts";
    cm_query();
    #my %hosts;
    my @hosts;
    foreach my $item (@{$json->{"items"}}){
        foreach(qw/hostname hostId/){
            defined($item->{$_}) or quit "UNKNOWN", "'$_' field not returned in item from host listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api";
        }
        #$hosts{$item->{"hostname"}} = $item->{"hostId"};
        push(@hosts, $item->{"hostname"});
    }
    @hosts = sort @hosts;
    if($quit){
        #printf("%-36s => %s\n\n", "hostId", "hostname");
        #foreach(sort keys %hosts){
        #    print $hosts{$_} . " => $_\n";
        #}
        #exit $ERRORS{"UNKNOWN"};
        print "hosts managed by Cloudera Manager:\n\n" . join("\n", @hosts) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    #return %hosts;
    return @hosts;
}

sub list_nameservices(;$){
    my $quit = shift;
    unless(defined($cluster) and defined($service)){
        usage "must define cluster and service to be able to list nameservices";
    }
    $url = "$api/clusters/$cluster/services/$service/nameservices";
    cm_query();
    my @nameservices;
    foreach(@{$json->{"items"}}){
        if(defined($_->{"name"})){
            push(@nameservices, $_->{"name"});
        } else {
            code_error "no 'name' field returned in item from nameservice listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api";
        }
    }
    @nameservices = sort @nameservices;
    if($quit){
        print "nameservices available for cluster '$cluster', service '$service':\n\n" . join("\n", @nameservices) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return @nameservices;
}

sub list_roles(;$){
    my $quit = shift;
    if(defined($cluster) and defined($service)){
        $url = "$api/clusters/$cluster/services/$service/roles";
    } elsif(defined($cm_mgmt)){
        $url = "$api/cm/service/roles";
    } else {
        usage "must define cluster and service or --CM-mgmt to be able to list roles";
    }
    cm_query();
    my @roles;
    foreach(@{$json->{"items"}}){
        if(defined($_->{"name"})){
            push(@roles, $_->{"name"});
        } else {
            code_error "no 'name' field returned in item from role listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api";
        }
    }
    @roles = sort @roles;
    if($quit){
        if(defined($cluster) and defined($service)){
            print "roles available for cluster '$cluster', service '$service':\n\n" . join("\n", @roles) . "\n";
        } elsif(defined($cm_mgmt)){
            print "roles available for CM mgmt services:\n\n" . join("\n", @roles) . "\n";
        }
        exit $ERRORS{"UNKNOWN"};
    }
    return @roles;
}

sub list_services(;$){
    my $quit = shift;
    usage "must define cluster to be able to list services" unless defined($cluster);
    $url = "$api/clusters/$cluster/services";
    cm_query();
    my @services;
    foreach(@{$json->{"items"}}){
        if(defined($_->{"name"})){
            push(@services, $_->{"name"});
        } else {
            code_error "no 'name' field returned in item from service listing from Cloudera Manager at '$url_prefix'. $nagios_plugins_support_msg_api";
        }
    }
    @services = sort @services;
    if($quit){
        print "services available for cluster '$cluster':\n\n" . join("\n", @services) . "\n";
        exit $ERRORS{"UNKNOWN"};
    }
    return @services;
}

sub listing_cm_components(){
    $list_activities    +
    $list_clusters      +
    $list_hosts         +
    $list_nameservices  +
    $list_roles         +
    $list_services;
}

sub list_cm_components(){
    if(listing_cm_components() > 1){
        usage "cannot specify more than one --list operation";
    }
    list_activities(1)    if($list_activities);
    list_clusters(1)      if($list_clusters);
    list_hosts(1)         if($list_hosts);
    list_nameservices(1)  if($list_nameservices);
    list_roles(1)         if($list_roles);
    list_services(1)      if($list_services);
}

sub validate_cm_activity(){
    defined($activity) or usage "activity not defined";
    $activity =~ /^\s*([\w-]+)\s*$/ or usage "Invalid activity given, must be alphanumeric with dashes";
    $activity = $1;
    vlog_option "activity", $activity;
    return $activity;
}

sub validate_cm_cluster(){
    defined($cluster) or usage "cluster not defined";
    $cluster    =~ /^\s*([\w\s\.-]+)\s*$/ or usage "Invalid cluster name given, may only contain alphanumeric, space, dash, dots or underscores";
    $cluster = $1;
    vlog_option "cluster", $cluster;
    return $cluster;
}

sub validate_cm_hostid(){
    defined($hostid) or usage "host id not defined";
    $hostid = isHostname($hostid) || usage "invalid host id given";
    vlog_option "hostId", "$hostid";
    return $hostid;
}

sub validate_cm_nameservice(){
    defined($nameservice) or usage "nameservice not defined";
    $nameservice =~ /^\s*([\w-]+)\s*$/ or usage "Invalid nameservice given, must be alphanumeric with dashes";
    $nameservice = $1;
    vlog_option "nameservice", $nameservice;
    return $nameservice;
}

sub validate_cm_role(){
    defined($role) or usage "role not defined";
    $role =~ /^\s*([\w-]+-\w+-\w+)\s*$/ or usage "Invalid role id given, expected in format such as <service>-<role>-<hexid> (eg hdfs4-NAMENODE-73d774cdeca832ac6a648fa305019cef). Use --list-roles to see available roles + IDs for a given cluster service";
    $role = $1;
    vlog_option "roleId", $role;
    return $role;
}

sub validate_cm_service(){
    defined($service) or usage "service not defined";
    $service    =~ /^\s*([\w-]+)\s*$/ or usage "Invalid service name given, must be alphanumeric with dashes";
    $service = $1;
    vlog_option "service", $service;
    return $service;
}

sub validate_cm_cluster_options(){
    defined($hostid and ($cluster or $service or $activity or $nameservice or $role)) and usage "cannot mix --hostId with other options such as and --cluster/service/roleId/activityId at the same time";
    if(defined($cluster) and defined($service)){
        $cluster    = validate_cm_cluster();
        $service    = validate_cm_service();
        $url = "$api/clusters/$cluster/services/$service";
        if(defined($activity)){
            $activity = validate_cm_activity();
            $url .= "/activities/$activity";
        } elsif(defined($nameservice)){
            $nameservice = validate_cm_nameservice();
            $url .= "/nameservices/$nameservice";
        } elsif(defined($role)){
            $role = validate_cm_role();
            $url .= "/roles/$role";
        }
    } elsif(defined($hostid)){
        $hostid = validate_cm_hostid();
        $url .= "$api/hosts/$hostid";
    } elsif(listing_cm_components()){
    } else {
        usage "no valid combination of types given, must be one of the following combinations:

    --cluster --service
    --cluster --service --activityId
    --cluster --service --nameservice
    --cluster --service --roleId
    --hostId
    ";
    }
    if(listing_cm_components() > 1){
        usage "cannot specify more than one --list operation";
    }
}

1;
