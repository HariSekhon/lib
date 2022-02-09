Hari Sekhon - Perl Library
==========================

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b74a91c19a5845e2961533a5933381db)](https://www.codacy.com/app/harisekhon/lib)
[![CodeFactor](https://www.codefactor.io/repository/github/harisekhon/lib/badge)](https://www.codefactor.io/repository/github/harisekhon/lib)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=HariSekhon_lib&metric=alert_status)](https://sonarcloud.io/dashboard?id=HariSekhon_lib)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=HariSekhon_lib&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=HariSekhon_lib)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=HariSekhon_lib&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=HariSekhon_lib)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=HariSekhon_lib&metric=security_rating)](https://sonarcloud.io/dashboard?id=HariSekhon_lib)
[![GitHub stars](https://img.shields.io/github/stars/harisekhon/lib?logo=github)](https://github.com/harisekhon/lib/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/harisekhon/lib?logo=github)](https://github.com/harisekhon/lib/network)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/HariSekhon/lib?logo=github)](https://github.com/HariSekhon/lib/commits/master)
[![Lines of Code](https://img.shields.io/badge/lines%20of%20code-10k-lightgrey?logo=codecademy)](https://github.com/HariSekhon/lib)
[![License](https://img.shields.io/github/license/HariSekhon/lib)](https://github.com/HariSekhon/lib/blob/master/LICENSE)
<!-- measure not found
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=HariSekhon_lib&metric=ncloc)](https://sonarcloud.io/dashboard?id=HariSekhon_lib)
-->

[![Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux)](https://github.com/harisekhon/lib#hari-sekhon---perl-library)
[![Mac](https://img.shields.io/badge/OS-Mac-blue?logo=apple)](https://github.com/harisekhon/lib#hari-sekhon---perl-library)
[![Docker](https://img.shields.io/badge/container-Docker-blue?logo=docker&logoColor=white)](https://hub.docker.com/r/harisekhon/github/)
[![Dockerfile](https://img.shields.io/badge/repo-Dockerfiles-blue?logo=docker&logoColor=white)](https://github.com/HariSekhon/Dockerfiles)
[![DockerHub Pulls](https://img.shields.io/docker/pulls/harisekhon/centos-github?label=DockerHub%20pulls&logo=docker&logoColor=white)](https://hub.docker.com/r/harisekhon/github)
[![DockerHub Build Automated](https://img.shields.io/docker/automated/harisekhon/centos-github?logo=docker&logoColor=white)](https://hub.docker.com/r/harisekhon/centos-github)
<!-- these badges don't work any more
[![Docker Build Status](https://img.shields.io/docker/cloud/build/harisekhon/centos-github?logo=docker&logoColor=white)](https://hub.docker.com/r/harisekhon/centos-github/builds)
[![MicroBadger](https://images.microbadger.com/badges/image/harisekhon/github.svg)](http://microbadger.com/#/images/harisekhon/github)
-->

[![CI Builds Overview](https://img.shields.io/badge/CI%20Builds-Overview%20Page-blue?logo=circleci)](https://bitbucket.org/harisekhon/devops-bash-tools/src/master/STATUS.md)
[![Jenkins](https://img.shields.io/badge/Jenkins-ready-blue?logo=jenkins&logoColor=white)](https://github.com/HariSekhon/lib/blob/master/Jenkinsfile)
[![Concourse](https://img.shields.io/badge/Concourse-ready-blue?logo=concourse)](https://github.com/HariSekhon/lib/blob/master/.concourse.yml)
[![GoCD](https://img.shields.io/badge/GoCD-ready-blue?logo=go)](https://github.com/HariSekhon/lib/blob/master/.gocd.yml)
[![TeamCity](https://img.shields.io/badge/TeamCity-ready-blue?logo=teamcity)](https://github.com/HariSekhon/TeamCity-CI)

[![Travis CI](https://img.shields.io/badge/TravisCI-legacy-lightgrey?logo=travis&label=Travis%20CI)](https://github.com/HariSekhon/lib/blob/master/.travis.yml)
[![AppVeyor](https://img.shields.io/appveyor/build/harisekhon/lib/master?logo=appveyor&label=AppVeyor)](https://ci.appveyor.com/project/HariSekhon/lib/branch/master)
[![Drone](https://img.shields.io/drone/build/HariSekhon/lib/master?logo=drone&label=Drone)](https://cloud.drone.io/HariSekhon/lib)
[![CircleCI](https://circleci.com/gh/HariSekhon/lib.svg?style=svg)](https://circleci.com/gh/HariSekhon/lib)
[![Codeship Status for HariSekhon/lib](https://app.codeship.com/projects/44957fe0-3c5f-0138-07d2-66210e546d42/status?branch=master)](https://app.codeship.com/projects/387244)
[![Shippable](https://img.shields.io/shippable/5e52c6364c324200063326d5/master?label=Shippable&logo=jfrog)](https://app.shippable.com/github/HariSekhon/lib/dashboard/jobs)
[![BuildKite](https://img.shields.io/buildkite/ee85ef275ba64807fc2efce47336b0e0d92a1cba7fcc94b584/master?label=BuildKite&logo=buildkite)](https://buildkite.com/hari-sekhon/lib)
[![Codefresh](https://g.codefresh.io/api/badges/pipeline/harisekhon/GitHub%2Flib?branch=master&key=eyJhbGciOiJIUzI1NiJ9.NWU1MmM5OGNiM2FiOWUzM2Y3ZDZmYjM3.O69674cW7vYom3v5JOGKXDbYgCVIJU9EWhXUMHl3zwA&type=cf-1)](https://g.codefresh.io/pipelines/edit/new/builds?id=5e58e2c43953b7316b4b7903&pipeline=lib&projects=GitHub&projectId=5e52ca8ea284e00f882ea992&context=github&filter=page:1;pageSize:10;timeFrameStart:week)
[![Cirrus CI](https://img.shields.io/cirrus/github/HariSekhon/lib/master?logo=Cirrus%20CI&label=Cirrus%20CI)](https://cirrus-ci.com/github/HariSekhon/lib)
[![Semaphore](https://harisekhon.semaphoreci.com/badges/lib.svg)](https://harisekhon.semaphoreci.com/projects/lib)
[![Wercker](https://app.wercker.com/status/7af643f46ecad1311bc1200fd42e509b/s/master "wercker status")](https://app.wercker.com/harisekhon/lib/runs)
[![Buddy](https://img.shields.io/badge/Buddy-ready-1A86FD?logo=buddy)](https://github.com/HariSekhon/lib/blob/master/buddy.yml)
<!--[![Wercker](https://img.shields.io/wercker/ci/5e58eec714b91a0800356b5b/master?label=Wercker&logo=oracle)](https://app.wercker.com/harisekhon/lib/runs)-->

[![Azure DevOps](https://dev.azure.com/harisekhon/GitHub/_apis/build/status/HariSekhon.lib?branchName=master)](https://dev.azure.com/harisekhon/GitHub/_build/latest?definitionId=3&branchName=master)
[![GitLab Pipeline](https://img.shields.io/gitlab/pipeline/harisekhon/lib?logo=gitlab&label=GitLab%20CI)](https://gitlab.com/HariSekhon/lib/pipelines)
[![BitBucket Pipeline](https://img.shields.io/bitbucket/pipelines/harisekhon/lib/master?logo=bitbucket&label=BitBucket%20CI)](https://bitbucket.org/harisekhon/lib/addon/pipelines/home#!/)
[![AWS CodeBuild](https://img.shields.io/badge/AWS%20CodeBuild-ready-blue?logo=amazon%20aws)](https://github.com/HariSekhon/lib/blob/master/buildspec.yml)
[![GCP Cloud Build](https://img.shields.io/badge/GCP%20Cloud%20Build-ready-blue?logo=google%20cloud&logoColor=white)](https://github.com/HariSekhon/lib/blob/master/cloudbuild.yaml)

[![Repo on Azure DevOps](https://img.shields.io/badge/repo-Azure%20DevOps-0078D7?logo=azure%20devops)](https://dev.azure.com/harisekhon/GitHub/_git/lib)
[![Repo on GitHub](https://img.shields.io/badge/repo-GitHub-2088FF?logo=github)](https://github.com/HariSekhon/lib)
[![Repo on GitLab](https://img.shields.io/badge/repo-GitLab-FCA121?logo=gitlab)](https://gitlab.com/HariSekhon/lib)
[![Repo on BitBucket](https://img.shields.io/badge/repo-BitBucket-0052CC?logo=bitbucket)](https://bitbucket.org/HariSekhon/lib)
[![Validation](https://github.com/HariSekhon/lib/actions/workflows/validate.yaml/badge.svg)](https://github.com/HariSekhon/lib/actions/workflows/validate.yaml)
[![Semgrep](https://github.com/HariSekhon/lib/actions/workflows/semgrep.yaml/badge.svg)](https://github.com/HariSekhon/lib/actions/workflows/semgrep.yaml)

[![GitHub Actions Ubuntu](https://github.com/HariSekhon/lib/workflows/GitHub%20Actions%20Ubuntu/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22GitHub+Actions+Ubuntu%22)
[![Mac](https://github.com/HariSekhon/lib/workflows/Mac/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Mac%22)
[![Mac 10.15](https://github.com/HariSekhon/lib/workflows/Mac%2010.15/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Mac+10.15%22)
[![Ubuntu](https://github.com/HariSekhon/lib/workflows/Ubuntu/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Ubuntu%22)
[![Ubuntu 14.04](https://github.com/HariSekhon/lib/workflows/Ubuntu%2014.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Ubuntu+14.04%22)
[![Ubuntu 16.04](https://github.com/HariSekhon/lib/workflows/Ubuntu%2016.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Ubuntu+16.04%22)
[![Ubuntu 18.04](https://github.com/HariSekhon/lib/workflows/Ubuntu%2018.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Ubuntu+18.04%22)
[![Ubuntu 20.04](https://github.com/HariSekhon/lib/workflows/Ubuntu%2020.04/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Ubuntu+20.04%22)
[![Debian](https://github.com/HariSekhon/lib/workflows/Debian/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Debian%22)
[![Debian 8](https://github.com/HariSekhon/lib/workflows/Debian%208/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Debian+8%22)
[![Debian 9](https://github.com/HariSekhon/lib/workflows/Debian%209/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Debian+9%22)
[![Debian 10](https://github.com/HariSekhon/lib/workflows/Debian%2010/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Debian+10%22)
[![CentOS](https://github.com/HariSekhon/lib/workflows/CentOS/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CentOS%22)
[![CentOS 7](https://github.com/HariSekhon/lib/workflows/CentOS%207/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CentOS+7%22)
[![CentOS 8](https://github.com/HariSekhon/lib/workflows/CentOS%208/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22CentOS+8%22)
[![Fedora](https://github.com/HariSekhon/lib/workflows/Fedora/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Fedora%22)
[![Alpine](https://github.com/HariSekhon/lib/workflows/Alpine/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Alpine%22)
[![Alpine 3](https://github.com/HariSekhon/lib/workflows/Alpine%203/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Alpine+3%22)

[![Perl versions](https://img.shields.io/badge/Perl-5.10+-39457E?logo=perl)](https://github.com/HariSekhon/lib)
[![Perl](https://github.com/HariSekhon/lib/workflows/Perl/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl%22)
[![Perl 5.10](https://github.com/HariSekhon/lib/workflows/Perl%205.10/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.10%22)
[![Perl 5.12](https://github.com/HariSekhon/lib/workflows/Perl%205.12/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.12%22)
[![Perl 5.14](https://github.com/HariSekhon/lib/workflows/Perl%205.14/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.14%22)
[![Perl 5.16](https://github.com/HariSekhon/lib/workflows/Perl%205.16/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.16%22)
[![Perl 5.18](https://github.com/HariSekhon/lib/workflows/Perl%205.18/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.18%22)
[![Perl 5.20](https://github.com/HariSekhon/lib/workflows/Perl%205.20/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.20%22)
[![Perl 5.22](https://github.com/HariSekhon/lib/workflows/Perl%205.22/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.22%22)
[![Perl 5.24](https://github.com/HariSekhon/lib/workflows/Perl%205.24/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.24%22)
[![Perl 5.26](https://github.com/HariSekhon/lib/workflows/Perl%205.26/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.26%22)
[![Perl 5.28](https://github.com/HariSekhon/lib/workflows/Perl%205.28/badge.svg)](https://github.com/HariSekhon/lib/actions?query=workflow%3A%22Perl+5.28%22)

Perl library, full of lots of validation code and utility functions.

Needed for a lot of the programs I've written over the years. In fact my current main library was actually cobbled together from lots of pieces of code I wrote over the years since I found myself reusing common things over and over. This drastically reduces the amount of code and effort required to write new robust well validated code which is why it's used extensively throughout the portions of code you'll find on my GitHub account, especially all the Advanced Nagios Plugins Collection which I've been developing for many years since 2006

Hari Sekhon

Cloud & Big Data Contractor, United Kingdom

[![My LinkedIn](https://img.shields.io/badge/LinkedIn%20Profile-HariSekhon-blue?logo=linkedin)](https://www.linkedin.com/in/harisekhon/)
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

- [Java library](https://github.com/harisekhon/lib-java)
- [Python library](https://github.com/harisekhon/pylib)

See also:

- [DevOps Bash Tools](https://github.com/harisekhon/devops-bash-tools) - 700+ DevOps Bash Scripts, Advanced `.bashrc`, `.vimrc`, `.screenrc`, `.tmux.conf`, `.gitconfig`, CI configs & Utility Code Library - AWS, GCP, Kubernetes, Docker, Kafka, Hadoop, SQL, BigQuery, Hive, Impala, PostgreSQL, MySQL, LDAP, DockerHub, Jenkins, Spotify API & MP3 tools, Git tricks, GitHub API, GitLab API, BitBucket API, Code & build linting, package management for Linux / Mac / Python / Perl / Ruby / NodeJS / Golang, and lots more random goodies

- [SQL Scripts](https://github.com/HariSekhon/SQL-scripts) - 100+ SQL Scripts - PostgreSQL, MySQL, AWS Athena, Google BigQuery

- [Templates](https://github.com/HariSekhon/Templates) - dozens of Code & Config templates - AWS, GCP, Docker, Jenkins, Terraform, Vagrant, Puppet, Python, Bash, Go, Perl, Java, Scala, Groovy, Maven, SBT, Gradle, Make, GitHub Actions Workflows, CircleCI, Jenkinsfile, Makefile, Dockerfile, docker-compose.yml, M4 etc.

- [Kubernetes configs](https://github.com/HariSekhon/Kubernetes-configs) - Kubernetes YAML configs - Best Practices, Tips & Tricks are baked right into the templates for future deployments

- [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) - 80+ DevOps CLI tools for AWS, GCP, Hadoop, HBase, Spark, Log Anonymizer, Ambari Blueprints, AWS CloudFormation, Linux, Docker, Spark Data Converters & Validators (Avro / Parquet / JSON / CSV / INI / XML / YAML), Elasticsearch, Solr, Travis CI, Pig, IPython

- [The Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 450+ programs for Nagios monitoring your Hadoop & NoSQL clusters. Covers every Hadoop vendor's management API and every major NoSQL technology (HBase, Cassandra, MongoDB, Elasticsearch, Solr, Riak, Redis etc.) as well as message queues (Kafka, RabbitMQ), continuous integration (Jenkins, Travis CI) and traditional infrastructure (SSL, Whois, DNS, Linux)

- [DevOps Perl Tools](https://github.com/harisekhon/perl-tools) - 25+ DevOps CLI tools for Hadoop, HDFS, Hive, Solr/SolrCloud CLI, Log Anonymizer, Nginx stats & HTTP(S) URL watchers for load balanced web farms, Dockerfiles & SQL ReCaser (MySQL, PostgreSQL, AWS Redshift, Snowflake, Apache Drill, Hive, Impala, Cassandra CQL, Microsoft SQL Server, Oracle, Couchbase N1QL, Dockerfiles, Pig Latin, Neo4j, InfluxDB), Ambari FreeIPA Kerberos, Datameer, Linux...

- [HAProxy Configs](https://github.com/HariSekhon/HAProxy-configs) - 80+ HAProxy Configs for Hadoop, Big Data, NoSQL, Docker, Elasticsearch, SolrCloud, HBase, Cloudera, Hortonworks, MapR, MySQL, PostgreSQL, Apache Drill, Hive, Presto, Impala, ZooKeeper, OpenTSDB, InfluxDB, Prometheus, Kibana, Graphite, SSH, RabbitMQ, Redis, Riak, Rancher etc.

- [Dockerfiles](https://github.com/HariSekhon/Dockerfiles) - 50+ DockerHub public images for Docker & Kubernetes - Hadoop, Kafka, ZooKeeper, HBase, Cassandra, Solr, SolrCloud, Presto, Apache Drill, Nifi, Spark, Mesos, Consul, Riak, OpenTSDB, Jython, Advanced Nagios Plugins & DevOps Tools repos on Alpine, CentOS, Debian, Fedora, Ubuntu, Superset, H2O, Serf, Alluxio / Tachyon, FakeS3

[git.io/perl-lib](https://git.io/perl-lib)
