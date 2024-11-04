
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
    reportyear INT(4),
    reportmonth INT(2),
    productCode VARCHAR(15),
    productLine VARCHAR(50),
    employeeLastName VARCHAR(50),
    employeeFirstName VARCHAR(50),
    country VARCHAR(50),
    officeCode VARCHAR(10),
    sales DECIMAL(9,2),
    discount DECIMAL(9,2),
    markup DECIMAL(9,2),
    PRIMARY KEY (reportyear, reportmonth, productCode, officeCode)
);
DELIMITER $$

-- REPORT01 (PEGALAN)

CREATE EVENT generate_sales_report 
ON SCHEDULE EVERY 1 MONTH
STARTS '2000-01-01 00:00:00'
DO
BEGIN
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
    WHERE		o.status IN ('Shipped','Completed')
    GROUP BY	reportyear, reportmonth, p.productcode,pp.productline, e.employeeNumber, ofc.officeCode;

END $$
DELIMITER ;




-- REPORT02 (TAN)

DROP TABLE IF EXISTS quantity_ordered_reports;
CREATE TABLE quantity_ordered_reports (
	reportid		INT(10),
	reportyear		INT(4),
    reportmonth 	INT(2),
    productLine 	VARCHAR(50),
    productCode		VARCHAR(15),
    country			VARCHAR(50),
    officeCode		VARCHAR(10),
    salesRepNumber	INT,
    totalQuantityOrdered INT,
    PRIMARY KEY (reportid, reportyear, reportmonth)
);
DELIMITER $$


CREATE EVENT generate_quantity_ordered_report 
ON SCHEDULE EVERY 1 MONTH
STARTS '2000-01-01 00:00:00'
DO
BEGIN
    -- Insert report data into quantity_ordered_reports table
    INSERT INTO quantity_ordered_reports (reportyear, reportmonth, productLine, productCode, country, officeCode, salesRepNumber, totalQuantityOrdered)
    SELECT		YEAR(o.orderdate)	as	reportyear,
			MONTH(o.orderdate)	as	reportmonth,
            p.productCode,
            pp.productLine,
            e.lastName, e.firstName,
            ofc.country, ofc.officeCode,     
            SUM(od.quantityordered) AS QUANTITYORDERED
FROM		orders o	JOIN	orderdetails od			ON	o.orderNumber=od.orderNumber
						JOIN	products p				ON	od.productCode=p.productCode
                        JOIN	product_productlines pp	ON	p.productCode=pp.productCode
                        JOIN	customers c 			ON	o.customerNumber=c.customerNumber
                        JOIN	salesrepassignments sa	ON	c.salesRepEmployeeNumber=sa.employeeNumber
                        JOIN	offices ofc				ON	sa.officeCode=ofc.officeCode
                        JOIN	salesrepresentatives sr	ON	sa.employeeNumber=sr.employeeNumber
                        JOIN	employees e				ON	sr.employeeNumber=e.employeeNumber
WHERE		o.status IN ('Shipped','Completed')
GROUP BY	reportyear, reportmonth, p.productcode,pp.productline, e.employeeNumber, ofc.officeCode;

END $$
DELIMITER ;





-- REPORT03
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








-- REPORT04
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


-- ORIGINAL SQL

DROP TABLE IF EXISTS reports_inventory;
CREATE TABLE reports_inventory (
	reportid		INT(10)	AUTO_INCREMENT,
    generationdate	DATETIME,
    generatedby		VARCHAR(100),
    reportdesc		VARCHAR(100),
    PRIMARY KEY (reportid)
);
