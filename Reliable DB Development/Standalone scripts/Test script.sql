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

-- change an employee's type (should pass)
UPDATE `dbsalesv2.0`.`employees` SET `employee_type` = 'Sales Manager' 
WHERE (`employeeNumber` = '9999');

-- select all employees
SELECT * FROM `dbsalesv2.0`.employees;

-- 4C.B test script (TAN)