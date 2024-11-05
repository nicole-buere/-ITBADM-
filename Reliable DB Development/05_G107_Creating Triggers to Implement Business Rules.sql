
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
    SET new.status = "In-Prcoess";
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

DROP TRIGGER IF EXISTS orders_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER `orders_BEFORE_UPDATE` BEFORE UPDATE ON `orders` FOR EACH ROW BEGIN
	DECLARE errormessage	VARCHAR(200);
    
    IF (new.ordernumber != old.ordernumber) THEN
		SET errormessage = CONCAT("Order Number  ", old.ordernumber, " cannot be updated to a new value of ", new.ordernumber);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Check if the updated orderdate is before the original orderdate
    IF (new.orderdate < old.orderdate) THEN
		SET errormessage = CONCAT("Updated orderdate cannot be less than the origianl date of ", old.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    IF (TIMESTAMPDIFF(DAY, new.orderdate, new.requireddate) < 3) THEN
		SET errormessage = CONCAT("Required Data cannot be less than 3 days from the Order Date of ", new.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
        -- Check for the precense of customer
    IF (new.customernumber IS NULL) THEN
		SET errormessage = CONCAT("Order number ", new.ordernumber, " cannot be updated without a customer");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check valid status transitions (preventing status reversion)
    IF NOT isValidStatus(old.status, new.status) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition: Status can only progress forward, not backward.';
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

    -- check if order was cancelled (edited by Josef)
	IF(old.status = "Cancelled") THEN
		SET errormessage = "Cannot modify cancelled orders";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    IF (new.ordernumber != old.ordernumber) THEN
		SET errormessage = CONCAT("Order Number  ", old.ordernumber, " cannot be updated to a new value of ", new.ordernumber);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Check if the updated orderdate is before the original orderdate
    IF (new.orderdate < old.orderdate) THEN
		SET errormessage = CONCAT("Updated orderdate cannot be less than the original date of ", old.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    IF (TIMESTAMPDIFF(DAY, new.orderdate, new.requireddate) < 3) THEN
		SET errormessage = CONCAT("Required Data cannot be less than 3 days from the Order Date of ", new.orderdate);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
        -- Check for the presence of customer
    IF (new.customernumber IS NULL) THEN
		SET errormessage = CONCAT("Order number ", new.ordernumber, " cannot be updated without a customer");
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
            SET quantityInStock = quantityInStock + var_quantityOrdered
            WHERE productCode = var_productCode;
        END LOOP;

        -- Close the cursor after processing
        CLOSE cur;
    END IF;
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

DROP TRIGGER IF EXISTS orderdetails_BEFORE_UPDATE;
DELIMITER $$
CREATE TRIGGER `orderdetails_BEFORE_UPDATE` BEFORE UPDATE ON `orderdetails` FOR EACH ROW
BEGIN
    DECLARE errormessage VARCHAR(200);
    DECLARE var_status 		VARCHAR(15);

    -- Check if the order is shipped
    IF isOrderShipped(OLD.orderNumber) THEN
        SET errormessage = 'No updates are allowed after the order is Shipped.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Ensure only quantityOrdered and priceEach are updated
    IF NOT isUpdateValid(OLD.quantityOrdered, NEW.quantityOrdered, OLD.priceEach, NEW.priceEach) THEN
        SET errormessage = 'Only quantityOrdered and priceEach can be updated.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check if reference number can be updated
    IF NOT canUpdateReference(OLD.orderNumber, OLD.referenceNo, NEW.referenceNo) THEN
        SET errormessage = 'Reference number can only be updated when the order status is Shipped.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;

    -- Check if the associated order is cancelled
    -- SELECT the status of the order that the orderdetails row is based on
		SELECT	`status`
		INTO	var_status
		FROM	orders
		WHERE	orders.orderNumber = old.orderNumber;
        
	IF(var_status = "Cancelled") THEN
		SET errormessage = "Cannot modify the details of a cancelled order";
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
    
    -- Prevent inventory going below zero
	IF (SELECT quantityInStock + old.quantityOrdered - new.quantityOrdered FROM current_products WHERE productCode = new.productCode) < 0 THEN
		SET errormessage = CONCAT("The quantity being ordered for ", new.productCode, " will make the inventory quantity go below zero");
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
	END IF;
    
    -- Prevent changing the order line number
	IF new.orderLineNumber != old.orderLineNumber THEN
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

-- PART 4B.D (BUERE)
DROP TRIGGER IF EXISTS `current_product_BEFORE_UPDATE`;
DELIMITER $$
CREATE TRIGGER `current_product_BEFORE_UPDATE`BEFORE UPDATE ON `dbsalesV2.0`.`current_products`FOR EACH ROW BEGIN
    DECLARE errormessage VARCHAR(200);
    -- Check if the product type is being modified
    IF OLD.product_type != NEW.product_type THEN
		SET errormessage = CONCAT('Product type for ', new.productCode, ' cannot be modified from ', old.product_type, ' to ', new.product_type);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
END$$
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

-- PART4D (PEGALAN)

ALTER TABLE customers
ADD COLUMN latest_audituser VARCHAR(45) DEFAULT NULL,
ADD COLUMN latest_activityreason VARCHAR(100) DEFAULT NULL;


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



