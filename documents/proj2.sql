-- COMP9311 15s1 Proj 2


-- Q1: ...

create or replace function Q1(integer) returns text
as
$$
... one SQL statement, possibly using other views defined by you ...
$$ language sql
;

-- Q2: ...

create or replace function Q2(integer)
	returns setof NewTranscriptRecord
as $$
declare
	... PLpgSQL variable delcarations ...
begin
	... PLpgSQL code ...
end;
$$ language plpgsql
;


-- Q3: ...

create or replace function Q3(integer)
	returns setof AcObjRecord
as $$
declare
	... PLpgSQL variable delcarations ...
begin
	... PLpgSQL code ...
end;
$$ language plpgsql
;

