DROP TABLE IF EXISTS reports_inventory;
CREATE TABLE reports_inventory (
    inv_reportid    INT(10) AUTO_INCREMENT,    -- Unique identifier for each entry in reports_inventory
    reportid        INT(10),                   -- Reference to the specific report's reportid (e.g., sales_reports)
    generationdate  DATETIME,                  -- Date and time the report was generated
    generatedby     VARCHAR(100),              -- Who generated the report
    reportdesc      VARCHAR(100),              -- Description of the report
    reporttable     VARCHAR(50),               -- Name of the report table (e.g., 'Sales, Discounts, and Markups', 'Quantity Ordered', etc.)
    PRIMARY KEY (inv_reportid),                -- Primary key for the reports_inventory table
    UNIQUE(reportid, reporttable)              -- Ensures uniqueness for report reference in specific report tables
);


-- Create a Special getMSRP
DROP FUNCTION IF EXISTS getMSRP_2;
DELIMITER $$
CREATE FUNCTION getMSRP_2 (param_productCode VARCHAR(15), param_origdate DATE) 
RETURNS DECIMAL(9,2)
DETERMINISTIC
BEGIN
	DECLARE	var_productcategory	ENUM('C', 'D');
    DECLARE var_producttype		ENUM('R', 'W');
    DECLARE var_MSRP			DECIMAL(9,2);
    DECLARE errormessage		VARCHAR(200);
    
	SELECT	product_category
    INTO	var_productcategory
    FROM	products
    WHERE	productCode = param_productCode;
    
    -- Check if the product exists
    IF (var_productcategory IS NULL) THEN
		SET errormessage := "Product does not exist";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

	-- Check if the product is discontinued
	IF (var_productcategory = 'D') THEN
		SET errormessage := "Product is discontinued. No MSRP available";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
	
    -- Check the current products table to determine if wholesale or retail
    
    SELECT	product_type
    INTO	var_producttype
    FROM	current_products
    WHERE	productCode = param_productCode;
    
    -- Check if the product is retail
    
    IF (var_producttype = 'R') THEN
		-- the product is retail
        SELECT  MSRP
        INTO	var_MSRP
        FROM	product_pricing
        WHERE	param_origdate BETWEEN startdate AND enddate
        AND		productCode = param_productCode;
        
        -- Check if the price was available
        IF (var_MSRP IS NULL) THEN
			SET errormessage := CONCAT("MSRP of the product does not exist yet given the date of ", param_origdate);
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
        END IF;
        RETURN var_MSRP;
    ELSE
		-- the product is wholesale
        SELECT 	MSRP
        INTO	var_MSRP
        FROM	product_wholesale
		WHERE	productCode = param_productCode;
	
		RETURN var_MSRP;
    END IF;
    
END $$
DELIMITER ;

SELECT * FROM `dbsalesv2.0`.product_pricing;
UPDATE product_pricing SET startdate='2000-01-01';

-- REPORT 01: Sales, Markups, and Discounts Report

DROP TABLE IF EXISTS sales_reports;
CREATE TABLE sales_reports (
    reportid            INT(10),                
    reportyear          INT(4),
    reportmonth         INT(2),
    generationdate      DATETIME,                -- Date when the report was generated
    productCode         VARCHAR(15),
    productLine         VARCHAR(50),
    employeeLastName    VARCHAR(50),
    employeeFirstName   VARCHAR(50),
    country             VARCHAR(50),
    officeCode          VARCHAR(10),
    orderDate           DATE,                    -- Include orderDate to ensure uniqueness
    SALES               DECIMAL(9,2),
    DISCOUNT            DECIMAL(9,2),
    MARKUP              DECIMAL(9,2),
    PRIMARY KEY (reportid, productCode, officeCode, employeeLastName, employeeFirstName, orderDate)  -- Composite primary key
);

DROP PROCEDURE IF EXISTS generate_sales_report;
DELIMITER $$

CREATE PROCEDURE generate_sales_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;

    -- Generate a new report id for sales_reports by incrementing the maximum report id found in the sales_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM sales_reports);

    -- Get the month name from the month number
    SET @month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
    
    -- Insert a record into reports_inventory for tracking with the generated report id
    INSERT INTO reports_inventory (inv_reportid, reportid, generationdate, generatedby, reportdesc, reporttable)
    VALUES (NULL, v_reportid, NOW(), CURRENT_USER(), CONCAT('Sales, Markups, and Discounts Summary Report for ', @month_name, ' ', p_year), 'Sales, Markups, and Discounts');

    -- Insert summarized monthly report data into sales_reports table using the generated report id
    INSERT INTO sales_reports (reportid, reportyear, reportmonth, generationdate, productCode, productLine, employeeLastName, employeeFirstName, country, officeCode, orderDate, sales, discount, markup)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        NOW() AS generationdate,
        p.productCode,
        pp.productLine,
        e.lastName,
        e.firstName,
        ofc.country,
        ofc.officeCode,
        o.orderDate,
        ROUND(SUM(od.priceEach * od.quantityOrdered), 2) AS SALES,
        ROUND(SUM(IF(od.priceEach < getMSRP_2(p.productCode, o.orderdate), getMSRP_2(p.productCode, o.orderdate) - od.priceEach, 0)), 2) AS DISCOUNT,
        ROUND(SUM(IF(od.priceEach >= getMSRP_2(p.productCode, o.orderdate), od.priceEach - getMSRP_2(p.productCode, o.orderdate), 0)), 2) AS MARKUP
    FROM    
        orders o
        JOIN orderdetails od ON o.orderNumber = od.orderNumber
        JOIN products p ON od.productCode = p.productCode
        JOIN product_productlines pp ON p.productCode = pp.productCode
        JOIN customers c ON o.customerNumber = c.customerNumber
        JOIN salesrepassignments sa ON c.salesRepEmployeeNumber = sa.employeeNumber
        JOIN offices ofc ON sa.officeCode = ofc.officeCode
        JOIN salesrepresentatives sr ON sa.employeeNumber = sr.employeeNumber
        JOIN employees e ON sr.employeeNumber = e.employeeNumber
    WHERE   
        o.status IN ('Shipped', 'Completed')
        AND MONTH(o.orderdate) = p_month
        AND YEAR(o.orderdate) = p_year
    GROUP BY 
        p.productCode, pp.productLine, e.employeeNumber, ofc.officeCode, e.lastName, e.firstName, ofc.country, o.orderDate;

END $$
DELIMITER ;



DROP EVENT IF EXISTS generate_monthly_sales_report;
DELIMITER $$
CREATE EVENT generate_monthly_sales_report
ON SCHEDULE EVERY 30 DAY
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    CALL generate_sales_report(YEAR(CURDATE()), MONTH(CURDATE()));
DELIMITER ;



-- CALL generate_sales_report(2003,9);
-- SELECT * FROM sales_reports ORDER BY reportid DESC;
-- SELECT * FROM reports_inventory ORDER BY inv_reportid DESC;
-- SELECT * FROM orders;


-- REPORT02: Quantity Ordered Report

DROP TABLE IF EXISTS quantity_ordered_reports;
CREATE TABLE quantity_ordered_reports (
    reportid            INT(10),                 -- Unique identifier for each report
    reportyear          INT(4),
    reportmonth         INT(2),
    productLine         VARCHAR(50),
    productCode         VARCHAR(15),
    country             VARCHAR(50),
    officeCode          VARCHAR(10),
    salesRepNumber      INT,
    quantityOrdered     INT,
    generationdate      DATETIME,               
    PRIMARY KEY (reportid, productCode, officeCode, salesRepNumber)  -- Composite primary key
);

DROP PROCEDURE IF EXISTS generate_quantity_ordered_report;
DELIMITER $$

CREATE PROCEDURE generate_quantity_ordered_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;

    -- Generate a new report id for quantity_ordered_reports by incrementing the maximum report id found in the quantity_ordered_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM quantity_ordered_reports);

    -- Get the month name from the month number
    SET @month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (reportid, generationdate, generatedby, reportdesc, reporttable)
    VALUES (v_reportid, NOW(), CURRENT_USER(), CONCAT('Quantity Ordered Report for ', @month_name, ' ', p_year), 'Quantity Ordered');

    -- Insert summarized monthly report data into quantity_ordered_reports table using the generated report id
    INSERT INTO quantity_ordered_reports (reportid, reportyear, reportmonth, productLine, productCode, country, officeCode, salesRepNumber, quantityOrdered, generationdate)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        pp.productLine,
        p.productCode,
        ofc.country,
        ofc.officeCode,
        sr.employeeNumber AS salesRepNumber,
        SUM(IFNULL(od.quantityOrdered, 0)) AS quantityOrdered,
        NOW() AS generationdate
    FROM    
        orders o
        JOIN orderdetails od ON o.orderNumber = od.orderNumber
        JOIN products p ON od.productCode = p.productCode
        JOIN product_productlines pp ON p.productCode = pp.productCode
        JOIN customers c ON o.customerNumber = c.customerNumber
        JOIN salesrepassignments sa ON c.salesRepEmployeeNumber = sa.employeeNumber
        JOIN offices ofc ON sa.officeCode = ofc.officeCode
        JOIN salesrepresentatives sr ON sa.employeeNumber = sr.employeeNumber
    WHERE   
        o.status IN ('Shipped', 'Completed')
        AND MONTH(o.orderdate) = p_month
        AND YEAR(o.orderdate) = p_year
    GROUP BY 
        pp.productLine, p.productCode, ofc.country, ofc.officeCode, sr.employeeNumber;

END $$
DELIMITER ;


-- Create an event to generate the quantity ordered report every month
DROP EVENT IF EXISTS generate_monthly_quantity_ordered_report;
DELIMITER $$

CREATE EVENT generate_monthly_quantity_ordered_report
ON SCHEDULE EVERY 30 DAY
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    CALL generate_quantity_ordered_report(YEAR(CURDATE()), MONTH(CURDATE()));
END $$
DELIMITER ;



-- Manually call the procedure to test
CALL generate_quantity_ordered_report(2003,11);

-- Check the results in reports_inventory and quantity_ordered_reports
SELECT * FROM quantity_ordered_reports ORDER BY reportid DESC;
SELECT * FROM reports_inventory ORDER BY inv_reportid DESC;

-- REPORT03: Turnaround Time Report

DROP TABLE IF EXISTS turnaroundtime_reports;
CREATE TABLE turnaroundtime_reports (
    reportid            INT(10),                 -- Unique identifier for each report
    reportyear          INT(4),
    reportmonth         INT(2),
    country             VARCHAR(100),
    office              VARCHAR(100),
    AVERAGETURNAROUND   DECIMAL(9,2),
    generationdate      DATETIME,                -- The date when the report was generated
    PRIMARY KEY (reportid, country, office)      -- Composite primary key
);

DROP PROCEDURE IF EXISTS generate_turnaroundtime_report;
DELIMITER $$

CREATE PROCEDURE generate_turnaroundtime_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;

    -- Generate a new report id by incrementing the maximum report id found in turnaroundtime_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM turnaroundtime_reports);

    -- Get the month name from the month number
    SET @month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (reportid, generationdate, generatedby, reportdesc, reporttable)
    VALUES (v_reportid, NOW(), CURRENT_USER(), CONCAT('Turnaround Time Report for ', @month_name, ' ', p_year), 'Turnaround Time');

    -- Insert summarized turnaround time report data into turnaroundtime_reports table using the generated report id
    INSERT INTO turnaroundtime_reports (reportid, reportyear, reportmonth, country, office, AVERAGETURNAROUND, generationdate)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        ofc.country,
        ofc.officeCode AS office,
        AVG(TIMESTAMPDIFF(DAY, o.orderdate, o.shippeddate)) AS AVERAGETURNAROUND,
        NOW() AS generationdate
    FROM    
        orders o
        JOIN customers c ON o.customerNumber = c.customerNumber
        JOIN salesrepassignments sa ON c.salesRepEmployeeNumber = sa.employeeNumber
        JOIN offices ofc ON sa.officeCode = ofc.officeCode
    WHERE   
        o.status IN ('Shipped', 'Completed')
        AND MONTH(o.orderdate) = p_month
        AND YEAR(o.orderdate) = p_year
    GROUP BY 
        ofc.country, ofc.officeCode;

END $$
DELIMITER ;

-- Create an event to generate the turnaround time report every month
DROP EVENT IF EXISTS generate_monthly_turnaroundtime_report;
DELIMITER $$

CREATE EVENT generate_monthly_turnaroundtime_report 
ON SCHEDULE EVERY 5 SECOND
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    CALL generate_turnaroundtime_report(YEAR(CURDATE()), MONTH(CURDATE()));
END $$
DELIMITER ;


-- CALL generate_turnaroundtime_report(2003,11);
-- SELECT * FROM turnaroundtime_reports ORDER BY reportid DESC ;
-- SELECT * FROM reports_inventory ORDER BY inv_reportid DESC ;
-- SELECT * FROM orders;


-- REPORT04: Pricing Variation Report

DROP TABLE IF EXISTS pricing_variation_reports;
CREATE TABLE pricing_variation_reports (
    reportid            INT(10),                 -- Unique identifier for each report
    reportyear          INT(4),
    reportmonth         INT(2),
    product_code        VARCHAR(15),
    product_line        VARCHAR(50),
    pricevariation      DECIMAL(9,2),
    generationdate      DATETIME,                
    PRIMARY KEY (reportid, product_code)         -- Composite primary key
);

DROP PROCEDURE IF EXISTS generate_pricing_variation_report;
DELIMITER $$

CREATE PROCEDURE generate_pricing_variation_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;

    -- Generate a new report id by incrementing the maximum report id found in pricing_variation_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM pricing_variation_reports);

    -- Get the month name from the month number
    SET @month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
    
    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (reportid, generationdate, generatedby, reportdesc, reporttable)
    VALUES (v_reportid, NOW(), CURRENT_USER(), CONCAT('Pricing Variation Report for ', @month_name, ' ', p_year), 'Pricing Variation');

    -- Insert summarized pricing variation data into pricing_variation_reports table using the generated report id
    INSERT INTO pricing_variation_reports (reportid, reportyear, reportmonth, product_code, product_line, pricevariation, generationdate)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        p.productCode,
        pp.productLine,
        ROUND(AVG(od.priceeach - getMSRP_2(p.productCode, o.orderdate)), 2) AS pricevariation,
        NOW() AS generationdate
    FROM    
        orders o
        JOIN orderdetails od ON o.orderNumber = od.orderNumber
        JOIN products p ON od.productCode = p.productCode
        JOIN product_productlines pp ON p.productCode = pp.productCode
    WHERE   
        o.status IN ('Shipped', 'Completed')
        AND MONTH(o.orderdate) = p_month
        AND YEAR(o.orderdate) = p_year
    GROUP BY 
        p.productCode, pp.productLine;
END $$
DELIMITER ;

-- Create an event to generate the pricing variation report every month
DROP EVENT IF EXISTS generate_monthly_pricing_variation_report;
DELIMITER $$

CREATE EVENT generate_monthly_pricing_variation_report
ON SCHEDULE EVERY 5 SECOND
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    CALL generate_pricing_variation_report(YEAR(CURDATE()), MONTH(CURDATE()));
END $$
DELIMITER ;



-- CALL generate_pricing_variation_report(2003,10);
-- SELECT * FROM pricing_variation_reports ORDER BY reportid DESC;
-- SELECT * FROM reports_inventory ORDER BY inv_reportid DESC;



-- ORIGINAL SQL

