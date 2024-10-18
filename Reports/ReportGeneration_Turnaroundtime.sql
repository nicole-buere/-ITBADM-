
-- Turnaroundtime report table 
DROP TABLE IF EXISTS turnaroundtime_report;
CREATE TABLE turnaroundtime_report(
	reportid		INT(10),
	reportyear		INT(4),
    reportmonth		INT(2),
    country 		VARCHAR(100),
    office			VARCHAR(100),
    avg_turnaround	DECIMAL(9,2),
    PRIMARY KEY (reportid, reportyear, reportmonth, country, office)
);

-- Stored Procedure
DROP PROCEDURE IF EXISTS generate_turnaroundtimereport; 
DELIMITER $$
CREATE PROCEDURE generate_turnaroundtimereport (param_year INT(4), param_month INT(2), param_generatedby VARCHAR(100))
BEGIN 
		DECLARE report_description VARCHAR(100); 
		DECLARE v_reportid INT(10); 
		SET report_description = CONCAT('Turnaround Time Report for the Month of ', param_month, ' and Year ', param_year); 
        
		
		INSERT INTO reports_inventory (generationdate, generatedby, reportdesc) VALUES (NOW(), param_generatedby, report_description); 
		SELECT MAX(reportid) INTO v_reportid FROM reports_inventory; 
		
		INSERT INTO turnaroundtime_reports 
				SELECT 				v_reportid, 
									YEAR(StartTime) as reportyear, 
									MONTH(StartTime) as reportmonth, 
									Country, 
									Office, 
									AVG(timestampdiff(MINUTE, StartTime, EndTime)) as avg_turnaroundtime 
				FROM 				
				WHERE 				EndTime IS NOT NULL 
				AND 				YEAR(StartTime) = param_year 
				AND					MONTH(StartTime) = param_month 
				GROUP BY 			YEAR(StartTime), MONTH(StartTime), Country, Office; 
        
        		SELECT ('Turnaround time report generated successfully'); 
        
END $$ 
DELIMITER ;

-- Temporal Trigger
DROP EVENT IF EXISTS generate_turnaroundtimereport; 
DELIMITER $$ 
CREATE EVENT generate_turnaroundtimereport 
ON SCHEDULE EVERY 1 MONTH 
DO 
BEGIN 
	CALL generate_turnaroundtimereport(YEAR(NOW()), MONTH(NOW()), 'System-Generated'); 
END $$ 
DELIMITER ;