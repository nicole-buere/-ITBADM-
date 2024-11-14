
-- Business Logic Implementation Script
-- Extended DB Sales
-- This script will create mechanisms in the Database to implement the
-- business rules to be applied on the data within extended DB Sales

-- TRIGGERS ON ORDER_DETAILS

DROP TRIGGER IF EXISTS orderdetails_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER `orderdetails_BEFORE_INSERT` BEFORE INSERT ON `orderdetails` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    
    SET new.referenceno = NULL;
    -- Check if the quantity ordered will make the inventory go below 0;
    
    IF ((SELECT quantityInStock-new.quantityOrdered FROM current_products WHERE productCode = new.productCode) < 0) THEN
		SET errormessage = CONCAT("The quantity being ordered for ", new.productCode, " will make the inventory quantity go below zero");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Auto generation of orderline numbers
    IF ((SELECT MAX(orderlinenumber)+1 FROM orderdetails WHERE ordernumber = new.ordernumber) IS NULL) THEN
		SET new.orderlinenumber = 1;
	ELSE 
		SET new.orderlinenumber = (SELECT MAX(orderlinenumber)+1 FROM orderdetails WHERE ordernumber = new.ordernumber);
    END IF;
    
    -- CHECK FOR THE consistency of the price to 20% MSRP discount and at most 100% MSRP
    -- This is not something appropriate to be coded in pure trigger
    -- This rule involved a complicated access to MSRP, and such access to MSRP should be done using
    -- STORED FUNCITON.

    IF (NEW.priceEach < getMSRP(NEW.productCode)*0.8) OR (NEW.priceEach > getMSRP(NEW.productCode)*2) THEN
   		SET errormessage = CONCAT("The price for this ", new.productCode, " should not be below 80% and above 100% of its ", getMSRP(NEW.productCode));
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage; 
    END IF;

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_AFTER_INSERT;
DELIMITER $$
CREATE TRIGGER `orderdetails_AFTER_INSERT` AFTER INSERT ON `orderdetails` FOR EACH ROW BEGIN
    -- Remove from the inventory the qty of the product ordered
	UPDATE current_products SET quantityInStock = quantityInStock - new.quantityOrdered WHERE productCode = new.productCode;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    
    -- Check if the new quantity will cause the inventory to go below 0
    IF ((SELECT quantityInStock+old.quantityOrdered-new.quantityOrdered FROM current_products WHERE productCode = new.productCode) < 0) THEN
		SET errormessage = CONCAT("The quantity being ordered for ", new.productCode, " will make the inventory quantity go below zero");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Check if line number is being updated
    IF (new.orderlinenumber != old.orderlinenumber) THEN
		SET errormessage = "The line number cannot be updated";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER `orderdetails_AFTER_UPDATE` AFTER UPDATE ON `orderdetails` FOR EACH ROW BEGIN
    -- Remove from the inventory the qty of the product ordered
	UPDATE current_products SET quantityInStock = quantityInStock + old.quantityOrdered - new.quantityOrdered WHERE productCode = new.productCode;
END $$
DELIMITER ;

-- TRIGGERS ON ORDERS
-- 4A.A
DROP TRIGGER IF EXISTS orders_BEFORE_INSERT;
DELIMITER $$
CREATE TRIGGER `orders_BEFORE_INSERT` BEFORE INSERT ON `orders` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    
	-- Autogeneration of order number (identifier)
    SET new.ordernumber := (SELECT MAX(ordernumber)+1 FROM orders);

	SET new.orderdate := NOW();
    IF (TIMESTAMPDIFF(DAY, new.orderdate, new.requireddate) < 3) THEN
		SET errormessage = CONCAT("Required Data cannot be less than 3 days from the Order Date of ", new.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    SET new.status = "In-Process";
    IF (new.shippeddate IS NOT NULL) THEN
		SET errormessage = CONCAT("The order is a new order with ordernumber - ", new.ordernumber, " and it should not have a shipped date yet");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Check for the precense of customer
    IF (new.customernumber IS NULL) THEN
		SET errormessage = CONCAT("Order number ", new.ordernumber, " cannot be made without a customer");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
END $$
DELIMITER ;

-- 4A.C 
DROP TRIGGER IF EXISTS orders_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER `orders_BEFORE_UPDATE` BEFORE UPDATE ON `orders` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    
    -- Prevents updating order number
    IF (new.ordernumber != old.ordernumber) THEN
		SET errormessage = CONCAT("Order Number  ", old.ordernumber, " cannot be updated to a new value of ", new.ordernumber);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Prevents updating order date
    IF (new.orderdate != old.orderdate) THEN
		SET errormessage = CONCAT("Order Date ", old.orderdate, " cannot be updated to a new value of ", new.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Prevents updating shipped date
    IF (new.shippeddate != old.shippeddate) THEN
		SET errormessage = CONCAT("Shipped Date ", old.shippeddate, " cannot be updated to a new value of ", new.shippeddate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Prevents updating customer number
	IF (new.customernumber != old.customernumber) THEN
		SET errormessage = CONCAT("Customer Number ", old.customernumber, " cannot be updated to a new value of ", new.customernumber);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Checks if updated Required Date is not less than 3 days from the order date    
    IF (TIMESTAMPDIFF(DAY, new.orderdate, new.requireddate) < 3) THEN
		SET errormessage = CONCAT("Required Date cannot be less than 3 days from the Order Date of ", new.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
	-- Check for the presence of customer
    IF (new.customernumber IS NULL) THEN
		SET errormessage = CONCAT("Order number ", new.ordernumber, " cannot be updated without a customer");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check valid status transitions (preventing status reversion)
     IF NOT isValidStatus(OLD.status, NEW.status) THEN
        SET NEW.status = OLD.status;
    END IF;
    
    -- Set shipped date when status is 'Shipped'
    IF (new.status = 'Shipped' AND old.status != 'Shipped') THEN
		SET new.shippedDate = NOW();
	END IF;
    
    -- Prevent any updates or changes once status is "Completed"
    IF (old.status = 'Completed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No further activity is allowed on completed orders.';
    END IF;
    
    -- Append new comments without removing existing ones
    IF (new.comments IS NOT NULL) THEN
        SET new.comments = CONCAT(old.comments, '\n', new.comments);
    END IF;

    -- 4A.E
    -- check if order was cancelled (edited by Josef)
	IF(old.status = "Cancelled") THEN
		SET errormessage = "Cannot modify cancelled orders";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orders_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER `orders_AFTER_UPDATE` AFTER UPDATE ON `orders` FOR EACH ROW 
BEGIN
    -- Declare the necessary variables
    DECLARE var_quantityOrdered DECIMAL(9,2);
    DECLARE var_productCode VARCHAR(15);
    DECLARE done INT DEFAULT 0;

    -- Declare a cursor to iterate through the products of the order
    DECLARE cur CURSOR FOR
        SELECT productCode, quantityOrdered 
        FROM orderdetails 
        WHERE orderNumber = old.orderNumber;

    -- Declare a handler for the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Only execute if the order is being cancelled
    IF new.status = 'Cancelled' THEN
        -- Open the cursor to fetch each product
        OPEN cur;

        read_loop: LOOP
            FETCH cur INTO var_productCode, var_quantityOrdered;
            IF done THEN
                LEAVE read_loop;
            END IF;

            -- Update the product inventory by returning the ordered quantity
            UPDATE current_products
            SET quantityInStock = quantityInStock + var_quantityOrdered,
				latest_audituser = USER(),
                latest_authorizinguser = 'SYSTEM',
                latest_activityreason = 'Order was cancelled',
                latest_activitymethod = 'W'
            WHERE productCode = var_productCode;
        END LOOP;

        -- Close the cursor after processing
        CLOSE cur;
    END IF;
    
	-- for the audit table
	INSERT INTO audit_orders VALUES
	('U', NOW(), new.orderNumber, 
	  old.orderDate, old.requiredDate, old.shippedDate, 
	  old.`status`, old.comments, old.customerNumber,
	  new.orderDate, new.requiredDate, new.shippedDate, 
	  new.`status`, new.comments, new.customerNumber,
	  USER(), new.latest_audituser, new.latest_authorizinguser,
	  new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;


DROP TRIGGER IF EXISTS orders_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER `orders_BEFORE_DELETE` BEFORE DELETE ON `orders` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    -- sends an error message when someone attempts to delete an order record
	SET errormessage = "You cannot delete orders from the records";
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    
END $$
DELIMITER ;

-- PART 4A.D (KRUEGER)
DROP TRIGGER IF EXISTS orderdetails_BEFORE_UPDATE;
DELIMITER $$

CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW
BEGIN
    DECLARE errormessage VARCHAR(200);
    DECLARE var_status VARCHAR(15);

    -- Retrieve the status of the associated order
    SELECT status INTO var_status
    FROM orders
    WHERE orders.orderNumber = OLD.orderNumber;

    -- Condition 1: If the order is "Shipped", allow only referenceNo updates
    IF var_status = 'Shipped' THEN
        IF NOT ((NEW.referenceNo <> OLD.referenceNo OR (OLD.referenceNo IS NULL AND NEW.referenceNo IS NOT NULL)) 
                AND NEW.quantityOrdered = OLD.quantityOrdered 
                AND NEW.priceEach = OLD.priceEach) THEN
            SET errormessage = 'No updates are allowed after the order is Shipped, except referenceNo';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
        END IF;
    END IF;

    -- Condition 2: If the order is "Cancelled", block all updates
    IF var_status = "Cancelled" THEN
        SET errormessage = "Cannot modify the details of a cancelled order";
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Condition 3: For other statuses, allow only quantityOrdered and priceEach updates
    IF var_status NOT IN ('Shipped', 'Cancelled') THEN
        IF NEW.quantityOrdered = OLD.quantityOrdered AND NEW.priceEach = OLD.priceEach THEN
            SET errormessage = 'Only quantityOrdered and priceEach can be updated';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
        END IF;
    END IF;

    -- Check if the new quantity would cause the inventory to go below zero
    IF (SELECT quantityInStock + OLD.quantityOrdered - NEW.quantityOrdered FROM current_products WHERE productCode = NEW.productCode) < 0 THEN
        SET errormessage = CONCAT("The quantity being ordered for ", NEW.productCode, " will make the inventory quantity go below zero");
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Prevent changing the order line number
    IF NEW.orderLineNumber != OLD.orderLineNumber THEN
        SET errormessage = "The line number cannot be updated";
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

END$$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_BEFORE_DELETE;
SHOW TRIGGERS LIKE 'orderdetails';
DELIMITER $$
CREATE TRIGGER orderdetails_BEFORE_DELETE
BEFORE DELETE ON orderdetails
FOR EACH ROW
BEGIN
    DECLARE errormessage VARCHAR(200);

    -- Check if the order is already shipped
    IF isOrderShipped(OLD.orderNumber) THEN
        SET errormessage = 'No deletions are allowed after the order is Shipped.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check if the status is "Pending" or "In Process" to allow cancellation
    IF (SELECT status FROM orders WHERE orderNumber = OLD.orderNumber) NOT IN ('Pending', 'In Process') THEN
        SET errormessage = 'Ordered products can only be cancelled when the order is in Pending or In Process status.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

END$$
DELIMITER ;

-- PART 4C-A (TAN)
-- alter the employee_type column so that old values can be edited
ALTER TABLE `dbsalesv2.0`.employees
MODIFY employee_type VARCHAR(50);

-- replace old values with ones in a new format
UPDATE `dbsalesv2.0`.employees
SET employee_type = 'Sales Representative'
WHERE employee_type = 'S';

UPDATE `dbsalesv2.0`.employees
SET employee_type = 'Sales Manager'
WHERE employee_type = 'N';

-- change the employee_type column to 'not null' and change the values accepted by changing the type to ENUM
ALTER TABLE `dbsalesv2.0`.`employees` 
CHANGE COLUMN `employee_type` `employee_type` ENUM('Sales Representative', 'Sales Manager', 'Inventory Manager') NOT NULL ;

-- fix typographical errors in existing database
UPDATE `dbsalesv2.0`.employees
SET jobTitle = 'Sales Manager (EMEA)'
WHERE jobTitle = 'Sale Manager (EMEA)';

-- alter employees table to only allow job titles that exist in the organization (as seen in the existing database)
ALTER TABLE `dbsalesv2.0`.`employees` 
CHANGE COLUMN `jobTitle` `jobTitle` ENUM('President', 'VP Sales', 'VP Marketing', 'Sales Manager (APAC)', 'Sales Manager (EMEA)', 'Sales Manager (NA)', 'Sales Manager', 'Sales Rep') NOT NULL ;

-- PART 4C.C (TAN)
-- create a column in the employees table that signifies whether an employee is active or not
ALTER TABLE `dbsalesv2.0`.`employees` 
ADD COLUMN `activeRecord` ENUM('Y', 'N') NULL AFTER `employee_type`;

-- set a value for the new column for those rows who don't have any value in that column
UPDATE `dbsalesv2.0`.employees
SET activeRecord = 'Y'
WHERE activeRecord IS NULL;

-- create trigger that will stop employee names and number from being updated
DROP TRIGGER IF EXISTS employees_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER `employees_BEFORE_UPDATE` BEFORE UPDATE ON `employees` FOR EACH ROW BEGIN
		
	-- PART 4C.B (TAN)
    DECLARE errormessage	VARCHAR(200);
    
    -- check if employee number is being changed
	IF(new.employeeNumber != old.employeeNumber) THEN
		SET errormessage = "Employee numbers cannot be edited";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- check if name is being changed
	IF(new.lastName != old.lastName OR new.firstName != old.firstName) THEN
		SET errormessage = "Employee name cannot be edited";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- PART 4C.C (TAN)
	-- check if employee is active in the organization
	IF(old.activeRecord = 'N') THEN
		SET errormessage = "Inactive employee records cannot be edited";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
END $$
DELIMITER ;

-- stop employee records from being deleted
DROP TRIGGER IF EXISTS employees_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER `employees_BEFORE_DELETE` BEFORE DELETE ON `employees` FOR EACH ROW BEGIN
	    DECLARE errormessage VARCHAR(200);
        SET errormessage = 'Employee records are not to be deleted';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
END $$
DELIMITER ;

-- PART 4B.B (KRUEGER)
DROP PROCEDURE IF EXISTS addProductLine;
DELIMITER $$

CREATE PROCEDURE `addProductLine`(
    IN v_productCode VARCHAR(15),
    IN v_productLine VARCHAR(50)
)
BEGIN
    DECLARE errormessage VARCHAR(200);

    -- Check if the product exists
    IF (SELECT COUNT(*) FROM products WHERE productCode = v_productCode) = 0 THEN
        SET errormessage = CONCAT('Product with code ', v_productCode, ' does not exist.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check if the product line exists
    IF (SELECT COUNT(*) FROM productlines WHERE productLine = v_productLine) = 0 THEN
        SET errormessage = CONCAT('Product line ', v_productLine, ' does not exist.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Prevent duplicate classifications
    IF (SELECT COUNT(*) FROM product_productlines WHERE productCode = v_productCode AND productLine = v_productLine) > 0 THEN
        SET errormessage = CONCAT('Product ', v_productCode, ' is already classified under line ', v_productLine);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Insert the product classification
    INSERT INTO product_productlines (productCode, productLine)
    VALUES (v_productCode, v_productLine);
END$$

DELIMITER ;


DROP EVENT IF EXISTS update_credit_limits;
DELIMITER $$

CREATE EVENT update_credit_limits
ON SCHEDULE EVERY 30 DAY
STARTS '2024-10-31 00:00:00'
DO
BEGIN
    -- Update credit limits based on total order amount for each customer in the current month
    UPDATE customers c
    LEFT JOIN (
        SELECT 
            o.customerNumber, 
            SUM(od.quantityOrdered * od.priceEach) AS customerTotalAmount
        FROM 
            orders o
        JOIN 
            orderdetails od ON o.orderNumber = od.orderNumber
        WHERE 
            MONTH(o.orderDate) = MONTH(CURDATE())
            AND YEAR(o.orderDate) = YEAR(CURDATE())
        GROUP BY 
            o.customerNumber
    ) AS customerOrders ON c.customerNumber = customerOrders.customerNumber
    SET 
        c.creditLimit = IFNULL(customerOrders.customerTotalAmount * 2, 0),
        c.latest_audituser = 'System',
        c.latest_activityreason = 'Monthly reassessment of credit limit';

    -- Additional credit for customers with more than 15 orders in the current month
    UPDATE customers c
    JOIN (
        SELECT 
            o.customerNumber, 
            MAX(od.quantityOrdered * od.priceEach) AS maxOrderAmount
        FROM 
            orders o
        JOIN 
            orderdetails od ON o.orderNumber = od.orderNumber
        WHERE 
            MONTH(o.orderDate) = MONTH(CURDATE())
            AND YEAR(o.orderDate) = YEAR(CURDATE())
        GROUP BY 
            o.customerNumber
        HAVING COUNT(*) > 15
    ) AS extraCredit ON c.customerNumber = extraCredit.customerNumber
    SET 
        c.creditLimit = c.creditLimit + extraCredit.maxOrderAmount,
        c.latest_audituser = 'System',
        c.latest_activityreason = 'Monthly reassessment: additional credit for high order count';

END $$
DELIMITER ;

-- PART 4C.D
-- Part 4C.D
ALTER TABLE salesrepassignments
ADD COLUMN quota_utilized DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN reassigned_by VARCHAR(50) DEFAULT NULL;

DROP EVENT IF EXISTS reassign_sales_rep;
DELIMITER $$
CREATE EVENT reassign_sales_rep
ON SCHEDULE EVERY 1 DAY
STARTS '2024-11-05 18:00:00'
DO
BEGIN
    DECLARE v_employeeNumber INT;

    -- Log start of event
    INSERT INTO event_logs (log_time, message) VALUES (NOW(), 'Event reassign_sales_rep started.');

    -- Temporary table to store employees with expiring assignments
    CREATE TEMPORARY TABLE IF NOT EXISTS no_reassignment_table (
        employeeNumber INT
    );

    -- Insert employees with assignments expiring today and no future assignment
    INSERT INTO no_reassignment_table (employeeNumber)
    SELECT employeeNumber
    FROM salesrepassignments sra1
    WHERE endDate = CURDATE()
      AND NOT EXISTS (
          SELECT 1
          FROM salesrepassignments sra2
          WHERE sra2.employeeNumber = sra1.employeeNumber
            AND sra2.officeCode = sra1.officeCode
            AND sra2.startDate > CURDATE()
      );

    -- Log count of employees to be reassigned
    INSERT INTO event_logs (log_time, message)
    VALUES (NOW(), CONCAT('Employees to reassign: ', (SELECT COUNT(*) FROM no_reassignment_table)));

    -- Loop through each employee in the temporary table
    WHILE (SELECT COUNT(*) FROM no_reassignment_table) > 0 DO
        -- Get the next employee number
        SELECT employeeNumber INTO v_employeeNumber
        FROM no_reassignment_table
        LIMIT 1;

        -- Log each reassignment attempt
        INSERT INTO event_logs (log_time, message)
        VALUES (NOW(), CONCAT('Reassigning employee: ', v_employeeNumber));

        -- Call the reassign procedure for this employee
        CALL auto_reassign_salesRep(v_employeeNumber);

        -- Delete the processed employee from the temporary table
        DELETE FROM no_reassignment_table
        WHERE employeeNumber = v_employeeNumber;
    END WHILE;

    -- Drop the temporary table
    DROP TEMPORARY TABLE IF EXISTS no_reassignment_table;

    -- Log end of event
    INSERT INTO event_logs (log_time, message) VALUES (NOW(), 'Event reassign_sales_rep finished.');
END$$
DELIMITER ;

-- 4C.E
DROP TRIGGER IF EXISTS before_insert_salesrepassignments;
DELIMITER $$
CREATE TRIGGER before_insert_salesrepassignments
BEFORE INSERT ON salesrepassignments FOR EACH ROW BEGIN
    DECLARE v_endDate DATE; 
    
    -- check if the employee already has an active assignment
    SELECT MAX(endDate) INTO v_endDate
    FROM salesrepassignments
    WHERE employeeNumber = NEW.employeeNumber;
    
    -- if there's an active assignment, set start date to the day after it ends
    IF v_endDate IS NOT NULL AND v_endDate >= CURDATE() THEN
        SET NEW.startDate = DATE_ADD(v_endDate, INTERVAL 1 DAY);
        
        -- limit the assignment duration to a maximum of one month
        SET NEW.endDate = LEAST(DATE_ADD(NEW.startDate, INTERVAL 1 MONTH), NEW.endDate);
    ELSE
        -- if no active assignment, allow the specified start and end dates
        SET NEW.startDate = CURDATE();
        SET NEW.endDate = LEAST(DATE_ADD(NEW.startDate, INTERVAL 1 MONTH), NEW.endDate);
    END IF;

    -- ensure the Sales Manager quota is applied
    IF NEW.quota IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quota must be set by the Sales Manager for new assignments.';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS before_update_salesrepassignments
DELIMITER $$
CREATE TRIGGER before_update_salesrepassignments BEFORE UPDATE ON salesrepassignments FOR EACH ROW BEGIN
    -- Enforce a maximum assignment duration of one month
    IF DATEDIFF(NEW.endDate, NEW.startDate) > 30 THEN
        SET NEW.endDate = DATE_ADD(NEW.startDate, INTERVAL 1 MONTH);
    END IF;

    -- Prevent updates to quota if not authorized
    IF NEW.quota IS NULL OR NEW.quota <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quota must be a positive value set by the Sales Manager.';
    END IF;
END$$
DELIMITER ;

-- for auditing current products purposes (TAN)
DROP TRIGGER IF EXISTS current_products_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER current_products_AFTER_INSERT AFTER INSERT ON current_products FOR EACH ROW BEGIN
	INSERT INTO audit_current_products VALUES
		('C', NOW(), new.productCode, NULL, NULL, NULL, NULL, NULL,
		  new.product_type, new.quantityInStock, new.current_status, new.discontinuing_manager, new.discontinue_reason,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

-- for adding or deleting things in discontinued_products based on updates to current_status (for 4b.e, by TAN)
DROP TRIGGER IF EXISTS current_products_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER current_products_BEFORE_UPDATE BEFORE UPDATE ON current_products FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);

	-- PART 4B.D (BUERE)
    -- Check if the product type is being modified
    IF OLD.product_type != NEW.product_type THEN
		SET errormessage = CONCAT('Product type for ', new.productCode, ' cannot be modified from ', old.product_type, ' to ', new.product_type);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

	-- if there the current_product is attempting to be moved to discontinued but there is no discontinuing_manager
	IF(old.current_status = 'C' AND new.current_status = 'D' AND new.discontinuing_manager IS NULL) THEN
		SET errormessage = CONCAT("The current product ", new.productCode, " needs a inventory manager to discontinue it");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
	END IF;

	-- if the new status is 'D' and the old one is 'C' and there is a discontiuing_manager in current_products row
	IF(old.current_status = 'C' AND new.current_status = 'D' AND new.discontinuing_manager IS NOT NULL) THEN
		-- if there are no entries in the discontinued products table that correspond to this current_product
		IF (SELECT COUNT(*) FROM discontinued_products WHERE productCode = new.productCode) = 0 THEN
			INSERT INTO discontinued_products VALUES
            (new.productCode, new.discontinue_reason, new.discontinuing_manager, 'SYSTEM', 'SYSTEM', 'Product being discontinued', 'D');
            
		END IF;
        
			UPDATE products
				SET product_category = 'D', latest_audituser = 'SYSTEM', latest_authorizinguser = 'SYSTEM', 
					latest_activityreason = 'Product being discontinued',
					latest_activitymethod = 'D'
			WHERE productCode = new.productCode;
        
	END IF;
    
	-- if the new status is 'C' and the old one is 'D'
	IF(old.current_status = 'D' AND new.current_status = 'C') THEN
		DELETE FROM discontinued_products
        WHERE productCode = new.productCode;
        
		UPDATE products
			SET product_category = 'C', latest_audituser = 'SYSTEM', latest_authorizinguser = 'SYSTEM',
				latest_activityreason = 'Product being re-continued',
				latest_activitymethod = 'D'
		WHERE productCode = new.productCode;
	END IF;

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS current_products_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER current_products_AFTER_UPDATE AFTER UPDATE ON current_products FOR EACH ROW BEGIN
INSERT INTO audit_current_products VALUES
		('U', NOW(), new.productCode, old.product_type, old.quantityInStock, old.current_status, old.discontinuing_manager, old.discontinue_reason,
		  new.product_type, new.quantityInStock, new.current_status, new.discontinuing_manager, new.discontinue_reason,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS current_products_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER current_products_BEFORE_DELETE BEFORE DELETE ON current_products FOR EACH ROW BEGIN
	INSERT INTO audit_current_products VALUES
		('D', NOW(), old.productCode, NULL, NULL, NULL, NULL, NULL,
        old.product_type, old.quantityInStock, old.current_status, old.discontinuing_manager, old.discontinue_reason,
		USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table necessary triggers for discontinued_products
DROP TRIGGER IF EXISTS discontinued_products_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER discontinued_products_AFTER_INSERT AFTER INSERT ON discontinued_products FOR EACH ROW BEGIN
	INSERT INTO audit_discontinued_products VALUES
		('C', NOW(), new.productCode, NULL, NULL,
		  new.reason, new.inventory_manager,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS discontinued_products_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER discontinued_products_AFTER_UPDATE AFTER UPDATE ON discontinued_products FOR EACH ROW BEGIN
	INSERT INTO audit_discontinued_products VALUES
		('U', NOW(), new.productCode, new.reason, new.inventory_manager,
		  old.reason, old.inventory_manager,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS discontinued_products_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER discontinued_products_BEFORE_DELETE BEFORE DELETE ON discontinued_products FOR EACH ROW BEGIN
	INSERT INTO audit_discontinued_products VALUES
		('D', NOW(), old.productCode, NULL, NULL,
        old.reason, old.inventory_manager,
		USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit triggers for banks table (TAN)
DROP TRIGGER IF EXISTS banks_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER banks_AFTER_INSERT AFTER INSERT ON banks FOR EACH ROW BEGIN
	INSERT INTO audit_banks VALUES
		('C', NOW(), new.bank, NULL, NULL, NULL,
		  new.bankname, new.branch, new.branchaddress, 
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS banks_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER banks_AFTER_UPDATE AFTER UPDATE ON banks FOR EACH ROW BEGIN
	INSERT INTO audit_banks VALUES
		('U', NOW(), new.bank, 
		  old.bankname, old.branch, old.branchaddress, 
          new.bankname, new.branch, new.branchaddress, 
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS banks_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER banks_BEFORE_DELETE BEFORE DELETE ON banks FOR EACH ROW BEGIN
	INSERT INTO audit_banks VALUES
		('D', NOW(), old.bank, 
		  NULL, NULL, NULL,
		  old.bankname, old.branch, old.branchaddress, 
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit triggers for check_payments table (TAN)
DROP TRIGGER IF EXISTS check_payments_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER check_payments_AFTER_INSERT AFTER INSERT ON check_payments FOR EACH ROW BEGIN
	INSERT INTO audit_check_payments VALUES
		('C', NOW(), new.customerNumber, new.paymentTimestamp, NULL,
		  new.checkno,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS check_payments_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER check_payments_AFTER_UPDATE AFTER UPDATE ON check_payments FOR EACH ROW BEGIN
	INSERT INTO audit_check_payments VALUES
		('U', NOW(), new.customerNumber, new.paymentTimestamp, 
		  old.checkno,
          new.checkno,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS check_payments_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER check_payments_BEFORE_DELETE BEFORE DELETE ON check_payments FOR EACH ROW BEGIN
	INSERT INTO audit_check_payments VALUES
		('D', NOW(), old.customerNumber, old.paymentTimestamp, 
		  NULL,
		  old.checkno,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table triggers for couriers (TAN)
DROP TRIGGER IF EXISTS couriers_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER couriers_AFTER_INSERT AFTER INSERT ON couriers FOR EACH ROW BEGIN
	INSERT INTO audit_couriers VALUES
		('C', NOW(), new.courierName, NULL,
		  new.address,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS couriers_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER couriers_AFTER_UPDATE AFTER UPDATE ON couriers FOR EACH ROW BEGIN
	INSERT INTO audit_couriers VALUES
		('U', NOW(), new.courierName,
		  old.address,
          new.address,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS couriers_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER couriers_BEFORE_DELETE BEFORE DELETE ON couriers FOR EACH ROW BEGIN
	INSERT INTO audit_couriers VALUES
		('D', NOW(), old.courierName,
		  NULL,
		  old.address,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table triggers for credit_payments (TAN)
DROP TRIGGER IF EXISTS credit_payments_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER credit_payments_AFTER_INSERT AFTER INSERT ON credit_payments FOR EACH ROW BEGIN
	INSERT INTO audit_credit_payments VALUES
		('C', NOW(), new.customerNumber, new.paymentTimestamp, 
		  NULL, NULL,
		  new.postingDate, new.paymentReferenceNo,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS credit_payments_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER credit_payments_AFTER_UPDATE AFTER UPDATE ON credit_payments FOR EACH ROW BEGIN
	INSERT INTO audit_credit_payments VALUES
		('U', NOW(), new.customerNumber, new.paymentTimestamp, 
		  old.postingDate, old.paymentReferenceNo,
          new.postingDate, new.paymentReferenceNo,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS credit_payments_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER credit_payments_BEFORE_DELETE BEFORE DELETE ON credit_payments FOR EACH ROW BEGIN
	INSERT INTO audit_credit_payments VALUES
		('D', NOW(), old.customerNumber, old.paymentTimestamp, 
		  NULL, NULL,
		  old.postingDate, old.paymentReferenceNo,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table triggers for customers table (TAN)
DROP TRIGGER IF EXISTS customers_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER customers_AFTER_INSERT AFTER INSERT ON customers FOR EACH ROW BEGIN
	INSERT INTO audit_customers VALUES
		('C', NOW(), new.customerNumber, 
		  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
		  new.customerName, new.contactLastName, new.contactFirstName, new.phone, new.addressLine1, new.addressLine2, new.city, 
          new.state, new.postalCode, new.country, new.salesRepEmployeeNumber, new.creditLimit, new.officeCode, new.startDate,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS customers_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER customers_AFTER_UPDATE AFTER UPDATE ON customers FOR EACH ROW BEGIN
	INSERT INTO audit_customers VALUES
		('U', NOW(), new.customerNumber,
		  old.customerName, old.contactLastName, old.contactFirstName, old.phone, old.addressLine1, old.addressLine2, old.city, 
          old.state, old.postalCode, old.country, old.salesRepEmployeeNumber, old.creditLimit, old.officeCode, old.startDate,
          new.customerName, new.contactLastName, new.contactFirstName, new.phone, new.addressLine1, new.addressLine2, new.city, 
          new.state, new.postalCode, new.country, new.salesRepEmployeeNumber, new.creditLimit, new.officeCode, new.startDate,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS customers_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER customers_BEFORE_DELETE BEFORE DELETE ON customers FOR EACH ROW BEGIN
	INSERT INTO audit_customers VALUES
		('D', NOW(), old.customerNumber,
		  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
		  old.customerName, old.contactLastName, old.contactFirstName, old.phone, old.addressLine1, old.addressLine2, old.city, 
          old.state, old.postalCode, old.country, old.salesRepEmployeeNumber, old.creditLimit, old.officeCode, old.startDate,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table triggers for departments (TAN)
DROP TRIGGER IF EXISTS departments_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER departments_AFTER_INSERT AFTER INSERT ON departments FOR EACH ROW BEGIN
	INSERT INTO audit_departments VALUES
		('C', NOW(), new.deptCode,
		  NULL, NULL,
		  new.deptName, new.deptManagerNumber,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS departments_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER departments_AFTER_UPDATE AFTER UPDATE ON departments FOR EACH ROW BEGIN
	INSERT INTO audit_departments VALUES
		('U', NOW(), new.deptCode,
		  old.deptName, old.deptManagerNumber,
		  new.deptName, new.deptManagerNumber,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS departments_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER departments_BEFORE_DELETE BEFORE DELETE ON departments FOR EACH ROW BEGIN
	INSERT INTO audit_departments VALUES
		('D', NOW(), old.deptCode,
		  NULL, NULL,
		  old.deptName, old.deptManagerNumber,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- audit table triggers for inventory_managers (TAN)
DROP TRIGGER IF EXISTS inventory_managers_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER inventory_managers_AFTER_INSERT AFTER INSERT ON inventory_managers FOR EACH ROW BEGIN
	INSERT INTO audit_inventory_managers VALUES
		('C', NOW(), new.employeeNumber,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS inventory_managers_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER inventory_managers_AFTER_UPDATE AFTER UPDATE ON inventory_managers FOR EACH ROW BEGIN
	INSERT INTO audit_inventory_managers VALUES
		('U', NOW(), new.employeeNumber,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS inventory_managers_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER inventory_managers_BEFORE_DELETE BEFORE DELETE ON inventory_managers FOR EACH ROW BEGIN
	INSERT INTO audit_inventory_managers VALUES
		('D', NOW(), old.employeeNumber,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;