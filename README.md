Hari Sekhon Libraries [![Build Status](https://travis-ci.org/harisekhon/lib.svg?branch=master)](https://travis-ci.org/harisekhon/lib)
=====================

My personal libraries, full of lots of validation code and utility functions.

Needed for a lot of the programs I've written over the years. In fact my current main library was actually cobbled together from lots of pieces of code I wrote over the years since I found myself reusing common things over and over. This drastically reduces the amount of code and effort required to write new robust well validated code which is why it's used extensively throughout the portions of code you'll find on my GitHub account, especially all the Advanced Nagios Plugins Collection which I've been developing for many years since 2006

#### Build + Unit Tests ####

```
make &&
make test
```

Continuous Integration is run on this repo to build and unit test it.

#### See Also ####

* [Java version of this library](https://github.com/harisekhon/lib-java)

Repos using this library:

* [Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - the largest repo of monitoring code for Hadoop & NoSQL technologies, every Hadoop vendor's management API and every major NoSQL technology (HBase, Cassandra, MongoDB, Elasticsearch, Solr, Riak, Redis etc.) as well as traditional Linux and infrastructure
* [Toolbox](https://github.com/harisekhon/toolbox) - Hadoop, NoSQL, Solr, Elasticsearch, Pig, Hive, Web, Linux CLI tools
* [Spotify Lookup & Cmd](https://github.com/harisekhon/spotify)
