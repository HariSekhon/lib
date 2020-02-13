Hari Sekhon Perl Library
========================
[![Build Status](https://travis-ci.org/HariSekhon/lib.svg?branch=master)](https://travis-ci.org/HariSekhon/lib)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b74a91c19a5845e2961533a5933381db)](https://www.codacy.com/app/harisekhon/lib)
[![GitHub stars](https://img.shields.io/github/stars/harisekhon/lib.svg)](https://github.com/harisekhon/lib/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/harisekhon/lib.svg)](https://github.com/harisekhon/lib/network)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/lib#hari-sekhon-perl-library)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

[![CI Mac](https://github.com/HariSekhon/lib/workflows/CI%20Mac/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Mac%22)
[![CI Ubuntu](https://github.com/HariSekhon/lib/workflows/CI%20Ubuntu/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Ubuntu%22)
[![CI Ubuntu 14.04](https://github.com/HariSekhon/lib/workflows/CI%20Ubuntu%2014.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Ubuntu+14.04%22)
[![CI Ubuntu 16.04](https://github.com/HariSekhon/lib/workflows/CI%20Ubuntu%2016.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Ubuntu+16.04%22)
[![CI Ubuntu 18.04](https://github.com/HariSekhon/lib/workflows/CI%20Ubuntu%2018.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Ubuntu+18.04%22)
[![CI CentOS](https://github.com/HariSekhon/lib/workflows/CI%20CentOS/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+CentOS%22)
[![CI CentOS 7](https://github.com/HariSekhon/lib/workflows/CI%20CentOS%207/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+CentOS+7%22)
[![CI CentOS 8](https://github.com/HariSekhon/lib/workflows/CI%20CentOS%208/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+CentOS+8%22)
[![CI Fedora](https://github.com/HariSekhon/lib/workflows/CI%20Fedora/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Fedora%22)
[![CI Alpine](https://github.com/HariSekhon/lib/workflows/CI%20Alpine/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CI+Alpine%22)

My personal Perl library, full of lots of validation code and utility functions.

Needed for a lot of the programs I've written over the years. In fact my current main library was actually cobbled together from lots of pieces of code I wrote over the years since I found myself reusing common things over and over. This drastically reduces the amount of code and effort required to write new robust well validated code which is why it's used extensively throughout the portions of code you'll find on my GitHub account, especially all the Advanced Nagios Plugins Collection which I've been developing for many years since 2006

Hari Sekhon

Cloud & Big Data Contractor, United Kingdom

(ex-Cloudera, former Hortonworks Consultant)

[https://www.linkedin.com/in/harisekhon](https://www.linkedin.com/in/harisekhon)
###### (you're welcome to connect with me on LinkedIn)

#### Build + Unit Tests ####

```
make &&
make test
```

[Continuous Integration](https://travis-ci.org/HariSekhon/lib) is run on this repo to build and unit test it (Test::More, almost 800 unit tests).

#### Configuration ####

Strict validations include host/domain/FQDNs using TLDs which are populated from the official IANA list, a snapshot of which is shipped as part of this project.

To update the bundled official IANA TLD list with the latest valid TLDs do
```
make tld
```
##### Custom TLDs #####

If using bespoke internal domains such as `.local`, `.intranet`, `.vm`, `.cloud` etc. that aren't part of the official IANA TLD list then this is additionally supported via a custom configuration file [resources/custom_tlds.txt](https://github.com/HariSekhon/lib/blob/master/resources/custom_tlds.txt) containing one TLD per line, with support for # comment prefixes. Just add your bespoke internal TLD to the file and it will then pass the host/domain/fqdn validations.

##### IO::Socket::SSL doesn't respect ignoring self-signed certs in recent version(s) eg. 2.020 #####

Recent version(s) of IO::Socket::SSL (2.020) seem to fail to respect options to ignore self-signed certs. The workaround is to create the hidden touch file below in the same top-level directory as the library to make it include and use Net::SSL instead of IO::Socket::SSL.
```
touch .use_net_ssl
```

#### See Also ####

Python and Java ports of this library can be found below - both with higher levels of code coverage testing:

* [Java library](https://github.com/harisekhon/lib-java)
* [Python library](https://github.com/harisekhon/pylib)

See also:

* [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) - 80+ DevOps CLI tools for AWS, Hadoop, HBase, Spark, Log Anonymizer, Ambari Blueprints, AWS CloudFormation, Linux, Docker, Spark Data Converters & Validators (Avro / Parquet / JSON / CSV / INI / XML / YAML), Elasticsearch, Solr, Travis CI, Pig, IPython

* [The Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 450+ programs for Nagios monitoring your Hadoop & NoSQL clusters. Covers every Hadoop vendor's management API and every major NoSQL technology (HBase, Cassandra, MongoDB, Elasticsearch, Solr, Riak, Redis etc.) as well as message queues (Kafka, RabbitMQ), continuous integration (Jenkins, Travis CI) and traditional infrastructure (SSL, Whois, DNS, Linux)

* [DevOps Bash Tools](https://github.com/harisekhon/devops-bash-tools) - 100+ DevOps Bash scripts, advanced `.bashrc`, `.vimrc`, `.screenrc`, `.tmux.conf`, `.toprc`, Utility Code Library used by CI and all my GitHub repos - includes code for AWS, Kubernetes, Kafka, Docker, Git, Code & build linting, package management for Linux / Mac / Perl / Python / Ruby / Golang, and lots more random goodies

* [DevOps Perl Tools](https://github.com/harisekhon/perl-tools) - 25+ DevOps CLI tools for Hadoop, HDFS, Hive, Solr/SolrCloud CLI, Log Anonymizer, Nginx stats & HTTP(S) URL watchers for load balanced web farms, Dockerfiles & SQL ReCaser (MySQL, PostgreSQL, AWS Redshift, Snowflake, Apache Drill, Hive, Impala, Cassandra CQL, Microsoft SQL Server, Oracle, Couchbase N1QL, Dockerfiles, Pig Latin, Neo4j, InfluxDB), Ambari FreeIPA Kerberos, Datameer, Linux...

* [HAProxy-configs](https://github.com/harisekhon/haproxy-configs) - 80+ HAProxy Configs for Hadoop, Big Data, NoSQL, Docker, Elasticsearch, SolrCloud, HBase, Cloudera, Hortonworks, MapR, MySQL, PostgreSQL, Apache Drill, Hive, Presto, Impala, ZooKeeper, OpenTSDB, InfluxDB, Prometheus, Kibana, Graphite, SSH, RabbitMQ, Redis, Riak, Rancher etc.

* [Dockerfiles](https://github.com/HariSekhon/Dockerfiles) - 50+ DockerHub public images for Docker & Kubernetes - Hadoop, Kafka, ZooKeeper, HBase, Cassandra, Solr, SolrCloud, Presto, Apache Drill, Nifi, Spark, Mesos, Consul, Riak, OpenTSDB, Jython, Advanced Nagios Plugins & DevOps Tools repos on Alpine, CentOS, Debian, Fedora, Ubuntu, Superset, H2O, Serf, Alluxio / Tachyon, FakeS3
