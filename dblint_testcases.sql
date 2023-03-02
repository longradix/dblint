-- Metadata Rules
-- The metadata rules are rules that pertain to the structure of the database.

-- 1 Missing Primary Keys
-- Test cases:
drop table if exists dblint_rule01_testcase01, dblint_rule01_testcase02, dblint_rule01_testcase03;
create table if not exists dblint_rule01_testcase01 (id smallint);                           -- pass
create table if not exists dblint_rule01_testcase02 (id smallint not NULL);                  -- pass
create table if not exists dblint_rule01_testcase03 (id smallint not NULL auto_increment);   -- fail

-- 2 Different Data Type Between Source and Target Columns in a Foreign Key
-- Test cases:

-- 3 Varchar Columns of Length Zero
-- Test cases:
drop table if exists dblint_rule02_testcase01, dblint_rule02_testcase02, dblint_rule02_testcase03;
create table if not exists dblint_rule03_testcase01 (id smallint not NULL auto_increment, str varchar(1), primary key (id));  -- pass
create table if not exists dblint_rule03_testcase02 (id smallint not NULL auto_increment, str varchar(0), primary key (id));  -- fail
create table if not exists dblint_rule03_testcase03 (id smallint not NULL auto_increment, str char(0), primary key (id));     -- fail

-- 4 Column names that have uppercase characters
-- Test cases:
drop table if exists dblint_rule04_testcase01, dblint_rule04_testcase02, dblint_rule04_testcase03;
create table if not exists dblint_rule04_testcase01 (str varchar(10));  -- pass
create table if not exists dblint_rule04_testcase02 (Str varchar(10));  -- fail
create table if not exists dblint_rule04_testcase03 (sTR varchar(10));  -- fail

-- 5 Inappropriate Length of Default Value For Char Columns
-- Test cases:

-- 6 Redundant Foreign Keys
-- Test case 1:
drop table if exists dblint_rule05_testcase01, dblint_rule05_testcase02;
create table if not exists dblint_rule05_testcase01 (id int not NULL, primary key (id));
create table if not exists dblint_rule05_testcase02 (time datetime not NULL, product1 int not NULL, product2 int not NULL,
  constraint fk_product_1 foreign key (product1) references dblint_rule05_testcase01 (id),
  constraint fk_product_2 foreign key (product2) references dblint_rule05_testcase01 (id)
);
-- Test case 2:
drop table if exists dblint_rule05_testcase03;
create table if not exists dblint_rule05_testcase03 (id int not NULL, date_rec int not NULL, supplier int not NULL,
  primary key (id),
  constraint fk_date_id1 foreign key (date_rec) references dblint_rule05_testcase03 (id),
  constraint fk_date_id2 foreign key (date_rec) references dblint_rule05_testcase03 (id)
);

-- 7 Table With Too Few Columns
-- Test cases (all fails):
drop table if exists dblint_rule07_testcase01, dblint_rule07_testcase02, dblint_rule07_testcase03;
create table if not exists dblint_rule07_testcase01 (str varchar(10));                      -- fail
create table if not exists dblint_rule07_testcase02 (id smallint not NULL);                 -- fail
create table if not exists dblint_rule07_testcase03 (id smallint not NULL auto_increment);  -- fail

-- 9 Too Many Nullable Columns
-- first query returns number of columns per table and second query returns number of nullable columns
-- Test cases:

-- 10 Too Long Column Names
-- Test cases:
drop table if exists dblint_rule10_testcase01;
create table if not exists dblint_rule10_testcase01 (id smallint unsigned not NULL auto_increment, p23456789012345678901 varchar(10), primary key (id));  -- fail

-- 11 Nullable and Unique Columns
-- Test case 1:
drop table if exists dblint_rule11_testcase01;
create table if not exists dblint_rule11_testcase01 (id int, name varchar(255), dob date, title varchar(255), salary int, constraint uc_emp_detail unique (name, dob));
insert into dblint_rule11_testcase01 (id, name, dob, title, salary) values (1, 'john smith', '1960-10-02', 'president', 500000), (2, 'jane doe', '1982-05-05', 'accountant', 80000), (3, 'tim smith', '1899-04-11', 'janitor', 95000);
insert into dblint_rule11_testcase01 (id, name, title, salary) values (4, 'jim johnson', 'office manager', 40000);
-- Test case 2:
drop table if exists dblint_rule11_testcase02;
create table if not exists dblint_rule11_testcase02 (id int, name varchar(255), product varchar(255), constraint uc_emp_detail unique (product));
insert into dblint_rule11_testcase02 (id, name, product) values (1, 'john smith', 'pen drive'), (2, 'jane doe', 'computer');
alter table dblint_rule11_testcase02 modify product varchar(255) not NULL;            -- pass
insert into dblint_rule11_testcase02 (id, name, product) values (3, 'smith', NULL);   -- fail

-- 14 Self-Referencing Primary Key
-- Test cases:
drop table if exists dblint_rule14_testcase01;
-- Table with Self Referencing Foreign Key
create table dblint_rule14_testcase01 (id int primary key, name varchar(30), parent varchar(30), constraint fk_parent foreign key (parent) references dblint_rule14_testcase01(id));   -- pass
-- Composite Key on a Self Referencing Table
create table dblint_rule14_testcase02 (site_number nvarchar(50) not NULL, district_id bigint not NULL, partner_site_number nvarchar(50) NULL, constraint pk_site primary key clustered (site_number, district_id);
alter table dblint_rule14_testcase02 with check add constraint fk_site_site foreign key (partner_site_number, district_id);   -- pass

-- 15 Inconsistent Data Types in Column Sequence
-- Test case (col2 has different data type):
drop table if exists dblint_rule15_testcase01;
create table if not exists dblint_rule15_testcase01 (id integer primary key auto_increment, col1 integer, col2 varchar(20), col3 integer, col4 integer);

-- 16 Missing Column in a Sequence of Columns
-- Test case (col8 missing):
drop table dblint_rule16_testcase01, dblint_rule16_testcase02, dblint_rule16_testcase03, dblint_rule16_testcase04;
create table if not exists dblint_rule16_testcase01 (col1 integer, col2 integer, col3 integer, col4 integer, col5 integer, col6 integer, col7 integer, col8 integer, col9 integer);  -- pass
create table if not exists dblint_rule16_testcase02 (col1 integer, col2 integer, col3 integer, col4 integer, col5 integer, col6 integer, col7 integer, col9 integer);                -- fail
create table if not exists dblint_rule16_testcase03 (col01 integer, col02 integer, col03 integer, col04 integer, col05 integer, col06 integer, col07 integer, col08 integer);        -- pass
create table if not exists dblint_rule16_testcase04 (col01 integer, col02 integer, col03 integer, col04 integer, col05 integer, col06 integer, col08 integer);                       -- fail

-- 17 Primary- and Unique-Key Constraints on the Same Columns
-- Test cases:
drop table if exists dblint_rule17_testcase01, dblint_rule17_testcase02, dblint_rule17_testcase03, dblint_rule17_testcase04, dblint_rule17_testcase05;
create table if not exists dblint_rule17_testcase01 (id int not NULL, name varchar(255) not NULL, constraint uc_personid unique (id), constraint pk_personid primary key(id));
create table if not exists dblint_rule17_testcase02 (id int not NULL, name varchar(255) not NULL, constraint uc_personid unique (id, lastname), constraint pk_personid primary key (id, name));
create table if not exists dblint_rule17_testcase03 (id int primary key, name varchar(255) not NULL, constraint uc_personid unique (id));
create table if not exists dblint_rule17_testcase04 (id int primary key not NULL, name varchar(255) not NULL, constraint uc_personid unique (id));
create table if not exists dblint_rule17_testcase05 (id int primary key auto_increment, name varchar(255) not NULL, constraint uc_personid unique (id));

-- 19 Too Short Column Names
-- Test cases:

-- 20 Too Many Text Columns in a Table
-- Test cases:

-- 21 Foreign-Key Without Index
-- Test case 1:
drop table if exists dblint_rule21_users, dblint_rule21_purchase;
create table if not exists dblint_rule21_users (id int(11) not NULL auto_increment, username varchar(50) not NULL, password varchar(20) not NULL, primary key (id));
create table if not exists dblint_rule21_purchase (id int(11) not NULL, name tinytext not NULL);
alter table dblint_rule21_purchase add foreign key (id) references users(id);
alter table dblint_rule21_purchase drop index id;
-- Test case 2:
drop table if exists dblint_rule21_portfolio, dblint_rule21_security;
create table if not exists dblint_rule21_portfolio (portfolio_id int(11) not NULL auto_increment, portfolio_name varchar(50) not NULL, primary key (portfolio_id));
create table if not exists dblint_rule21_security (security_id int(11) not NULL, security_name tinytext not NULL, portfolio_id int(11) not NULL, foreign key (portfolio_id) references portfolio (portfolio_id), primary key(security_id));
alter table dblint_rule21_security drop index portfolio_id;

-- 22 Primary-Key Columns Not Positioned First
-- Test cases:
drop table if exists dblint_rule22_testcase01;
create table if not exists dblint_rule22_testcase01 (col01 varchar(10), id smallint unsigned not NULL auto_increment, primary key (id));  -- fail

-- 23 Use of Reserved Words From SQL
-- Test cases for table names (all fails):
drop table if exists all;
create table if not exists all (id smallint unsigned);  -- fail
create table if not exists all (id smallint unsigned not NULL auto_increment);
create table if not exists all (id smallint unsigned not NULL auto_increment, primary key (id));
-- Test cases for table names (all pass):
drop table if exists `all`;
create table if not exists `all` (id smallint unsigned);  -- pass
create table if not exists `all` (id smallint unsigned not NULL auto_increment);
create table if not exists `all` (id smallint unsigned not NULL auto_increment, primary key (id));
-- Test cases for column names:
drop table if exists dblint_rule23_testcase01, dblint_rule23_testcase02, dblint_rule23_testcase03;
create table if not exists dblint_rule23_testcase01 (accessible varchar(1));                                                             -- fail
alter table dblint_rule23_testcase01 add column localtime varchar(1);                                                                    -- fail
create table if not exists dblint_rule23_testcase02 (id smallint unsigned not NULL auto_increment, all varchar(10), primary key (id));   -- fail
create table if not exists dblint_rule23_testcase03 (id smallint unsigned not NULL auto_increment, `all` varchar(10), primary key (id)); -- pass

-- 24 Different Data Types for Columns With the Same Name
-- Test cases:
drop table if exists dblint_rule24_testcase01, dblint_rule24_testcase02, dblint_rule24_testcase03, dblint_rule24_testcase04;
create table if not exists dblint_rule24_testcase01 (col01 varchar(10));
create table if not exists dblint_rule24_testcase02 (col01 date);
create table if not exists dblint_rule24_testcase03 (id smallint unsigned not NULL auto_increment, primary key (id));
create table if not exists dblint_rule24_testcase04 (id varchar(10));

-- 25 Use of Special Characters in Identifiers: !@#$%^&*(),/?;:-+[]{}|
-- Test cases:
drop table if exists dblint_rule25_testcase01, dblint_rule25_testcase02, dblint_rule25_testcase03, dblint_rule25_testcase04, dblint_rule25_testcase05, dblint_rule25_testcase06, dblint_rule25_testcase07, dblint_rule25_testcase08;
create table if not exists dblint_rule25_testcase01 (col!01 varchar(10));   -- fail
create table if not exists dblint_rule25_testcase02 (col_01 date);          -- pass
create table if not exists dblint_rule25_testcase03 (id# smallint unsigned not NULL auto_increment, primary key (id));   -- fail
create table if not exists dblint_rule25_testcase04 (id} varchar(10));      -- fail
create table if not exists dblint_rule25_testcase05 (id$01 varchar(10));    -- fail
create table if not exists dblint_rule25_testcase06 (id$_ varchar(10));     -- fail
create table if not exists dblint_rule25_testcase07 (id$id varchar(10));    -- fail
create table if not exists dblint_rule25_testcase08 (`id(id` varchar(10));  -- pass?

-- 27 Too Large Varchar Columns
-- Test cases:
drop table if exists dblint_rule27_testcase;
create table if not exists dblint_rule27_testcase (col01 varchar(256));     -- fail

--
--

-- Data Rules
-- The data rules are rules that pertain to the contents of the database.

-- 28 	Duplicate rows in a table
-- Test cases:
drop table if exists dblint_rule28_testcase;
create table if not exists dblint_rule28_testcase (id integer primary key auto_increment, col1 integer default 0, col2 varchar(20), col3 int, col4 float);
insert into dblint_rule28_testcase (col1, col2, col3, col4) values (1, 'abc', 1, 1.0), (1, 'abc', 1, 1.0);  -- duplicate row
insert into dblint_rule28_testcase (col1, col2, col3, col4) values (3, 'bbc', 1, 1.0), (4, 'bbc', 1, 1.0);  -- duplicate row
insert into dblint_rule28_testcase (col1, col2, col3, col4) values (5, 'aac', 1, 1.0), (6, 'aac', 1, 1.0);  -- duplicate row
insert into dblint_rule28_testcase (col2) values (''), ('');  -- empty duplicate row, except for 0-value on col1

-- 29 	Storing lists in varchar columns
-- Test cases:
drop table if exists dblint_rule29_testcase;
create table dblint_rule29_testcase (id integer primary key auto_increment, list varchar(40));
insert into dblint_rule29_testcase (list) values ('a,b,c,d,e,f,g,h,i,j,k,l'), ('a,b,c'),('1,2,3'), ('london,paris');
insert into dblint_rule29_testcase (list) values ('london'), ('paris');   -- not a list

-- 30 	Wrong representation of boolean values
-- Test cases:

-- 31 	Defined primary key is not a minimal key
-- Test cases:

-- 32 	Redundant columns, ie two columns with the same value
-- Test case 01:
drop table if exists dblint_rule32_testcase01;
create table if not exists dblint_rule32_testcase01 (id integer primary key auto_increment, num integer, duplicate integer);
insert into dblint_rule32_testcase01 (num) values (1), (2), (3), (4), (5);
update dblint_rule32_testcase01 set duplicate = num;
-- Test case 02:
drop table if exists dblint_rule32_testcase02;
create table if not exists dblint_rule32_testcase02 (id integer primary key auto_increment, num float, duplicate float);
insert into dblint_rule32_testcase02 (num) values (1.0), (2.0), (3.0), (4.0), (5.0);
update dblint_rule32_testcase02 set duplicate = floor(num);
-- Test case 03:
drop table if exists dblint_rule32_testcase03;
create table if not exists dblint_rule32_testcase03 (id integer primary key auto_increment, num integer, text varchar(20), duplicate integer);
insert into dblint_rule32_testcase03 (num, text) values (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc');
update dblint_rule32_testcase03 set duplicate = id;
-- Test case 04:
drop table if exists dblint_rule32_testcase04;
create table if not exists dblint_rule32_testcase04 (id integer primary key auto_increment, num integer, text varchar(20), duplicate varchar(20));
insert into dblint_rule32_testcase04 (num, text) values (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc');
update dblint_rule32_testcase04 set duplicate = text;

-- 33 	All values equal the default value
-- Test cases:
drop table if exists dblint_rule33_testcase;
create table if not exists dblint_rule33_testcase (id integer primary key auto_increment, col1 integer default 0, text varchar(20));
insert into dblint_rule33_testcase (text) values ('abc'), ('abc'), ('bbc'), ('bbc'), ('aac'), ('aac');

-- 34 	Not-NULL columns containing many empty strings
-- Test cases:
drop table if exists dblint_rule34_testcase;
create table if not exists dblint_rule34_testcase (id integer primary key auto_increment, text varchar(20) not NULL);
insert into dblint_rule34_testcase (text) values (''), (''), (''), (''), (''), (''), (''), (''), (''), (''), (''), ('aac');

-- 35 	Numbers or dates stored in varchar columns
-- Test cases:
drop table if exists dblint_rule35_testcase0, dblint_rule35_testcase02;
create table if not exists dblint_rule35_testcase01 (id integer primary key auto_increment, text varchar(20));
create table if not exists dblint_rule35_testcase02 (id integer primary key auto_increment, text varchar(20));
insert into dblint_rule35_testcase01 (text) values ('1'), ('2'), ('3'), ('4'), ('5'), ('6');
insert into dblint_rule35_testcase02 (text) values ('2013-01-01'), ('2013-02-01'), ('2013-03-01'), ('2013-04-01'), ('2013-04-02'), ('2013-05-01');

-- 36 	Empty tables
-- Test cases:
drop table if exists dblint_rule36_testcase01;
create temporary table dblint_rule36_testcase01 (id integer primary key auto_increment, num integer, corpus varchar(20));

-- 37 	Mixture of data types in text columns
-- Test cases:
drop table if exists dblint_rule37_testcase;
create table if not exists dblint_rule37_testcase (id integer primary key auto_increment, col1 varchar(20), col2 varchar(20), col3 varchar(20));
insert into dblint_rule37_testcase (col1, col2, col3) values ('1',                   '1.1', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('0',                   '0.0', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('bbc',              '-3.0e2', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('bbc',                 '4.2', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('1.1',             '5.01e+3', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('2.1',                 '2.5', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('2012-01-01',          '1.0', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('23:01:01',            '5.0', '2012-01-01');
insert into dblint_rule37_testcase (col1, col2, col3) values ('2012-01-01 23:01:01', '11:01', '2012');

-- 38 	Columns with only one value
-- Test cases:
drop table if exists dblint_rule38_testcase;
create table if not exists dblint_rule38_testcase (id integer primary key auto_increment, num integer, text varchar(20));
insert into dblint_rule38_testcase (num, text) values (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc'), (1, 'abc');

-- 39 	All values differ from the default value
-- Test cases:
drop table if exists dblint_rule39_testcase;
create table if not exists dblint_rule39_testcase (id integer primary key auto_increment, col1 integer default 0, text varchar(20) default '', col3 varchar(20) default '');
insert into dblint_rule39_testcase (col1, text, col3) values (1, 'abc', ''), (1, 'abc', 'a'), (1, 'bbc', 'b'), (1, 'bbc', 'c'), (1, 'aac', ''), (1, 'aac', 'c');

-- 40 	Inconsistent casing of first character in text columns
-- Test cases:
drop table if exists dblint_rule40_testcase;
create table if not exists dblint_rule40_testcase (id integer primary key auto_increment, text varchar(20));
insert into dblint_rule40_testcase (text) values ('name', 'Name', 'NAME', 'NAme', 'nAME');   -- fail

-- 41 	Unnecessary one-to-one relational tables
-- Test cases:

-- 42 	Column values from a small domain
-- Test cases:
drop table if exists dblint_rule42_testcase;
create table if not exists dblint_rule42_testcase (id integer primary key auto_increment, col1 integer, col2 varchar(20));
insert into dblint_rule42_testcase (col1, col2) values (1, 'abc'), (1, 'abc'), (1, 'bbc'), (2, 'bbc'), (2, 'aac'), (2, 'aac');

-- 43 	Large unfilled varchar columns
-- Test cases:
drop table if exists dblint_rule43_testcase;
create table if not exists dblint_rule43_testcase (id integer primary key auto_increment, col1 varchar(10), col2 varchar(255));
insert into dblint_rule43_testcase (col1, col2) values ('1', 'abc'), ('1', 'abd'), ('1', 'bbc'), ('2', 'bbc'), ('2', 'aac'), ('3', 'aac');

-- 44 	Missing not-NULL constraints
-- Test cases:
drop table if exists dblint_rule44_testcase;
create table if not exists dblint_rule44_testcase (id integer primary key auto_increment, num integer, corpus varchar(20));
insert into dblint_rule44_testcase (num, corpus) values (1, 'abc'), (1, 'abd'), (1, 'bbc'), (2, 'bbc'), (2, 'aac'), (3, 'aac');
insert into dblint_rule44_testcase (num) values (4);   -- when this row is added, then column corpus is not listed as missing a not NULL constraint; else omit this row.

-- 45 	Column containing too many NULLs
-- Test cases:
drop table if exists dblint_rule45_testcase;
create table if not exists dblint_rule45_testcase (id integer primary key auto_increment, num integer, text varchar(20));
insert into dblint_rule45_testcase (num, text) values (1, 'abc'), (2, 'abc'), (3, 'abc'), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL), (NULL, NULL);

-- 46 	Outlier data in column
-- Test cases:

-- 50 Table names should be in lowercase
-- Test cases:
drop table if exists dblint_rule50_testcase01, dblint_rule50_Testcase02, dblint_rule50_TESTCASE03;
create table if not exists dblint_rule50_testcase01 (id int);   -- pass
create table if not exists dblint_rule50_Testcase02 (id int);   -- fail
create table if not exists dblint_rule50_TESTCASE03 (id int);   -- fail

-- 51 Foreign key conflicts
-- Test cases:
drop table if exists dblint_rule51_exam, dblint_rule51_student;
create table if not exists dblint_rule51_exam (id int(11) not NULL, marks varchar(45) default NULL, primary key (id), key id_idx (id));
create table if not exists dblint_rule51_student (id int(11) not NULL, name varchar(45) default NULL, address varchar(45) default NULL, rank int(11) default NULL,
  primary key (id),
  key id_idx (id),
  key id_idx1 (id),
  constraint id foreign key (id) references dblint_rule51_exam(id) on delete no action on update no action
);
insert into dblint_rule51_exam (id, marks) values (1, 23), (2, 45), (3, 87);
insert into dblint_rule51_student (id, name, address, rank) values (1, 'dilan', 'Dolumbo', 5), (2, 'kalipa', 'St. Kargerita', 17);  -- fail: there is no student with id = 3

-- 52 Too short table names
-- Checks whether the table name has length at least 3
-- Test cases:
drop table if exists p, pp, ppp, pppp;
create table if not exists p (id smallint unsigned not NULL auto_increment, primary key (id)) comment = 'DBlint rule 52: Too short table name';    -- fail
create table if not exists pp (id smallint unsigned not NULL auto_increment, primary key (id)) comment = 'DBlint rule 52: Too short table name';   -- fail
create table if not exists ppp (id smallint unsigned not NULL auto_increment, primary key (id)) comment = 'DBlint rule 52: Too short table name';  -- pass
create table if not exists pppp (id smallint unsigned not NULL auto_increment, primary key (id)) comment = 'DBlint rule 52: Too short table name'; -- pass

-- 53 Too long table names
-- Checks whether the table name has length at most 20
-- Test cases where every 0 is a multiple of 10 characters:
drop table if exists dblint___0_________0, dblint___0_________0_, dblint___0_________0__;
create table if not exists dblint___0_________0 (id smallint unsigned not NULL auto_increment, primary key (id));   -- fail
create table if not exists dblint___0_________0_ (id smallint unsigned not NULL auto_increment, primary key (id));  -- fail
create table if not exists dblint___0_________0__ (id smallint unsigned not NULL auto_increment, primary key (id)); -- fail

