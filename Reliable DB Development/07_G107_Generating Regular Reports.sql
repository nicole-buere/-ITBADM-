
DROP TABLE IF EXISTS reports_inventory;
CREATE TABLE reports_inventory (
	reportid		INT(10)	AUTO_INCREMENT,
    generationdate	DATETIME,
    generatedby		VARCHAR(100),
    reportdesc		VARCHAR(100),
    PRIMARY KEY (reportid)
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

DROP TABLE IF EXISTS sales_reports;
CREATE TABLE sales_reports (
    reportid            INT(10) AUTO_INCREMENT,
    reportyear          INT(4),
    reportmonth         INT(2),
    productCode         VARCHAR(15),
    productLine         VARCHAR(50),
    employeeLastName    VARCHAR(50),
    employeeFirstName   VARCHAR(50),
    country             VARCHAR(50),
    officeCode          VARCHAR(10),
    SALES               DECIMAL(9,2),
    DISCOUNT            DECIMAL(9,2),
    MARKUP              DECIMAL(9,2),
    PRIMARY KEY (reportid)
);


-- REPORT01

DROP PROCEDURE IF EXISTS generate_sales_report;
DELIMITER $$
CREATE PROCEDURE generate_sales_report()
BEGIN
    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc)
    VALUES (NOW(), USER(), CONCAT('Sales Report for ', MONTHNAME(NOW()), ' ', YEAR(NOW())));
    -- Insert monthly report data into sales_reports table
    INSERT INTO sales_reports (reportyear, reportmonth, productCode, productLine, employeeLastName, employeeFirstName, country, officeCode, sales, discount, markup)
	SELECT		YEAR(o.orderdate)	as	reportyear,
				MONTH(o.orderdate)	as	reportmonth,
				p.productCode,
				pp.productLine,
				e.lastName, e.firstName,
				ofc.country, ofc.officeCode,
				ROUND(SUM(od.priceEach*od.quantityOrdered),2)	as	SALES,
				ROUND(SUM(IF(od.priceEach < getMSRP_2(p.productCode,o.orderdate), getMSRP_2(p.productCode,o.orderdate)-od.priceEach, 0)),2)  AS	DISCOUNT,
				ROUND(SUM(IF(od.priceEach >= getMSRP_2(p.productCode,o.orderdate), od.priceEach-getMSRP_2(p.productCode,o.orderdate), 0)),2) AS	MARKUP
	FROM		orders o	JOIN	orderdetails od			ON	o.orderNumber=od.orderNumber
							JOIN	products p				ON	od.productCode=p.productCode
							JOIN	product_productlines pp	ON	p.productCode=pp.productCode
							JOIN	customers c 			ON	o.customerNumber=c.customerNumber
							JOIN	salesrepassignments sa	ON	c.salesRepEmployeeNumber=sa.employeeNumber
							JOIN	offices ofc				ON	sa.officeCode=ofc.officeCode
							JOIN	salesrepresentatives sr	ON	sa.employeeNumber=sr.employeeNumber
							JOIN	employees e				ON	sr.employeeNumber=e.employeeNumber
	WHERE		o.`status` IN ('Shipped','Completed')
	GROUP BY	reportyear, reportmonth, p.productcode,pp.productline, e.employeeNumber, ofc.officeCode;

END $$
DELIMITER ;


DROP EVENT IF EXISTS generate_monthly_sales_report;
DELIMITER $$
CREATE EVENT generate_monthly_sales_report 
	ON SCHEDULE EVERY 1 MONTH
	STARTS '2024-10-31 00:00:00'
	DO
	CALL generate_sales_report();
DELIMITER ;



-- CALL generate_sales_report();
-- SELECT * FROM reports_inventory ORDER BY generationdate DESC LIMIT 1;
-- SELECT * FROM sales_reports ORDER BY reportid DESC LIMIT 1; ;



-- REPORT02

DROP TABLE IF EXISTS quantity_ordered_reports;
CREATE TABLE quantity_ordered_reports (
    reportid            INT(10) AUTO_INCREMENT,
    reportyear          INT(4),
    reportmonth         INT(2),
    productLine         VARCHAR(50),
    productCode         VARCHAR(15),
    country             VARCHAR(50),
    officeCode          VARCHAR(10),
    salesRepNumber      INT,
    quantityOrdered     INT,
    PRIMARY KEY (reportid)
);


DROP PROCEDURE IF EXISTS generate_quantity_ordered_report;
DELIMITER $$

CREATE PROCEDURE generate_quantity_ordered_report()
BEGIN
    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc)
    VALUES (NOW(), USER(), CONCAT('Quantity Ordered Report for ', MONTHNAME(NOW()), ' ', YEAR(NOW())));

    -- Insert report data into quantity_ordered_reports table
    INSERT INTO quantity_ordered_reports (reportyear, reportmonth, productLine, productCode, country, officeCode, salesRepNumber, quantityOrdered)
    SELECT  
        YEAR(o.orderdate) AS reportyear,
        MONTH(o.orderdate) AS reportmonth,
        pp.productLine,
        p.productCode,
        ofc.country,
        ofc.officeCode,
        sr.employeeNumber AS salesRepNumber,
        SUM(od.quantityOrdered) AS quantityOrdered
    FROM    
        orders o
        LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
        LEFT JOIN products p ON od.productCode = p.productCode
        LEFT JOIN product_productlines pp ON p.productCode = pp.productCode
        LEFT JOIN customers c ON o.customerNumber = c.customerNumber
        LEFT JOIN salesrepassignments sa ON c.salesRepEmployeeNumber = sa.employeeNumber
        LEFT JOIN offices ofc ON sa.officeCode = ofc.officeCode
        LEFT JOIN salesrepresentatives sr ON sa.employeeNumber = sr.employeeNumber
        LEFT JOIN employees e ON sr.employeeNumber = e.employeeNumber
    WHERE   
        o.status IN ('Shipped', 'Completed')
    GROUP BY 
        reportyear, reportmonth, p.productCode, pp.productLine, ofc.officeCode, sr.employeeNumber;

END $$

DELIMITER ;



DROP EVENT IF EXISTS generate_monthly_quantity_ordered_report;
DELIMITER $$
CREATE EVENT generate_monthly_quantity_ordered_report 
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-10-31 00:00:00'
DO
CALL generate_quantity_ordered_report;

DELIMITER ;

-- CALL generate_quantity_ordered_report;
-- SELECT * FROM reports_inventory ORDER BY generationdate DESC LIMIT 1;
-- SELECT * FROM quantity_ordered_reports ORDER BY reportid DESC LIMIT 1;


-- REPORT03

DROP TABLE IF EXISTS turnaroundtime_reports;
CREATE TABLE turnaroundtime_reports (
    reportid        INT(10) AUTO_INCREMENT,
    reportyear      INT(4),
    reportmonth     INT(2),
    country         VARCHAR(100),
    office          VARCHAR(100),
    AVERAGETURNAROUND  DECIMAL(9,2),
    PRIMARY KEY (reportid)
);


DROP PROCEDURE IF EXISTS generate_turnaroundtime_report;
DELIMITER $$

CREATE PROCEDURE generate_turnaroundtime_report()
BEGIN
    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc)
    VALUES (NOW(), USER(), CONCAT('Turnaround Time Report for ', MONTHNAME(NOW()), ' ', YEAR(NOW())));

    INSERT INTO turnaroundtime_reports (reportyear, reportmonth, country, office, AVERAGETURNAROUND)
    SELECT		YEAR(o.orderdate)	as	reportyear,
                MONTH(o.orderdate)	as	reportmonth,
                ofc.country, ofc.officeCode,
                AVG(TIMESTAMPDIFF(DAY,o.orderdate,o.shippeddate)) AS	AVERAGETURNAROUND
    FROM		orders o	JOIN	orderdetails od			ON	o.orderNumber=od.orderNumber
                            JOIN	products p				ON	od.productCode=p.productCode
                            JOIN	product_productlines pp	ON	p.productCode=pp.productCode
                            JOIN	customers c 			ON	o.customerNumber=c.customerNumber
                            JOIN	salesrepassignments sa	ON	c.salesRepEmployeeNumber=sa.employeeNumber
                            JOIN	offices ofc				ON	sa.officeCode=ofc.officeCode
                            JOIN	salesrepresentatives sr	ON	sa.employeeNumber=sr.employeeNumber
                            JOIN	employees e				ON	sr.employeeNumber=e.employeeNumber
    WHERE		o.status IN ('Shipped','Completed')
    GROUP BY	reportyear, reportmonth, ofc.officeCode;

END $$
DELIMITER ;

DROP EVENT IF EXISTS generate_monthly_turnaroundtime_report;
DELIMITER $$

CREATE EVENT generate_monthly_turnaroundtime_report 
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-10-31 00:00:00'
DO
CALL generate_turnaroundtime_report;
DELIMITER ;

-- CALL generate_turnaroundtime_report;
-- SELECT * FROM reports_inventory ORDER BY generationdate DESC LIMIT 1;
-- SELECT * FROM turnaroundtime_reports ORDER BY reportid DESC LIMIT 1;

-- REPORT04 

DROP TABLE IF EXISTS pricing_variation_reports;
CREATE TABLE  pricing_variation_reports (
	reportid						INT(10) AUTO_INCREMENT,
	reportyear						INT(4),
    reportmonth 					INT(2),
    product_code					VARCHAR(15),
    product_line					VARCHAR(50),
    pricevariation					DECIMAL(9,2),
    PRIMARY KEY (reportid)
);

DROP PROCEDURE IF EXISTS generate_pricing_variation_report;
DELIMITER $$

CREATE PROCEDURE generate_pricing_variation_report()
BEGIN
    -- Insert a record into reports_inventory for tracking
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc)
    VALUES (NOW(), USER(), CONCAT('Pricing Variation Report for ', MONTHNAME(NOW()), ' ', YEAR(NOW())));
    -- Insert calculated pricing variation data into pricing_variation_reports table
    INSERT INTO pricing_variation_reports (reportyear, reportmonth, product_code, product_line, pricevariation)
    SELECT		YEAR(o.orderdate)	as	reportyear,
                MONTH(o.orderdate)	as	reportmonth,
                p.productCode,
                pp.productLine,
                ROUND(AVG(od.priceeach-getMSRP_2(p.productCode,o.orderdate)),2) as PRICEVARIATION
    FROM		orders o	JOIN	orderdetails od			ON	o.orderNumber=od.orderNumber
                            JOIN	products p				ON	od.productCode=p.productCode
                            JOIN	product_productlines pp	ON	p.productCode=pp.productCode
                            JOIN	customers c 			ON	o.customerNumber=c.customerNumber
                            JOIN	salesrepassignments sa	ON	c.salesRepEmployeeNumber=sa.employeeNumber
                            JOIN	offices ofc				ON	sa.officeCode=ofc.officeCode
                            JOIN	salesrepresentatives sr	ON	sa.employeeNumber=sr.employeeNumber
                            JOIN	employees e				ON	sr.employeeNumber=e.employeeNumber
    WHERE		o.status IN ('Shipped','Completed')
    GROUP BY	reportyear, reportmonth, p.productcode,pp.productline;

END $$
DELIMITER ;

DROP EVENT IF EXISTS generate_monthly_pricing_variation_report;
DELIMITER $$

CREATE EVENT generate_monthly_pricing_variation_report
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-10-31 00:00:00'
DO
CALL generate_pricing_variation_report;
DELIMITER ;

-- CALL generate_pricing_variation_report;
-- SELECT * FROM reports_inventory ORDER BY generationdate DESC LIMIT 1;
-- SELECT * FROM pricing_variation_reports ORDER BY reportid DESC LIMIT 1;




-- ORIGINAL SQL

