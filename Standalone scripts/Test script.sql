-- 4A.E test script (TAN)

-- select orders
SELECT * FROM `dbsalesv2.0`.orders;
SELECT * FROM `dbsalesv2.0`.audit_orders;

SELECT * FROM `dbsalesv2.0`.orderdetails;
SELECT * FROM `dbsalesv2.0`.audit_orderdetails;

SELECT * FROM `dbsalesv2.0`.orderdetails
WHERE orderNumber = '10428';

-- select current products
SELECT * FROM `dbsalesv2.0`.current_products;

-- insert an order (should succeed)
INSERT INTO `dbsalesv2.0`.`orders` (`orderNumber`, `orderDate`, `requiredDate`, `status`, `comments`, `customerNumber`) 
VALUES ('10428', '2016-09-15 16:01:36', '2025-01-01 00:00:00', 'In Process', 'Test Order 4 ae', '119');
-- insert and orderdetail (should succeed)
INSERT INTO `dbsalesv2.0`.`orderdetails` (`orderNumber`, `productCode`, `quantityOrdered`, `priceEach`, `orderLineNumber`) 
VALUES ('10428', 'S24_2022', '20', '44.80', '1');

INSERT INTO `dbsalesv2.0`.`orderdetails` (`orderNumber`, `productCode`, `quantityOrdered`, `priceEach`, `orderLineNumber`) 
VALUES ('10428', 'S18_1749', '20', '136', '1');


-- delete an order (should fail)
DELETE FROM `dbsalesv2.0`.`orders` WHERE (`orderNumber` = '10428');

-- cancel an order (should pass)
UPDATE `dbsalesv2.0`.`orders` SET `status` = 'Cancelled' 
WHERE (`orderNumber` = '10428');

-- updated a cancelled order (should fail)
UPDATE `dbsalesv2.0`.`orders` SET `comments` = 'test comment' 
WHERE `orderNumber` = '10101' AND status = 'Cancelled';

-- 4B.E test script (TAN)

-- select
SELECT * FROM `dbsalesv2.0`.discontinued_products;

SELECT * FROM `dbsalesv2.0`.current_products;

SELECT * FROM `dbsalesv2.0`.products;

SELECT * FROM `dbsalesv2.0`.inventory_managers;

-- insert an inventory manager (should pass)
INSERT INTO `dbsalesv2.0`.`inventory_managers` (`employeeNumber`) 
VALUES ('1002');

-- discontinue a product without specifying an inventory manager (should fail)
UPDATE `dbsalesv2.0`.`current_products` SET `current_status` = 'D' 
WHERE (`productCode` = 'S10_1678');

-- discontinue a product while specifying an inventory manager (should succeed)
UPDATE `dbsalesv2.0`.`current_products` SET `current_status` = 'D', `discontinuing_manager` = '1002', `discontinue_reason` = 'Not up to standard'
WHERE (`productCode` = 'S10_1678');

-- re-continue a product (should succeed)
UPDATE `dbsalesv2.0`.`current_products` SET `current_status` = 'C' 
WHERE (`productCode` = 'S10_1678');

-- 4C.A test script (TAN)

-- insert an employee record without specifying job title or employee type (should fail)
INSERT INTO `dbsalesv2.0`.`employees` (`employeeNumber`, `lastName`, `firstName`, `extension`, `email`, `jobTitle`, `employee_type`, `activeRecord`) 
VALUES ('9999', 'Test', 'Man', 'x1234', 'testmand@classicmodelcars.com', '', '', 'Y');

-- insert an employee record with an invalid job title or employee type (should fail)
INSERT INTO `dbsalesv2.0`.`employees` (`employeeNumber`, `lastName`, `firstName`, `extension`, `email`, `jobTitle`, `employee_type`, `activeRecord`) 
VALUES ('9999', 'Test', 'Man', 'x1234', 'testmand@classicmodelcars.com', 'faketitle', 'faketype', 'Y');

-- insert an employee record with a valid job title and employee type (should pass)
INSERT INTO `dbsalesv2.0`.`employees` (`employeeNumber`, `lastName`, `firstName`, `extension`, `email`, `jobTitle`, `employee_type`, `activeRecord`) 
VALUES ('9999', 'Test', 'Man', 'x1234', 'testmand@classicmodelcars.com', 'Sales Rep', 'Sales Representative', 'Y');

-- change an employee type to Sales Manager (should pass)
UPDATE `dbsalesv2.0`.`employees` SET `employee_type` = 'Sales Manager' WHERE (`employeeNumber` = '9999');

-- select all employees
SELECT * FROM `dbsalesv2.0`.employees;

-- 4C.B test script (TAN)

-- update an employee's name (should fail)
UPDATE `dbsalesv2.0`.`employees` SET `lastName` = 'TestMurphy' 
WHERE (`employeeNumber` = '1002');

-- change an employee's type (should pass)
UPDATE `dbsalesv2.0`.`employees` SET `employee_type` = 'Sales Manager' 
WHERE (`employeeNumber` = '1002');

-- 4C.C test script (TAN)

-- deactivate (resign) and employee (should pass)
UPDATE `dbsalesv2.0`.`employees` SET `activeRecord` = 'N' 
WHERE (`employeeNumber` = '9999');

-- change a deactivated employee's type (should fail)
UPDATE `dbsalesv2.0`.`employees` SET `employee_type` = 'Sales Manager' 
WHERE (`employeeNumber` = '9999');

-- delete an employee record (should fail)
DELETE FROM `dbsalesv2.0`.`employees` 
WHERE (`employeeNumber` = '9999');

-- Audit table testing

SELECT * FROM `dbsalesv2.0`.banks;
SELECT * FROM `dbsalesv2.0`.audit_banks;

INSERT INTO `dbsalesv2.0`.`banks` (`bank`, `bankname`, `branch`, `branchaddress`, `latest_audituser`, `latest_authorizinguser`, `latest_activityreason`, `latest_activitymethod`) 
VALUES ('2', 'a', 'b', 'c', 'Aaron', 'Carl', 'fun', 'D');

UPDATE `dbsalesv2.0`.`banks` SET `bankname` = 'c' WHERE (`bank` = '2');

DELETE FROM `dbsalesv2.0`.`banks` WHERE (`bank` = '2');
