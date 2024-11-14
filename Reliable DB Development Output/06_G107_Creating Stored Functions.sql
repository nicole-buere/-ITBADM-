
-- Stored Function Implementation Script
-- Extended DB Sales
-- This script will create stored functions in the Database to be used in the
-- implementation of business rules

-- Getting a specific MSRP for a product

-- For discontinued products
-- products		     - to determine if the product is Current or Discontinued. And if its discontinued, we return an ERROR

-- For wholesale products
-- products		     - to determine if the product is Current or Discontinued
-- current_products  - to determine if the product is retail or wholesale
-- product_wholesale - to get the MSRP of the wholesale product

-- For retail products
-- products			- to determine if the product is Current of Discontinued
-- current_products	- to determine if the product is retail or wholesale
-- product_retail	- to read the retail product
-- product_pricing	- to get the MSRP applicable depending on the date, if the price is not available, we return an ERROR

-- To create a function instead that will accept one  value PRODUCT CODE and returns the MSRP

DROP FUNCTION IF EXISTS getMSRP;
DELIMITER $$
CREATE FUNCTION getMSRP (param_productCode VARCHAR(15)) 
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
        WHERE	NOW() BETWEEN startdate AND enddate
        AND		productCode = param_productCode;
        
        -- Check if the price was available
        IF (var_MSRP IS NULL) THEN
			SET errormessage := CONCAT("MSRP of the product does not exist yet given the date of ", NOW());
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

-- PART 4B.C (PEGALAN)

DROP VIEW IF EXISTS view_product_msrp;
CREATE VIEW view_product_msrp AS
SELECT 
    p.productCode,
    p.productName,
    getMSRP(p.productCode) AS msrp
FROM 
    products p;

GRANT SELECT ON view_product_msrp TO salesmodule, inventorymodule, paymentmodule;
-- Create a function that checks for the valid values of status
-- 4A.C
DROP FUNCTION IF EXISTS isStatusValid;
DELIMITER $$
CREATE FUNCTION isStatusValid (param_status VARCHAR(15))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	IF (param_status IN ("In Process","Shipped","Disputed","Resolved","Completed","Cancelled")) THEN
		RETURN TRUE;
	ELSE 
		RETURN FALSE;
    END IF;
END $$
DELIMITER ;

-- Create a Function that checks if the old status to the new status is VALID
-- based on the rules in 4A.C

DROP FUNCTION IF EXISTS isValidStatus;
DELIMITER $$
CREATE FUNCTION isValidStatus(param_oldstatus VARCHAR(15), param_newstatus VARCHAR(15)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE errormessage VARCHAR(200);
    
    -- Allow same status transitions
    IF (param_oldstatus = param_newstatus) THEN 
        RETURN TRUE;
    END IF;
    
    -- Validate both statuses
    IF (NOT isStatusValid(param_oldstatus) OR NOT isStatusValid(param_newstatus)) THEN
        SET errormessage := CONCAT("Either ", param_oldstatus, " or ", param_newstatus, " is not a valid status");
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;    
    END IF;

    -- Transition Rules
    CASE param_oldstatus
        WHEN 'In Process' THEN
            IF (param_newstatus NOT IN ('Shipped', 'Cancelled')) THEN
                SET errormessage := CONCAT("Status from ", param_oldstatus, " to ", param_newstatus, " is not allowed.");
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
            END IF;

        WHEN 'Shipped' THEN
            IF (param_newstatus NOT IN ('Disputed', 'Completed')) THEN
                SET errormessage := CONCAT("Status from ", param_oldstatus, " to ", param_newstatus, " is not allowed.");
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
            END IF;

        WHEN 'Disputed' THEN
            IF (param_newstatus NOT IN ('Resolved', 'Cancelled')) THEN
                SET errormessage := CONCAT("Status from ", param_oldstatus, " to ", param_newstatus, " is not allowed.");
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
            END IF;

        WHEN 'Resolved' THEN
            IF (param_newstatus NOT IN ('Completed', 'Cancelled')) THEN
                SET errormessage := CONCAT("Status from ", param_oldstatus, " to ", param_newstatus, " is not allowed.");
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
            END IF;

        WHEN 'Completed' THEN
            SET errormessage := 'No status changes are allowed once the order is completed.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
            
		 WHEN 'Cancelled' THEN
            SET errormessage := 'No status changes are allowed once the order is cancelled.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
		
        ELSE
            -- Invalid old status case (shouldn't occur if validation passes)
            SET errormessage := CONCAT("Invalid old status: ", param_oldstatus);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END CASE;

    RETURN TRUE;
END $$
DELIMITER ;


-- PART 4A.D (KRUEGER)
-- Check if an order is shipped
DROP FUNCTION IF EXISTS isOrderShipped;
DELIMITER $$
CREATE FUNCTION isOrderShipped(orderNumber INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE orderStatus VARCHAR(20);
    
    -- Fetch the current status of the order
    SELECT status INTO orderStatus
    FROM orders
    WHERE orders.orderNumber = orderNumber;
    
    -- Return TRUE if the status is "Shipped"
    IF orderStatus = 'Shipped' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$
DELIMITER ;

-- Check if only quantityOrdered and priceEach are being updated
DROP FUNCTION IF EXISTS isUpdateValid;
DELIMITER $$

CREATE FUNCTION isUpdateValid(old_quantity INT, new_quantity INT, old_price DECIMAL(10,2), new_price DECIMAL(10,2))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    -- Allow the update if either quantityOrdered or priceEach are being modified
    IF old_quantity != new_quantity OR old_price != new_price THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$
DELIMITER ;


-- Check if referenceNo can be updated (only if the order is "Shipped")
DROP FUNCTION IF EXISTS canUpdateReference;
DELIMITER $$

CREATE FUNCTION canUpdateReference(orderNumber INT, old_ref VARCHAR(20), new_ref VARCHAR(20))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    -- Check if the reference number is being updated
    IF old_ref != new_ref THEN
        -- Allow update only if order status is "Shipped"
        IF isOrderShipped(orderNumber) THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    ELSE
        -- No change in reference number
        RETURN TRUE;
    END IF;
END$$
DELIMITER ;


-- PART 4A.F (PEGALAN)
DROP PROCEDURE IF EXISTS procedure_auto_cancel_unshipped_orders;
DELIMITER $$

CREATE PROCEDURE procedure_auto_cancel_unshipped_orders()
BEGIN
    -- Update orders that are more than 7 days old and have not been shipped
    UPDATE orders
    SET `status` = 'Cancelled',
        comments = CONCAT(IFNULL(comments, ''), ' System auto-cancelled the order due to delay in shipping.')
    WHERE `status` = 'In Process'
      AND DATEDIFF(NOW(), orderDate) > 7;
END $$

DELIMITER ;


DROP EVENT IF EXISTS auto_cancel_unshipped_orders;
DELIMITER $$

CREATE EVENT auto_cancel_unshipped_orders
ON SCHEDULE EVERY 1 DAY
DO
CALL procedure_auto_cancel_unshipped_orders();
$$

DELIMITER ;

-- PART 4B.A (BUERE) 
DROP PROCEDURE IF EXISTS add_product;
DELIMITER $$

CREATE PROCEDURE add_product(
    IN v_productCode VARCHAR(15),
    IN v_productName VARCHAR(70),
    IN v_productScale VARCHAR(10),
    IN v_productVendor VARCHAR(50),
    IN v_productDescription TEXT,
    IN v_buyPrice DOUBLE,
    IN v_productType ENUM('R', 'W'),
    IN v_quantityInStock SMALLINT,
    IN v_MSRP DECIMAL(9, 2),
    IN v_productLine VARCHAR(50),
    IN v_end_username VARCHAR(45),
    IN v_end_userreason VARCHAR(45)
)
BEGIN
    DECLARE latest_pCode VARCHAR(15);
    DECLARE end_username VARCHAR(45) DEFAULT 'System';
    DECLARE end_userreason VARCHAR(45) DEFAULT 'Automated system entry';

    -- check if user input is NULL or empty, and set defaults if so
    SET end_username = IFNULL(v_end_username, 'System');
    SET end_userreason = IFNULL(v_end_userreason, 'Automated system entry');

    -- Check if quantityInStock is greater than 0
    IF v_quantityInStock <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity in stock must be greater than 0';
    END IF;

    -- insert into products table and automatically categorize it as a current product ('C')
    INSERT INTO products (productCode, productName, productScale, productVendor, productDescription, buyPrice, product_category, latest_audituser, latest_activityreason)
    VALUES (v_productCode, v_productName, v_productScale, v_productVendor, v_productDescription, v_buyPrice, 'C', end_username, end_userreason);

    -- retrieve the latest added product code from audit_products 
    SELECT productCode INTO latest_pCode
    FROM audit_products
    WHERE activity = 'C' 
    AND activity_timestamp = (SELECT MAX(activity_timestamp) FROM audit_products) 
    LIMIT 1;

    -- insert product into current_products 
    INSERT INTO current_products (productCode, product_type, quantityInStock)
    VALUES (latest_pCode, v_productType, v_quantityInStock);

    -- add created product to either product_retail or product_wholesale, based on its type
    IF v_productType = 'R' THEN
        INSERT INTO product_retail (productCode)
        VALUES (latest_pCode);
        
        INSERT INTO product_pricing (productCode, startDate, endDate, MSRP)
        VALUES (latest_pCode, DATE(NOW()), DATE(DATE_ADD(NOW(), INTERVAL 7 DAY)), v_MSRP);
    ELSE
        INSERT INTO product_wholesale (productCode, MSRP)
        VALUES (latest_pCode, v_MSRP);
    END IF;

    -- associate the product with a product line in the product_productlines table
    INSERT INTO product_productlines (productCode, productLine)
    VALUES (latest_pCode, v_productLine);
END $$
DELIMITER ;

-- Part 4C.D
DROP PROCEDURE IF EXISTS auto_reassign_salesRep;
DELIMITER $$

CREATE PROCEDURE auto_reassign_salesRep(IN p_employeeNumber INT)
BEGIN
    DECLARE v_officeCode INT;
    DECLARE v_quota DECIMAL(10, 2);
    DECLARE v_quota_utilized DECIMAL(10, 2);

    -- retrieve the latest expired assignment for the employee 
    SELECT officeCode, quota, IFNULL(quota_utilized, 0)
    INTO v_officeCode, v_quota, v_quota_utilized
    FROM salesrepassignments
    WHERE employeeNumber = p_employeeNumber
      AND endDate = CURDATE()
    ORDER BY endDate DESC
    LIMIT 1;

    -- calculate the new quota by deducting the utilized quota from the previous assignment
    SET v_quota = v_quota - v_quota_utilized;

    -- insert the new assignment into salesrepassignments
    INSERT INTO salesrepassignments (
        employeeNumber,
        officeCode,
        startDate,
        endDate,
        quota,
        quota_utilized,
        reassigned_by 
    )
    VALUES (
        p_employeeNumber,
        v_officeCode,
        NOW(),
        DATE_ADD(NOW(), INTERVAL 1 WEEK),
        v_quota,       -- Adjusted quota for the new assignment
        0,             -- Reset quota utilized for the new assignment
        'System'
    );

    -- log activity in the audit table
    INSERT INTO audit_salesrepassignments (
        employeeNumber,
        officeCode,
        startDate,
        endDate,
        quota,
        quota_utilized,
        reassigned_by,
        action
    )
    VALUES (
        p_employeeNumber,
        v_officeCode,
        NOW(),
        DATE_ADD(NOW(), INTERVAL 7 DAY),
        v_quota,
        0,
        'System',
        'REASSIGNMENT'
    );
END$$
DELIMITER ;