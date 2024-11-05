-- ITDBADM - 107
-- Buere, Krueger, Pegalan, Tan


-- by: Lara Nicole B. Pegalan
DROP TABLE IF EXISTS sales_reports;
CREATE TABLE sales_reports (
	reportid		INT(10),
	reportyear		INT(4),
    reportmonth 	INT(2),
    reportday		INT(2),
    sales			DECIMAL(9,2),
    discounts		DECIMAL(9,2),
    markups			DECIMAL(9,2),
    PRIMARY KEY (reportid, reportyear, reportmonth, reportday)
);


DROP FUNCTION IF EXISTS getMSRPDifference;
DELIMITER $$
CREATE FUNCTION getMSRPDifference (param_productCode VARCHAR(15)) 
RETURNS DOUBLE
DETERMINISTIC
BEGIN
	DECLARE msrp DECIMAL(9,2);
    DECLARE buyPrice DOUBLE;
    
    SET msrp= getMSRP(productCode);

	SELECT  p.buyPrice 
	FROM 	products
	WHERE p.productCode = productCode;
    
    SET getMSRPDifference = price - msrp;

	RETURN getMSRPDifference;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS generate_salesreport;
DELIMITER $$

CREATE PROCEDURE generate_salesreport (param_year INT(4), param_month INT(2), param_generatedby VARCHAR(100)) 
BEGIN
	DECLARE report_description	VARCHAR(100);
    DECLARE v_reportid			INT(10);
    DECLARE MARKUPS				DOUBLE;
    DECLARE DISCOUNTS			DOUBLE;
    SET report_description = CONCAT('Sales Report for the Month of ', param_month, ' and year ', param_year);
    SET MARKUPS = getMSRPDifference(productCode);
    SET DISCOUNTS = getMSRPDifference(productCode);
    
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc) VALUES (NOW(), param_generatedby, report_description);
    SELECT MAX(reportid) INTO v_reportid FROM reports_inventory;

	INSERT INTO sales_reports 
		SELECT		v_reportid,
					YEAR(orderdate)		as reportyear, 
					MONTH(orderdate)	as reportmonth, 
					DAY(orderdate)		as reportday,
					ROUND(SUM(od.priceEach*od.quantityOrdered),2)	as SALES,
                   	DISCOUNTS as DISCOUNTS,
					MARKUPS as MARKUPS
		FROM		orders o JOIN orderdetails od ON o.orderNumber=od.orderNumber
		WHERE		o.status IN ('Shipped', 'Completed')
		AND			YEAR(orderdate)  = param_year
		AND			MONTH(orderdate) = param_month
		GROUP BY	YEAR(orderdate), MONTH(orderdate), DAY(orderdate);
END $$
DELIMITER ;

-- CALL generate_salesreport (2024, 10, "Sales Executive");
-- SHOW PROCESSLIST;
-- SHOW EVENTS;


DROP TABLE IF EXISTS reports_inventory;
CREATE TABLE reports_inventory (
	reportid		INT(10)	AUTO_INCREMENT,
    generationdate	DATETIME,
    generatedby		VARCHAR(100),
    reportdesc		VARCHAR(100),
    PRIMARY KEY (reportid)
);