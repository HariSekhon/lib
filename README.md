Hari Sekhon Perl Library
========================
[![Build Status](https://travis-ci.org/HariSekhon/lib.svg?branch=master)](https://travis-ci.org/HariSekhon/lib)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b74a91c19a5845e2961533a5933381db)](https://www.codacy.com/app/harisekhon/lib)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/lib#hari-sekhon-perl-library)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

My personal Perl library, full of lots of validation code and utility functions.

Needed for a lot of the programs I've written over the years. In fact my current main library was actually cobbled together from lots of pieces of code I wrote over the years since I found myself reusing common things over and over. This drastically reduces the amount of code and effort required to write new robust well validated code which is why it's used extensively throughout the portions of code you'll find on my GitHub account, especially all the Advanced Nagios Plugins Collection which I've been developing for many years since 2006

#### Build + Unit Tests ####

```
make &&
make test
```

Continuous Integration is run on this repo to build and unit test it (Test::More, almost 800 unit tests).

#### Configuration ####

Strict validations include host/domain/FQDNs using TLDs which are populated from the official IANA list, a snapshot of which is shipped as part of this project.

To update the bundled official IANA TLD list with the latest valid TLDs do
```
make tld
```
##### Custom TLDs #####

If using bespoke internal domains such as ```.local``` or ```.intranet``` that aren't part of the official IANA TLD list then this is additionally supported via a custom configuration file [resources/custom_tlds.txt](https://github.com/HariSekhon/lib/blob/master/resources/custom_tlds.txt) containing one TLD per line, with support for # comment prefixes. Just add your bespoke internal TLD to the file and it will then pass the host/domain/fqdn validations.

##### IO::Socket::SSL doesn't respect ignoring self-signed certs in recent version(s) eg. 2.020 #####

Recent version(s) of IO::Socket::SSL (2.020) seem to fail to respect options to ignore self-signed certs. The workaround is to create the hidden touch file below in the same top-level directory as the library to make it include and use Net::SSL instead of IO::Socket::SSL.
```
touch .use_net_ssl
```

#### See Also ####

Python and Java ports of this library can be found below - both with higher levels of code coverage testing:

* [Java library](https://github.com/harisekhon/lib-java)
* [Python library](https://github.com/harisekhon/pylib)

Repos using this library:

* [Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 220+ programs - the largest repo of monitoring code for Hadoop & NoSQL technologies, every Hadoop vendor's management API and every major NoSQL technology (HBase, Cassandra, MongoDB, Elasticsearch, Solr, Riak, Redis etc.) as well as traditional Linux and infrastructure
* [Tools](https://github.com/harisekhon/tools) - 30+ tools for Hadoop, NoSQL, Solr, Elasticsearch, Pig, Hive, Web URL + Nginx stats watchers, SQL and NoSQL syntax recasers, various Linux CLI tools
* [PyTools](https://github.com/harisekhon/pytools) - Hadoop, Spark (PySpark), Pig => Solr / Elasticsearch indexers, Pig Jython UDFs, Ambari Blueprints, AWS CloudFormation templates, HBase, Linux, IPython Notebook, Data converters between different data formats and syntactic validators for Avro, Parquet, CSV, JSON, YAML...
* [Spotify Lookup & Command Line Controller](https://github.com/harisekhon/spotify) - converts Spotify URIs to 'Artist - Track' form by querying the Spotify Metadata API. Spotify Cmd - command line control of Spotify on Mac via AppleScript calls. Useful for automation.
