-- by Josef Michael T. Tan

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

DROP PROCEDURE IF EXISTS generate_quantityreport;
DELIMITER $$
CREATE PROCEDURE generate_quantityreport (param_year INT(4), param_month INT(2), param_generatedby VARCHAR(100), param_productLine VARCHAR(50), param_productCode VARCHAR(15),
										  param_country VARCHAR(50), param_officeCode VARCHAR(50), param_salesRepNumber INT)
BEGIN
	DECLARE report_description	VARCHAR(100);
    DECLARE v_reportid			INT(10);
    SET report_description = CONCAT('Quantity Ordered Report for the Month of ', param_month, ' and year ', param_year);
    
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc) VALUES (NOW(), param_generatedby, report_description);
    SELECT MAX(reportid) INTO v_reportid FROM reports_inventory;

	INSERT INTO quantity_ordered_reports 
		SELECT		v_reportid,
					YEAR(orderdate)		as reportyear, 
					MONTH(orderdate)	as reportmonth, 
                    productLine,
                    od.productCode as productCode,
                    ofc.country as country,
                    ofc.officeCode as officeCode,
                    salesRepEmployeeNumber as salesRepNumber,
					SUM(quantityOrdered) as totalQuantityOrdered
		FROM		orderdetails od 
			JOIN orders o ON od.orderNumber=o.orderNumber
            JOIN customers c ON o.customerNumber=c.customerNumber
			JOIN offices ofc ON c.officeCode=ofc.officeCode
            JOIN product_productlines pl ON od.productCode=pl.productCode
		WHERE		param_productLine = productLine
        AND			param_productCode = productCode
        AND			param_country = country
        AND 		param_officeCode = officeCode
        AND			param_salesRepNumber = salesRepEmployeeNumber
		AND			YEAR(orderdate)  = param_year
		AND			MONTH(orderdate) = param_month
		GROUP BY	YEAR(orderdate), MONTH(orderdate);
END $$
DELIMITER ;

-- test call for quantity report procedure
CALL generate_quantityreport (2024, 10, "SYSTEM", "Classic Cars", "S10_1949", "USA", 1, 1002);