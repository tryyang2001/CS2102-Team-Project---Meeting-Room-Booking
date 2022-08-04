/**
 * add_department(dept_id ID, dept_name VARCHAR(50))
 */
SELECT * FROM Departments;
CALL add_department(100, 'TESTING');
CALL add_department(100, 'Test');




/**
 * remove_department(dept_id INT)
 */
select * from departments;
CALL remove_department(10);
/*Invalid department*/
CALL remove_department(11);





/**
 * add_room(floor_no INT, room_no INT, room_name VARCHAR(50), dept_id INT, manager_id INT, room_capacity INT)
 */
 SELECT * FROM Employees
/*duplicate room*/
call add_room(2,1,'example1',1,1,5);
/*not manager cannot add room*/
call add_room(20,1,'example1',1,1,5);
/*manager not from the same department as room*/
call add_room(20,1,'example1',1,31,5);
/*prevent insert on meetingrooms*/
insert into meetingrooms values(20,1,'example1',1);
/*add room successfully*/
call add_room(20,1,'example1',1,37,5);
/*manager that is resigned cannot add room*/
call remove_employee(37,CURRENT_DATE);
call add_room(20,2,'example1',1,37,5);





/**
 * change_capacity(IN floor_num INT, IN room_num INT, IN capacity INT, IN date_changed DATE, IN man_id INT) 
 */
-- Test 1: Not a manager. Expected: Not a manager, cannot change. --
CALL change_capacity(3, 2, 5, '2021-10-25', 5);

-- Test 2: Resigned manager. Expected: Resigned, cannot change. --
CALL change_capacity(3, 2, 5, '2021-10-25', 42);

-- Test 3: Not the correct manager. Expected: Not the correct manager, cannot change.--
CALL change_capacity(3, 2, 5, '2021-10-25', 32);

-- Test 4: Change capacity on D5 to 5. Any bookings with capacity > 5 from D6 onwards to be cancelled, every participant
-- to be removed. --
CALL change_capacity(3, 2, 10, CURRENT_DATE, 38); --D0 capacity: 10
CALL declare_health (38, CURRENT_DATE, '36'); --replace with today's date..
CALL declare_health (1, CURRENT_DATE, '36');
CALL declare_health (2, CURRENT_DATE, '36');
CALL declare_health (3, CURRENT_DATE, '36');
CALL declare_health (4, CURRENT_DATE, '36');
CALL declare_health (5, CURRENT_DATE, '36');
--Book 6 participants for D2 
CALL book_room (3, 2, CURRENT_DATE+2, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+2, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+2, 3, 6, 2);
CALL join_meeting (3, 2, CURRENT_DATE+2, 3, 6, 3);
CALL join_meeting (3, 2, CURRENT_DATE+2, 3, 6, 4);
CALL join_meeting (3, 2, CURRENT_DATE+2, 3, 6, 5);
--Book 6 participants for D4 
CALL book_room (3, 2, CURRENT_DATE+4, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+4, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+4, 3, 6, 2);
CALL join_meeting (3, 2, CURRENT_DATE+4, 3, 6, 3);
CALL join_meeting (3, 2, CURRENT_DATE+4, 3, 6, 4);
CALL join_meeting (3, 2, CURRENT_DATE+4, 3, 6, 5);
--Book 6 participants for D5 
CALL book_room (3, 2, CURRENT_DATE+5, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+5, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+5, 3, 6, 2);
CALL join_meeting (3, 2, CURRENT_DATE+5, 3, 6, 3);
CALL join_meeting (3, 2, CURRENT_DATE+5, 3, 6, 4);
CALL join_meeting (3, 2, CURRENT_DATE+5, 3, 6, 5);
--Book 6 participants for D6 
CALL book_room (3, 2, CURRENT_DATE+6, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 2);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 3);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 4);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 5);
--Book 5 participants for D7 
CALL book_room (3, 2, CURRENT_DATE+7, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+7, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+7, 3, 6, 2);
CALL join_meeting (3, 2, CURRENT_DATE+7, 3, 6, 3);
CALL join_meeting (3, 2, CURRENT_DATE+7, 3, 6, 4);

--Change capacity on D5 to 5. Only D6 meetings should get cancelled.
CALL change_capacity(3, 2, 5, CURRENT_DATE+5, 38); 
SELECT * FROM Bookings;
SELECT * FROM Attends;

-- Test 5 (To be done after Test 4): Change capacity on D2 to 2. Any bookings with capacity > 2 on D3, D4, D5 to be cancelled, 
-- every participant to be removed. D6 onwards is okay if >2, <=5. --
CALL change_capacity(3, 2, 2, CURRENT_DATE+2, 38); --Expect D4, D5 to be removed.

-- Test 6 (To be done after Test 4, 5): Book room for D3, D6 with capacity 3. 
-- 3rd participant should be rejected for D3, but accepted for D6. --
CALL book_room (3, 2, CURRENT_DATE+3, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+3, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+3, 3, 6, 2);
CALL book_room (3, 2, CURRENT_DATE+6, 3, 6, 38);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 1);
CALL join_meeting (3, 2, CURRENT_DATE+6, 3, 6, 2);





/**
 * add_employee(emp_name VARCHAR(50), kind CHAR(7), dept_id INT, phone VARCHAR(20), home VARCHAR(20), office VARCHAR(20))
 */
CALL add_employee('Test Employee 1', 'junior', 1, '987654321', '123456789', '567891234');
CALL add_employee('Test Employee 2', 'junior', 1, '987654321', '123456789');
CALL add_employee('Test Employee 3', 'junior', 1, '987654321');
CALL add_employee('Test Employee 4', 'senior', 2, '123455555');
CALL add_employee('Test Employee 5', 'manager', 3, '123455665');
CALL add_employee(NULL, 'junior', 7, '123456666');
SELECT * FROM Employees;





/**
 * remove_employee(emp_id INT, resigned_date DATE)
 */
select * from employees;
/*Already resigned*/
CALL remove_employee(46, '2021-10-16');
/*Not resigned*/
CALL remove_employee(46, '2021-10-30');

/*Remove employee from future meetings*/
CALL declare_health(40, CURRENT_DATE, 36.8);
CALL declare_health(39, CURRENT_DATE, 36.8);

CALL book_room(2, 2, CURRENT_DATE, 17, 18, 40);
CALL book_room(2, 2, CURRENT_DATE, 18, 20, 39);
CALL join_meeting(2, 2, CURRENT_DATE, 18, 20, 40);

select * from bookings;
select * from attends;
CALL remove_employee(40, '2021-10-30');

/*Check resigned date not > today*/
CALL remove_employee(39, CURRENT_DATE + 1);

/*Prevent delete on employee*/
DELETE FROM employees WHERE emp_id = 1;

SELECT * FROM attends;




/**
 * search_room(room_capacity INT, date DATE, start_time INT, end_time INT)
 */
/*no rooms found for capacity 10*/
select * from search_room(10,CURRENT_DATE,12,14);
/*rooms found and capacity sorted in ascending*/
select * from search_room(6,CURRENT_DATE,12,14);





/** 
 * book_room(IN floor_num INT, IN room_num INT, IN date DATE, IN start_hour INT, IN end_hour INT, IN emp_id INT) 
 */
-- Test 1: Not a booker. Expected: FK constraint, not booked.
CALL book_room (1, 2, CURRENT_DATE, 3, 6, 2);

-- Test 2: End hour <= Start hour, End hour <> 0. Expected: Error message end hour <= start hour, not booked.
CALL book_room (1, 2, CURRENT_DATE, 6, 3, 2);

-- Test 3: End hour >= 24. Expected: Error message end hour >= 24, not booked.
CALL book_room (1, 2, CURRENT_DATE, 7, 24, 2);

-- Test 4: Booker has not declared temp. Expected: Error message no declare temp, not booked.
CALL book_room (2, 1, CURRENT_DATE, 3, 6, 19);

-- Test 5: Booker declared temp but fever. Expected: Error message fever, not booked.
CALL declare_health (19, CURRENT_DATE, '38'); 
CALL book_room (2, 1, CURRENT_DATE, 12, 15, 19);

-- Test 7: Booker resigned. Expected: Error message resigned, not booked. 
CALL book_room(2, 1, CURRENT_DATE,12, 15, 42);

-- Test 6: Booker declared temp. Expected: Success.
CALL declare_health (27, CURRENT_DATE, '36'); 
CALL book_room (2, 1, CURRENT_DATE+1, 12, 14, 27);

-- Test 7: Between start and end hour, there is already one other booking.  
-- Expected: Error message for the overlap booking. Not booked.
CALL book_room (2, 1, CURRENT_DATE+4, 3, 4, 27);
CALL book_room (2, 1, CURRENT_DATE+4, 1, 6, 27);

-- Test 8: Start date in the past. Expected: Error start date must be today or after, not booked.
CALL book_room (2, 1, '2021-10-09', 3, 6, 27);

-- Test 9: End hour = 0. Expected: Success, treat as midnight.
CALL book_room (2, 1, CURRENT_DATE, 21, 0, 27);





/**
 * unbook_room(floor_no INT, room_no INT, booking_date DATE, start_hour INT, end_hour INT, booker_id INT)
 */
SELECT * FROM MeetingRooms;
SELECT * FROM Bookings;
/*set up for testing*/
INSERT INTO Seniors Values(1);
INSERT INTO Managers Values(2);
UPDATE Employees SET dept_id = 1 WHERE emp_id = 2;
CALL declare_health(1, CURRENT_DATE, 37.0);
CALL declare_health(2, CURRENT_DATE, 37.4);
CALL book_room(2, 1, CURRENT_DATE, 19, 22, 1);
/*unbook not approved meeting room*/
CALL unbook_room(2, 1, CURRENT_DATE, 19, 20, 2); --different booker id, expect false, no deletion
CALL unbook_room(2, 1, CURRENT_DATE, 19, 20, 1); --expect true, meeting deleted
/*unbook approved meeting room*/
CALL approve_meeting(2, 1, CURRENT_DATE, 20, 22, 2); 
CALL unbook_room(2,1,CURRENT_DATE, 20, 22, 1);
/*restore data*/
INSERT INTO Juniors Values(1);
INSERT INTO Juniors Values(2);
UPDATE Employees SET dept_id = 2 WHERE emp_id = 2;





/**
 * join_meeting(floor_no INT, room_no INT, meeting_date DATE, start_hour INT, end_hour INT, participant_emp_id INT)
 */
CALL declare_health(2, CURRENT_DATE, 36.8);
CALL declare_health(3, CURRENT_DATE, 36.8);
CALL declare_health(4, CURRENT_DATE, 36.8);
CALL declare_health(37, CURRENT_DATE, 36.8);
CALL declare_health(38, CURRENT_DATE, 36.8);

CALL book_room(2, 2, CURRENT_DATE+1, 14, 16, 37);
CALL join_meeting(2, 2, CURRENT_DATE+1, 14, 16, 2);
CALL join_meeting(2, 2, CURRENT_DATE+1, 14, 16, 3);


SELECT * FROM Attends


/**
 * leave_meeting(floor_no INT, room_no INT, meeting_date DATE, start_hour INT, end_hour INT, participant_emp_id INT)
 */

call declare_health(36,CURRENT_DATE,36.8);
call declare_health(1,CURRENT_DATE,36.8);
call declare_health(2,CURRENT_DATE,36.8);
call declare_health(3,CURRENT_DATE,36.8);
call book_room(20,1,CURRENT_DATE+1,14,16,36);
call join_meeting(20,1,CURRENT_DATE+1,14,16,1);
call join_meeting(20,1,CURRENT_DATE+1,14,16,2);
call join_meeting(20,1,CURRENT_DATE+1,14,16,3);
/*leave meeting not approved successfully*/
call leave_meeting(20,1,CURRENT_DATE+1,14,16,1);
/*not allowed to leave approved meeting*/
call approve_meeting(20,1,CURRENT_DATE+1,14,16,37);
call leave_meeting(20,1,CURRENT_DATE+1,14,16,2);
/*booker leave meeting*/
call leave_meeting(20,1,CURRENT_DATE+1,14,16,36);

SELECT * FROM Bookings


/** 
 * approve_meeting(IN floor_num INT, IN room_num INT, IN booking_date DATE, IN start_hour INT, IN end_hour INT, IN emp_id INT) 
 */
-- Call this first: 
CALL declare_health (36, CURRENT_DATE, '36'); 
CALL book_room (2, 9, CURRENT_DATE+10, 3, 6, 36);

-- Test 1: Not a manager. Expected: FK constraint, not approved.
CALL approve_meeting (2, 9, CURRENT_DATE+10, 3, 6, 2);

-- Test 2: Manager has resigned. Expected: Error msg resigned, not approved.
CALL approve_meeting (2, 9, CURRENT_DATE+10, 3, 6, 45);

-- Test 3: Some meeting in the range does not exist. Expected: Error msg for the ones that do not exist, all not approved.
CALL approve_meeting (2, 9, CURRENT_DATE+10, 3, 7, 36);

-- Test 4: Not a manager of the dept. Expected: Error msg not correct manager, not approved.
CALL approve_meeting (2, 9, CURRENT_DATE+10, 3, 5, 22);

-- Test 5: Correct manager, correct hours. Expected: Success, all approved.
CALL approve_meeting (2, 9, CURRENT_DATE+10, 3, 6, 36);

-- Test 5: Once approved, cannot join or update booking. Expected: Booking already approved, no more changes.
CALL declare_health(1, CURRENT_DATE, 36.8)
CALL join_meeting (2, 9, CURRENT_DATE+10, 3, 6, 1);
UPDATE Bookings SET start_hour = 2 WHERE date = CURRENT_DATE+10 AND floor = 2 AND room = 9;

-- Test 6: End hour <= Start hour, End hour <> 0. Expected: Error msg, not approved.
CALL approve_meeting(2, 9, CURRENT_DATE+10, 6, 3, 36);

-- Test 7: End hour or start hour not in correct range (0 - 23). Expected: Error msg, not approved.
CALL approve_meeting(2, 9, CURRENT_DATE+10, -5, 3, 36);
CALL approve_meeting(2, 9, CURRENT_DATE+10, -5, 24, 36);

-- Test 8: Start hour = 0. Expected: Success (if booking exists, for this case, was created in T9 of book_room), treat as midnight.
CALL approve_meeting(2, 1, CURRENT_DATE, 21, 0, 37);





/** 
 * declare_health(emp_id INT, date DATE, temperature NUMERIC)
 */
DROP TRIGGER IF EXISTS emp_resigned_cannot_declare_health ON HealthDeclarations; --drop this trigger if you want to declare temperature in past date
SELECT * FROM HealthDeclarations ORDER BY date ASC;
/*ridiculous temperature*/
CALL declare_health(1, CURRENT_DATE, 99.2); --expect false
/*declare temperature by using the past date*/
CALL declare_health(1, '2021-09-23', 37.0); --past date, expect false
CALL declare_health(1, '2022-01-01', 37.0); --future date, expect false
CALL declare_health(1, CURRENT_DATE, 37.0); -- current date, expect true
/*direct insert into healthdeclarations table*/
INSERT INTO HealthDeclarations Values(2, CURRENT_DATE, 37.6); --expect fever = true
INSERT INTO HealthDeclarations VALUES(3, CURRENT_DATE, 37.9); --fever!
UPDATE HealthDeclarations SET fever = FALSE WHERE emp_id = 2 AND date = CURRENT_DATE;
UPDATE HealthDeclarations SET fever = FALSE WHERE emp_id = 3 AND date = CURRENT_DATE;





/** 
 * contact tracing(emp_id INT)
 */
DROP TRIGGER IF EXISTS b_ensure_booking_date_is_not_in_past ON Bookings; /*needed to create past bookings*/
CALL declare_health(2, CURRENT_DATE, 36)
CALL declare_health(6, CURRENT_DATE, 36);
CALL declare_health(7, CURRENT_DATE, 36)
CALL declare_health(38, CURRENT_DATE, 36)
CALL book_room(2, 1, CURRENT_DATE-3, 14, 16, 38);
CALL join_meeting(2, 1, CURRENT_DATE-3, 14, 16, 6);
CALL join_meeting(2, 1, CURRENT_DATE-3, 14, 16, 7);
CALL approve_meeting(2, 1, CURRENT_DATE-3, 14, 16, 37); /*37 is the manager of dept 1*/

CALL declare_health(9, CURRENT_DATE, 36.8);
CALL declare_health(10, CURRENT_DATE, 36.8);

CALL book_room(2, 1, CURRENT_DATE+6, 14, 16, 38);
CALL join_meeting(2, 1, CURRENT_DATE+6, 14, 16, 9);
CALL join_meeting(2, 1, CURRENT_DATE+6, 14, 16, 10);
CALL approve_meeting(2, 1, CURRENT_DATE+6, 14, 16, 37); /*37 is the manager of dept 1*/

SELECT * FROM bookings;
SELECT * FROM attends;

UPDATE healthdeclarations SET temperature = 38 WHERE emp_id = 38 AND date = CURRENT_DATE;

SELECT * FROM contact_tracing(38); /*emp 6,7 where in the meeting*/





/**
 * non_compliance(start_date DATE, end_date DATE)
 */
select * from non_compliance(CURRENT_DATE,CURRENT_DATE);
select * from non_compliance(CURRENT_DATE-1,CURRENT_DATE);





/** 
 * view_booking_report(IN start_date DATE, IN emp_id INT) 
 */
-- Test 1: Has not booked anything yet. 
SELECT view_booking_report (CURRENT_DATE, 35);

-- Test 2: Booked 3 meetings, not approved.
CALL declare_health (35, CURRENT_DATE, '36'); 
CALL book_room (2, 8, CURRENT_DATE+10, 3, 6, 35);
SELECT view_booking_report (CURRENT_DATE, 35);

-- Test 3: 2 out of 3 meetings approved.
CALL approve_meeting (2, 8, CURRENT_DATE+10, 3, 5, 35);
SELECT view_booking_report (CURRENT_DATE, 35);

/**
 * view_manager_report(start_date DATE, manager_id INT)
 */
CALL declare_health(36, CURRENT_DATE, 36.8);
CALL declare_health(37, CURRENT_DATE, 36.8);

CALL book_room(2, 2, CURRENT_DATE+6, 14, 16, 36);
CALL book_room(2, 2, CURRENT_DATE+5, 14, 16, 37);

SELECT * FROM view_manager_report(CURRENT_DATE, 38);





/**
 * view_future_meeting(date DATE, emp_id INT)
 */
SELECT * FROM Attends;
/*view future meeting that exists in Attends*/
SELECT * FROM view_future_meeting('2021-09-23', 1);
SELECT * FROM view_future_meeting('2021-09-24', 3);
/*view future meeting that does not exist in Attends*/
SELECT * FROM view_future_meeting('2021-11-20', 1); --expect nothing shown



/**
 * Additional features
 */

/*Check if employee has fever*/
CALL declare_health(5, CURRENT_DATE, 38);
CALL join_meeting(2, 2, CURRENT_DATE+1, 14, 16, 5);






/*Prevent update if approved*/
CALL approve_meeting(2, 2, CURRENT_DATE+1, 14, 16, 38); /*38 is the manager of dept 2*/
CALL join_meeting(2, 2, CURRENT_DATE+1, 14, 16, 4);
CALL change_capacity(2, 2, 5, CURRENT_DATE, 38); /*Current cap is 3*/






/*Prevent meeting conflicts*/
CALL book_room(2, 2, CURRENT_DATE+1, 14, 16, 37);
CALL book_room(2, 3, CURRENT_DATE+1, 14, 16, 37);






/*Prevent resigned employee from being addded to meeting*/
CALL book_room(2, 3, CURRENT_DATE+2, 14, 16, 38);
CALL join_meeting(2, 3, CURRENT_DATE+2, 14, 16, 40); /*Assume emp_id 40 has resigned*/






/*Check max cap*/
CALL declare_health(6, CURRENT_DATE, 36.8);
CALL declare_health(7, CURRENT_DATE, 36.8);
CALL declare_health(8, CURRENT_DATE, 36.8);

CALL book_room(2, 1, CURRENT_DATE+3, 14, 16, 38); /*Cap is 3*/
CALL join_meeting(2, 1, CURRENT_DATE+3, 14, 16, 6);
CALL join_meeting(2, 1, CURRENT_DATE+3, 14, 16, 7);
CALL join_meeting(2, 1, CURRENT_DATE+3, 14, 16, 8);






--Testing edit email and emp_id
SELECT CURRVAL('Employees_emp_id_seq')
INSERT INTO Employees Values(101, 'abc@email.com', 'abc', '12345678', NULL, NULL, NULL, 1);
INSERT INTO Juniors Values(101)
UPDATE Employees SET emp_id = 100 WHERE emp_id = 46






--Testing change of seniority
SELECT * FROM Juniors;
SELECT * FROM Bookers;
SELECT * FROM Seniors;
SELECT * FROM Managers;
/*promote*/
INSERT INTO Seniors Values(2); --junior to senior, expect true, execute without error
INSERT INTO Managers Values(1); --junior to manager, expect true, execute without error
/*demote without making booking and approve meeting*/
INSERT INTO Juniors Values(1); --manager to junior, expect true, execute without error
INSERT INTO Juniors Values(2); --senior to junior, expect true, execute without error
/*demote when the employee has made bookings/approve meeting*/
SELECT * FROM Bookings;
INSERT INTO Juniors Values(28);
INSERT INTO Seniors Values(37);
/*direct insert into bookers*/
INSERT INTO Bookers Values(1); --junior to booker, expect false, block insertion
/*booker to junior*/
INSERT INTO Juniors Values(19); -- booker to junior, expect true, execute without error
INSERT INTO Seniors Values(19); --restore data














