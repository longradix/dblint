# dblint
A MySQL database linter

Manually reviewing the quality of a database schema is time consuming and error-prone. This tool, dblint, automates the analysis of database design by statically applying database design rules. New design rules can be easily added. There are two rule types: the metadata level or the data level.

dblint has been implemented and evaluated on MySQL and its derivatives.

Immplemented from https://projekter.aau.dk/projekter/en/studentthesis/dblint-a-tool-for-automated-analysis-of-database-design(f9f7ad9f-6043-4424-82e2-5e4a1d1ad875).html where the numbering scheme has been reused as much as possible and not all rules are implemented:

+----+------------------------------------------------------------------------+----------+-------------+
| id | name                                                                   | severity | implemented |
+----+------------------------------------------------------------------------+----------+-------------+
|  0 | Non-InnoDB tables present, ie temporary data                           | info     | y           |
|  1 | Missing primary keys                                                   | error    | y           |
|  2 | Different data type between source and target columns in a foreign key | error    | o           |
|  3 | Varchar columns of length zero                                         | error    | y           |
|  4 | Inconsistent naming convention of tables and columns                   | warning  | y           |
|  5 | Inappropriate length of default value for CHAR columns                 | warning  | y           |
|  6 | Redundant foreign keys                                                 | warning  | o           |
|  7 | Tables with too few columns                                            | error    | y           |
|  8 | Too big indices                                                        | warning  | o           |
|  9 | Too many nullable columns                                              | warning  | y           |
| 10 | Too long column names                                                  | warning  | y           |
| 11 | Nullable and unique columns                                            | warning  | y           |
| 12 | Cycles between tables                                                  | warning  | n           |
| 13 | Inconsistent max lengths of varchar columns                            | warning  | n           |
| 14 | Self-referencing primary key                                           | error    | y           |
| 15 | Inconsistent data types in column sequence                             | warning  | n           |
| 16 | Missing column in a sequence of columns                                | warning  | n           |
| 17 | Primary- and unique-key constraints on the same columns                | warning  | y           |
| 18 | Redundant indices                                                      | warning  | o           |
| 19 | Too short column names                                                 | warning  | y           |
| 20 | Too many text columns in a table                                       | warning  | y           |
| 21 | Foreign-key without index                                              | warning  | o           |
| 22 | Primary-key columns not positioned first                               | warning  | y           |
| 23 | Use of reserved words from SQL                                         | warning  | y           |
| 24 | Different data types for columns with the same name                    | error    | y           |
| 25 | Use of special characters in identifiers                               | warning  | y           |
| 26 | Table islands                                                          | warning  | n           |
| 27 | Too large varchar columns                                              | warning  | y           |
| 28 | Duplicate rows in a table                                              | error    | y           |
| 29 | Storing lists in varchar columns                                       | error    | y           |
| 30 | Wrong representation of boolean values                                 | warning  | n           |
| 31 | Defined primary key is not a minimal key                               | error    | y           |
| 32 | Redundant columns                                                      | warning  | y           |
| 33 | All values equal the default value                                     | warning  | y           |
| 34 | Not-NULL columns containing many empty strings                         | warning  | y           |
| 35 | Numbers or dates stored in varchar columns                             | error    | y           |
| 36 | Empty tables                                                           | error    | y           |
| 37 | Mixture of data types in text columns                                  | warning  | y           |
| 38 | Columns with only one value                                            | warning  | y           |
| 39 | All values differ from the default value                               | warning  | y           |
| 40 | Inconsistent casing of first character in text columns                 | warning  | n           |
| 41 | Unnecessary one-to-one relational tables                               | error    | n           |
| 42 | Column values from a small domain                                      | warning  | y           |
| 43 | Large unfilled varchar columns                                         | error    | y           |
| 44 | Missing NOT-NULL constraints                                           | warning  | y           |
| 45 | Column containing too many NULLs                                       | error    | y           |
| 46 | Outlier data in column                                                 | warning  | n           |
| 47 | Table names should be given in plural                                  | warning  | y           |
| 48 | Too short table names                                                  | warning  | y           |
| 49 | Too long table names                                                   | warning  | y           |
| 50 | Table names should be in lowercase                                     | warning  | y           |
| 51 | Tables without comments                                                | error    | y           |
| 52 | Columns without comments                                               | error    | y           |
| 53 | Stored procedures without comments                                     | warning  | y           |
| 54 | Not using the smallest datatype possible                               | warning  | y           |
| 55 | Two columns with the same values                                       | warning  | y           |
| 56 | Foreign key conflicts                                                  | warning  | o           |
| 57 | Tables which have been created or updated a long time ago              | warning  | y           |
| 58 | Integer primary keys should be of type bigint                          | warning  | y           |
| 59 | Storing apostrophe in varchar columns                                  | warning  | y           |
+----+------------------------------------------------------------------------+----------+-------------+
