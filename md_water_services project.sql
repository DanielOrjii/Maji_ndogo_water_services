USE md_water_services;
# Exploring the database #
SELECT 
	*
FROM
	water_source
WHERE 
	source_id = 'AkRu05234224'
OR source_id = 'HaZa21742224';

# Where water quality score is 10 and it is not a tap in home#
SELECT 
	*
FROM
	water_quality
WHERE 
	subjective_quality_score = 10
AND 
	visit_count > 1;
    
# Replacing rows with a description "clean" and a biological count > 0.01 to indicate presence of contamination#
SELECT 
	*
FROM
	well_pollution
WHERE
	 results LIKE 'Clean%'
AND 
	biological > 0.01;    

SET SQL_SAFE_UPDATES = 0;

UPDATE well_pollution
SET results = 'Contaminated: Biological'
WHERE results = 'Clean'
AND biological > 0.01;

USE md_water_services;
# Exploring the database#
SELECT 
	*
FROM
	data_dictionary;
    
SELECT
	*
FROM
	employee;

# Create a column containing email addresses of assigned employees#
SELECT
	CONCAT(
	LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email
FROM
	employee;

UPDATE employee
SET email = CONCAT(
	LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');
 
 # Trim the phone number column to prevent errors #
SELECT
	LENGTH(phone_number)
FROM
	employee;

UPDATE employee
SET phone_number = TRIM(phone_number);

# Different location of employees #
SELECT
	town_name,
	COUNT(town_name) as loc_of_employees
FROM
	employee
GROUP BY 
	town_name;
    
# Identifying the top 3 employees by number of visits  #
SELECT
	DISTINCT(assigned_employee_id),
    COUNT(assigned_employee_id) AS amt_of_visit 
FROM
	visits
GROUP BY
	assigned_employee_id
ORDER BY 
	COUNT(assigned_employee_id) DESC
LIMIT 3;

# Getting the contact details of the top employees #
SELECT
    DISTINCT(vis.assigned_employee_id),
    COUNT(vis.assigned_employee_id) AS amt_of_visit,
	emp.employee_name,
    emp.phone_number
FROM
	employee AS emp
INNER JOIN
visits AS vis
ON emp.assigned_employee_id = vis.assigned_employee_id
GROUP BY
	vis.assigned_employee_id
ORDER BY 
	COUNT(vis.assigned_employee_id) DESC
LIMIT 3;

# Returning the no. of records per town #
SELECT
	town_name,
    COUNT(town_name) AS no_of_record
FROM
	location AS loc
GROUP BY
	town_name;

SELECT
	loc.town_name,
    COUNT(vis.record_id)
FROM
	location AS loc
INNER JOIN
	visits AS vis
ON 	
	loc.location_id = vis.location_id
GROUP BY
	loc.town_name;

# Returning the no. of records per province #
SELECT
	province_name,
    COUNT(province_name)
FROM
	location
GROUP BY
	province_name;

# Returning the no. of records by town and province #    
SELECT	
	province_name,
    town_name,
    COUNT(town_name) AS records_per_town
FROM
	location
GROUP BY 	
	province_name,
    town_name
ORDER BY
	province_name,
	COUNT(town_name) DESC;
    
# No. of records per location type #
SELECT
	location_type,
    COUNT(location_type) AS num_sources,
    ROUND(COUNT(location_type)/(SELECT
		COUNT(location_type)
	FROM
		location) * 100) AS pct_source
FROM
	location
GROUP BY
	location_type;

# Number of people served #
SELECT
	SUM(number_of_people_served) AS total_people_served
FROM
	water_source;

# Number of individual water source #
SELECT 
	type_of_water_source,
	COUNT(type_of_water_source) AS no_of_sources
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY
	 COUNT(type_of_water_source) DESC;

# How many people share particular sources on average #
SELECT 
	type_of_water_source,
    ROUND(SUM(number_of_people_served)/COUNT(type_of_water_source)) AS avg_people_served
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY
	ROUND(SUM(number_of_people_served)/COUNT(type_of_water_source)) DESC;

# How many and what percentage of people share particular sources in total #    
SELECT 
	type_of_water_source,
    ROUND(SUM(number_of_people_served)) AS total_people_served_per_source,
    ROUND(SUM(number_of_people_served)/(
										SELECT
											SUM(number_of_people_served)
										FROM
											water_source) * 100
										) AS pct_people_served
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY
	ROUND(SUM(number_of_people_served)) DESC;

#How many and what percentage of people have tap installed in their homes #
SELECT 
	type_of_water_source,
    ROUND(SUM(number_of_people_served)) AS total_people_served_per_source,
    ROUND(SUM(number_of_people_served)/(
										SELECT
											SUM(number_of_people_served)
										FROM
											water_source
										WHERE
											type_of_water_source LIKE 'tap%') * 100
										) AS pct_people_served
FROM
	water_source
WHERE
	type_of_water_source LIKE 'tap%'
GROUP BY
	type_of_water_source
ORDER BY
	ROUND(SUM(number_of_people_served)) DESC;

# Percentage of clean wells #
SELECT
		ROUND(COUNT(
		CASE 
			WHEN description LIKE 'clean%' THEN 1 
		 END)/COUNT(type_of_water_source) * 100) AS pct_of_fxnal_taps
FROM
	water_source AS ws
INNER JOIN
	well_pollution AS wp
ON
	ws.source_id = wp.source_id
WHERE 
	type_of_water_source = 'well';

# Rank water sources based on number of users except tap_in_home #
WITH people_served AS (
	SELECT 
		type_of_water_source,
		ROUND(SUM(number_of_people_served)) AS total_people_served_per_source
	FROM
		water_source
	GROUP BY
		type_of_water_source
	ORDER BY
		ROUND(SUM(number_of_people_served)) DESC
)
SELECT
	type_of_water_source,
    total_people_served_per_source,
    RANK() OVER (ORDER BY total_people_served_per_source DESC) AS rank_
FROM
	people_served
WHERE 
	type_of_water_source != 'tap_in_home';
    
# Which sources should be fixed first? #
SELECT
	*,
	ROW_NUMBER() OVER (ORDER BY number_of_people_served DESC) AS rank_
FROM
	water_source
WHERE 	
	type_of_water_source = 'shared_tap'
OR 
	type_of_water_source = 'well';
    
# How long was the survey #
SELECT
	ABS(DATEDIFF(
    MIN(time_of_record),
    MAX(time_of_record))) AS len_of_survey
FROM
	visits;

# Average total queue time for water if they dont have taps in home#
SELECT
    ROUND(SUM(time_in_queue)/COUNT(time_in_queue)) AS avg_queue_time_in_min
FROM
	visits
WHERE time_in_queue != 0;
    
# Average queue time on different days #
SELECT
    DAYNAME(time_of_record) AS weekdays,
    ROUND(AVG(time_in_queue)) AS avg_queue_time
FROM
	visits
GROUP BY 
	DAYNAME(time_of_record)
ORDER BY
	ROUND(AVG(time_in_queue)) DESC;
    
# What time during the day do people collect water #
SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_the_day,
    ROUND(AVG(time_in_queue)) AS avg_queue_time
FROM
	visits
GROUP BY 
	TIME_FORMAT(TIME(time_of_record), '%H:00')
ORDER BY
	TIME_FORMAT(TIME(time_of_record), '%H:00') ASC;
    
# Queue time for different hours on different days #
WITH CTE AS (
	SELECT
		TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
		DAYNAME(time_of_record) AS weekday,
		time_in_queue
	FROM
		visits
	WHERE 
		time_in_queue != 0
)
SELECT
	hour_of_day,
	ROUND(AVG(
		CASE
		WHEN weekday = 'Sunday' THEN time_in_queue
        ELSE NULL
	END),0) AS Sunday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Monday' THEN time_in_queue
        ELSE NULL
	END),0) AS Monday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Tuesday' THEN time_in_queue
        ELSE NULL
	END),0) AS Tuesday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Wednesday' THEN time_in_queue
        ELSE NULL
	END),0) AS Wednesday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Thursday' THEN time_in_queue
        ELSE NULL
	END),0) AS Thursday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Friday' THEN time_in_queue
        ELSE NULL
	END),0) AS Friday,
    ROUND(AVG(
		CASE
		WHEN weekday = 'Saturday' THEN time_in_queue
        ELSE NULL
	END),0) AS Saturday
FROM
	CTE
GROUP BY hour_of_day;

#Comparing the independently conducted audit with our results #
CREATE VIEW Incorrect_record AS (
	SELECT
		wq.record_id AS record_id,
		vs.location_id AS audit_loc,
		ar.type_of_water_source AS water_source_type,
		wq.subjective_quality_score AS water_quality_score,
		ar.true_water_source_score AS audit_score,
		ar.statements,
		emp.employee_name AS emp_name
	FROM
		water_quality AS wq
	INNER JOIN
		visits AS vs
	ON 
		wq.record_id = vs.record_id
	INNER JOIN
		auditor_report AS ar
	ON 
		vs.location_id = ar.location_id
	INNER JOIN
		employee AS emp
	ON
		vs.assigned_employee_id = emp.assigned_employee_id
	WHERE
		wq.visit_count = 1
	AND
		wq.subjective_quality_score != ar.true_water_source_score
	);

# Finding the employees with the most errors#
CREATE VIEW error_count AS(
	SELECT
		emp_name AS name_staff,
		COUNT(emp_name) AS num_of_mistakes
	FROM
		Incorrect_record
	GROUP BY
		emp_name
	ORDER BY	
		COUNT(emp_name) DESC
	); 
    
# Filters all of the records were the corrupt employees gathered data#
WITH Suspect_list AS(
	SELECT 
		name_staff,
		num_of_mistakes
	FROM
		error_count
	WHERE
		num_of_mistakes > (SELECT
								AVG(num_of_mistakes)
							FROM
								error_count))
									SELECT
										sl.name_staff,
										ir.audit_loc,
										ir.statements
									FROM
										Suspect_list AS sl
									JOIN
										incorrect_record AS ir
									ON
										sl.name_staff = ir.emp_name
									WHERE
										ir.audit_loc = 'AkRu04508'
									OR 
										ir.audit_loc = 'AkRu07310' 
                                    OR 
										ir.audit_loc = 'KiRu29639'
                                    OR 
										ir.audit_loc = 'AmAm09607';
# Checking if any other employee aside from the suspects had any statement concerning cash #
SELECT
	*
FROM
	incorrect_record
WHERE 
	statements LIKE '%cash%'
AND
	emp_name != 'Bello Azibo'
AND 
	emp_name != 'Malachi Mavuso'
AND 
	emp_name != 'Zuriel Matembo'
AND 
	emp_name !=  'Lalitha Kaburi';
    
# Provinces with more sources than the  rest #
CREATE VIEW amt_of_sources AS(
	SELECT
		loc.province_name,
		loc.town_name,
		loc.location_type,
		ws.type_of_water_source,
		ws.number_of_people_served AS total_people_served,
		vs.time_in_queue AS avg_time_per_source,
		wp.results
    FROM
		location AS loc
	JOIN
		visits AS vs
	ON
		loc.location_id = vs.location_id
	LEFT JOIN
		well_pollution AS wp
	ON
		vs.source_id = wp.source_id
	JOIN
		water_source AS ws
	ON
		vs.source_id = ws.source_id
	WHERE
		visit_count = 1
);

# Percentage of people using each source type per province #
WITH province_totals AS(
	SELECT
		province_name,
        SUM(total_people_served) AS tot_ppl_served
	FROM
		amt_of_sources
	GROUP BY
		province_name
	)
    SELECT
		aos.province_name,
		ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN total_people_served ELSE 0 END) * 100/ pt.tot_ppl_served), 0) AS river,
		ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN total_people_served ELSE 0 END) * 100/ pt.tot_ppl_served), 0) AS shared_tap,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN total_people_served ELSE 0 END) * 100/ pt.tot_ppl_served), 0) AS tap_in_home,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN total_people_served ELSE 0 END) * 100/ pt.tot_ppl_served), 0) AS tap_in_home_broken,
		ROUND((SUM(CASE WHEN type_of_water_source = 'well'
				THEN total_people_served ELSE 0 END) * 100/ pt.tot_ppl_served), 0) AS well
	FROM
		amt_of_sources AS aos
	JOIN
		province_totals AS pt
	ON
		aos.province_name = pt.province_name
	GROUP BY 
		province_name
	ORDER BY
		province_name;
	

# Percentage of people using each source type per town #
CREATE TEMPORARY TABLE town_aggregated_water_accesss
WITH town_totals AS(
	SELECT
		aos.province_name AS province_name,
        aos.town_name AS town_name,
        SUM(aos.total_people_served) AS tot_ppl_served
	FROM
		amt_of_sources AS aos
	GROUP BY
		province_name, town_name
	)
    SELECT
		aos.province_name,
        aos.town_name,
		ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN total_people_served ELSE 0 END) * 100/ tt.tot_ppl_served), 0) AS river,
		ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN total_people_served ELSE 0 END) * 100/ tt.tot_ppl_served), 0) AS shared_tap,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN total_people_served ELSE 0 END) * 100/ tt.tot_ppl_served), 0) AS tap_in_home,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN total_people_served ELSE 0 END) * 100/ tt.tot_ppl_served), 0) AS tap_in_home_broken,
		ROUND((SUM(CASE WHEN type_of_water_source = 'well'
				THEN total_people_served ELSE 0 END) * 100/ tt.tot_ppl_served), 0) AS well
	FROM
		amt_of_sources AS aos
	JOIN
		town_totals AS tt
	ON
		aos.province_name = tt.province_name
	AND
		aos.town_name = tt.town_name
	GROUP BY 
		aos.province_name, aos.town_name
	ORDER BY
		aos.province_name, aos.town_name;
        
# Percentage of towns with the most broken taps#
SELECT 
	province_name,
    town_name,
    ROUND(tap_in_home_broken/(tap_in_home + tap_in_home_broken) * 100) AS pct_broken_taps
FROM
	town_aggregated_water_accesss
ORDER BY
	ROUND(tap_in_home_broken/(tap_in_home + tap_in_home_broken) * 100) DESC;
    
# Creating a table to guide the engineer job on what to fix, upgrade and repair, and tracking the progress of each improvement #
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In Progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);
        
SET SQL_SAFE_UPDATES = 0;

# Updating the information in our project_progress table#
INSERT INTO project_progress (source_id, Address, Town, Province, Source_type, Improvement)
SELECT
	ws.source_id,
	loc.address,
	loc.town_name,
	loc.province_name,
	ws.type_of_water_source,
	CASE
		WHEN wp.results LIKE '%Biological%'
			THEN 'Install UV and RO filter'
		WHEN wp.results LIKE '%Chemical%'
			THEN 'Install RO filter'
		WHEN ws.type_of_water_source LIKE '%River%'
			THEN 'Drill well'
		WHEN vs.time_in_queue > 29
			THEN CONCAT( 'Install ', FLOOR(vs.time_in_queue/30), ' taps nearby')
		WHEN ws.type_of_water_source LIKE '%Tap_in_home_broken%'
			THEN 'Diagnose local infrastructure' ELSE NULL 
            END AS Improvement
FROM
	water_source ws
LEFT JOIN
	well_pollution wp
ON
	ws.source_id = wp.source_id
INNER JOIN
	visits vs
ON
		ws.source_id = vs.source_id
INNER JOIN
	location loc
ON 
	loc.location_id = vs.location_id
WHERE
	vs.visit_count = 1
AND(
	ws.type_of_water_source IN ('tap_in_home_broken', 'river')
OR
	(ws.type_of_water_source = 'shared_tap' AND vs.time_in_queue > 29)
OR
	wp.results != 'Clean'
);

SELECT
	*
FROM
	project_progress;