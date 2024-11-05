-- Pricing Variation Report Table
DROP TABLE IF EXISTS pricingVariation_reports;
CREATE TABLE  pricingVariation_reports (
	report_id						INT(10),
	report_year						INT(4),
    report_month 					INT(2),
    report_day						INT(2),
    product							VARCHAR(70),
    product_line					VARCHAR(50),
    pricing_variationPercentage		DECIMAL(9,2),
    PRIMARY KEY (report_id, report_year, report_month, report_day, product, product_line)
);

-- Stored procedure to create Pricing Variation Report
DROP PROCEDURE IF EXISTS generate_pricingVariation_report;
DELIMITER $$
CREATE PROCEDURE generate_pricingVariation_report (param_year INT(4), param_month INT(2), param_generatedby VARCHAR(100)) 
BEGIN
	DECLARE report_description	VARCHAR(100);
    DECLARE v_reportid			INT(10);
    SET report_description = CONCAT('Pricing Variation for the Month of ', param_month, ' and year ', param_year);
    
    INSERT INTO reports_inventory (generationdate, generatedby, reportdesc) 
    VALUES (NOW(), param_generatedby, report_description);
    SELECT MAX(reportid) INTO v_reportid FROM reports_inventory;		
    
    INSERT INTO pricingVariation_reports (report_year, report_month, report_day, product, product_line, pricing_variationPercentage)
	SELECT 		param_year 	as 	report_year,
				param_month as 	report_month,
                param_day 	as	report_day,
                pl.productLine,
                p.productName,
                (AVG(pp.current_price) - AVG(pp.previous_price)) / AVG(pp.previous_price) * 100 as pricing_variationPercentage
	FROM 		products p JOIN product_pricing pp ON p.productCode = pp.productCode
    WHERE		YEAR(pp.priceDate) = param_year
	AND			MONTH(pp.priceDate) = param_month
	AND			DAY(pp.priceDate) = param_day
    GROUP BY 	YEAR(pp.priceDate), MONTH(pp.priceDate), DAY(pp.priceDate);
END $$
DELIMITER ;


-- Temporal Trigger
DROP EVENT IF EXISTS generate_salesreport;
DELIMITER $$
CREATE EVENT generate_salesreport 
ON SCHEDULE EVERY 10 SECOND
DO
BEGIN
	CALL  generate_pricingVariation_report (YEAR(NOW()), MONTH(NOW()), "System-Generated");
END $$
DELIMITER ;
