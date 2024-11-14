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
    generatedby         VARCHAR(100),            -- Who generated the report
    reportdesc          VARCHAR(200),            -- Description of the report
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
    
    -- Insert summarized monthly report data into sales_reports table using the generated report id
    INSERT INTO sales_reports (reportid, reportyear, reportmonth, generationdate, generatedby, reportdesc, productCode, productLine, employeeLastName, employeeFirstName, country, officeCode, orderDate, sales, discount, markup)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        NOW() AS generationdate,
        IF(CURRENT_USER() = 'root@localhost', 'System', CURRENT_USER()) AS generatedby,
        CONCAT('Sales, Markups, and Discounts Summary Report for ', @month_name, ' ', p_year) AS reportdesc,
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
    -- CALL generate_sales_report(2003,9);
END$$
DELIMITER ;



-- SELECT * FROM sales_reports ORDER BY reportid DESC;
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
    generationdate      DATETIME,                -- Date and time the report was generated
    generatedby         VARCHAR(100),            -- Who generated the report
    reportdesc          VARCHAR(200),            -- Description of the report
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

    -- Insert summarized monthly report data into quantity_ordered_reports table using the generated report id
    INSERT INTO quantity_ordered_reports (reportid, reportyear, reportmonth, generationdate, generatedby, reportdesc, productLine, productCode, country, officeCode, salesRepNumber, quantityOrdered)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        NOW() AS generationdate,
        IF(CURRENT_USER() = 'root@localhost', 'System', CURRENT_USER()) AS generatedby,
        CONCAT('Quantity Ordered Report for ', @month_name, ' ', p_year) AS reportdesc,
        pp.productLine,
        p.productCode,
        ofc.country,
        ofc.officeCode,
        sr.employeeNumber AS salesRepNumber,
        SUM(IFNULL(od.quantityOrdered, 0)) AS quantityOrdered
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
    -- CALL generate_quantity_ordered_report(2004, 11);
END $$
DELIMITER ;


-- Check the results in quantity_ordered_reports
-- SELECT * FROM quantity_ordered_reports ORDER BY reportid DESC;


-- REPORT03: Turnaround Time Report

DROP TABLE IF EXISTS turnaroundtime_reports;
CREATE TABLE turnaroundtime_reports (
    reportid            INT(10),                 -- Unique identifier for each report
    entryid             INT(10) AUTO_INCREMENT,  -- Unique identifier for each row
    reportyear          INT(4),
    reportmonth         INT(2),
    country             VARCHAR(100),
    office              VARCHAR(100),
    AVERAGETURNAROUND   DECIMAL(9,2),
    PRIMARY KEY (entryid)                       -- Use entryid as the primary key
);

DROP PROCEDURE IF EXISTS generate_turnaroundtime_report;
DELIMITER $$

CREATE PROCEDURE generate_turnaroundtime_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;
    DECLARE v_row_count INT;
    DECLARE v_month_name VARCHAR(20);

    -- Generate a new report id for turnaroundtime_reports by incrementing the maximum report id found in the turnaroundtime_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM turnaroundtime_reports);

    -- Get the month name from the month number
    SET v_month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
    
    -- Insert summarized turnaround time report data into turnaroundtime_reports table using the generated report id
    INSERT INTO turnaroundtime_reports (reportid, reportyear, reportmonth, country, office, AVERAGETURNAROUND)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        ofc.country,
        ofc.officeCode AS office,
        AVG(TIMESTAMPDIFF(DAY, o.orderdate, o.shippeddate)) AS AVERAGETURNAROUND
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
    
    -- Get the number of rows inserted
    SET v_row_count = ROW_COUNT();

    -- If no rows were inserted, signal an error
    IF v_row_count = 0 THEN
        SET @error_message = CONCAT('No entries found for ', v_month_name, ' ', p_year);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
    END IF;

END $$
DELIMITER ;




-- Create an event to generate the turnaround time report every month
DROP EVENT IF EXISTS generate_monthly_turnaroundtime_report;
DELIMITER $$

CREATE EVENT generate_monthly_turnaroundtime_report 
ON SCHEDULE EVERY 30 DAY
STARTS '2024-10-31 00:00:00'
DO
BEGIN
	CALL generate_turnaroundtime_repor(YEAR(CURDATE()), MONTH(CURDATE()));
    -- CALL generate_turnaroundtime_report(2003,9);
END $$
DELIMITER ;


-- CALL generate_turnaroundtime_report(2003,11);
-- SELECT * FROM turnaroundtime_reports ORDER BY reportid DESC ;
-- SELECT * FROM orders;


-- REPORT04: Pricing Variation Report

DROP TABLE IF EXISTS pricing_variation_reports;
CREATE TABLE pricing_variation_reports (
    reportid            INT(10),                 -- Unique identifier for each report
    entryid             INT(10) AUTO_INCREMENT,  -- Unique identifier for each row
    reportyear          INT(4),
    reportmonth         INT(2),
    product_code        VARCHAR(15),
    product_line        VARCHAR(50),
    pricevariation      DECIMAL(9,2),
    PRIMARY KEY (entryid)                       -- Use entryid as the primary key
);

DROP PROCEDURE IF EXISTS generate_pricing_variation_report;
DELIMITER $$

CREATE PROCEDURE generate_pricing_variation_report(IN p_year INT, IN p_month INT)
BEGIN
    DECLARE v_reportid INT;
    DECLARE v_row_count INT;
    DECLARE v_month_name VARCHAR(20);

    -- Generate a new report id by incrementing the maximum report id found in pricing_variation_reports table
    SET v_reportid = (SELECT IFNULL(MAX(reportid), 0) + 1 FROM pricing_variation_reports);

    -- Get the month name from the month number
    SET v_month_name = ELT(p_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
    
    -- Insert summarized pricing variation data into pricing_variation_reports table using the generated report id
    INSERT INTO pricing_variation_reports (reportid, reportyear, reportmonth, product_code, product_line, pricevariation)
    SELECT  
        v_reportid AS reportid,
        p_year AS reportyear,
        p_month AS reportmonth,
        p.productCode,
        pp.productLine,
        ROUND(AVG(od.priceeach - getMSRP_2(p.productCode, o.orderdate)), 2) AS pricevariation
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
    
    -- Get the number of rows inserted
    SET v_row_count = ROW_COUNT();

    -- If no rows were inserted, signal an error
    IF v_row_count = 0 THEN
        SET @error_message = CONCAT('No entries found for ', v_month_name, ' ', p_year);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
    END IF;

END $$
DELIMITER ;


-- Create an event to generate the pricing variation report every month
DROP EVENT IF EXISTS generate_monthly_pricing_variation_report;
DELIMITER $$

CREATE EVENT generate_monthly_pricing_variation_report
ON SCHEDULE EVERY 30 DAY
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    CALL generate_pricing_variation_report(YEAR(CURDATE()), MONTH(CURDATE()));
    -- CALL generate_pricing_variation_report(2003,10);
END $$
DELIMITER ;



-- CALL generate_pricing_variation_report(2003,10);
-- SELECT * FROM pricing_variation_reports ORDER BY reportid DESC;



-- ORIGINAL SQL

