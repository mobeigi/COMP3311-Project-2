-- COMP3311 15s1 Project 2
--
-- MyMyUNSW Solution
-- By: Mohammad Ghasembeigi (z3464208)


-- Q1 --

create or replace function Q1(integer)
  returns text
as $$
  SELECT name as Name
  FROM people
  WHERE id = $1
  OR unswid = $1

$$ language sql
;


-- Q2 --

create or replace function Q2(integer)
	returns setof NewTranscriptRecord
as $$
declare
  rec NewTranscriptRecord;
  UOCtotal integer := 0;
  UOCpassed integer := 0;
  wsum integer := 0;
  wam integer := 0;
  x integer;
begin
  select s.id into x
    from   Students s join People p on (s.id = p.id)
    where  p.unswid = $1;

    if (not found) then
      raise EXCEPTION 'Invalid student %',$1;
    end if;

    for rec in
      select  su.code,
              substr(t.year::text,3,2)||lower(t.term),

              prog.code,

              substr(su.name,1,20),

              e.mark, e.grade, su.uoc

      from   People p
      join Students s on (p.id = s.id)

      join Course_enrolments e on (e.student = s.id)

      join Courses c on (c.id = e.course)

      join Subjects su on (c.subject = su.id)

      join Semesters t on (c.semester = t.id)

      join program_enrolments pe on (pe.student = s.id) AND (pe.semester = t.id)

      join programs prog on (prog.id = pe.program)

      where  p.unswid = $1
      order by t.starting, su.code
    
    loop
      if (rec.grade = 'SY') then
        UOCpassed := UOCpassed + rec.uoc;
      elsif (rec.mark is not null) then
        if (rec.grade in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
          -- only counts towards creditted UOC
          -- if they passed the course
          UOCpassed := UOCpassed + rec.uoc;
        end if;

        -- we count fails towards the WAM calculation
        UOCtotal := UOCtotal + rec.uoc;

        -- weighted sum based on mark and uoc for course
        wsum := wsum + (rec.mark * rec.uoc);
      
        -- don't give UOC if they failed
        if (rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
          rec.uoc := 0;
        end if;
      end if;

      return next rec;
    end loop;

    if (UOCtotal = 0) then
      rec := (null,null,null,'No WAM available',null,null,null);
    else
      wam := wsum / UOCtotal;
      rec := (null,null,null,'Overall WAM',wam,null,UOCpassed);
    end if;

    -- append the last record containing the WAM
    return next rec;

end;
$$ language plpgsql
;

-- Q3  --

-- This function calls __Q3HELPER
-- We return distinct rows heres to avoid any duplicates at all
create or replace function Q3(integer)
	returns setof AcObjRecord
as $$
declare
  rec AcObjRecord;
begin
  FOR rec IN
    SELECT DISTINCT *
    FROM (
          SELECT * FROM __Q3HELPER($1)
         ) AS dupRecs
  LOOP
    RETURN NEXT rec;
  END LOOP;
end;
$$ language plpgsql
;

-- Helper function that returns all records
create or replace function __Q3HELPER(integer)
	returns setof AcObjRecord
as $$
declare
  rec AcObjRecord;
  gdefby text;  -- ie pattern or enumerated (query also exists), see:  select * from acad_object_groups where gdefby <> 'pattern' AND gdefby <> 'enumerated';
  gtype text; -- type such as subject, stream or program
  definition text; -- relevant pattern or query
  pattern text; -- used to loop over entire definition pattern by pattern
begin
  SELECT aog.gdefby, aog.gtype, aog.definition
  INTO gdefby, gtype, definition
  FROM acad_object_groups aog
  WHERE id = $1;
  
  IF (gdefby = 'pattern') THEN

    FOR pattern IN
      SELECT *
      FROM regexp_split_to_table(definition, E',') -- split definition into patterns on comma
    LOOP
    
      -- Trim surrounding whitespace
      pattern := trim(pattern);
    
      -- Consider special case for GEN ed/FREE definitions subjects
      -- We will ignore them (based on updated spec)
      IF gtype = 'subject' THEN
        IF (pattern SIMILAR TO 'GEN%|ZGEN%|FREE%') THEN
          CONTINUE; --goto next pattern
        END IF;
      END IF;
      
      -- Update pattern, stored # means any 1 character which in SQL regexp is: _
      -- All other regexp patterns in table are valid as is
      pattern := REPLACE(pattern, '#', '_');
      
      IF gtype = 'subject' THEN
          -- Select distinct subject codes from subjects
        FOR rec IN
          SELECT DISTINCT gtype, s.code
          FROM subjects s
          WHERE (s.code SIMILAR TO pattern )
          ORDER BY s.code
        LOOP
          RETURN NEXT rec;
        END LOOP;
      ELSIF gtype = 'program' THEN
        -- Select distinct program codes from programs
        FOR rec IN
          SELECT DISTINCT gtype, p.code
          FROM programs p
          WHERE (p.code SIMILAR TO pattern )
          ORDER BY p.code
        LOOP
          RETURN NEXT rec;
        END LOOP;
      ELSIF gtype = 'stream' THEN
        -- Select distinct stream codes from streams
        FOR rec IN
          SELECT DISTINCT gtype, s.code
          FROM streams s
          WHERE (s.code SIMILAR TO pattern )
          ORDER BY s.code
        LOOP
          RETURN NEXT rec;
        END LOOP;
      END IF;
       
    END LOOP;
    
  -- Return empty result for non pattern groups
  ELSE
    RETURN;
  END IF;
end;
$$ language plpgsql
;