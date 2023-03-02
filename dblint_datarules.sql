-- Data Rules
-- The data rules are rules that pertain to the contents of the database, except rule 00.

-- Set a few variables
set @max_rows = 1000000;  -- maximum amount of rows in table to test for duplication

delimiter //

drop procedure if exists dblint_debug //
create procedure dblint_debug (message varchar(255)) 
comment 'Store Dblint debugging messages'
begin 
  insert into dblint_debug select 0, message; 
end;
-- call dblint_debug (concat('myvar is: ', myvar, ' and myvar2 is: ', myvar2));

-- Rule 00: Drop non-InnoDB tables

drop procedure if exists dblint_rule00 //
create procedure dblint_rule00 (in schema_ varchar(32))
comment 'Drop all non-InnoDB tables (ie temporary tables), so that dblint works on actual data'
begin
  declare table_ varchar(32);
  declare number_of_tables integer default 0;
  declare i integer default 1;
  declare T cursor for select table_name from information_schema.tables where table_schema = schema_ and engine <> 'InnoDB';
  open T;
  select found_rows() into number_of_tables;

  select table_name, engine from information_schema.tables where table_schema = schema_ and engine <> 'InnoDB';

  tableLoop: loop
    if i > number_of_tables then
      leave tableLoop;
    end if;
    fetch T into table_;
    set @v_sql = concat('drop table ', schema_, '.', table_, ';');
    prepare statement from @v_sql;
    execute statement;
    deallocate prepare statement;
    set i = i + 1;
  end loop tableLoop;
  close T;
end;
//

-- Rule 28: Duplicate rows in a table
-- One million rows takes about 10 mins.

drop procedure if exists dblint_rule28 //
create procedure dblint_rule28 (in schema_ varchar(32))
comment 'Duplicate rows in a table'
begin
  declare rule_ integer default 28;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows between 1 and @max_rows;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;
  select table_name, table_rows, 'Check manually' as message from information_schema.tables where table_schema = schema_ and table_rows > @max_rows;

  tableLoop: while i < number_of_objects do
    fetch cursorT into table_;
    -- the contrived concat prevents the prepared statement from having to deal with reserved words
    set @columnnames = (select concat('`', group_concat(column_name separator '`, `'), '`') from information_schema.columns where table_schema = schema_ and table_name = table_ and column_key <> 'PRI' order by ordinal_position);
    set @v_sql = concat('select "', table_, '" as table_name, ', @columnnames, ' from ', schema_, '.', table_, ' group by ', @columnnames, ' having count(*) > 1');
    prepare statement from @v_sql;
    execute statement;
    deallocate prepare statement;

    set i = i + 1;
  end while tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 29: Storing lists in varchar columns
-- List elements are separated by either comma (,) or semicolon (;).

drop procedure if exists dblint_rule29 //
create procedure dblint_rule29 (in schema_ varchar(32))
comment 'Storing lists in varchar columns'
begin
  declare rule_ integer default 29;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_name not like 'dblint%' and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- set @v_sql = concat('select "', table_, '" as table_name, ', column_, ', count(*) from ', schema_, '.', table_, ' where ', column_, ' regexp "([a-za-z0-9]+[,; ])+" group by ', column_);
          set @v_sql = concat('insert into dblint_results (id, table_name, column_name, message) select 29, "', table_, '", "', column_, '", "Contains list" from ', schema_, '.', table_, ' where ', column_, ' regexp "([a-za-z0-9]+[,;])+" group by ', column_);
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 31: Defined primary key is not a minimal key

drop procedure if exists dblint_rule31 //
create procedure dblint_rule31 (in schema_ varchar(32))
comment 'Defined primary key is not a minimal key'
begin
  declare rule_ integer default 31;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.columns where table_schema = schema_ and column_key = 'PRI' group by table_name;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: while i < number_of_objects do
    fetch cursorT into table_;

    set @totalrows = (select table_rows from information_schema.tables where table_schema = schema_ and table_name = table_);
    if @totalrows = 0 then
      set i = i + 1;
      iterate tableLoop;
    end if;

    set @joinon = (select group_concat('t1.', column_name, ' = t2.', column_name) from information_schema.columns where table_schema = schema_ and table_name = table_ and column_key <> 'PRI');
    set @joinon = replace(@joinon, ',', ' and ');
    set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' as t1 join ', schema_, '.', table_, ' as t2 on ', @joinon, ' into @matchrows');
    prepare statement from @v_sql;
    execute statement;
    deallocate prepare statement;
    if @matchrows > @totalrows then
      insert into dblint_results (id, table_name, message) select rule_, table_, 'Defined primary key is not a minimal key';
    end if;

    set i = i + 1;
  end while tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 32: Redundant columns

drop procedure if exists dblint_rule32 //
create procedure dblint_rule32 (in schema_ varchar(32))
comment 'Redundant columns'
begin
  declare rule_ integer default 32;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: while i < number_of_objects do
    fetch cursorT into table_;

    begin
      declare column01 varchar(64);
      declare numcolumns1 integer default 0;
      declare j1 integer default 1;
      declare cursorC1 cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ order by ordinal_position;
      open cursorC1;

      select found_rows() into numcolumns1;

      columnLoop1: while j1 < numcolumns1 do
        fetch cursorC1 into column01;

        begin
          declare column02 varchar(64);
          declare numcolumns2 integer default 0;
          declare j2 integer default 1;
          declare cursorC2 cursor for
            select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and column_name > column01 order by ordinal_position;
          open cursorC2;

          select found_rows() into numcolumns2;

          columnLoop2: while j2 < numcolumns2 do
            fetch cursorC2 into column02;

            begin
              set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' where ', column01, ' <> ', column02, ' into @equalrows');
              prepare statement from @v_sql;
              execute statement;
              deallocate prepare statement;
              if @equalrows = 0 then
                select table_ as table_name, column01 as column_name01, column02 as column_name02;
              end if;
            end;

            set j2 = j2 + 1;
          end while columnLoop2;
          close cursorC2;
        end;

        set j1 = j1 + 1;
      end while columnLoop1;
      close cursorC1;
    end;

    set i = i + 1;
  end while tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 33: All values equal the default value

drop procedure if exists dblint_rule33 //
create procedure dblint_rule33 (in schema_ varchar(32))
comment 'All values equal the default value'
begin
  declare rule_ integer default 33;
  declare table_ varchar(32);
  declare number_of_tables integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_tables;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_tables then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare number_of_columns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and column_default is not NULL;
      open cursorC;

      select found_rows() into number_of_columns;

      columnLoop: loop
        if j > number_of_columns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- select the columns that have only one value
          set @v_sql = concat('select ', column_, ' from ', schema_, '.', table_, ' group by ', column_, ' having count(distinct ', column_, ') = 1 into @value');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          set @defaultvalue = (select column_default from information_schema.columns where table_schema = schema_ and table_name = table_ and column_name = column_);
          if @value = @defaultvalue then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, concat('All values equal the default value: ', coalesce(@defaultvalue, 'none'));
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 34: Not-NULL columns containing many empty strings

drop procedure if exists dblint_rule34 //
create procedure dblint_rule34 (in schema_ varchar(32))
comment 'Not-NULL columns containing many empty strings'
begin
  declare rule_ integer default 34;
  declare factor real default 0.5;    -- factor is the minimum fraction of rows that have NULL values only
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;
    set @totalrows = (select table_rows from information_schema.tables where table_schema = schema_ and table_name = table_);

    begin
      declare curColumn varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' and is_nullable = 'NO' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into curColumn;

        begin
          set @emptystringrows = 0;
          set @v_sql = concat("select count(*) from ", schema_, ".", table_, " where ", curColumn, " = '' into @emptystringrows");
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @emptystringrows > @totalrows * factor then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, curColumn, 'Not NULL column containing many empty strings';
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 35: Numbers or dates stored in varchar columns

drop procedure if exists dblint_rule35 //
create procedure dblint_rule35 (in schema_ varchar(32))
comment 'Numbers or dates stored in varchar columns'
begin
  declare rule_ integer default 35;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;
    set @totalrows = (select table_rows from information_schema.tables where table_schema = schema_ and table_name = table_);

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- test numbers
          set @v_where = concat_ws(" ", " where ", column_, " regexp '^[1-9]?[0-9]*$'");
          set @v_sql = concat("select count(*) from ", schema_, ".", table_, @v_where, " into @isnumberrows");
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @isnumberrows = @totalrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Number stored in varchar column';
          end if;

          if @isnumberrows > 0 then
            set j = j + 1;
            iterate columnLoop;
          end if;

          -- test dates
          set @v_where = concat_ws(" ", " where cast(", column_, " as date) is not NULL ");
          set @v_sql = concat("select count(*) from ", schema_, ".", table_, @v_where, " into @isdaterows");
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @isdaterows = @totalrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Date stored in varchar column';
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 37: Mixture of data types in text columns

drop procedure if exists dblint_rule37 //
create procedure dblint_rule37 (in schema_ varchar(32))
comment 'Mixture of data types in text columns'
begin
  declare rule_ integer default 37;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- get the count of non empty rows
          set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' where ', column_, ' is not NULL and ', column_, ' <> "" into @nonemptyrows');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;

          set @v_select = concat('select count(*) from ', schema_, '.', table_);
          set @v_extra_cond = concat(" and ", column_, "<> '' and ", column_, " is not NULL into @foundrows");

          -- test integer
          set @v_where = concat(' where ', column_, ' regexp "^-?[1-9]?[0-9]+$" ');
          set @v_sql = concat(@v_select, @v_where, @v_extra_cond);

          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;

          if @foundrows > 0 and @foundrows <> @nonemptyrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Integers in varchar column';
            set j = j + 1;
            iterate columnLoop;
          end if;

          -- test float
          set @v_where = concat(' where ', column_, ' regexp "^-?[0-9]*[\.][0-9]+([ee][-+]?[0-9]+)?$" ');
          set @v_sql = concat(@v_select, @v_where, @v_extra_cond);

          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;

          if @foundrows > 0 and @foundrows <> @nonemptyrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Floats in varchar column';
            set j = j + 1;
            iterate columnLoop;
          end if;

          -- test date, time, datetime
          set @v_where = concat(' where ', column_, ' regexp "^[0-9\:\/\-]+$" ');
          set @v_sql = concat(@v_select, @v_where, @v_extra_cond);

          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;

          if @foundrows > 0 and @foundrows <> @nonemptyrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Dates in varchar column';
            set j = j + 1;
            iterate columnLoop;
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 38: Columns with only one value

drop procedure if exists dblint_rule38 //
create procedure dblint_rule38 (in schema_ varchar(32))
comment 'Columns with only one value'
begin
  declare rule_ integer default 38;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and column_key = '' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- select columns that have only one value
          set @v_sql = concat('insert into dblint_results (id, table_name, column_name, message) select 38, "', table_, '", "', column_, '", "Has only one value" from ', schema_, ".", table_, ' having count(distinct ', column_, ') = 1');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 39: All values differ from the default value

drop procedure if exists dblint_rule39 //
create procedure dblint_rule39 (in schema_ varchar(32))
comment 'All values differ from the default value'
begin
  declare rule_ integer default 39;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare curColumn varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and column_key = '' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into curColumn;

        begin
          -- call dblint_debug (concat('table is: ', table_, ' and column is: ', curColumn));
          set @defaultvalue = (select column_default from information_schema.columns where table_schema = schema_ and table_name = table_ and column_name = curColumn and column_default is not NULL);
          set @v_sql = concat_ws(' ', 'select count(*) from ', schema_, '.', table_, 'where', curColumn, '<=> trim("', @defaultvalue, '") into @notequalrows');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @notequalrows = 0 then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, curColumn, concat('All values differ from default: ', coalesce(@defaultvalue, 'none'));
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 40: Inconsistent casing of first character in text columns

drop procedure if exists dblint_rule40 //
create procedure dblint_rule40 (in schema_ varchar(32))
comment 'Inconsistent casing of first character in text columns'
begin
  declare rule_ integer default 40;
  declare table_ varchar(32);
  declare number_of_tables integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select t.table_name from information_schema.tables t inner join information_schema.columns c on t.table_schema = c.table_schema and t.table_name = c.table_name where t.table_schema = schema_ and (data_type = 'varchar' or data_type like '%text' or data_type like '%blob') and table_rows > 0 group by table_name;
  open cursorT;
  select found_rows() into number_of_tables;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_tables then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare number_of_columns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and (data_type = 'varchar' or data_type like '%text' or data_type like '%blob');
      open cursorC;

      select found_rows() into number_of_columns;

      columnLoop: loop
        if j > number_of_columns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          set @count = (select count(*) from table_ where cast(lower(substring(column_, 1, 1)) as binary) = cast(substring(column_, 1, 1) as binary) and column_ is not NULL);
          if @count > 0 then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Column starts with uppercase or lowercase letter';
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 42: Column values from a small domain

drop procedure if exists dblint_rule42 //
create procedure dblint_rule42 (in schema_ varchar(32))
comment 'Column values from a small domain'
begin
  declare rule_ integer default 42;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          -- consider 2 - 9 distinct values constitute a small domain.
          set @v_sql = concat('insert into dblint_results (id, table_name, column_name, message) select 42, "', table_, '", "', column_, '", concat("Has only ", count(distinct ', column_, '), " values") from ', schema_, '.', table_, ' having count(distinct ', column_, ') between 2 and 9');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 43: Large unfilled varchar columns

drop procedure if exists dblint_rule43 //
create procedure dblint_rule43 (in schema_ varchar(32))
comment 'Large unfilled varchar columns'
begin
  declare rule_ integer default 43;
  declare factor real default 0.5;       -- factor is the fraction of the column-size in which the largest value still fits
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    set @totalrows = (select table_rows from information_schema.tables where table_name = table_ and table_schema = schema_);

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        set @maxlength = (select character_maximum_length from information_schema.columns where table_schema = schema_ and table_name = table_ and column_name = column_);

        begin
          set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' where length(', column_, ') < ', factor, ' * ', convert(@maxlength using latin1), ' into @numofrows');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @numofrows = @totalrows then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, concat('Large character_maximum_length: ', @maxlength);
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 44: Missing Not-NULL constraints

drop procedure if exists dblint_rule44 //
create procedure dblint_rule44 (in schema_ varchar(32))
comment 'Missing Not-NULL constraints'
begin
  declare rule_ integer default 44;
  declare table_ varchar(32);
  declare numtables integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;
  select found_rows() into numtables;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > numtables then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and is_nullable = 'YES' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' where ', column_, ' is NULL into @nullrows');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @nullrows = 0 then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Has missing NOT NULL constraint';
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 45: Column containing too many NULLs

drop procedure if exists dblint_rule45 //
create procedure dblint_rule45 (in schema_ varchar(32))
comment 'Column containing too many NULLs'
begin
  declare rule_ integer default 45;
  declare factor real default 0.8;    -- factor is the minimum fraction of rows that have NULL values only
  declare table_ varchar(32);
  declare numtables integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_rows > 0;
  open cursorT;

  select count(*) into numtables;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > numtables then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    set @totalrows = (select table_rows from information_schema.tables where table_schema = schema_ and table_name = table_);

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and is_nullable = 'YES' order by ordinal_position;
      open cursorC;

      select count(*) into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          set @v_sql = concat('select count(*) from ', schema_, '.', table_, ' where ', column_, ' is NULL into @nullrows');
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
          if @nullrows > @totalrows * factor then
            insert into dblint_results (id, table_name, column_name, message) select rule_, table_, column_, 'Contains too many NULLs';
          end if;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

-- Rule 59: Storing apostrophe in varchar columns

drop procedure if exists dblint_rule59 //
create procedure dblint_rule59 (in schema_ varchar(32))
comment 'Storing apostrophe in varchar columns'
begin
  declare rule_ integer default 59;
  declare table_ varchar(32);
  declare number_of_objects integer default 0;
  declare i integer default 1;
  declare cursorT cursor for 
    select table_name from information_schema.tables where table_schema = schema_ and table_name not like 'dblint%' and table_rows > 0;
  open cursorT;
  select found_rows() into number_of_objects;

  select concat(id, ' ', name, ': ', description) as description from dblint_rules where id = rule_;

  tableLoop: loop
    if i > number_of_objects then
      leave tableLoop;
    end if;
    fetch cursorT into table_;

    begin
      declare column_ varchar(64);
      declare numcolumns integer default 0;
      declare j integer default 1;
      declare cursorC cursor for
        select column_name from information_schema.columns where table_schema = schema_ and table_name = table_ and data_type = 'varchar' order by ordinal_position;
      open cursorC;

      select found_rows() into numcolumns;

      columnLoop: loop
        if j > numcolumns then
          leave columnLoop;
        end if;
        fetch cursorC into column_;

        begin
          set @v_sql = concat('insert into dblint_results (id, table_name, column_name, message) select 59, "', table_, '", "', column_, '", "Contains apostrophe" from ', schema_, '.', table_, ' where ', column_, ' like "%\'%" or ', column_, ' like "%\’%" or ', column_, ' like "%\”%" group by ', column_);
          prepare statement from @v_sql;
          execute statement;
          deallocate prepare statement;
        end;

        set j = j + 1;
      end loop columnLoop;
      close cursorC;
    end;

    set i = i + 1;
  end loop tableLoop;
  close cursorT;

  select remediation from dblint_rules where id = rule_;
end;
//

delimiter ;

