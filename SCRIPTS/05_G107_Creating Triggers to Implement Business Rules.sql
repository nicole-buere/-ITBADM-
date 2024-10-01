
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
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orders_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER `orders_AFTER_UPDATE` AFTER UPDATE ON `orders` FOR EACH ROW BEGIN
	DECLARE var_quantityOrdered DECIMAL(9,2);
    DECLARE var_productCode VARCHAR(15);

    -- Handle cancelled orders
    -- Handle cancelled orders
    IF new.status = "Cancelled" THEN
		-- Iterate through each product in the order and return to inventory
		DECLARE cur CURSOR FOR
			SELECT productCode, quantityOrdered 
			FROM orderdetails 
			WHERE orderNumber = old.orderNumber;
		DECLARE done INT DEFAULT 0;

		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

		OPEN cur;

		-- Loop through each order detail row
		LOOP
			FETCH cur INTO var_productCode, var_quantityOrdered;
			IF done THEN
				LEAVE LOOP;
			END IF;

			-- Update inventory
			UPDATE current_products
			SET quantityInStock = quantityInStock + var_quantityOrdered
			WHERE productCode = var_productCode;
		END LOOP;

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
