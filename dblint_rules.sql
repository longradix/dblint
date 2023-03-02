-- Rule violation handling

drop table if exists dblint_results;
create table if not exists dblint_results (
  id int comment 'Identifier, following the numbering scheme from the original dblint',
  table_name varchar(64) comment 'Table name',
  column_name varchar(64) comment 'Column name',
  message varchar(255) comment 'Description of rule violation'
) comment = 'Dblint results';

drop table if exists dblint_debug;
create table if not exists dblint_debug (sortorder int auto_increment primary key, message varchar(255) comment 'Description of code violation') comment = 'Dblint debugging messages';

-- Rule descriptions

drop table if exists dblint_rules;
create table if not exists dblint_rules (
  id int primary key comment 'Identifier, following the numbering scheme from the original dblint',
  name varchar(255) comment 'Brief description of the dblint rule',
  implemented enum('y', 'n', 'o') comment 'Indicator of whether the rule is implemented or not, or is under construction',
  severity enum('error', 'warning', 'info') comment 'Indicator of whether a violation of the rule is either erroneous or is for notification only',
  description varchar(1000) comment 'Full description of the dblint rule',
  remediation varchar(255) comment 'The text to display on what the database issue is and how to solve it'
) comment = 'Dblint rules, from https://projekter.aau.dk/projekter/files/43732470/final.pdf';

select id, implemented, severity, remediation from dblint_rules;

insert into dblint_rules values
(0, 'Non-InnoDB tables present, ie temporary data', 'y', 'info',
'The standard database engine is InnoDB and all other engines can be considered for auxiliary use and these should therefore be excluded from the data rules 28-46.',
'Consider running dblint_rule00 to remove non-InnoDB tables.'
),
(1, 'Missing primary keys', 'y', 'error',
'A primary key uniquely identifies rows in tables. Missing a primary/unique key on a table allows duplication of rows, which should be avoided. Furthermore, individual rows cannot be referenced using foreign keys when the table lacks a primary/unique key. If a table does not contain columns suitable for a primary key, it is always possible to create a surrogate key.',
'Add a primary key: ALTER TABLE table_name ADD PRIMARY KEY(col1, col2);'
),
(2, 'Different data type between source and target columns in a foreign key', 'o', 'error',
'A foreign key is a relationship between two tables, a source table and a target table. Values from the source column are stored in the target column. Hence the data type of the two columns should be identical, else there is an opportunity for mismatches, such as one value being larger than the other column can hold.',
'Amend the data type in one of the columns to make them identical: ALTER TABLE table_name MODIFY column_name VARCHAR(100);'
),
(3, 'Varchar columns of length zero', 'y', 'error',
'A column designed to contain no data is a bad design practice. A varchar of length 0 is sometimes used to represent boolean values, such that the empty string equals true and a NULL value equal false. However, there are better and less obscure ways to model boolean values.',
'Remove the column of length zero: ALTER TABLE table_name DROP COLUMN column_name;'
),
(4, 'Inconsistent naming convention of tables and columns', 'y', 'warning',
'Using consistent naming of columns and tables creates transparency for database designers and application programmers. An inconsistent naming convention complicates database maintenance and writing queries.',
'Rename the columns: ALTER TABLE table_name CHANGE old_column_name new_column_name VARCHAR(100);'
),
(5, 'Inappropriate length of default value for CHAR columns', 'y', 'warning',
'A CHAR column always occupies the specified length, even when the empty string is used. so should only be used if the length is small or the size of the data is known in advance. Otherwise, VARCHAR columns should be used because they occupy only the space corresponding to the actual data.',
'Amend the data type in one of the columns to make them more space efficient: ALTER TABLE table_name MODIFY column_name VARCHAR(100);'
),
(6, 'Redundant foreign keys', 'o', 'warning',
'Duplicate foreign keys could have contradicting referential actions, such as "CASCADE" and "SET NULL". Having contradicting referential actions may lead to unforeseen events when, eg deleting rows. Furthermore, if the foreign-keys have indices the database will have to maintain more indices.',
'The redundant foreign key can be deleted: ALTER TABLE table_name DROP FOREIGN KEY constraint_name;'
),
(7, 'Tables with too few columns', 'y', 'error',
'A table with zero columns cannot contain any data. A table with one column can be accepted under special circumstances, but should generally be avoided.',
'If the table has zero columns, it can likely be dropped (DROP TABLE table_name;). If it has one column, its contents can most likely be integrated with a parameters table or other key-value pair table.'
),
(8, 'Too big indices', 'o', 'warning',
'Large indices reduce performance because they are expensive to maintain and should be avoided when smaller keys are sufficient. Some databases have a maximum key size on indices. In some cases, a large natural primary key can be replaced with a surrogate key.',
'[No remediation has been defined yet]'
),
(9, 'Too many nullable columns', 'y', 'warning',
'There are two cases: 1- All columns are nullable except the primary key columns. 2- A large percentage of the columns are nullable. The first case is especially bad if the primary key is a single surrogate key, because a row can contain no useful data. In the second case, it is likely that the developer forgot to add the appropriate NOT-NULL constraints.',
'Add NOT NULL constraint to column: ALTER TABLE table_name MODIFY column_name INT(11) NOT NULL;'
),
(10, 'Too long column names', 'y', 'warning',
'The maintainability of a schema might decrease with long names, because it makes identifiers harder to remember and queries more difficult to write. It also reduces portability of the data model, since maximum column sizes over database systems differ.',
'Rename the columns: ALTER TABLE table_name CHANGE old_column_name new_column_name VARCHAR(100);'
),
(11, 'Nullable and unique columns', 'y', 'warning',
'Null in a database typically refers to "value does not exist" or "value unknown", and as such should not be allowed in columns, which have a unique constraint defined. Null values in unique indices are handled differently across databases. Some databases allows zero or one NULL value in a unique index, while others allow multiple NULL values. This difference may be a portability issue and cause misunderstandings among developers.',
'Either remove the nullability constraint or the uniqueness constraint on the column.'
),
(12, 'Cycles between tables', 'n', 'warning',
'A cycle can be necessary to model specific data structures, eg a hierarchical structure. However, the developer should be aware that the cycle exists, because circular dependencies may cause several problems if deferrability and delete rules are not considered. These problems are the following. If there is a cascade delete on all references, it is possible to delete all data in the tables. If no references are deferred and the columns are mandatory, data cannot be inserted.',
'[No remediation has been defined yet]'
),
(13, 'Inconsistent max lengths of varchar columns', 'n', 'warning',
'Consistency of the maximum length of varchar columns makes code better maintainable. A table with 200 columns of maximum length 256 and three columns of length 255 deviates from the standard, and could be all 256 without conflicting with the data in the columns.',
'N/A'
),
(14, 'Self-referencing primary key', 'y', 'error',
'Having a foreign key relation on a primary key column referencing itself indicates an error. The foreign key must reference its own row and not contain any useful information. Such a foreign key can be deleted without loss of functionality or conflicts in the database.',
'The redundant foreign key can be deleted: ALTER TABLE table_name DROP FOREIGN KEY constraint_name;'
),
(15, 'Inconsistent data types in column sequence', 'n', 'warning',
'A sequence of related columns can be inferred from the naming, eg ("address_1", "address_2", ..., "address_n"). Another example is columns used for extensibility, eg 10 columns ("cust_col_1", ..., "cust_col_10"), used to store unforeseen information after the database is deployed. All columns in the sequence should have the same data type to avoid confusion and potential errors. Imagine that there are 10 columns in a sequence and the third column data type is integer and the others are varchars. This may result in problems because a developer might mistake the third column for being a varchar, like the others. Furthermore, varying data types in a column sequence violates consistency.',
'Amend the data type in one of the columns to make them identical: ALTER TABLE table_name MODIFY column_name VARCHAR(100);'
),
(16, 'Missing column in a sequence of columns', 'n', 'warning',
'If there exist a sequence of columns, eg ("col_1", "col_2", ..., "col_n"), the postfix number should be ordered sequential from 1 to n. If a column is missing from a sequence, it has probably been forgotten or deleted without proper refactoring.',
'[No remediation has been defined yet]'
),
(17, 'Primary- and unique-key constraints on the same columns', 'y', 'warning',
'Having a primary-key and unique-key constraint on the same columns makes the unique constraint redundant.',
'The unique key can be deleted without affecting data integrity, by dropping the index: ALTER TABLE table_name DROP INDEX index_name;'
),
(18, 'Redundant indices', 'o', 'warning',
'Redundant indices are usually not necessary. A redundant index is an index where the sequence of columns is a prefix of another index, eg the index "idx_a(col_1)" is redundant to "idx_b(col_1, col_2)". Redundant indices reduce performance, because the database needs to maintain more data structures than necessary. There may be cases where a redundant index is reasonable, but most likely it can be deleted.',
'Remove the index from the table: DROP INDEX index_name ON table_name;'
),
(19, 'Too short column names', 'y', 'warning',
'Columns should be named with meaningful and distinct names. This makes it easy to read and understand the data model and queries. Very short column names have a tendency to consist of abbreviations or letters that have certain meaning within the development team only. However, these columns are not very maintainable and make queries less understandable.',
'Rename column: ALTER TABLE table_name RENAME COLUMN old_column_name TO new_column_name;'
),
(20, 'Too many text columns in a table', 'y', 'warning',
'Columns of the TEXT data type are used to store large string values. Normally they will only take up the space they need, however the data are stored outside the table, and hence it requires an additional I/O for each value. If a table contains a large number of these columns, it could indicate that the developer is unaware of the different data types.',
'[No remediation has been defined yet]'
),
(21, 'Foreign-key without index', 'o', 'warning',
'When deleting/updating a row from the referenced table, the database checks that the specific row is not referenced, and takes corresponding action depending on the delete/update rule. This check looks up values in the referencing table, which requires a full table scan if an index does not exist. Having an index on the foreign-key columns will make this look-up faster.',
'[No remediation has been defined yet]'
),
(22, 'Primary-key columns not positioned first', 'y', 'warning',
'It is convention to position the primary-key columns first. The order of columns in a table is important for readability purposes and for performance purposes when making selections. A related case is when a table contains a sequence of columns, such as ("address_1", "address_2", ...), and it is natural to place the columns ascending based on the postfix number. Similarly placing the primary-key columns first makes it possible to quickly see how rows are uniquely identified.',
'Change the column order: ALTER TABLE table_name MODIFY column_name VARCHAR(100) FIRST;'
),
(23, 'Use of reserved words from SQL', 'y', 'warning',
'SQL keywords such as "date", "from" and "change" should be avoided when choosing identifiers. Avoiding reserved SQL keywords in identifiers makes the queries more readable and column names will not need to be escaped in queries.',
'Rename the columns: ALTER TABLE table_name CHANGE old_column_name new_column_name VARCHAR(100);'
),
(24, 'Different data types for columns with the same name', 'y', 'error',
'A column name often refers to a concept, so when the same name is used with different data types, the representation of that concept is inconsistent. Data errors could arise from implicit casts such as in natural joins.',
'Amend the data type in one of the columns to make them identical: ALTER TABLE table_name MODIFY column_name VARCHAR(100);'
),
(25, 'Use of special characters in identifiers', 'y', 'warning',
'Special characters in identifier names should be avoided, except the character "_".',
'Rename the columns: ALTER TABLE table_name CHANGE old_column_name new_column_name VARCHAR(100);'
),
(26, 'Table islands', 'n', 'warning',
'Having a connected schema means that the data is related. If the schema is not connected it is possible that one is trying to model two separate concepts. In such cases, the table islands are better implemented in separate schemas.',
'[No remediation has been defined yet]'
),
(27, 'Too large varchar columns', 'y', 'warning',
'Large varchar columns may cause the row to overflow, resulting in chaining, ie splitting a row that does not fit into one block and spanning it over multiple blocks connected by a linked list. Chained rows are slower to extract from the database as they require additional I/Os.',
'[No remediation has been defined yet]'
),
(28, 'Duplicate rows in a table', 'y', 'error',
'Duplicate rows in a table are not desirable, because they require additional space and may lead to an inconsistent state. A row is a duplicate if two rows contain the same data, ignoring the primary-key column. Duplication shows that the same data is present but identified in different ways.',
'Make an inference on which row(s) to delete: DELETE FROM table_name WHERE id = 123;'
),
(29, 'Storing lists in varchar columns', 'y', 'error',
'Storing lists in varchar columns is a violation of the first normal form. It indicates that the application has logic that handles such a list. However, in a database context such a list should be modeled using a second table, with a one-to-many relation. Furthermore, if the list is used to reference rows in another table, it is not possible for the database to enforce referential constraints on the relation. This means that the list can reference a row that no longer exists, leading to adverse effects in the application.',
'Collect the values of the list and store in its own table.'
),
(30, 'Wrong representation of boolean values', 'n', 'warning',
'A boolean can be represented with only one bit, but is not supported in all databases. Booleans can be stored as: (true, false), (t, f), (yes, no), (y, n), (1, 0). A good representation is both unambiguous and space efficient. Words are space inefficient, hence ruled out. The convention from programming languages, ie (1, 0) for true and false respectively, is a possibility. Also, single char columns with values such as (t, f) or (y, n) could be used, which require only one byte and are unambiguous. Also, booleans should be consistent and not a mixture of chars, words and numbers.',
'Make a choice which boolean values should be used and update the tables accordingly.'
),
(31, 'Defined primary key is not a minimal key', 'y', 'error',
'If the primary key is not a minimal superkey, then it is possible to identify a row with fewer attributes. Using a superkey instead of a primary key is even less attractive when other tables need to reference it. Each of the referencing tables will need to hold more information than actually needed, resulting in using more space and less efficient indices.',
'Rebuild primary key column: ALTER TABLE table_name DROP CONSTRAINT my_pk; ALTER TABLE table_name ADD CONSTRAINT my_pk PRIMARY KEY (exchange, date);'
),
(32, 'Redundant columns', 'y', 'warning',
'A table with two or more columns containing identical values for all rows indicates that one or more columns are unnecessary. If one of the columns is in a unique key or primary key, it indicates a third normal-form violation.',
'Possibly the columns can be deleted: ALTER TABLE table_name DROP column_name;'
),
(33, 'All values equal the default value', 'y', 'warning',
'If all values in a column equal the default value, then the column is redundant. If the column is not used in the overlying application, it should be removed to prevent cluttering of the design and to save space.',
'Possibly the columns can be deleted: ALTER TABLE table_name DROP column_name;'
),
(34, 'Not-NULL columns containing many empty strings', 'y', 'warning',
'If a varchar column has a NOT-NULL constraint, it is mandatory. If the column contains many empty strings it indicates that the overlying application circumvents this restriction. This could be the result of misunderstandings between application and database developers. Modeling unknown or nonexistent values with the empty string should be avoided.',
'Either update the data in the column, or drop the column if it is not needed or can be inferred in other ways.'
),
(35, 'Numbers or dates stored in varchar columns', 'y', 'error',
'If a varchar column contains only numbers or dates, then an incorrect data type is chosen. Choosing a more strict data type improves data quality. There are design patterns, such as the Entity Attributes and Value, that use the varchar data type to store many different data types. However, if the column contains numbers or dates exclusively, it indicates that the data type of the column could be changed.',
'Amend the data type in the offending columns: ALTER TABLE table_name MODIFY column_name DATE;'
),
(36, 'Empty tables', 'y', 'error',
'A table without data clutters the design unnecessarily. Note that this only applies to regular tables, and not to temporary tables.',
'Possibly the table can be deleted: DROP TABLE table_name;'
),
(37, 'Mixture of data types in text columns', 'y', 'warning',
'A varchar column containing a mixture of data types can be necessary in some situations, such as in key-value pairs where multiple data types are stored in the same column. Alternatively, it could be a case of modeling different concepts using one column.',
'Harmonise the data type of the offending column, if necessary'
),
(38, 'Columns with only one value', 'y', 'warning',
'A column with only one value may be redundant. However, there are exceptions, such as columns with boolean values, or columns containing values from a small domain only. An example of the latter could be all users having the same time zone.',
'Establish whether the values are part of the data or whether the column should be redesigned.'
),
(39, 'All values differ from the default value', 'y', 'warning',
'The default value is not used and could be a legacy issue. Removing the default value from the column definition should not affect the overlying application. Values from a small domain such as booleans are an exception to this, because of cases where, eg a table "users" has an "activated" column. This column will have the default value "false", but when all users are activated it will have the value "true".',
'Change or drop the default value: ALTER TABLE table_name ALTER column_name SET DEFAULT "new_default_value"; ALTER TABLE table_name ALTER column_name DROP DEFAULT;'
),
(40, 'Inconsistent casing of first character in text columns', 'n', 'warning',
'If the casing of the first character differs from row to row in a text column, then this is a sign of an underlying data quality issue. For example, it could indicate that the application does not validate user input, such as emails correctly.',
'[No remediation has been defined yet]'
),
(41, 'Unnecessary one-to-one relational tables', 'n', 'error',
'Modeling a one-to-one relation with a relational table connecting two entities is often unnecessary. If the relational table covers most values in one of the source tables, the relation could be modeled using an additional column.',
'[No remediation has been defined yet]'
),
(42, 'Column values from a small domain', 'y', 'warning',
'If a varchar column contains values from a small domain, the data could come from an enum structure. Not all databases support such an enum data type, so if the enum type is unavailable on the database, the column should have a check constraint ensuring that the column only contains allowable values.',
'Amend the data type of the column into an enumerated type: ALTER TABLE table_name MODIFY column_name ENUM("val1", "val2", ...);'
),
(43, 'Large unfilled varchar columns', 'y', 'error',
'The maximum length of a varchar should be chosen such that it matches the data stored in the column. If the data in the column uses less than half of the maximum length, the column width could be decreased. It could be that the overlying application has only recently been implemented, but in general this should not happen.',
'Decrease the size of the varchar column: ALTER TABLE table_name MODIFY COLUMN column_name VARCHAR(100);'
),
(44, 'Missing NOT-NULL constraints', 'y', 'warning',
'If a column is defined to be nullable without containing any NULL values, the column should be declared with the NOT NULL constraint.',
'Add the not-NULL constraint to the column: ALTER TABLE table_name MODIFY column_name VARCHAR(100) NOT NULL;'
),
(45, 'Column containing too many NULLs', 'y', 'error',
'A column with very few values could indicate functionalities rarely used or legacy columns.',
'Redesign the data model or remove the column from the table if it has no use in the overlying application.'
),
(46, 'Outlier data in column', 'n', 'warning',
'Outlier data may indicate missing check constraints or dirty data. When a column contains data that deviates from the majority, it may be generated by another mechanism. To avoid that a process stores dirty data, the definition of the column could be made more strict by adding check constraints.',
'Establish whether the outliers are part of the data or whether the row should be deleted for being degenerate.'
),
(47, 'Table names should be given in plural', 'y', 'warning',
'For consistency purposes, table names should be given in plural.',
'Rename the table: RENAME TABLE table_name TO new_table_name;'
),
(48, 'Too short table names', 'y', 'warning',
'Tables should be named with meaningful and distinct names. This makes it easy to read and understand the data model and queries. Very short table names have a tendency to consist of abbreviations or letters that have meaning within the development team only. However, these table are not very maintainable and make queries less understandable.',
'Rename the table: RENAME TABLE table_name TO new_table_name;'
),
(49, 'Too long table names', 'y', 'warning',
'The maintainability of a schema might decrease with long names, because it makes identifiers harder to remember and queries more difficult to write. It also reduces portability of the data model, since maximum table name sizes over DMBSs differ.',
'Rename the table: RENAME TABLE table_name TO new_table_name;'
),
(50, 'Table names should be in lowercase', 'y', 'warning',
'By having a consistent casing of all table names makes the display of database schemas more visually appealing and improves legibility of SQL statements when automated query tools are used.',
'Rename the table: RENAME TABLE table_name TO lower(table_name);'
),
(51, 'Tables without comments', 'y', 'error',
'All tables must have comments so that a metadata model exists for the database, ie a self-documenting database, and the table can be more easily used within a reporting environment.',
'Add the column comment by repeating the entire definition of the column: ALTER TABLE table_name CHANGE COLUMN column_name column_name BIGINT COMMENT "The column comment";'
),
(52, 'Columns without comments', 'y', 'error',
'All columns must have comments so that a metadata model exists for the database, ie a self-documenting database, and the table can be more easily used within a reporting environment.',
'Add the column comment by repeating the entire definition of the column: ALTER TABLE table_name CHANGE COLUMN column_name column_name BIGINT COMMENT "The column comment";'
),
(53, 'Stored procedures without comments', 'y', 'warning',
'All stored procedures must have comments so that a metadata model exists for the database, ie a self-documenting database, and the stored procedure can be more easily maintained.',
'Add the comment by repeating the entire definition of the column: ALTER TABLE table_name CHANGE COLUMN column_name column_name BIGINT COMMENT "The column comment";'
),
(54, 'Not using the smallest datatype possible', 'y', 'warning',
'The large datatypes, such as BIGINT, BLOB and TEXT, may not always be necessary as the contents may fit in smaller datatypes. The use of smaller datatypes improves the performance of full-text searches.',
'Amend the data type in one of the columns to make them smaller: ALTER TABLE table_name MODIFY column_name VARCHAR(255);'
),
(55, 'Two columns with the same values', 'y', 'warning',
'Two columns in the same table and not being part of the primary key that have the same value in every row, means that one of the columns is redundant.',
'Possibly one of the columns can be deleted: ALTER TABLE table_name DROP column_name;'
),
(56, 'Foreign key conflicts', 'o', 'warning',
'Rows that would conflict if foreign key constraint are added.',
'[No remediation has been defined yet]'
),
(57, 'Tables which have been created or updated a long time ago', 'y', 'warning',
'Tables that have been created or updated a long time ago may be remnants from a test or a legacy implementation. These tables can either be updated or removed',
'Review or remove the table: DROP TABLE table_name;'
),
(58, 'Integer primary keys should be of type bigint', 'y', 'warning',
'Columns that are part of the primary key and of type integer (such as auto-increment columns) may exceed the maximum allowable value when the amount of rows in the table grows too big. In such cases a bigint is preferable.',
'Consider changing the data type of the column: ALTER TABLE table_name MODIFY column_name BIGINT;'
),
(59, 'Storing apostrophe in varchar columns', 'y', 'warning',
'Columns with apostrophes (ie single quote) can be troublesome in downstream processing or reporting for it may be interpreted as a closing character of a string. Spotting the locations where apostrophes are stored gives an understanding of where those downstreams errors are likely to be caused by.',
'[No remdiation defined yet]'
)
;


