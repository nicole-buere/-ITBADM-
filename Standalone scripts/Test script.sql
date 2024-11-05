-- 4A.E test script (TAN)

-- select orders
SELECT * FROM `dbsalesv2.0`.orders;

-- delete an order (should fail)
DELETE FROM `dbsalesv2.0`.`orders` WHERE (`orderNumber` = '10427');

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
