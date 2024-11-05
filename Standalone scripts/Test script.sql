-- 4A.E test script (TAN)

-- select orders
SELECT * FROM `dbsalesv2.0`.orders;

-- select current products
SELECT * FROM `dbsalesv2.0`.current_products;

-- delete an order (should fail)
DELETE FROM `dbsalesv2.0`.`orders` WHERE (`orderNumber` = '10427');

-- updated a cancelled order (should fail)
UPDATE `dbsalesv2.0`.`orders` SET `shippedDate` = '2004-06-17 00:00:00' 
WHERE `orderNumber` = '10260' AND status = 'Cancelled';

-- cancel an order (should pass)
UPDATE `dbsalesv2.0`.`orders` SET `status` = 'Cancelled' 
WHERE (`orderNumber` = '10101');

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

-- 4B.E test script (TAN)

-- select
SELECT * FROM `dbsalesv2.0`.discontinued_products;

SELECT * FROM `dbsalesv2.0`.current_products;

SELECT * FROM `dbsalesv2.0`.products;

-- insert an inventory manager
INSERT INTO `dbsalesv2.0`.`inventory_managers` (`employeeNumber`) 
VALUES ('1002');

-- discontinue a product
UPDATE `dbsalesv2.0`.`products` SET `product_category` = 'D' 
WHERE (`productCode` = 'S10_1678');

-- re-continue a product
UPDATE `dbsalesv2.0`.`products` SET `product_category` = 'C' 
WHERE (`productCode` = 'S10_1678');


