-- COMP9311 15s1 Proj 2
--
-- check.sql ... checking functions
--
--
-- Helper functions
--

create or replace function
	proj2_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj2_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj2_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- proj2_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	proj2_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- proj2_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	proj2_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not proj2_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj2_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not proj2_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return proj2_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- proj2_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	proj2_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj2_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array[
				'q1a', 
				'q2a',  'q3a', 'q3b', 'q3c' 
				];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Proj 2
--


create or replace function check_q1a() returns text
as $chk$
select proj2_check('function','q1','q1a_expected',
                   $$select * from q1(9334555)$$)
$chk$ language sql;


create or replace function check_q2a() returns text
as $chk$
select proj2_check('function','q2','q2a_expected',
                   $$select * from q2(3489313)$$)
$chk$ language sql;


create or replace function check_q3a() returns text
as $chk$
select proj2_check('function','q3','q3a_expected',
                   $$select * from q3(1058)$$)
$chk$ language sql;

create or replace function check_q3b() returns text
as $chk$
select proj2_check('function','q3','q3b_expected',
                   $$select * from q3(1410)$$)
$chk$ language sql;

create or replace function check_q3c() returns text
as $chk$
select proj2_check('function','q3','q3c_expected',
                   $$select * from q3(1121)$$)
$chk$ language sql;


--
-- Tables of expected results for test cases
--


drop table if exists q1a_expected;
create table q1a_expected (
    q6 text
);


drop table if exists q2a_expected;
create table q2a_expected (
    code character(8),
    term character(4),
    prog character(4),
    name text,
    mark integer,
    grade character(2),
    uoc integer
);

drop table if exists q3a_expected;
create table q3a_expected (
    objtype text,
    object text
);

drop table if exists q3b_expected;
create table q3b_expected (
    objtype text,
    object text
);

drop table if exists q3c_expected;
create table q3c_expected (
    objtype text,
    object text
);





COPY q1a_expected (q6) FROM stdin;
John Shepherd
\.


COPY q2a_expected (code, term, prog, name, mark, grade, uoc) FROM stdin;
ARTS1750	12s1	3432	Intro to Development	78	DN	6
EDST1101	12s1	3432	Educational Psycholo	80	DN	6
PSYC1001	12s1	3432	Psychology 1A	84	DN	6
PSYC1021	12s1	3432	Intro to Psych Appli	84	DN	6
ARTS1062	12s2	3432	Hollywood Film	75	DN	6
ARTS1871	12s2	3432	Cultural Experience	64	PS	6
CRIM1011	12s2	3432	Intro to Criminal Ju	63	PS	6
PSYC1011	12s2	3432	Psychology 1B	72	CR	6
ARTS2284	13x1	3432	Europe in the Middle	51	PS	6
GENM0518	13x1	3432	Health & Power in In	97	HD	6
\N	\N	\N	Overall WAM	74	\N	60
\.

COPY q3a_expected (objtype, object) FROM stdin;
subject	COMP2011
subject	COMP2021
subject	COMP2041
subject	COMP2091
subject	COMP2110
subject	COMP2111
subject	COMP2121
subject	COMP2411
subject	COMP2711
subject	COMP2811
subject	COMP2821
subject	COMP2911
subject	COMP2920
\.

COPY q3b_expected (objtype, object) FROM stdin;
subject	CVEN4101
subject	CVEN4102
subject	CVEN4103
subject	CVEN4104
\.

COPY q3c_expected (objtype, object) FROM stdin;
subject	PTRL3001
subject	PTRL3002
subject	PTRL3003
subject	PTRL3015
subject	PTRL3022
subject	PTRL3023
subject	PTRL3025
\.

