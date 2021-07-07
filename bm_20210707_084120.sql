--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bm; Type: SCHEMA; Schema: -; .
--

CREATE SCHEMA bm;


--
-- Name: add_equipment(text); Type: PROCEDURE; Schema: bm; .
--

CREATE PROCEDURE bm.add_equipment(name text)
    LANGUAGE plpgsql
    AS $$
	DECLARE
		next_id int;
	BEGIN
		SELECT COALESCE(max(id), 0) FROM bm.equipment INTO next_id;
		next_id = next_id + 1;
	
		INSERT INTO bm.equipment(id, name, key) VALUES (next_id, name, name);
	END;
$$;


--
-- Name: add_equipment(text, text); Type: PROCEDURE; Schema: bm; .
--

CREATE PROCEDURE bm.add_equipment(name text, key text)
    LANGUAGE plpgsql
    AS $$
	DECLARE
		next_id int;
	BEGIN
		SELECT COALESCE(max(id), 0) FROM bm.equipment INTO next_id;
		next_id = next_id + 1;
	
		INSERT INTO bm.equipment(id, name, key) VALUES (next_id, name, key);
	END;
$$;


--
-- Name: add_exercise(text, text, integer[], boolean, boolean, boolean, boolean, boolean, integer, integer, integer); Type: PROCEDURE; Schema: bm; .
--

CREATE PROCEDURE bm.add_exercise(name text, level text, equipment integer[], unilateral boolean, isometric boolean, ok_for_higher_reps boolean, skill boolean, compound boolean, main_group integer, seconds_per_rep integer, max_hold_seconds integer)
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		next_id int;
		i int;
	BEGIN
		SELECT COALESCE(max(id), 0) INTO next_id FROM bm.exercises;
		next_id := next_id + 1;
	
		FOREACH i IN ARRAY equipment LOOP
			INSERT INTO bm.exercise_equipment (exercise_id, equipment_id)
			VALUES (next_id, i);
		END LOOP;
	
		INSERT INTO bm.exercises (
		id,
		name,
		unilateral,
		isometric,
		skill,
		compount,
		level,
		main_group,
		seconds_per_rep,
		max_hold_seconds,
		created
		)
		VALUES (
			next_id,
			name,
			unilateral,
			isometric,
			skill,
			compound,
			level,
			main_group,
			seconds_per_rep,
			max_hold_seconds,
			CURRENT_TIMESTAMP
		);
	END;
$$;


--
-- Name: add_exercisegroup(text, integer, integer, integer); Type: PROCEDURE; Schema: bm; .
--

CREATE PROCEDURE bm.add_exercisegroup(name text, num integer, next integer, prev integer)
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		next_id int;
	BEGIN
		SELECT COALESCE(max(id),0) FROM bm.exercisegroups INTO next_id;
		next_id = next_id + 1;
	
		INSERT INTO bm.exercisegroups(id, name, number, next_group, previous_group)
		VALUES (next_id, name, num, next, prev);
	
	END;
$$;


--
-- Name: add_level(text); Type: PROCEDURE; Schema: bm; .
--

CREATE PROCEDURE bm.add_level(name text)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		INSERT INTO bm.levels (name) VALUES (name);
	END;
$$;


--
-- Name: get_equipment_ids(text[]); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_equipment_ids(names text[]) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		ids int[];
		i int;
		eq_name TEXT;
	BEGIN
		SELECT array_length(names, 1) 
		INTO i;
	
		IF i = 0 OR (i = 1 AND length(names[0]) = 1)
		THEN
			SELECT ARRAY(
				SELECT id
				FROM bm.equipment
			) INTO ids;
			RETURN ids;
		
		ELSE
			FOREACH eq_name IN ARRAY names
			LOOP 
				SELECT e.id 
				INTO i
				FROM bm.equipment e
				WHERE LOWER(e.key) = LOWER(eq_name); 
				SELECT array_append(ids, i) INTO ids; 
			END LOOP;

		END IF;
		
		RETURN ids;
	END;
$$;


--
-- Name: get_exercisegroup_ids(text[]); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_exercisegroup_ids(names text[]) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		ids int[];
		i int;
		exg_name TEXT;
	
	BEGIN
		SELECT array_length(names, 1)
		INTO i;
	
		IF i = 0 OR (i = 1 AND names[0] = '')
		THEN
			SELECT ARRAY(
				SELECT id
				FROM bm.exercisegroups
			) INTO ids;
			RETURN ids;
		
		ELSE 
			FOREACH exg_name IN ARRAY names
			LOOP 
				SELECT e.id 
				INTO i
				FROM bm.exercisegroups e
				WHERE LOWER(e.name) = LOWER(exg_name); 
				SELECT array_append(ids, i) INTO ids; 
			END LOOP;
		END IF;
	
		RETURN ids;
	END;
$$;


--
-- Name: get_numbers_to(integer); Type: FUNCTION; Schema: bm; Owner: postgres
--

CREATE FUNCTION bm.get_numbers_to(to_num integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
    DECLARE
        i int;
        nums int[];
	BEGIN
        for i in 0..to_num LOOP
            select array_append(nums, i) into nums;
        end loop;
        return nums;
	END; 
	$$;


--
-- Name: get_random_number(integer); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_random_number(num integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	rand int;
	BEGIN
		RETURN floor(random() * (num + 1));
	END;
$$;


--
-- Name: get_random_number_between(integer, integer); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_random_number_between(a integer, b integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		diff int;
		smaller int;
		bigger int;
		rand int;
	BEGIN
		SELECT abs(a - b) 
		INTO diff;
	
		IF a < b
		THEN
			SELECT a 
			INTO smaller;
			SELECT b
			INTO bigger;
		ELSE 
			SELECT b
			INTO smaller;
			SELECT a
			INTO bigger;
		END IF;
	
		SELECT floor(smaller + random() * (diff + 1))
		INTO rand;
	
		IF rand < bigger
		THEN 
			RETURN rand;
		ELSE
			RETURN rand - 1;
		END IF;
	END;
$$;


--
-- Name: get_random_numbers(integer, integer, integer); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_random_numbers(a integer, b integer, c integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		i int;
		arr int[];
	BEGIN
		FOR i IN 1..c LOOP
			SELECT array_append(arr, bm.get_random_number_between(a, b)) INTO arr;
			i := i + 1;
		END LOOP;
		
		RETURN arr;
	END;
$$;


--
-- Name: get_sets_and_reps(text); Type: FUNCTION; Schema: bm; .
--

CREATE FUNCTION bm.get_sets_and_reps(g text) RETURNS TABLE(max_sets integer, min_sets integer, max_reps integer, min_reps integer)
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		count int;
	BEGIN
		CREATE TEMP TABLE numbers AS
		SELECT sar.max_sets, sar.min_sets, sar.max_reps, sar.min_reps
		FROM bm.sets_and_reps sar
		WHERE lower(sar.goal) = lower(g);
	
		SELECT count(*)
		INTO count
		FROM numbers;
	
		IF NOT count = 1 THEN
			RETURN QUERY 
			SELECT 
				sar.max_sets max_sets, 
				sar.min_sets min_sets, 
				sar.max_reps max_reps, 
				sar.min_reps min_reps
			FROM bm.sets_and_reps sar 
			WHERE lower(sar.goal) = 'default';
		ELSE
			RETURN QUERY 
			SELECT 
				n.max_sets max_sets,
				n.min_sets min_sets,
				n.max_reps max_reps,
				n.min_reps min_reps
			FROM numbers n
			LIMIT 1; -- just in CASE hahaha
		END IF;

		DROP TABLE numbers;
	END;
$$;


--
-- Name: get_workout(text[], text[], text, integer, boolean, text); Type: FUNCTION; Schema: bm; Owner: postgres
--

CREATE FUNCTION bm.get_workout(eq text[], exg text[], goal text, num_of_ex_per_group integer, higher_reps boolean DEFAULT false, difficulty text DEFAULT 'all'::text) RETURNS TABLE(id integer, exercise_name text, sets_per_exercise integer, reps_per_set integer, total_duration integer)
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		i int;
		j int;
		k int;
		
		selected_exercise_ids int[];
		selected_equipment_ids int[];
		selected_exgroup_ids int[];
		selected_difficulties int[];
		selected_difficulty int;
	
		num_to_return int;
	
		max_sets int;
		min_sets int;
		max_reps int;
		min_reps int;
	
	BEGIN	
        -- If higher reps are true, do not return ton of exercises.
		IF higher_reps = TRUE AND num_of_ex_per_group > 2
		THEN 
			num_to_return := array_length(exg, 1) * 2;
		ELSE 
			num_to_return := array_length(exg, 1) * num_of_ex_per_group;
		END IF;
		
		-- Find difficulty level id.
		select l.id
		into selected_difficulty
		from bm.levels l
		where "name" = difficulty;
		
		-- If no difficulty is found, select them all.
		if selected_difficulty is NULL
		THEN
            select count(*)
            into selected_difficulty
            from bm.levels;
		end if;
	
        -- Select all difficulty levels up to selected one.
        -- It is assumed that easier level is a lower id.
        select bm.get_numbers_to(selected_difficulty)
        into selected_difficulties;
        
		SELECT bm.get_equipment_ids(eq)
		INTO selected_equipment_ids;
	
		SELECT bm.get_exercisegroup_ids(exg)
		INTO selected_exgroup_ids;
	
		CREATE TEMP TABLE found_exercises AS 
		SELECT e.id, e.name, e.main_group, e.seconds_per_rep 
		FROM bm.exercises e
		inner JOIN 
			bm.exercise_equipment ee ON e.id = ee.exercise_id
		WHERE 
                ee.equipment_id = ANY(selected_equipment_ids) or ee.equipment_id = 0
			AND
                e.main_group = any(selected_exgroup_ids)
			AND
                e.level_id = any(selected_difficulties)
            AND
                (e.ok_for_high_reps = higher_reps or e.ok_for_high_reps is null);
	
        -- How many exercises did we find?
		SELECT count(*) INTO j FROM found_exercises;
		
		-- If there's no exercises found, just return.
		if j = 0
		then 
            drop table found_exercises;
            return;
        end if;
		
		-- Select random exercises.
		SELECT bm.get_random_numbers(1, j, 2 * num_to_return) INTO selected_exercise_ids;
	
        -- Select set/rep ranges and tweak them a bit
		SELECT csar.max_sets, csar.min_sets, csar.max_reps, csar.min_reps
		INTO max_sets, min_sets, max_reps, min_reps
		FROM bm.get_sets_and_reps(goal) csar;
		
		if higher_reps = true
		then
            max_reps := max_reps * 2;
            min_reps := round(min_reps * 1.5);
		end if;
	
		CREATE TABLE workout (
			id int,
			exercise_name TEXT,
			sets_per_exercise int,
			reps_per_set int,
			total_duration int,
			main_group int
		);

		i := 0;
		
		-- Loop selection from found_exercises in case first select yields too little exercises.
		WHILE i < num_to_return LOOP
			selected_exercise_ids := array[]::int[];
			SELECT count(*) INTO j FROM found_exercises;
			SELECT bm.get_random_numbers(1, j, 2 * num_to_return) INTO selected_exercise_ids;	
		
			INSERT INTO workout (
				SELECT distinct
					f.id id,
					f.name exercise_name,
					bm.get_random_number_between(max_sets, min_sets) sets_per_exercise,
					bm.get_random_number_between(max_reps, min_reps) reps_per_set,
					sets_per_exercise * reps_per_set * f.seconds_per_rep
				FROM found_exercises f
				WHERE 
                        f.id = any(selected_exercise_ids)
                    and 
                        f.main_group = any(selected_exgroup_ids) -- Not sure why, but for some reason without this the found_exercises query selects all exercise groups.
			);
			
			SELECT count(*)
			INTO i
			FROM workout;
		END LOOP;
	
		RETURN QUERY
		SELECT 
			DISTINCT ON (w.id) w.id,
			w.exercise_name, 
			w.sets_per_exercise, 
			w.reps_per_set,
			w.total_duration
		FROM workout w;
		
		DROP TABLE workout;
		DROP TABLE found_exercises;
	END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: equipment; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.equipment (
    id integer NOT NULL,
    name text,
    key text
);


--
-- Name: exercise_equipment; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.exercise_equipment (
    exercise_id integer,
    equipment_id integer
);


--
-- Name: exercise_exercisegroup; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.exercise_exercisegroup (
    exercise_id integer,
    exercisegroup_id integer
);


--
-- Name: exercisegroups; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.exercisegroups (
    id integer NOT NULL,
    number integer,
    previous_group integer,
    next_group integer,
    name text
);


--
-- Name: exercises; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.exercises (
    id integer NOT NULL,
    name text,
    isometric boolean,
    unilateral boolean,
    ok_for_high_reps boolean,
    skill boolean,
    main_group integer,
    compount boolean,
    seconds_per_rep integer,
    max_hold_seconds integer,
    created timestamp without time zone,
    level_id integer
);


--
-- Name: levels; Type: TABLE; Schema: bm; Owner: postgres
--

CREATE TABLE bm.levels (
    id integer NOT NULL,
    name character varying(24) NOT NULL
);


--
-- Name: levels_id_seq; Type: SEQUENCE; Schema: bm; Owner: postgres
--

CREATE SEQUENCE bm.levels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: levels_id_seq; Type: SEQUENCE OWNED BY; Schema: bm; Owner: postgres
--

ALTER SEQUENCE bm.levels_id_seq OWNED BY bm.levels.id;


--
-- Name: sets_and_reps; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.sets_and_reps (
    id integer NOT NULL,
    goal text,
    max_sets integer,
    min_sets integer,
    max_reps integer,
    min_reps integer
);


--
-- Name: workout_exercisegroup; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.workout_exercisegroup (
    workout_id integer,
    exercisegroup_id integer
);


--
-- Name: workout_sets_and_reps; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.workout_sets_and_reps (
    workout_id integer,
    sets_and_reps_id integer
);


--
-- Name: workouts; Type: TABLE; Schema: bm; .
--

CREATE TABLE bm.workouts (
    id integer NOT NULL,
    rest_between_sets_seconds integer,
    rest_between_exercises_seconds integer,
    total_duration_seconds integer,
    rounds integer,
    created timestamp without time zone
);


--
-- Name: levels id; Type: DEFAULT; Schema: bm; Owner: postgres
--

ALTER TABLE ONLY bm.levels ALTER COLUMN id SET DEFAULT nextval('bm.levels_id_seq'::regclass);


--
-- Data for Name: equipment; Type: TABLE DATA; Schema: bm; .
--

INSERT INTO bm.equipment (id, name, key) VALUES
	(1, 'Gymnastic rings', 'rings'),
	(2, 'Bar', 'bar'),
	(3, 'Barbell', 'barbell'),
	(4, 'Dumbbell', 'dumbbell'),
	(5, 'Kettlebell', 'kettlebell'),
	(6, 'Parallettes', 'parallettes');


--
-- Data for Name: exercise_equipment; Type: TABLE DATA; Schema: bm; .
--

INSERT INTO bm.exercise_equipment (exercise_id, equipment_id) VALUES
	(1, 2),
	(1, 1),
	(2, 6),
	(2, 0),
	(2, 2),
	(2, 1),
	(3, 2),
	(3, 1),
	(3, 6),
	(3, 0),
	(4, 2),
	(4, 1),
	(4, 6),
	(4, 0),
	(5, 6),
	(6, 2),
	(6, 1),
	(6, 0),
	(6, 6),
	(7, 6),
	(7, 0),
	(7, 1),
	(8, 6),
	(8, 0),
	(8, 1),
	(9, 0),
	(9, 6),
	(10, 0),
	(10, 6),
	(11, 6),
	(11, 0),
	(11, 1),
	(12, 6),
	(12, 0),
	(12, 1),
	(13, 1),
	(14, 0),
	(14, 1),
	(15, 3),
	(15, 4),
	(15, 5),
	(16, 6),
	(16, 1),
	(17, 6),
	(18, 3),
	(18, 4),
	(18, 5),
	(19, 3),
	(19, 4),
	(19, 5),
	(20, 3),
	(21, 4),
	(21, 5),
	(22, 3),
	(22, 4),
	(22, 5),
	(23, 6),
	(23, 2),
	(23, 1),
	(24, 2),
	(24, 1),
	(25, 2),
	(25, 1),
	(26, 2),
	(26, 1),
	(27, 2),
	(27, 1),
	(28, 2),
	(28, 1),
	(29, 2),
	(29, 1),
	(30, 2),
	(30, 1),
	(31, 2),
	(32, 3),
	(32, 4),
	(32, 5),
	(33, 3),
	(33, 4),
	(33, 5),
	(34, 3),
	(34, 4),
	(34, 5),
	(35, 3),
	(35, 4),
	(35, 5),
	(36, 3),
	(36, 4),
	(36, 5),
	(37, 2),
	(37, 1),
	(38, 3),
	(38, 4),
	(38, 5),
	(39, 3),
	(39, 4),
	(39, 5),
	(40, 0),
	(40, 1),
	(41, 2),
	(41, 1),
	(42, 0),
	(42, 1),
	(43, 0),
	(43, 1),
	(44, 5),
	(44, 4),
	(45, 3),
	(46, 4),
	(46, 5),
	(47, 4),
	(47, 5),
	(48, 3),
	(48, 4),
	(49, 3),
	(49, 4),
	(50, 3),
	(51, 0),
	(52, 2),
	(52, 1),
	(53, 0),
	(54, 0),
	(55, 0),
	(55, 1),
	(55, 3),
	(56, 0),
	(57, 0),
	(58, 3),
	(59, 0),
	(60, 0),
	(61, 0),
	(62, 0),
	(63, 0),
	(63, 6),
	(64, 0),
	(64, 6),
	(65, 0),
	(65, 6),
	(65, 2),
	(66, 0),
	(66, 6),
	(66, 2),
	(67, 0),
	(67, 6),
	(67, 2),
	(68, 0),
	(68, 6),
	(68, 2),
	(69, 0),
	(70, 3),
	(70, 5),
	(70, 4),
	(71, 0),
	(72, 0),
	(73, 3),
	(73, 5),
	(73, 4),
	(74, 3),
	(74, 5),
	(74, 4),
	(75, 0),
	(76, 0),
	(77, 3),
	(77, 5),
	(77, 4),
	(78, 3),
	(78, 5),
	(78, 4),
	(79, 3),
	(80, 0),
	(81, 0),
	(82, 3),
	(82, 5),
	(82, 4),
	(83, 2),
	(83, 1),
	(84, 2),
	(84, 1),
	(85, 2),
	(85, 1),
	(86, 2),
	(86, 1),
	(87, 2),
	(87, 1),
	(88, 2),
	(88, 1),
	(89, 2),
	(89, 1),
	(90, 2),
	(90, 1),
	(91, 2),
	(91, 1),
	(92, 5),
	(92, 4),
	(93, 2),
	(93, 1),
	(94, 3),
	(95, 3),
	(95, 5),
	(95, 4),
	(96, 0),
	(97, 0),
	(98, 0),
	(99, 0),
	(100, 0);


--
-- Data for Name: exercise_exercisegroup; Type: TABLE DATA; Schema: bm; .
--



--
-- Data for Name: exercisegroups; Type: TABLE DATA; Schema: bm; .
--

INSERT INTO bm.exercisegroups (id, number, previous_group, next_group, name) VALUES
	(1, 1, 0, 2, 'Skill'),
	(2, 2, 1, 3, 'Legs'),
	(3, 3, 2, 4, 'Pull'),
	(4, 4, 3, 5, 'Push'),
	(5, 0, 5, 1, 'Midsection'),
	(6, 5, 4, 0, 'Arms');


--
-- Data for Name: exercises; Type: TABLE DATA; Schema: bm; .
--

INSERT INTO bm.exercises (id, name, isometric, unilateral, ok_for_high_reps, skill, main_group, compount, seconds_per_rep, max_hold_seconds, created, level_id) VALUES
	(4, 'Tuck planche', true, false, NULL, false, 4, true, 0, 20, '2021-06-21 22:15:42.602631', 2),
	(8, 'Pseudo planche push up', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.60447', 2),
	(10, 'Handstand push up against wall', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.605152', 2),
	(11, 'Planche lean', true, false, NULL, false, 4, true, 0, 60, '2021-06-21 22:15:42.605411', 2),
	(15, 'Shoulder press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.606454', 2),
	(16, 'Dips', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.606694', 2),
	(18, 'Bench press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.607184', 2),
	(19, 'Incline bench press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.607478', 2),
	(20, 'Behind the neck press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.607739', 2),
	(21, 'One arm bench press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.608', 2),
	(22, 'Decline bench press', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.608268', 2),
	(35, 'Shrug', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.611553', 2),
	(2, 'Planche', true, false, NULL, false, 4, true, 0, 20, '2021-06-21 22:15:42.601421', 4),
	(37, 'One arm pull up', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.612121', 4),
	(39, 'Stiff leg deadlift', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.612597', 2),
	(38, 'Deadlift', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.612361', 2),
	(65, 'Crow stand', true, false, NULL, true, 1, false, 0, 120, '2021-06-21 22:15:42.619184', 2),
	(1, 'Front lever', true, false, NULL, false, 3, true, 0, 20, '2021-06-21 22:15:42.596889', 3),
	(3, 'Straddle planche', true, false, NULL, false, 4, true, 0, 20, '2021-06-21 22:15:42.602075', 3),
	(9, 'Handstand push up', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.604851', 3),
	(12, 'One arm push up', false, true, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.605708', 3),
	(14, 'Archer push up', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.6062', 3),
	(17, 'Russian dips', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.606929', 3),
	(24, 'Straddle front lever', true, false, NULL, false, 3, true, 0, 30, '2021-06-21 22:15:42.608827', 3),
	(29, 'Muscle up', false, false, NULL, false, 3, true, 3, 0, '2021-06-21 22:15:42.610134', 3),
	(30, 'Archer pull up', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.610367', 3),
	(32, 'Power clean', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.610835', 3),
	(43, 'One arm bodyweigh curl(low bar/rings)', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.613601', 2),
	(67, 'Handstand', true, false, NULL, true, 1, false, 0, 300, '2021-06-21 22:15:42.619701', 3),
	(71, 'Pistol squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.620654', 3),
	(85, 'Straddle front lever pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.623898', 3),
	(6, 'Planche push up', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.60361', 4),
	(41, 'Bodyweight bicep curl(low bar/rings)', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.613122', 2),
	(72, 'Shrimp squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.620894', 4),
	(83, 'Front lever pull up hold', true, false, NULL, false, 3, true, 0, 10, '2021-06-21 22:15:42.623468', 4),
	(84, 'Front lever pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.623685', 4),
	(86, 'One arm pull ups', false, true, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.624109', 4),
	(5, 'Dead planche', true, false, NULL, false, 4, true, 0, 10, '2021-06-21 22:15:42.603131', 5),
	(13, 'Rings handstand push up', false, false, NULL, false, 4, true, 0, 20, '2021-06-21 22:15:42.605959', 5),
	(23, 'Victorian', true, false, NULL, false, 3, true, 0, 10, '2021-06-21 22:15:42.608527', 5),
	(26, 'One arm front lever', true, false, NULL, false, 4, true, 0, 10, '2021-06-21 22:15:42.609374', 5),
	(31, 'One arm muscle up', false, false, NULL, false, 4, true, 2, 0, '2021-06-21 22:15:42.610605', 5),
	(51, 'Dragon flag', true, false, NULL, false, 5, false, 0, 40, '2021-06-21 22:15:42.615642', 3),
	(58, 'Russian twists', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.617384', 2),
	(63, 'L-sit', true, false, NULL, false, 5, false, 0, 60, '2021-06-21 22:15:42.618689', 3),
	(64, 'V-sit', false, false, NULL, false, 5, false, 0, 30, '2021-06-21 22:15:42.61893', 4),
	(53, 'Dragon flag raises', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.616125', 3),
	(52, 'Hanging leg raises', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.615875', 2),
	(36, 'Clean', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.611825', 3),
	(33, 'Snatch', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.611071', 3),
	(25, 'Tuck front lever', true, false, NULL, false, 3, true, 0, 60, '2021-06-21 22:15:42.609112', 2),
	(28, 'Pull up', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.609896', 2),
	(34, 'Row', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.611303', 2),
	(40, 'Bodyweight pushdown', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.612853', 2),
	(42, 'One arm bodyweight pushdown', false, true, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.613366', 2),
	(7, 'Push up', false, false, NULL, false, 4, true, 1, 0, '2021-06-21 22:15:42.604059', 1),
	(48, 'Standing bicep curl', false, false, NULL, false, 5, true, 2, 0, '2021-06-21 22:15:42.614879', 1),
	(69, 'Squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.620173', 1),
	(70, 'Weighted squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.62042', 1),
	(73, 'Front squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.62112', 1),
	(74, 'Zercher squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.621367', 1),
	(75, 'Step up', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.621626', 1),
	(76, 'Walking lunge', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.621867', 1),
	(77, 'Weighted step up', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.622118', 1),
	(78, 'Weighted walking lunge', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.622365', 1),
	(79, 'Good morning', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.62259', 1),
	(81, 'Wide squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.623021', 1),
	(82, 'Straight leg deadlift', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.623236', 1),
	(92, 'One arm row', false, true, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.625568', 1),
	(93, 'Australian pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.625775', 1),
	(94, 'Bent over row', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.625981', 1),
	(66, 'Wall handstand', true, false, NULL, true, 1, false, 0, 300, '2021-06-21 22:15:42.619455', 2),
	(68, 'Elbow lever', true, false, NULL, true, 1, false, 0, 240, '2021-06-21 22:15:42.619937', 2),
	(80, 'Glute-ham raise', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.622806', 2),
	(87, 'Tuck lever pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.624324', 2),
	(88, 'Pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.624587', 2),
	(89, 'Typewriter pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.624924', 3),
	(90, 'Assisted one arm pull ups', false, true, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.625138', 3),
	(91, 'Archer pull ups', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.62536', 3),
	(95, 'One arm snatch', false, true, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.626198', 3),
	(99, 'Weighted pistol squat', false, false, NULL, false, 2, true, 3, 0, '2021-06-21 22:15:42.627025', 3),
	(100, 'Beginner shrimp squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.627226', 3),
	(98, 'Deep shrimp squat', false, false, NULL, false, 2, true, 3, 0, '2021-06-21 22:15:42.626824', 4),
	(96, 'Dragon squat', false, false, NULL, false, 2, true, 3, 0, '2021-06-21 22:15:42.62642', 5),
	(97, 'Weighted dragon squat', false, false, NULL, false, 2, true, 2, 0, '2021-06-21 22:15:42.626622', 5),
	(60, 'Leg flutters', false, false, NULL, false, 5, false, 1, 0, '2021-06-21 22:15:42.617893', 1),
	(56, 'Mountain climbers', false, false, NULL, false, 5, false, 1, 0, '2021-06-21 22:15:42.616883', 1),
	(62, 'Side plank', true, true, NULL, false, 5, false, 0, 300, '2021-06-21 22:15:42.618413', 1),
	(59, 'Lying leg raises', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.617631', 1),
	(54, 'Crunches', false, false, NULL, false, 5, false, 1, 0, '2021-06-21 22:15:42.616385', 1),
	(55, 'Ab wheel', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.61663', 1),
	(61, 'Plank', true, false, NULL, false, 5, false, 0, 300, '2021-06-21 22:15:42.618134', 1),
	(57, 'Crunches with raised legs', false, false, NULL, false, 5, false, 2, 0, '2021-06-21 22:15:42.617143', 1),
	(27, 'Australian pull up', false, false, NULL, false, 3, true, 2, 0, '2021-06-21 22:15:42.609647', 1),
	(44, 'Overhead extension on one arm', false, true, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.613833', 1),
	(45, 'Overhead extension', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.614086', 1),
	(46, 'Concentration curl', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.614347', 1),
	(47, 'Hammer curl', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.614617', 1),
	(50, 'Narrow grip bench press', false, false, NULL, false, 6, true, 2, 0, '2021-06-21 22:15:42.615402', 1),
	(49, 'Reverse curl', false, false, NULL, false, 6, false, 2, 0, '2021-06-21 22:15:42.615137', 1);


--
-- Data for Name: levels; Type: TABLE DATA; Schema: bm; Owner: postgres
--

INSERT INTO bm.levels (id, name) VALUES
	(1, 'beginner'),
	(2, 'medium'),
	(3, 'hard'),
	(4, 'insane'),
	(5, 'sensei');


--
-- Data for Name: sets_and_reps; Type: TABLE DATA; Schema: bm; .
--

INSERT INTO bm.sets_and_reps (id, goal, max_sets, min_sets, max_reps, min_reps) VALUES
	(0, 'strength', 15, 5, 7, 1),
	(1, 'muscle', 12, 3, 15, 7),
	(2, 'endurance', 8, 1, 50, 20),
	(3, 'default', 8, 3, 15, 5);


--
-- Data for Name: workout_exercisegroup; Type: TABLE DATA; Schema: bm; .
--



--
-- Data for Name: workout_sets_and_reps; Type: TABLE DATA; Schema: bm; .
--



--
-- Data for Name: workouts; Type: TABLE DATA; Schema: bm; .
--



--
-- Name: levels_id_seq; Type: SEQUENCE SET; Schema: bm; Owner: postgres
--

SELECT pg_catalog.setval('bm.levels_id_seq', 5, true);


--
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: exercisegroups exercisegroups_pkey; Type: CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.exercisegroups
    ADD CONSTRAINT exercisegroups_pkey PRIMARY KEY (id);


--
-- Name: exercises exercises_pkey; Type: CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.exercises
    ADD CONSTRAINT exercises_pkey PRIMARY KEY (id);


--
-- Name: levels levels_pkey; Type: CONSTRAINT; Schema: bm; Owner: postgres
--

ALTER TABLE ONLY bm.levels
    ADD CONSTRAINT levels_pkey PRIMARY KEY (id);


--
-- Name: sets_and_reps sets_and_reps_pkey; Type: CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.sets_and_reps
    ADD CONSTRAINT sets_and_reps_pkey PRIMARY KEY (id);


--
-- Name: workouts workouts_pkey; Type: CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.workouts
    ADD CONSTRAINT workouts_pkey PRIMARY KEY (id);


--
-- Name: exercise_exercisegroup exercise_exercisegroup_exercise_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.exercise_exercisegroup
    ADD CONSTRAINT exercise_exercisegroup_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES bm.exercises(id);


--
-- Name: exercise_exercisegroup exercise_exercisegroup_exercisegroup_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.exercise_exercisegroup
    ADD CONSTRAINT exercise_exercisegroup_exercisegroup_id_fkey FOREIGN KEY (exercisegroup_id) REFERENCES bm.exercisegroups(id);


--
-- Name: exercises exercises_level_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.exercises
    ADD CONSTRAINT exercises_level_id_fkey FOREIGN KEY (level_id) REFERENCES bm.levels(id);


--
-- Name: workout_exercisegroup workout_exercisegroup_exercisegroup_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.workout_exercisegroup
    ADD CONSTRAINT workout_exercisegroup_exercisegroup_id_fkey FOREIGN KEY (exercisegroup_id) REFERENCES bm.exercisegroups(id);


--
-- Name: workout_exercisegroup workout_exercisegroup_workout_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.workout_exercisegroup
    ADD CONSTRAINT workout_exercisegroup_workout_id_fkey FOREIGN KEY (workout_id) REFERENCES bm.workouts(id);


--
-- Name: workout_sets_and_reps workout_sets_and_reps_workout_id_fkey; Type: FK CONSTRAINT; Schema: bm; .
--

ALTER TABLE ONLY bm.workout_sets_and_reps
    ADD CONSTRAINT workout_sets_and_reps_workout_id_fkey FOREIGN KEY (workout_id) REFERENCES bm.workouts(id);


--
-- PostgreSQL database dump complete
--

