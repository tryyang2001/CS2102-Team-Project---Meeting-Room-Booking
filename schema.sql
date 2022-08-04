DROP TABLE IF EXISTS Departments, Employees, Juniors, Bookers, Seniors, Managers, HealthDeclarations, MeetingRooms, Bookings, Attends, Updates CASCADE;

CREATE TABLE Departments(
	dept_id INTEGER NOT NULL,
	dept_name VARCHAR(50) NOT NULL,
	PRIMARY KEY (dept_id)
);

CREATE TABLE Employees(
	emp_id SERIAL NOT NULL,
	email VARCHAR(100) NOT NULL UNIQUE,
	name VARCHAR(50) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	office VARCHAR(20),
	home VARCHAR(20),
	resigned_date DATE,
	dept_id INTEGER NOT NULL,
	PRIMARY KEY (emp_id),
	FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON UPDATE CASCADE
);

CREATE TABLE Juniors(
	emp_id INTEGER NOT NULL,
	PRIMARY KEY (emp_id),
	FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON UPDATE CASCADE
);

CREATE TABLE Bookers(
	emp_id INTEGER NOT NULL,
	PRIMARY KEY (emp_id),
	FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON UPDATE CASCADE
);

CREATE TABLE Seniors(
	emp_id INTEGER NOT NULL,
	PRIMARY KEY (emp_id),
	CONSTRAINT senior_fkey FOREIGN KEY (emp_id) REFERENCES Bookers (emp_id) 
	ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE Managers(
	emp_id INTEGER NOT NULL,
	PRIMARY KEY (emp_id),
	CONSTRAINT manager_fkey FOREIGN KEY (emp_id) REFERENCES Bookers (emp_id) 
	ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE HealthDeclarations(
	emp_id INTEGER NOT NULL,
	date DATE NOT NULL,
	temperature NUMERIC(3,1) NOT NULL CHECK (temperature >= 34 AND temperature <= 43),
	fever BOOLEAN DEFAULT FALSE, CHECK ((temperature <= 37.5 AND fever = FALSE) OR (temperature > 37.5 AND fever = TRUE)),
	PRIMARY KEY (emp_id, date),
	FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON UPDATE CASCADE
);

CREATE TABLE MeetingRooms(
	floor INTEGER NOT NULL,
	room INTEGER NOT NULL,
	name VARCHAR(50) NOT NULL,
	dept_id INTEGER NOT NULL,
	PRIMARY KEY(floor, room),
	FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON UPDATE CASCADE
);

CREATE TABLE Bookings(
	booker_id INTEGER NOT NULL,
	date DATE NOT NULL,
	start_hour INTEGER NOT NULL CHECK (start_hour >=0 and start_hour <= 23),
	floor INTEGER NOT NULL,
	room INTEGER NOT NULL,
	manager_id INTEGER,
	PRIMARY KEY (date, start_hour, floor, room),
	FOREIGN KEY (booker_id) REFERENCES Bookers(emp_id) ON UPDATE CASCADE,
	FOREIGN KEY (manager_id) REFERENCES Managers(emp_id) ON UPDATE CASCADE,
	FOREIGN KEY (floor, room) REFERENCES MeetingRooms(floor, room) ON UPDATE CASCADE
);

CREATE TABLE Attends(
	emp_id INTEGER NOT NULL,
	date DATE NOT NULL,
	start_hour INTEGER NOT NULL,
	floor INTEGER NOT NULL,
	room INTEGER NOT NULL,
	PRIMARY KEY (emp_id, date, start_hour, floor, room),
	FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON UPDATE CASCADE,
	FOREIGN KEY (date, start_hour, floor, room) REFERENCES Bookings(date, start_hour, floor, room) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Updates(
	date DATE NOT NULL,
	floor INTEGER NOT NULL,
	room INTEGER NOT NULL,
	max_capacity INTEGER NOT NULL,
	manager_id INTEGER NOT NULL,
	PRIMARY KEY (date, floor, room),
	FOREIGN KEY (floor, room) REFERENCES MeetingRooms(floor, room) ON UPDATE CASCADE,
	FOREIGN KEY (manager_id) REFERENCES Managers(emp_id) ON UPDATE CASCADE
);