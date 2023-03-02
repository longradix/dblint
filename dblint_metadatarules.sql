-- Metadata Rules
-- The metadata rules are rules that pertain to the structure of the database.

-- Set a few variables
set @factor = 0.8;              -- used for maximum amount of columns meeting a certain criterion
set @max_length_name = 20;      -- used for table names and column names
set @min_length_name = 3;       -- used for table names and column names
set @default_max_varchar = 255; -- used for column contents which exceed maximum length
set @days_since_update = 30;    -- used for table creation and/or update date

-- 0 Check whether all tables are InnoDB or not 
-- Not a formal check, but useful to know nonetheless, as some checks only apply to InnoDB tables, ie back when MyISAM was the norm
-- Table_type includes both tables and views
-- If the result is non-empty, then consider running dblint_rule00
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 0;
select table_name, table_type, engine, table_rows, table_comment from information_schema.tables where table_schema = @schema and engine <> 'InnoDB';
insert into dblint_results (table_name, message) select table_name, concat('Non-InnoDB table: ', engine) as message from information_schema.tables where table_schema = @schema and engine <> 'InnoDB';
update dblint_results set id = 0 where id is NULL;

-- 1 Missing Primary Keys
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 1;
insert into dblint_results (table_name, message) select c.table_name, 'No primary key' as message from (select table_name from information_schema.columns where table_schema = @schema group by table_name, column_key) c inner join information_schema.tables t on c.table_name = t.table_name group by c.table_name having count(*) = 1;
update dblint_results set id = 1 where id is NULL;

-- 2 Different Data Type Between Source and Target Columns in a Foreign Key
-- [start; tables must be converted to InnoDB first: CREATE TABLE dblint.t1 LIKE @myTable; ALTER TABLE dblint.t1 ENGINE = InnoDB; afterwards: DROP TABLE dblint.t1;]
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 2;
insert into dblint_results (table_name, message) select table_name, concat('Data type conflict: ', table_name, '.', column_name, ' -> ', referenced_table_name, '.', referenced_column_name) from information_schema.key_column_usage where referenced_table_schema = @schema and referenced_table_name is not NULL order by table_name, column_name;
update dblint_results set id = 2 where id is NULL;

-- 3 Varchar Columns of Length Zero
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 3;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Length zero: ', column_type) from information_schema.columns where table_schema = @schema and data_type like '%char' and character_maximum_length = 0;
update dblint_results set id = 3 where id is NULL;

-- 4 Inconsistent Naming Convention
-- Note: the analogous rule for tables is rule 50.
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 4;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, 'Mixed case in column name' as message from information_schema.columns where table_schema = @schema and cast(lower(column_name) as binary) <> cast(column_name as binary);
update dblint_results set id = 4 where id is NULL;

-- 5 Inappropriate Length of Default Value For Char Columns
-- [Check where the default value is smaller than the character_maximum_length]
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 5;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Column type ', column_type, ' has length ', length(column_default)) as message from information_schema.columns where table_schema = @schema and data_type like '%char' and character_maximum_length < length(column_default);
update dblint_results set id = 5 where id is NULL;

-- 6 Redundant Foreign Keys
-- [requires InnoDB tables: CREATE TABLE dblint.t1 LIKE @myTable; ALTER TABLE dblint.t1 ENGINE = InnoDB; afterwards: DROP TABLE dblint.t1;]
-- This check is available in Percona: http://www.maatkit.org/doc/mk-duplicate-key-checker.html
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 6;
insert into dblint_results (table_name, column_name, message) select table_name, constraint_name, concat('Contraint has redundant type: ', constraint_type) as message from information_schema.table_constraints where table_schema = @schema group by table_schema, table_name, constraint_name, constraint_type having count(*) > 1;
update dblint_results set id = 6 where id is NULL;

-- 7 Tables With Too Few Columns
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 7;
insert into dblint_results (table_name, message) select c.table_name, concat('Column count: ', count(*)) from information_schema.tables t inner join information_schema.columns c on t.table_schema = c.table_schema and t.table_name = c.table_name where t.table_schema = @schema group by c.table_name having count(*) < 2;
update dblint_results set id = 7 where id is NULL;

-- 8 Too Big Indices
-- [nothing to do]: Always aim to index the original data, ie even if the index is on urls. That is often the most useful information you can put into an index. Note that too small indexes are normally not a problem, because MySQL ignores these in queries.

-- 9 Too Many Nullable Columns
-- first query returns number of nullable columns and second query returns number of columns per table
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 9;
insert into dblint_results (table_name, message) select c03.table_name, concat('Many nullable columns: ', c03.count_nullable_columns, ' out of ', count(*)) as message from (
  select c01.table_name as table_name, count(c02.is_nullable) as count_nullable_columns
  from information_schema.columns c02 left join information_schema.columns c01 on c01.table_name = c02.table_name
  where c01.table_schema = @schema and c02.table_schema = @schema and c02.is_nullable = 'YES'
  group by c01.table_name, c02.table_name, c01.column_name
) c03 group by c03.table_name, c03.count_nullable_columns;
update dblint_results set id = 9 where id is NULL;

-- 10 Too Long Column Names
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 10;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Too long column name: ', length(column_name)) from information_schema.columns where table_schema = @schema and length(column_name) > @max_length_name;
update dblint_results set id = 10 where id is NULL;

-- 11 Nullable and Unique Columns
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 11;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Nullable column is part of the key: ', column_key) from information_schema.columns where table_schema = @schema and is_nullable = 'YES' and length(column_key) > 1;
update dblint_results set id = 11 where id is NULL;

-- 12 Cycles Between Tables
-- Not implemented

-- 13 Inconsistent Max Lengths of Varchar Columns
-- Not implemented

-- 14 Self-Referencing Primary Key
-- [start, can only be done on InnoDB tables: CREATE TABLE dblint.t1 LIKE @myTable; ALTER TABLE dblint.t1 ENGINE = InnoDB; afterwards: DROP TABLE dblint.t1;]
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 14;
select t.table_schema, t.table_name, t.constraint_type, t.constraint_name, k.referenced_table_name, k.referenced_column_name from information_schema.table_constraints t left join information_schema.key_column_usage k on t.constraint_name = k.constraint_name where t.table_schema = @schema and t.constraint_type = 'FOREIGN KEY';
update dblint_results set id = 14 where id is NULL;
select * from dblint_results where id = 14;

-- 15 Inconsistent Data Types in Column Sequence
-- Not implemented

-- 16 Missing Column in a Sequence of Columns
-- Not implemented

-- 17 Primary- and Unique-Key Constraints on the Same Columns
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 17;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, 'Unique-Key constraints on primary key' from information_schema.key_column_usage where table_schema = @schema group by table_name, column_name having count(*) > 1;
update dblint_results set id = 17 where id is NULL;

-- 18 Redundant Indices
-- From http://www.oreillynet.com/databases/blog/2006/09/_finding_redundant_indexes_usi.html
-- Also: http://rpbouman.blogspot.co.uk/2006/09/finding-redundant-indexes-using-mysql.html
-- Limitations: FULLTEXT indexes are ignored and column prefixes are ignored.
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 18;
select table_name, index_type, min(column_names) column_names, trim(',' from case index_type when 'BTREE' then replace(
    -- report all but the last one: the last one is the longest one
    substring_index(group_concat('`', index_name, '`' order by column_count, non_unique, index_name desc separator ','), ',', count(*)-1),
    -- get the first one: the first one is the smallest unique one
    concat('`', substring_index(group_concat(if(non_unique = 0, index_name, '') order by non_unique, column_count, index_name separator ','), ',', 1), '`'), '')
    when 'HASH' then substring_index(group_concat('`', index_name, '`' order by non_unique, index_name separator ','), ',', 1-count(*))
    when 'SPATIAL' then substring_index(group_concat('`', index_name, '`' order by index_name separator ','), ',', 1-count(*))
    else 'Unexpected index type: not implemented'
  end) redundant_indexes
from (select table_name, index_name, index_type, non_unique, count(seq_in_index) as column_count, group_concat(if(seq_in_index = 1, column_name, '') separator '') as column_name, group_concat(column_name order by seq_in_index separator ',') as column_names
  from information_schema.statistics s
  where s.table_schema = @schema and s.index_type != 'FULLTEXT'
  group by table_name, index_name, index_type, non_unique) as s
group by table_name, index_type, if(index_type = 'HASH', column_names, column_name)
having redundant_indexes != '';
update dblint_results set id = 18 where id is NULL;
select * from dblint_results where id = 18;

-- 19 Too Short Column Names
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 19;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Too short column name: ', length(column_name)) from information_schema.columns where table_schema = @schema and lower(column_name) <> 'id' and length(column_name) < @min_length_name;
update dblint_results set id = 19 where id is NULL;

-- 20 Too Many Text Columns in a Table
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 20;
insert into dblint_results (table_name, message) select c03.table_name, concat('Text columns: ', c03.count_text_columns, ' out of ', count(*)) as message from (
    select c01.table_name as table_name, count(c02.column_name) as count_text_columns
    from information_schema.columns c02 left join information_schema.columns c01 on c01.table_name = c02.table_name
    where c01.table_schema = @schema and c02.table_schema = @schema and (c02.data_type like '%text' or c02.data_type like '%blob')
    group by c01.table_name, c02.table_name, c01.column_name
) c03 group by c03.table_name, c03.count_text_columns;
update dblint_results set id = 20 where id is NULL;
select * from dblint_results where id = 20;

-- 21 Foreign-Key Without Index
-- [Is this automatically enforced for InnoDB? http://dev.mysql.com/doc/refman/5.7/en/innodb-foreign-key-constraints.html; otherwise start]
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 21;
insert into dblint_results (table_name, message) select table_name, 'Foreign key has no index' from information_schema.table_constraints where constraint_type = 'FOREIGN KEY';
update dblint_results set id = 21 where id is NULL;

-- 22 Primary-Key Columns Not Positioned First
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 22;
insert into dblint_results (table_name, column_name, message) select c.table_name, c.column_name, concat('Primary key at position: ', c.ordinal_position) as message from (select table_name, column_name, min(ordinal_position) as ordinal_position from information_schema.columns where table_schema = @schema and column_key = 'PRI' group by table_name, column_name) c where c.ordinal_position > 1;
update dblint_results set id = 22 where id is NULL;

-- 23 Use of Reserved Words From SQL (supported since version 8.0)
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 23;
-- check for reserved words in table names
insert into dblint_results (table_name, message) select table_name, 'Reserved word in table name' as message from information_schema.tables where table_schema = @schema and upper(table_name) in (select word from information_schema.keywords where reserved = 1);
-- check for reserved words in column names
insert into dblint_results (table_name, column_name, message) select table_name, column_name, 'Reserved word in column name' as message from information_schema.columns where table_schema = @schema and upper(column_name) in (select word from information_schema.keywords where reserved = 1);
update dblint_results set id = 23 where id is NULL;

-- 24 Different Data Types for Columns With the Same Name
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 24;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Different data type for column with the same name: ', column_type) as message from information_schema.columns where table_schema = @schema and column_name in (select c.column_name from (select column_name from information_schema.columns where column_name in (select column_name from information_schema.columns where table_schema = @schema group by column_name having count(*) > 1) and table_schema = @schema group by column_name, data_type) c group by column_name having count(*) > 1) order by column_name, table_name;
update dblint_results set id = 24 where id is NULL;

-- 25 Use of Special Characters in Identifiers and for both tables and columns: !@#$%^&*(),/?;:-+[]{}|
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 25;
-- check for special characters in table names
insert into dblint_results (table_name, message) select table_name, 'Table name has special character' as message from information_schema.tables where table_schema = @schema and (table_name like "%!%" or table_name like "%@%" or table_name like "%#%" or table_name like "%$%" or table_name like "%\%%" or table_name like "%^%" or table_name like "%&%" or table_name like "%*%" or table_name like "%(%" or table_name like "%)%" or table_name like "%{%" or table_name like "%}%" or table_name like "%[%" or table_name like "%]%" or table_name like "%|%" or table_name like "%,%" or table_name like "%/%" or table_name like "%?%" or table_name like "%-%");
-- check for special characters in column names
insert into dblint_results (table_name, column_name, message) select table_name, column_name, 'Column name has special character' as message from information_schema.columns where table_schema = @schema and (column_name like "%!%" or column_name like "%@%" or column_name like "%#%" or column_name like "%$%" or column_name like "%\%%" or column_name like "%^%" or column_name like "%&%" or column_name like "%*%" or column_name like "%(%" or column_name like "%)%" or column_name like "%{%" or column_name like "%}%" or column_name like "%[%" or column_name like "%]%" or column_name like "%|%" or column_name like "%,%" or column_name like "%/%" or column_name like "%?%" or column_name like "%-%");
update dblint_results set id = 25 where id is NULL;

-- 26 Table Islands
-- Not implemented: not a critical error, it is informational

-- 27 Too Large Varchar Columns
-- Unclear when chaining occurs, so picking the value that was customary for maximum varchar sizes in old versions of MySQL.
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 27;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Too large varchar column: ', column_type) as message from information_schema.columns where table_schema = @schema and data_type like '%char' and character_maximum_length > @default_max_varchar;
update dblint_results set id = 27 where id is NULL;

-- 36 Empty Tables
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 36;
insert into dblint_results (table_name, message) select table_name, 'Empty table' as message from information_schema.tables where table_schema = @schema and table_rows = 0;
update dblint_results set id = 36 where id is NULL;


-- Additional rules
-- Additional rules not part of the original dblint implementation. These work on information_schema.

-- 47 Table names should be given in plural
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 47;
insert into dblint_results (table_name, message) select table_name, 'Table name not in plural' as message from information_schema.columns where table_schema = @schema and replace(table_name, '_', '') not like '%s' group by table_name;
update dblint_results set id = 47 where id is NULL;

-- 48 Too short table names
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 48;
insert into dblint_results (table_name, message) select table_name, concat('Too short table name: ', length(table_name)) as message from information_schema.tables where table_schema = @schema and length(table_name) < @min_length_name;
update dblint_results set id = 48 where id is NULL;

-- 49 Too long table names
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 49;
insert into dblint_results (table_name, message) select table_name, concat('Too long table name: ', length(table_name)) as message from information_schema.tables where table_schema = @schema and length(table_name) > @max_length_name;
update dblint_results set id = 49 where id is NULL;

-- 50 Table names should be in lowercase
-- Note: the analogous rule for columns is rule 4.
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 50;
insert into dblint_results (table_name, message) select table_name, 'Table name not in lowercase' as message from information_schema.tables where table_schema = @schema and cast(lower(table_name) as binary) <> cast(table_name as binary);
update dblint_results set id = 50 where id is NULL;

-- 51 Tables without comments
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 51;
insert into dblint_results (table_name, message) select table_name, 'Table without comment' as message from information_schema.tables where table_schema = @schema and (table_comment = '' or table_comment is NULL);
update dblint_results set id = 51 where id is NULL;

-- 52 Columns without comments
-- Note: this rule is not necessarily portable
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 52;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, 'Column without comment' as message from information_schema.columns where table_schema = @schema and (column_comment = '' or column_comment is NULL);
update dblint_results set id = 52 where id is NULL;

-- 53 Stored procedures without comments
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 53;
insert into dblint_results (table_name, message) select routine_name, concat(upper(substring(routine_type, 1, 1)), lower(substring(routine_type from 2)), ' without comment') as message from information_schema.routines where routine_schema = @schema and routine_type in ('procedure', 'function') and (routine_comment = '' or routine_comment is NULL);
update dblint_results set id = 53 where id is NULL;

-- 54 Not using the smallest datatype possible
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 54;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Large data type: ', column_type) as message from information_schema.columns where table_schema = @schema and (data_type like '%blob' or data_type like '%text' or (data_type = 'bigint' and column_key <> 'PRI'));
update dblint_results set id = 54 where id is NULL;

-- 55 Two columns with the same values
-- [Not implemented]

-- 56 Foreign key conflicts
-- Unclear how to apply this rule if the parent and child tables/columns are not known; cannot loop over all tables/columns

-- 57 Tables which have been created or updated a long time ago
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 57;
insert into dblint_results (table_name, message) select table_name, concat(case when coalesce(update_time, create_time) = update_time then 'Updated ' else 'Created ' end, datediff(now(), coalesce(update_time, create_time)), ' days ago') as message from information_schema.tables where table_schema = @schema and datediff(now(), coalesce(update_time, create_time)) > @days_since_update order by table_name;
update dblint_results set id = 57 where id is NULL;

-- 58 Integer primary keys should be of type bigint
select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = 58;
insert into dblint_results (table_name, column_name, message) select table_name, column_name, concat('Primary key not using type bigint: ', column_type) as message from information_schema.columns where table_schema = @schema and data_type like '%int' and data_type <> 'bigint' and column_key = 'PRI';
update dblint_results set id = 58 where id is NULL;

