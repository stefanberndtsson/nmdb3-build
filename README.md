NoCrew Movie Database Builder
=============================

Description
-----------

Downloads, read, parses and fiddles with the files IMDb publishes, to construct a PostgreSQL database
that's actually usable. In my case with my other project, nmdb3 which is a Rails app talking to this DB.

This takes a long time to build. Approximately 6 hours on a Core2duo, 1.86GHz with 8GB of memory. It also
uses around 6GB of RAM just for the ruby process.


Requirements and setup
----------------------

* Ruby 1.9.x
* JRuby 1.6.x (Should technically not be necessary, but it can thread properly, hence speed up one part of this)
* PostgreSQL 8.x or newer with contrib files (fuzzystrmatch)
* Sphinxsearch 0.9.9 (It may work with other versions, but I've never tried)

There are three config files in YAML format.

* build.conf.sample
* db.conf.sample
* sphinxsearch.conf.sample

You have to create a corresponding file for each of these without the .sample extension and edit them to match
your needs.

Sphinxsearch has a sample config file in sphinx.conf.sample. Make sure it's setup properly and that the user
used to connect to PostgreSQL has sufficient rights to read the sphinx tables and views.

Once setup, run either (default rake job is upgrade):
* "rake install" for a fresh installation without reusing id's from a previous run
* "rake upgrade" for dumping id's before rebuilding


How does it work?
-----------------

* Download files via FTP using open-uri
* Decompress each file using zlib
* Convert files to UTF-8 using iconv
* Restart PostgreSQL (this is done to reduce the memory footprint of PostgreSQL while building)
* If upgrading, dump old movies and people id's from the previously created database, otherwise create empty files
* (fork) Convert each file in turn to a series of tab separated files
* Create a temporary database
* Load basic schema
* Add fuzzystrmatch.sql to DB
* Load data from tab-files to tempdb
* Link TV-Series episodes to main item for the series
* Build some indexes
* Fill TV-Series main item with cast/character data from episodes
* Build more indexes
* Create tables with summaries for keywords, genres and languages (used for similarity comparisons)
* Run a long job through jruby building a massive comparison table (uses around 13GB with index on disk)
* Load the massive table
* Create index on massive table
* Create tables and views used for indexing in Sphinxsearch
* Create tables and indexes for tables used for suggestions (fuzzy-match)
* Restart PostgreSQL so we can be fairly sure noone's using the database
* If exists, remove the previously saved database
* If exists, rename the currently active database to save it
* Rename our temporary database to the active one
* Start Sphinxsearch reindexing
* Restart Apache

The fork when converting files is done to keep the extreme RAM usage separate from the rest of the Rake process.
Without it, the allocated memory would remain within the process for the whole build process. This would cause
severe swapping when jruby gets going.
