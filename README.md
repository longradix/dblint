# dblint
A MySQL database linter

Manually reviewing the quality of a database schema is time consuming and error-prone. This tool, dblint, automates the analysis of database design by statically applying database design rules. New design rules can be easily added. There are two rule types: the metadata level and the data level.

dblint has been implemented and evaluated on MySQL and its derivatives.

Implemented from https://projekter.aau.dk/projekter/en/studentthesis/dblint-a-tool-for-automated-analysis-of-database-design(f9f7ad9f-6043-4424-82e2-5e4a1d1ad875).html From this source the numbering scheme has been reused as much as possible; not all rules are implemented.

Read dblint_overview to see which rules are implemented.
Use dblint-script to run all rules on the mysql command line.
The scripts create the following tables within the same schema as specified in dblint-script:
* dblint_debug: debugging messages; for development purposes only
* dblint_results: results from running dblint
* dblint_rules: the dblint rules which have been implemented
