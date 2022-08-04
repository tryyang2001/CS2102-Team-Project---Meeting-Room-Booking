/*add_department*/
DROP PROCEDURE IF EXISTS add_department;

CREATE OR REPLACE PROCEDURE add_department 
(IN dept_ID INT, IN dept_name VARCHAR(50)) 
AS $$
BEGIN
	INSERT INTO Departments VALUES(dept_ID, dept_name);
	RAISE NOTICE 'A new department % with ID % has been created!', dept_name, dept_ID;
END;
$$ LANGUAGE plpgsql;

/*remove_department*/
DROP PROCEDURE IF EXISTS remove_department;

CREATE OR REPLACE PROCEDURE remove_department 
(IN department_id INT)
AS $$
BEGIN
	IF ((SELECT COUNT(*) FROM departments WHERE dept_id = department_id) = 0) THEN
		RAISE EXCEPTION 'Department % does not exist!', department_id;
	ELSE
		DELETE
		FROM departments
		WHERE dept_id = department_id;
		RAISE NOTICE 'Department % has been removed!', department_id;
	END IF;
END;
$$ LANGUAGE plpgsql;

/*add_room*/
DROP PROCEDURE IF EXISTS add_room;

CREATE OR REPLACE PROCEDURE add_room 
	(floor_num int, room_num int, room_name varchar(50), d_id int, m_id int, capacity int)
AS $$
BEGIN
	INSERT INTO meetingrooms VALUES (floor_num, room_num, room_name, d_id);
	RAISE NOTICE 'A room at floor %, room %, belonging to department % has been added.', 
		floor_num, room_num, d_id;

    INSERT INTO updates VALUES (CURRENT_DATE, floor_num, room_num, capacity, m_id);

	RAISE NOTICE 'Capacity of meeting room at floor %, room % has been changed to % on %.',
		floor_num, room_num, capacity, CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;


/*change_capacity*/
DROP PROCEDURE IF EXISTS change_capacity;

CREATE OR REPLACE PROCEDURE change_capacity (IN floor_num INT, IN room_num INT, IN capacity INT, IN date_changed DATE, IN man_id INT)
AS $$
DECLARE
	has_corr_record_for_the_day INT;
BEGIN
	has_corr_record_for_the_day := (SELECT COUNT(*) FROM Updates U 
								WHERE floor_num = U.floor
								AND room_num = U.room
								AND date_changed = U.date);
	IF (has_corr_record_for_the_day = 0) THEN 
	     INSERT INTO Updates VALUES (date_changed, floor_num, room_num, capacity, man_id);
		 RAISE NOTICE 'Maximum capacity for floor % room % has been changed to % on %.', floor_num, room_num, capacity, date_changed;
	ELSE UPDATE Updates U SET max_capacity = capacity, manager_id = man_id
		 WHERE U.floor = floor_num AND U.room = room_num AND U.date = date_changed;
		 RAISE NOTICE 'Maximum capacity for floor % room % has been changed to % on %.', floor_num, room_num, capacity, date_changed;
	END IF;
END
$$ LANGUAGE plpgsql;

/*add_employee*/
DROP PROCEDURE IF EXISTS add_employee;

CREATE OR REPLACE PROCEDURE add_employee
(IN emp_name VARCHAR(50), IN kind CHAR(7), IN dept INT, IN phone VARCHAR(20), IN home VARCHAR(20) DEFAULT NULL, IN office VARCHAR(20) DEFAULT NULL) 
AS $$
DECLARE 
	emp_ID INT;
BEGIN
	INSERT INTO Employees(emp_id, name, phone, home, office, dept_id) VALUES (DEFAULT, emp_name, phone, home, office, dept);
	SELECT CURRVAL('Employees_emp_id_seq') INTO emp_ID;
	IF LOWER(kind) = 'junior' THEN
		INSERT INTO Juniors VALUES (emp_ID);
	ELSIF LOWER(kind) = 'senior' THEN
		INSERT INTO Seniors VALUES (emp_ID);
	ELSIF LOWER(kind) = 'manager' THEN
		INSERT INTO Managers VALUES (emp_ID);
	ELSE 
		RAISE EXCEPTION 'The input % is invalid! The employee must be either junior, senior or manager!', kind;
	END IF;
	RAISE NOTICE 'The employee has been added successfully!';
END
$$ LANGUAGE plpgsql;

/*remove_employee*/
DROP PROCEDURE IF EXISTS remove_employee;

CREATE OR REPLACE PROCEDURE remove_employee 
(IN employee_id INT, IN resign_date DATE)
AS $$
DECLARE
	temp DATE;
BEGIN
	temp := (SELECT resigned_date FROM employees WHERE emp_id = employee_id);
	IF (temp) IS NOT NULL THEN
		RAISE EXCEPTION 'Employee % has already resigned on %.', employee_id, temp;
	ELSE
		UPDATE employees
		SET resigned_date = resign_date
		WHERE emp_id = employee_id;
		RAISE NOTICE 'Employee % has resigned on %.', employee_id, resign_date;
	END IF;
END;
$$ LANGUAGE plpgsql;

/*search_room*/
DROP FUNCTION IF EXISTS search_room;

CREATE OR REPLACE FUNCTION search_room
    (capacity int, search_date date, start_time int, end_time int)
RETURNS TABLE(floor_num int, room_num int, department_id int, room_capacity int)
AS $$
    BEGIN
        RETURN QUERY SELECT m.floor, m.room, m.dept_id, u.max_capacity
        FROM meetingrooms m,
             updates u
        WHERE m.floor = u.floor
          AND m.room = u.room
          AND u.max_capacity >= capacity
        EXCEPT
        SELECT b.floor, b.room, m.dept_id, u.max_capacity
        FROM bookings b,
             meetingrooms m,
             updates u
        WHERE b.date = search_date
          AND b.start_hour >= start_time
          AND b.start_hour < end_time
          AND b.room = u.room
          AND b.floor = u.floor
        ORDER BY max_capacity, floor, room;
    END;
$$ LANGUAGE plpgsql;

/*book_room*/
DROP PROCEDURE IF EXISTS book_room;

CREATE OR REPLACE PROCEDURE book_room (IN floor_num INT, IN room_num INT, IN booking_date DATE, IN booking_start_hour INT, IN booking_end_hour INT, IN emp_id INT)
AS $$
DECLARE
	tempStartHour INT;
BEGIN
	IF (booking_end_hour < 0 OR booking_end_hour > 23) THEN RAISE EXCEPTION 'End hour must be between 0 and 23 (inclusive).'; END IF;
	IF booking_end_hour = 0 THEN booking_end_hour := 24; END IF;
	IF (booking_end_hour <= booking_start_hour) THEN RAISE EXCEPTION 'End hour should be after start hour.';
	ELSEIF (SELECT COUNT(*) FROM Bookings b 
			WHERE b.date = booking_date 
			AND b.floor = floor_num 
			AND b.room = room_num 
			AND b.start_hour BETWEEN booking_start_hour AND (booking_end_hour -1)) > 0 THEN RAISE EXCEPTION 'Booking failed! There is a clash with another booking within this time period.';
	ELSE 
		tempStartHour := booking_start_hour;
		WHILE (tempStartHour <> booking_end_hour) LOOP
			INSERT INTO Bookings VALUES (emp_id, booking_date, tempStartHour, floor_num, room_num, NULL);
			RAISE NOTICE 'A booking has been made for floor % room % on % for hour %.', floor_num, room_num, booking_date, tempStartHour;
			tempStartHour := tempStartHour + 1;
		END LOOP;
	END IF;
END
$$ LANGUAGE plpgsql;


/*unbook_room*/
DROP PROCEDURE IF EXISTS unbook_room;

CREATE OR REPLACE PROCEDURE unbook_room
(IN flr_no INT, room_no INT, booking_date Date, booking_start_hour INT, booking_end_hour INT, eid INT) 
AS $$
DECLARE 
	booker INT;
BEGIN
	IF (booking_date < CURRENT_DATE OR (booking_date = CURRENT_DATE AND booking_start_hour < EXTRACT (HOUR FROM NOW()))) THEN  
		RAISE EXCEPTION 'You cannot unbook meeting that has been passed. Please change the date or start hour!';
	END IF;
	IF ((SELECT COUNT(*) FROM Bookings b
		 WHERE b.floor = flr_no AND b.room = room_no AND b.date = booking_date AND 
		 b.start_hour = booking_start_hour) = 0) THEN
		RAISE EXCEPTION 'The booking with provided details does not exist! Please check and try again!';
	END IF;
	IF booking_end_hour - booking_start_hour <= 0 THEN
		RAISE EXCEPTION 'The provided booking start hour is later than or equal to the end hour! Please check and try again!';
	END IF;
	WHILE booking_end_hour - booking_start_hour > 0 LOOP
		SELECT booker_id INTO booker FROM Bookings b
		WHERE b.floor = flr_no AND b.room = room_no AND b.date = booking_date AND 
		b.start_hour = booking_start_hour;
		IF (booker <> eid) THEN
			RAISE EXCEPTION 'Only the booker can cancel the booking! Employee % is not the booker!', eid;
			EXIT;
		END IF;
		DELETE FROM Bookings b WHERE b.floor = flr_no AND b.room = room_no AND b.date = booking_date AND 
		b.start_hour = booking_start_hour AND booker_id = eid;
		RAISE NOTICE 'Booking on % at start_hour % has been cancelled!', booking_date, booking_start_hour;
		booking_start_hour := booking_start_hour + 1;
	END LOOP;
END
$$ LANGUAGE plpgsql;


/*join_meeting*/
CREATE OR REPLACE PROCEDURE join_meeting (IN floor_number INT, IN room_number INT, IN meeting_date DATE, IN meeting_start_hour INT, IN meeting_end_hour INT, IN employee_id INT)
AS $$
DECLARE
	current_hour INT;
	start_hour_exist INT;
	end_hour_exist INT;
	total_hours INT;
BEGIN
	current_hour := meeting_start_hour;
	
	IF (meeting_end_hour < 0 OR meeting_end_hour >= 24) THEN RAISE EXCEPTION 'End hour must be between 0 and 23 (inclusive).';
	ELSEIF (meeting_end_hour <= meeting_start_hour AND meeting_end_hour <> 0) THEN RAISE EXCEPTION 'End hour should be after start hour.';
	END IF;
	
	IF meeting_end_hour = 0 THEN /*Cater for midnight booking*/
		meeting_end_hour := 24;
	END IF;
	
	start_hour_exist := (SELECT COUNT(*) FROM bookings
					WHERE floor = floor_number
					AND room = room_number
					AND date = meeting_date
					AND start_hour = meeting_start_hour);

	end_hour_exist := (SELECT COUNT(*) FROM bookings
					WHERE floor = floor_number
					AND room = room_number
					AND date = meeting_date
					AND start_hour = meeting_end_hour - 1);

	total_hours := (SELECT COUNT(*) FROM bookings
					WHERE floor = floor_number
					AND room = room_number
					AND date = meeting_date
					AND start_hour BETWEEN meeting_start_hour AND meeting_end_hour - 1);

	IF (start_hour_exist = 0 OR end_hour_exist = 0 or total_hours <> meeting_end_hour - meeting_start_hour) THEN
		RAISE EXCEPTION 'Booking on % at % to % on floor % and room % does not exist.', meeting_date, meeting_start_hour, meeting_end_hour, floor_number, room_number;
	ELSE
		WHILE current_hour < meeting_end_hour LOOP
			INSERT INTO ATTENDS VALUES (employee_id, meeting_date, current_hour, floor_number, room_number);
			current_hour := current_hour + 1;
		END LOOP;
		
		IF meeting_end_hour = 24 THEN /*Cater for midnight booking*/
			meeting_end_hour := 0;
		END IF;
	
		RAISE NOTICE 'Employee % has been added to the meeting on % at floor % and room % from % to %.', employee_id, meeting_date, floor_number, room_number, meeting_start_hour, meeting_end_hour;
	END IF;
END;
$$ LANGUAGE plpgsql;


/*leave_meeting*/
DROP PROCEDURE IF EXISTS leave_meeting;

CREATE OR REPLACE PROCEDURE leave_meeting
    (floor_num int, room_num int, attend_date date, start_time int, end_time int, e_id int)
AS $$
DECLARE
	temp1 INT := 0;
BEGIN
	temp1 := (
        SELECT COUNT(*)
        FROM bookings
        WHERE booker_id = e_id
          AND floor = floor_num
          AND room = room_num
          AND date = attend_date
		  AND start_hour >= start_time
		  AND start_hour < end_time
    );
	
	IF (temp1 <> 0) THEN 
		DELETE FROM bookings
		WHERE booker_id = e_id
          AND floor = floor_num
          AND room = room_num
          AND date = attend_date
		  AND start_hour >= start_time
		  AND start_hour < end_time;
	ELSE
		DELETE FROM attends
		WHERE emp_id = e_id
		  AND floor = floor_num
		  AND room = room_num
		  AND date = attend_date
		  AND start_hour >= start_time
		  AND start_hour < end_time;
		RAISE NOTICE 'Employee % left the meeting held on %, % - %, at floor %, room %.', 
			e_id, attend_date, start_time, end_time, floor_num, room_num;
	END IF;
END;
$$ LANGUAGE plpgsql;


/*approve_meeting*/
DROP PROCEDURE IF EXISTS approve_meeting;

CREATE OR REPLACE PROCEDURE approve_meeting 
(IN floor_num INT, IN room_num INT, IN booking_date DATE, IN start_hour INT, IN end_hour INT, IN emp_id INT)
AS $$
DECLARE
	tempStartHour INT;
BEGIN
	IF (emp_id IS NULL) THEN RAISE EXCEPTION 'Employee id cannot be null!'; END IF;
	IF (start_hour < 0 OR start_hour > 23 OR end_hour < 0 OR end_hour > 23) THEN RAISE EXCEPTION 'Both start and end hour must be between 0 and 23 (inclusive)'; END IF;
	IF end_hour = 0 THEN end_hour := 24; END IF;
	IF (end_hour <= start_hour) THEN RAISE EXCEPTION 'End hour should be after start hour';
	ELSE 
		tempStartHour := start_hour;
		WHILE (tempStartHour <> end_hour) LOOP
			UPDATE Bookings b SET manager_id = emp_id 
				WHERE b.date = booking_date
				AND b.floor = floor_num
				AND b.room = room_num
				AND b.start_hour = tempStartHour;
			IF NOT FOUND THEN RAISE EXCEPTION 'Error! There is no booking for floor % room % on % for hour %. All other bookings in the provided range will not be approved as well. ', floor_num, room_num, booking_date, tempStartHour;
			ELSE tempStartHour := tempStartHour + 1;
			END IF;
		END LOOP;
		IF end_hour = 24 THEN end_hour := 0; END IF;
		RAISE NOTICE 'The booking(s) for floor % room % on % that starts at hour % and ends at hour % has been approved.', floor_num, room_num, booking_date, start_hour, end_hour;
	END IF;
END
$$ LANGUAGE plpgsql;



/*declare_health*/
DROP PROCEDURE IF EXISTS declare_health;

CREATE OR REPLACE PROCEDURE declare_health
(IN emp_ID INT, IN declared_date DATE, IN measured_temp NUMERIC)
AS $$
BEGIN
	INSERT INTO HealthDeclarations(emp_id, date, temperature) Values(emp_ID, declared_date, measured_temp);
	RAISE NOTICE 'Health declaration completed.';
END
$$ LANGUAGE plpgsql;

/*contact_tracing*/
DROP FUNCTION IF EXISTS contact_tracing;

CREATE OR REPLACE FUNCTION contact_tracing (IN employee_id INT)
RETURNS TABLE (id INT) AS $$
DECLARE
	having_fever BOOLEAN;
BEGIN
	having_fever := (SELECT fever FROM healthdeclarations WHERE emp_id = employee_id AND date = CURRENT_DATE);

	IF (having_fever) THEN	
		RETURN QUERY
		WITH MeetingsEmployeeAttendedInPastThreeDays AS (
			SELECT a.date, a.start_hour, a.floor, a.room
			FROM attends a, bookings b
			WHERE a.date = b.date
			AND a.start_hour = b.start_hour
			AND a.floor = b.floor
			AND a.room = b.room
			AND emp_id = employee_id
			AND a.date BETWEEN CURRENT_DATE - 3 AND CURRENT_DATE
			AND b.manager_id IS NOT NULL /* Ensure it was approved */
		),
		EmployeesInCloseContact AS (
			SELECT DISTINCT(emp_id) FROM attends
			WHERE (date, start_hour, floor, room) IN (SELECT * FROM MeetingsEmployeeAttendedInPastThreeDays)
			AND emp_id <> employee_id /* Exclude employee that is having fever*/
		)
		SELECT * FROM EmployeesInCloseContact;
	END IF;
END;
$$ LANGUAGE plpgsql;

/*non_compliance*/
DROP FUNCTION IF EXISTS non_compliance;

CREATE OR REPLACE FUNCTION non_compliance
    (start_date date, end_date date)
RETURNS TABLE(e_id int, number_of_days bigint)
AS $$
    BEGIN
		RETURN QUERY
		SELECT emp_id, COUNT(*)
		FROM (
			SELECT e.emp_id, g.day::date
			FROM  employees e
			CROSS JOIN generate_series(start_date, end_date, interval  '1 day') AS g(day)
			EXCEPT
			SELECT emp_id, date FROM healthdeclarations
		) t1
		GROUP BY t1.emp_id
		ORDER BY COUNT(*) DESC, emp_id ASC;
    END;
$$ LANGUAGE plpgsql;


/*view_booking_report*/
CREATE OR REPLACE FUNCTION view_booking_report 
(IN start_date DATE, IN emp_id INT)
RETURNS TABLE(floor_number INT, room_number INT, date DATE, start_hour INT, is_approved TEXT) AS $$
DECLARE
BEGIN
	RETURN QUERY SELECT b.floor, b.room, b.date, b.start_hour, 
		CASE 
			WHEN b.manager_id IS NULL THEN 'Pending'
			WHEN b.manager_id IS NOT NULL THEN 'Yes' END AS is_approved
	FROM Bookings b
	WHERE b.booker_id = emp_id
	AND b.date >= start_date
	ORDER BY (b.date, b.start_hour) ASC;
	
END
$$ LANGUAGE plpgsql;

/*view_future_meeting*/
DROP FUNCTION IF EXISTS view_future_meeting;

CREATE OR REPLACE FUNCTION view_future_meeting
(IN meeting_start_date DATE, IN eid INT)
RETURNS TABLE (floor_number INT, room_number INT, meeting_date DATE, meeting_start_hour INT)
AS $$
BEGIN
	RETURN QUERY
	SELECT a.floor, a.room, a.date, a.start_hour 
	FROM Attends a, Bookings b
	WHERE a.date >= meeting_start_date AND a.emp_id = eid AND b.floor = a.floor AND b.room = a.room AND 
	b.date = a.date AND b.start_hour = a.start_hour AND b.manager_id IS NOT NULL
	ORDER BY date ASC, start_hour ASC;
END
$$ LANGUAGE plpgsql;


/*view_manager_report*/
DROP FUNCTION IF EXISTS view_manager_report;

CREATE OR REPLACE FUNCTION view_manager_report 
(IN start_date DATE, IN employee_id INT)
RETURNS SETOF bookings AS $$
DECLARE
	is_manager INT;
	department_id INT;
BEGIN
	is_manager := (SELECT COUNT(*) FROM managers WHERE emp_id = employee_id);
	department_id := (SELECT dept_id FROM employees WHERE emp_id = employee_id);
	IF (is_manager = 1) THEN
		RETURN QUERY
		SELECT * FROM bookings b
		WHERE (b.floor, b.room) IN (SELECT r.floor, r.room FROM meetingrooms r WHERE dept_id = department_id)
		AND b.date >= start_date
		AND b.manager_id IS NULL /* Ensure that it is not approved yet */
		ORDER BY b.date, b.start_hour;
	END IF;
END;
$$ LANGUAGE plpgsql;


/* END OF FUNCTIONS & PROCEDURES*/
/* TRIGGERS START HERE*/

/*Ensures manager belongs to the department to approve bookings*/
DROP TRIGGER IF EXISTS prevent_approval_by_incorrect_manager ON Bookings;
DROP FUNCTION IF EXISTS check_approver_is_correct_manager CASCADE;

CREATE OR REPLACE FUNCTION check_approver_is_correct_manager()
RETURNS TRIGGER AS $$
DECLARE
	is_same_dept INT;
BEGIN
	is_same_dept := (SELECT COUNT(*) FROM Employees e, MeetingRooms m
					 WHERE e.emp_id = NEW.manager_id
					 AND m.floor = NEW.floor
					 AND m.room = NEW.room
					 AND e.dept_id = m.dept_id
					);
	IF (is_same_dept <> 1 AND NEW.manager_id IS NOT NULL) THEN
		RAISE EXCEPTION 'Booking for floor % room % on % for hour % cannot be approved as employee % is not a manager of the department that the room belongs to.',
		OLD.floor, OLD.room, OLD.date, OLD.start_hour, NEW.manager_id;
	ELSE
		RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_approval_by_incorrect_manager
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_approver_is_correct_manager();

/*Ensure booker does not have a fever and has declared temperature*/
DROP TRIGGER IF EXISTS c_ensure_booker_not_fever ON Bookings;
DROP FUNCTION IF EXISTS check_booker_has_fever CASCADE;

CREATE OR REPLACE FUNCTION check_booker_has_fever()
RETURNS TRIGGER AS $$
DECLARE
	booker_has_declared_temp INT;
	booker_has_fever INT;
BEGIN
	booker_has_declared_temp := (SELECT COUNT (*) FROM HealthDeclarations h
								 WHERE NEW.booker_id = h.emp_id
								 AND CURRENT_DATE = h.date);
	booker_has_fever := (SELECT COUNT (*) FROM HealthDeclarations h
						 WHERE NEW.booker_id = h.emp_id
						 AND CURRENT_DATE = h.date
						 AND h.fever = TRUE);
	IF (booker_has_declared_temp = 0) THEN RAISE EXCEPTION 'Booking cannot be made as booker has not declared temperature.';
	ELSEIF (booker_has_fever = 1) THEN RAISE EXCEPTION 'Booking cannot be made as booker is having a fever.';
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER c_ensure_booker_not_fever
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_booker_has_fever();

/*Adds a booker to attends*/
DROP TRIGGER IF EXISTS add_booker_to_attends ON Bookings;
DROP FUNCTION IF EXISTS booking_made_add_booker_to_attends;

CREATE OR REPLACE FUNCTION booking_made_add_booker_to_attends()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO Attends VALUES (NEW.booker_id, NEW.date, NEW.start_hour, NEW.floor, NEW.room);
	RAISE NOTICE 'Booker % has been added to the meeting at floor % room % for hour %.', NEW.booker_id, NEW.floor, NEW.room, NEW.start_hour;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_booker_to_attends 
AFTER INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION booking_made_add_booker_to_attends();

/*Ensure booker has not resigned*/
DROP TRIGGER IF EXISTS a_ensure_booker_not_resigned ON Bookings; --name starts with 'a' to make sure this is run first 
DROP FUNCTION IF EXISTS check_booker_has_resigned CASCADE;

CREATE OR REPLACE FUNCTION check_booker_has_resigned()
RETURNS TRIGGER AS $$
DECLARE
	booker_has_resigned INT;
BEGIN
	booker_has_resigned := (SELECT COUNT (*) FROM Employees e
							WHERE NEW.booker_id = e.emp_id
							AND e.resigned_date IS NOT NULL);
	IF (booker_has_resigned = 1) THEN RAISE EXCEPTION 'Booking cannot be made as booker % has resigned.', NEW.booker_id;
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER a_ensure_booker_not_resigned
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_booker_has_resigned();

/*Ensure booking date is >= today*/
DROP TRIGGER IF EXISTS b_ensure_booking_date_is_not_in_past ON Bookings;
DROP FUNCTION IF EXISTS check_date_is_in_past CASCADE;

CREATE OR REPLACE FUNCTION check_date_is_in_past()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.date < CURRENT_DATE OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= extract(hour from now()))) THEN RAISE EXCEPTION 'Booking cannot be made as the booking date % has already passed.', NEW.date;
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER b_ensure_booking_date_is_not_in_past
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_date_is_in_past();

/*Ensure booking approver has not resigned*/
DROP TRIGGER IF EXISTS a_ensure_approver_not_resigned ON Bookings;
DROP FUNCTION IF EXISTS check_approver_has_resigned CASCADE;

CREATE OR REPLACE FUNCTION check_approver_has_resigned()
RETURNS TRIGGER AS $$
DECLARE
	approver_has_resigned INT;
BEGIN
	approver_has_resigned := (SELECT COUNT (*) FROM Employees e
							WHERE NEW.manager_id = e.emp_id
							AND e.resigned_date IS NOT NULL);
	IF (approver_has_resigned = 1) THEN RAISE EXCEPTION 'Booking for floor % room % on % for hour % 
		cannot be approved as employee % has already resigned.',
		OLD.floor, OLD.room, OLD.date, OLD.start_hour, NEW.manager_id;
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER a_ensure_approver_not_resigned
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_approver_has_resigned();

/*Ensure that meeting approved cannot have a change in participants*/
DROP TRIGGER IF EXISTS b_ensure_meeting_not_already_approved ON Bookings;
DROP FUNCTION IF EXISTS check_meeting_already_approved CASCADE;

CREATE OR REPLACE FUNCTION check_meeting_already_approved()
RETURNS TRIGGER AS $$
BEGIN
	IF (OLD.manager_id IS NOT NULL AND NEW.manager_id IS NOT NULL) THEN RAISE EXCEPTION 'Booking for floor % room % on % for hour % 
		cannot be updated as it has already been approved by manager %!',
		OLD.floor, OLD.room, OLD.date, OLD.start_hour, OLD.manager_id;
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER b_ensure_meeting_not_already_approved
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_meeting_already_approved();

/*Helps to ensure meetings/bookings in the past cannot get deleted.*/
DROP TRIGGER IF EXISTS cannot_unbook_booking_in_the_past ON Bookings;
DROP FUNCTION IF EXISTS check_unbook_date_not_passed();

CREATE OR REPLACE FUNCTION check_unbook_date_not_passed()
RETURNS TRIGGER AS $$
BEGIN
	IF (OLD.date < CURRENT_DATE OR (OLD.date = CURRENT_DATE AND OLD.start_hour < EXTRACT (HOUR FROM NOW()))) THEN  
		RAISE EXCEPTION 'You cannot unbook meeting that has been passed. Please change the date or start hour!';
	END IF;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cannot_unbook_booking_in_the_past
BEFORE DELETE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_unbook_date_not_passed();

/*Ensure attends does not exceed room capacity*/
DROP TRIGGER IF EXISTS prevent_exceed_of_max_capacity ON attends;
DROP FUNCTION IF EXISTS check_within_max_capacity();

CREATE OR REPLACE FUNCTION check_within_max_capacity()
RETURNS TRIGGER AS $$
DECLARE
	room_capacity INT;
	current_capacity INT;
BEGIN
	room_capacity := (SELECT max_capacity
					 FROM updates
					 WHERE floor = NEW.floor
					 AND room = NEW.room
					 AND date < NEW.DATE
					 ORDER BY date DESC LIMIT 1);
	current_capacity := (SELECT count(*) FROM Attends
						WHERE date = NEW.date
						AND start_hour = NEW.start_hour
						AND floor = NEW.floor
						AND room = NEW.room);
	IF (current_capacity >= room_capacity) THEN
		RAISE EXCEPTION 'The meeting room capacity is % and there are already % employees attending!', room_capacity, current_capacity;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_exceed_of_max_capacity
BEFORE INSERT OR UPDATE ON attends
FOR EACH ROW EXECUTE FUNCTION check_within_max_capacity();

/*Ensure employee attending booking has declared his temperature and does not have a fever*/
DROP TRIGGER IF EXISTS prevent_attends_during_fever ON attends;
DROP FUNCTION IF EXISTS check_employee_having_fever;

CREATE OR REPLACE FUNCTION check_employee_having_fever()
RETURNS TRIGGER AS $$
DECLARE
	having_fever BOOLEAN;
BEGIN
	having_fever := (SELECT fever FROM healthdeclarations WHERE emp_id = NEW.emp_id AND date = CURRENT_DATE);
	IF (having_fever) THEN
		RAISE EXCEPTION 'Employee % is having a fever and cannot join the meeting!', NEW.emp_id;
	ELSIF (having_fever IS NULL) THEN
		RAISE EXCEPTION 'Employee % has not declared his temperature today and cannot join the meeting!', NEW.emp_id;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_attends_during_fever
BEFORE INSERT ON attends
FOR EACH ROW EXECUTE FUNCTION check_employee_having_fever();

/*Prevent insert/update of attendees once booking is approved*/
DROP TRIGGER IF EXISTS prevent_update_if_approved ON attends;
DROP FUNCTION IF EXISTS check_booking_approved;

CREATE OR REPLACE FUNCTION check_booking_approved()
RETURNS TRIGGER AS $$
DECLARE
	booking_exist INT;
	booking_not_approved INT;
BEGIN
	booking_exist := (SELECT COUNT(*) FROM bookings
							 WHERE date = NEW.date
							 AND floor = NEW.floor
					  		 AND room = NEW.room
							 AND start_hour = NEW.start_hour);
	booking_not_approved := (SELECT COUNT(*) FROM bookings
							 WHERE date = NEW.date
							 AND floor = NEW.floor
							 AND room = NEW.room
							 AND start_hour = NEW.start_hour
							 AND manager_id IS NULL);
	IF (booking_exist = 0)  THEN
		RAISE EXCEPTION 'Booking does not exist!';
	ELSIF (booking_not_approved = 0) THEN
		RAISE EXCEPTION 'Booking is already approved!';
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_update_if_approved
BEFORE INSERT ON attends
FOR EACH ROW EXECUTE FUNCTION check_booking_approved();


/*Ensures that participants cannot leave an approved meeting*/
DROP TRIGGER IF EXISTS check_leave ON attends;
DROP FUNCTION IF EXISTS check_leave_meeting;

CREATE OR REPLACE FUNCTION check_leave_meeting()
RETURNS TRIGGER
AS $$
DECLARE
    temp2 int := 0;
	room_capacity int;
	current_capacity int;
BEGIN
    temp2 := (
        SELECT manager_id
        FROM bookings
        WHERE floor = OLD.floor
          AND room = OLD.room
          AND date = OLD.date
          AND start_hour = OLD.start_hour
    );
	IF (temp2 IS NOT null) THEN RAISE EXCEPTION 'Participants are not allowed to leave an approved meeting.';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_leave
BEFORE DELETE ON attends
FOR EACH ROW EXECUTE FUNCTION check_leave_meeting();

/*Ensures that an employee cannot attend more than 1 meeting at each time*/
DROP TRIGGER IF EXISTS prevent_insert_and_update_if_conflict ON attends;
DROP FUNCTION IF EXISTS check_meeting_conflict;

CREATE OR REPLACE FUNCTION check_meeting_conflict()
RETURNS TRIGGER AS $$
DECLARE
	added_to_current_meeting INT;
	has_another_meeting INT;
BEGIN
	added_to_current_meeting := (SELECT COUNT(*) FROM attends
							WHERE emp_id = NEW.emp_id
							AND date = NEW.date
							AND start_hour = NEW.start_hour
							AND room = NEW.room
							AND floor = NEW.floor);
	has_another_meeting := (SELECT COUNT(*) FROM attends
							WHERE emp_id = NEW.emp_id
							AND date = NEW.date
							AND start_hour = NEW.start_hour);
	IF (added_to_current_meeting <> 0) THEN
		RAISE EXCEPTION 'Employee % is already in the meeting on % at %.', NEW.emp_id, NEW.date, NEW.start_hour;
	ELSIF (has_another_meeting <> 0) THEN
		RAISE EXCEPTION 'Employee % has another meeting on % at %.', NEW.emp_id, NEW.date, NEW.start_hour;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_insert_and_update_if_conflict
BEFORE INSERT OR UPDATE ON attends
FOR EACH ROW EXECUTE FUNCTION check_meeting_conflict();

/*Prevents a resigned employee from joining the meeting*/
DROP TRIGGER IF EXISTS a_prevent_insert_and_update_if_resigned ON attends;
DROP FUNCTION IF EXISTS check_resigned();

CREATE OR REPLACE FUNCTION check_resigned()
RETURNS TRIGGER AS $$
DECLARE
	employee_resigned_date DATE;
BEGIN
	employee_resigned_date := (SELECT resigned_date FROM employees WHERE emp_id = NEW.emp_id);
	IF (employee_resigned_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has already resigned and cannot be added to the booking.', NEW.emp_id;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER a_prevent_insert_and_update_if_resigned
BEFORE INSERT OR UPDATE ON attends
FOR EACH ROW EXECUTE FUNCTION check_resigned();

/*Ensure only manager from the same department can change room capacity*/	
DROP TRIGGER IF EXISTS prevent_capacity_change_by_incorrect_manager ON Updates;
DROP FUNCTION IF EXISTS check_capacity_changed_by_correct_manager;

CREATE OR REPLACE FUNCTION check_capacity_changed_by_correct_manager()
RETURNS TRIGGER AS $$
DECLARE 
	is_same_dept INT;
BEGIN
	is_same_dept := (SELECT COUNT(*) FROM Employees e, MeetingRooms m
					 WHERE e.emp_id = NEW.manager_id
					 AND m.floor = NEW.floor   
					 AND m.room = NEW.room
					 AND e.dept_id = m.dept_id
					);
	IF (is_same_dept <> 1) THEN            
		RAISE EXCEPTION 'Maximum capacity cannot be changed as employee % is not a manager of the department that floor % room % belongs to.',
			NEW.manager_id, NEW.floor, NEW.room;
	ELSE                                                                              
		RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_capacity_change_by_incorrect_manager
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_capacity_changed_by_correct_manager();


/*Deletes booking exceeding max capacity*/
DROP TRIGGER IF EXISTS remove_future_bookings_exceeding_capacity ON Updates;
DROP FUNCTION IF EXISTS capacity_changed_remove_bookings_exceeding_capacity;

CREATE OR REPLACE FUNCTION capacity_changed_remove_bookings_exceeding_capacity()
RETURNS TRIGGER AS $$
DECLARE 
	effective_start_date DATE; 
	effective_end_date DATE;
	_result INT;
BEGIN
	effective_start_date := NEW.date + 1;
	effective_end_date := (SELECT date FROM Updates WHERE date > effective_start_date
							 AND max_capacity > NEW.max_capacity
							 ORDER BY date ASC
							 LIMIT 1);
	IF effective_end_date IS NOT NULL THEN
		UPDATE Bookings b
	    SET manager_id = NULL
	    WHERE b.floor = NEW.floor
	    AND b.room = NEW.room
	    AND b.date BETWEEN effective_start_date AND effective_end_date
	    AND (SELECT COUNT(*) FROM attends a2 
			 WHERE a2.floor=b.floor AND a2.room=b.room AND a2.date = b.date AND a2.start_hour = b.start_hour
			 GROUP BY (a2.floor, a2.room, a2.date, a2.start_hour)) > NEW.max_capacity;
		DELETE FROM Bookings b
	    WHERE b.floor = NEW.floor
	    AND b.room = NEW.room
	    AND b.date BETWEEN effective_start_date AND effective_end_date
	    AND (SELECT COUNT(*) FROM attends a2 
			 WHERE a2.floor=b.floor AND a2.room=b.room AND a2.date = b.date AND a2.start_hour = b.start_hour
			 GROUP BY (a2.floor, a2.room, a2.date, a2.start_hour)) > NEW.max_capacity;
		GET DIAGNOSTICS _result = ROW_COUNT;
		RAISE NOTICE '% bookings have been deleted for floor % room % because they exceed the maximum capacity of %.', 
		_result, NEW.floor, NEW.room, NEW.max_capacity;
		RETURN NEW;
	ELSE
		UPDATE Bookings b
	    SET manager_id = NULL
	    WHERE b.floor = NEW.floor
	    AND b.room = NEW.room
	    AND b.date >= effective_start_date 
	    AND (SELECT COUNT(*) FROM attends a2 
			 WHERE a2.floor=b.floor AND a2.room=b.room AND a2.date = b.date AND a2.start_hour = b.start_hour
			 GROUP BY (a2.floor, a2.room, a2.date, a2.start_hour)) > NEW.max_capacity;
		DELETE FROM Bookings b
	    WHERE b.floor = NEW.floor
	    AND b.room = NEW.room
	    AND b.date >= effective_start_date
	    AND (SELECT COUNT(*) FROM attends a2 
			 WHERE a2.floor=b.floor AND a2.room=b.room AND a2.date = b.date AND a2.start_hour = b.start_hour
			 GROUP BY (a2.floor, a2.room, a2.date, a2.start_hour)) > NEW.max_capacity;
			 		GET DIAGNOSTICS _result = ROW_COUNT;
		RAISE NOTICE '% bookings have been deleted for floor % room % because they exceed the maximum capacity of %.', 
		_result, NEW.floor, NEW.room, NEW.max_capacity;
		RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER remove_future_bookings_exceeding_capacity
AFTER INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION capacity_changed_remove_bookings_exceeding_capacity();


/*Ensure manager updating capacity is not resigned*/
DROP TRIGGER IF EXISTS a_ensure_manager_changing_capacity_not_resigned ON Updates;
DROP FUNCTION IF EXISTS check_manager_has_resigned();

CREATE OR REPLACE FUNCTION check_manager_has_resigned()
RETURNS TRIGGER AS $$               
DECLARE
	manager_has_resigned INT;
BEGIN
	manager_has_resigned := (SELECT COUNT (*) FROM Employees e
							WHERE NEW.manager_id = e.emp_id
							AND e.resigned_date IS NOT NULL);
	IF (manager_has_resigned = 1) THEN RAISE EXCEPTION 'Capacity for floor % room % for % onwards
		cannot be changed by employee %, who has already resigned.',
		NEW.floor, NEW.room, NEW.date, NEW.manager_id;
	ELSE RETURN NEW;
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER a_ensure_manager_changing_capacity_not_resigned
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_manager_has_resigned();

/*Blocks delete on updates table*/
DROP TRIGGER IF EXISTS prevent_updates_table_delete ON Updates;
DROP FUNCTION IF EXISTS prevent_delete();

CREATE OR REPLACE FUNCTION prevent_delete()
RETURNS TRIGGER AS $$
BEGIN
	RAISE EXCEPTION 'Sorry! We do not allow deletes on this table.';
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_updates_table_delete
BEFORE DELETE ON Updates
FOR EACH ROW EXECUTE FUNCTION prevent_delete();

/*Ensures that every meeting room added has a capacity specified in updates*/
DROP TRIGGER IF EXISTS check_if_room_exists_in_updates ON meetingrooms;
DROP FUNCTION IF EXISTS check_insert_on_meetingrooms();

CREATE OR REPLACE FUNCTION check_insert_on_meetingrooms()
RETURNS TRIGGER
AS $$
DECLARE
    temp1 int := 0;
BEGIN
    temp1 := (
        SELECT COUNT(*)
        FROM updates
        WHERE floor = new.floor
          AND room = new.room
     );

    IF (temp1 <> 1) THEN RAISE EXCEPTION 'Adding room meeting failed. Use the procedure add_room to add a room.';
    END IF;

    RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_if_room_exists_in_updates
AFTER INSERT ON meetingrooms
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_insert_on_meetingrooms();

/*Removes employee meetings once they resigned*/
DROP TRIGGER IF EXISTS remove_future_meetings ON employees;
DROP FUNCTION IF EXISTS employee_resigned_remove_meetings;

CREATE OR REPLACE FUNCTION employee_resigned_remove_meetings()
RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM bookings WHERE booker_id = NEW.emp_id AND date >= NEW.resigned_date AND start_hour > extract(hour from now());
	DELETE FROM attends WHERE emp_id = NEW.emp_id AND date >= NEW.resigned_date AND start_hour > extract(hour from now());
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER remove_future_meetings
BEFORE UPDATE OF resigned_date ON employees
FOR EACH ROW EXECUTE FUNCTION employee_resigned_remove_meetings();

/*Auto generates employee ID and email*/
DROP TRIGGER IF EXISTS auto_generate_emp_id_and_email ON Employees;
DROP FUNCTION IF EXISTS generate_emp_id_and_email();

CREATE OR REPLACE FUNCTION generate_emp_id_and_email()
RETURNS TRIGGER AS $$
DECLARE 
	emp_name VARCHAR(50);
BEGIN 
	emp_name := LOWER(replace(NEW.name, ' ', '')); --remove white space when generating email
	NEW.email := emp_name || NEW.emp_id || '@company.com';
	RAISE NOTICE 'The id of the employee has been auto-generated: %', NEW.emp_id;
	RAISE NOTICE 'The email of the employee has been auto-generated: %', NEW.email;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_generate_emp_id_and_email
BEFORE INSERT ON Employees
FOR EACH ROW EXECUTE FUNCTION generate_emp_id_and_email();

/*Ensures that an employee is assigned to either junior/senior/manager*/
DROP TRIGGER IF EXISTS employee_kind_specified ON Employees;
DROP FUNCTION IF EXISTS check_emp_id_in_juniors_seniors_managers();

CREATE OR REPLACE FUNCTION check_emp_id_in_juniors_seniors_managers()
RETURNS TRIGGER AS $$
BEGIN 
	IF (SELECT COUNT(*) FROM Juniors WHERE emp_id = NEW.emp_id) = 0 THEN
		IF (SELECT COUNT(*) FROM Bookers WHERE emp_id = NEW.emp_id) = 0 THEN
			RAISE EXCEPTION 'You cannot register an employee that is not junior, senior and manager!';
		END IF;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER employee_kind_specified
AFTER INSERT ON Employees DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_emp_id_in_juniors_seniors_managers();

/*Ensures that employee resign date is <= today*/
DROP TRIGGER IF EXISTS check_resign_date ON employees;
DROP FUNCTION IF EXISTS employee_resigned_check_date();

CREATE OR REPLACE FUNCTION employee_resigned_check_date()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.resigned_date > CURRENT_DATE) THEN
		RAISE EXCEPTION 'Resign date cannot be greater than today!';
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_resign_date
BEFORE UPDATE OF resigned_date ON employees
FOR EACH ROW EXECUTE FUNCTION employee_resigned_check_date();

/*Prevents deletion of employee and sets resigned date instead*/
DROP TRIGGER IF EXISTS prevent_delete_on_employees ON employees;
DROP FUNCTION IF EXISTS set_resign_date();

CREATE OR REPLACE FUNCTION set_resign_date()
RETURNS TRIGGER AS $$
BEGIN
	RAISE NOTICE 'You cannot delete an employee. Employee % has been set to resign on %.', OLD.emp_id, CURRENT_DATE;
	UPDATE employees SET resigned_date = CURRENT_DATE WHERE emp_id = OLD.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_delete_on_employees
BEFORE DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION set_resign_date();

/*Prevents direct insert emp_id into Employees table*/
DROP TRIGGER IF EXISTS a_prevent_direct_insert_into_employees ON Employees;
DROP FUNCTION IF EXISTS prevent_direct_insert_into_employees();
CREATE OR REPLACE FUNCTION prevent_direct_insert_into_employees() 
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.emp_id <> (SELECT CURRVAL('Employees_emp_id_seq')) THEN
		RAISE EXCEPTION 'The id of the employee is auto-generated by the system, you should not create a new id!';
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER a_prevent_direct_insert_into_employees
BEFORE INSERT ON Employees
FOR EACH ROW EXECUTE FUNCTION prevent_direct_insert_into_employees();

/*Prevents update of emp_id or email*/
DROP TRIGGER IF EXISTS check_update_on_employees ON Employees;
DROP FUNCTION IF EXISTS prevent_update_emp_id_and_email();

CREATE OR REPLACE FUNCTION prevent_update_emp_id_and_email()
RETURNS TRIGGER AS $$
BEGIN 
	IF NEW.emp_id <> OLD.emp_id THEN
		RAISE NOTICE 'The employee id should not be changed as it is auto-generated by system, hence the emp_id remains as %', OLD.emp_id;
		NEW.emp_id = OLD.emp_id;
	ELSIF NEW.email <> OLD.email THEN
		RAISE NOTICE 'The employee email should not be changed as it is auto-generated by system, hence the email remains as %', OLD.email;
		NEW.email = OLD.email;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_update_on_employees
BEFORE UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION prevent_update_emp_id_and_email();

/*Helps to ensure that the employee id is only in Junior*/
DROP TRIGGER IF EXISTS add_or_change_junior ON Juniors;
DROP FUNCTION IF EXISTS ensure_emp_id_only_in_juniors();

CREATE OR REPLACE FUNCTION ensure_emp_id_only_in_juniors() 
RETURNS TRIGGER AS $$
BEGIN 
	DELETE FROM Bookers WHERE emp_id = NEW.emp_id;
	RAISE NOTICE 'The employee % has successfully changed to junior!', NEW.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_or_change_junior
AFTER INSERT OR UPDATE ON Juniors
FOR EACH ROW EXECUTE PROCEDURE ensure_emp_id_only_in_juniors();

/*Ensure that an employee cannot be deleted from Juniors without being a Manager or Senior*/
DROP TRIGGER IF EXISTS delete_junior ON Juniors;
DROP FUNCTION IF EXISTS ensure_emp_id_in_bookers();

CREATE OR REPLACE FUNCTION ensure_emp_id_in_bookers()
RETURNS TRIGGER AS $$
BEGIN 
	IF (SELECT COUNT(*) FROM Bookers WHERE emp_id = OLD.emp_id) = 1 THEN
		RAISE NOTICE 'Successfully changed! Employee % is no longer a junior!', OLD.emp_id;
		RETURN OLD;
	END IF;
	RAISE NOTICE 'You are not supposed to remove junior with id %, as he/she has not yet been assigned a new role', OLD.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_junior
BEFORE DELETE ON Juniors
FOR EACH ROW EXECUTE FUNCTION ensure_emp_id_in_bookers();

/*Helps to delete the employee from Juniors when he is inserted into Seniors or Managers*/
DROP TRIGGER IF EXISTS add_or_change_bookers ON Bookers;
DROP FUNCTION IF EXISTS ensure_emp_id_not_in_juniors();

CREATE OR REPLACE FUNCTION ensure_emp_id_not_in_juniors()
RETURNS TRIGGER AS $$
BEGIN 
	IF (SELECT COUNT(*) FROM Seniors WHERE emp_id = NEW.emp_id) = 1 THEN
		RAISE NOTICE 'The new senior with id % now has the authority to make a booking in the same department!', NEW.emp_id;
	ELSIF (SELECT COUNT(*) FROM Managers WHERE emp_id = NEW.emp_id) = 1 THEN
		RAISE NOTICE 'The new manager with id % now has the authority to make a booking in the same department!', NEW.emp_id;
	ELSE
		RAISE EXCEPTION 'You are not supposed to remove junior with id %, as he/she has not yet been assigned a new role', NEW.emp_id;
	END IF;
	DELETE FROM Juniors WHERE emp_id = NEW.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_or_change_bookers
AFTER INSERT OR UPDATE ON Bookers
FOR EACH ROW EXECUTE FUNCTION ensure_emp_id_not_in_juniors();

/*Helps to faciliate the change from a Junior or Senior to Manager*/
DROP TRIGGER IF EXISTS add_or_change_manager ON Managers;
DROP FUNCTION IF EXISTS ensure_emp_id_not_in_juniors_and_seniors();

CREATE OR REPLACE FUNCTION ensure_emp_id_not_in_juniors_and_seniors()
RETURNS TRIGGER AS $$
BEGIN 
	DELETE FROM Seniors WHERE emp_id = NEW.emp_id;
	IF (SELECT COUNT(*) FROM Bookers WHERE emp_id = NEW.emp_id) = 0 THEN
		INSERT INTO Bookers VALUES (NEW.emp_id);
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_or_change_manager
AFTER INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION ensure_emp_id_not_in_juniors_and_seniors();

/*Ensures that a Manager must be assigned a new role before deletion*/
DROP TRIGGER IF EXISTS delete_manager ON Managers;
DROP FUNCTION IF EXISTS ensure_emp_id_in_juniors_or_seniors();

CREATE OR REPLACE FUNCTION ensure_emp_id_in_juniors_or_seniors()
RETURNS TRIGGER AS $$
BEGIN 
	IF (SELECT COUNT(*) FROM Juniors WHERE emp_id = OLD.emp_id) = 1 THEN
		RAISE NOTICE 'Successfully changed! Employee % is no longer a manager!', OLD.emp_id;
		RETURN OLD;
	ELSIF (SELECT COUNT(*) FROM Seniors WHERE emp_id = OLD.emp_id) = 1 THEN
		RAISE NOTICE 'Successfully changed! Employee % is no longer a manager!', OLD.emp_id;
		RETURN OLD;
	END IF;
	RAISE NOTICE 'You are not supposed to remove manager with id %, as he/she has not yet been assigned a new role', OLD.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_manager
BEFORE DELETE ON Managers
FOR EACH ROW EXECUTE FUNCTION ensure_emp_id_in_juniors_or_seniors();


/*Ensures that a Senior will be inserted into Bookers*/
DROP TRIGGER IF EXISTS add_or_change_senior ON Seniors;
DROP FUNCTION IF EXISTS check_senior_in_managers();

CREATE OR REPLACE FUNCTION check_senior_in_managers()
RETURNS TRIGGER AS $$
BEGIN 
	DELETE FROM Managers WHERE emp_id = NEW.emp_id;
	IF (SELECT COUNT(*) FROM Seniors WHERE emp_id = NEW.emp_id) = 1 THEN
		IF (SELECT COUNT(*) FROM Bookers WHERE emp_id = NEW.emp_id) = 0 THEN
			INSERT INTO Bookers VALUES (NEW.emp_id);
		END IF;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_or_change_senior
AFTER INSERT OR UPDATE ON Seniors
FOR EACH ROW EXECUTE PROCEDURE check_senior_in_managers();

/*Ensure that if a Senior was removed, the employee is transferred to Junior or Manager*/
DROP TRIGGER IF EXISTS delete_senior ON Seniors;
DROP FUNCTION IF EXISTS ensure_emp_id_in_juniors_or_managers();

CREATE OR REPLACE FUNCTION ensure_emp_id_in_juniors_or_managers()
RETURNS TRIGGER AS $$
BEGIN 
	IF (SELECT COUNT(*) FROM Juniors WHERE emp_id = OLD.emp_id) = 1 THEN
		RAISE NOTICE 'Successfully removed! Employee % is no longer a senior!', OLD.emp_id;
		RETURN OLD;
	ELSIF (SELECT COUNT(*) FROM Managers WHERE emp_id = OLD.emp_id) = 1 THEN
		RAISE NOTICE 'Successfully removed! Employee % is no longer a senior!', OLD.emp_id;
		RETURN OLD;
	END IF;
	RAISE NOTICE 'You are not supposed to remove senior with id %, as he/she has not yet been assigned a new role', OLD.emp_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_senior
BEFORE DELETE ON Seniors
FOR EACH ROW EXECUTE FUNCTION ensure_emp_id_in_juniors_or_managers();

/*Helps to ensure temperature > 37.5 will have fever = true*/
DROP TRIGGER IF EXISTS fever_checking ON HealthDeclarations;
DROP FUNCTION IF EXISTS check_fever();

CREATE OR REPLACE FUNCTION check_fever()
RETURNS TRIGGER AS $$
BEGIN 
	NEW.fever := TRUE;
	RAISE NOTICE 'Alert! The employee with id % is having fever!', NEW.emp_id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fever_checking
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW WHEN (NEW.temperature > 37.5) EXECUTE FUNCTION check_fever();

/*Helps to ensure employee that has resigned cannot declare temperature*/
DROP TRIGGER IF EXISTS emp_resigned_cannot_declare_health ON HealthDeclarations;
DROP FUNCTION IF EXISTS check_emp_resign_status_and_date_validity();

CREATE OR REPLACE FUNCTION check_emp_resign_status_and_date_validity()
RETURNS TRIGGER AS $$
BEGIN
	IF (SELECT resigned_date FROM Employees WHERE emp_id = NEW.emp_id) IS NOT NULL THEN
		RAISE EXCEPTION 'The employee with id % has resigned, thus cannot declare health at here anymore!', NEW.emp_id;
		RETURN NULL;
	ELSIF NEW.date <> CURRENT_DATE THEN 
		RAISE EXCEPTION 'You are only allowed to declare temperature for today!';
		RETURN NULL;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER emp_resigned_cannot_declare_health
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION check_emp_resign_status_and_date_validity();

/*Perform contacting tracing and helps to ensure that employees will be removed from meetings*/
DROP TRIGGER IF EXISTS perform_contact_tracing ON healthdeclarations;
DROP FUNCTION IF EXISTS trigger_contact_tracing();

CREATE OR REPLACE FUNCTION trigger_contact_tracing()
RETURNS TRIGGER AS $$
BEGIN	
	/*Remove approval from meetings*/
	UPDATE bookings
	SET manager_id = NULL
	WHERE (booker_id IN (SELECT * FROM contact_tracing(NEW.emp_id))
		   OR booker_id = NEW.emp_id) /*Need to include current employee having fever*/
	AND (date = CURRENT_DATE AND start_hour > extract(hour from now()))
	OR (date > CURRENT_DATE	AND date <= CURRENT_DATE + 7);
	
	/* Remove employees from meetings in the next 7 days */
	DELETE FROM attends
	WHERE emp_id IN (SELECT * FROM contact_tracing(NEW.emp_id))
	AND ((date = CURRENT_DATE AND start_hour > extract(hour from now()))
	OR (date > CURRENT_DATE	AND date <= CURRENT_DATE + 7));
	
	/* Remove bookers in the next 7 days */
	DELETE FROM bookings
	WHERE booker_id IN (SELECT * FROM contact_tracing(NEW.emp_id))
	AND ((date = CURRENT_DATE AND start_hour > extract(hour from now()))
	OR (date > CURRENT_DATE	AND date <= CURRENT_DATE + 7));

	/* Remove employee with fever from all future meetings */
	DELETE FROM attends
	WHERE emp_id = NEW.emp_id
	AND ((date = CURRENT_DATE AND start_hour > extract(hour from now()))
	OR date > CURRENT_DATE);
	
	/* Delete meetings that employee with fever booked */
	DELETE FROM bookings
	WHERE booker_id = NEW.emp_id
	AND ((date = CURRENT_DATE AND start_hour > extract(hour from now()))
	OR date > CURRENT_DATE);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER perform_contact_tracing
AFTER INSERT OR UPDATE ON healthdeclarations
FOR EACH ROW WHEN (NEW.fever = true) EXECUTE FUNCTION trigger_contact_tracing();
