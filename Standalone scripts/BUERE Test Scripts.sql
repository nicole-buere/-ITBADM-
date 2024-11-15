-- Test Script
-- 4A.C
SELECT * FROM `dbsalesv2.0`.orders;
-- update orderNumber
UPDATE `dbsalesv2.0`.`orders` SET `orderNumber` = '12121' WHERE (`orderNumber` = '10100');

-- update orderdate 
UPDATE `dbsalesv2.0`.`orders` SET `orderDate` = '2003-01-05 00:00:00' WHERE (`orderNumber` = '10100');

-- update requiredDate
UPDATE `dbsalesv2.0`.`orders` SET `requiredDate` = '2003-01-14 00:00:00' WHERE (`orderNumber` = '10100');
-- required date is less than the ordered date
UPDATE `dbsalesv2.0`.`orders` SET `requiredDate` = '2003-01-05 00:00:00' WHERE (`orderNumber` = '10100');

-- update shippeddate
UPDATE `dbsalesv2.0`.`orders` SET `orderDate` = '2003-01-05 00:00:00', `shippedDate` = '2003-01-11 00:00:00' WHERE (`orderNumber` = '10100');

-- update customer number
UPDATE `dbsalesv2.0`.`orders` SET `requiredDate` = '2003-01-05 00:00:00', `customerNumber` = '123' WHERE (`orderNumber` = '10100');

-- Testing of isValid Function
SELECT isValidStatus("In Process","Shipped");
SELECT isValidStatus("Shipped","Disputed");
SELECT isValidStatus("Disputed","Resolved");
SELECT isValidStatus("Shipped","Completed");
SELECT isValidStatus("In Process","Cancelled");
SELECT isValidStatus("Disputed","Cancelled");
SELECT isValidStatus("Resolved","Cancelled");
SELECT isValidStatus("Shipped","Cancelled");
SELECT isValidStatus("Completed","Cancelled");
SELECT isValidStatus("Cancelled","Shipped");


-- 4B.A
INSERT INTO `dbsalesv2.0`.`productlines` (`productLine`) VALUES ('new productline'); -- if new product line should be inserted first
CALL add_product('123456','Dodge Charger','1:64', 'Sample Vendor', 'Test product description.', 25.99, 'R', 100, 45.50, 'Classic Cars', NULL, NULL);
-- if no stock it should have an error
CALL add_product('789102','Corvette','1:34', 'Sample Vendor', 'Test product description.', 35.99, 'R', 0, 45.50, 'new productline', NULL, NULL);

-- 4B.D
-- Updated product type from W to R --> should show error not allowed
UPDATE `dbsalesv2.0`.`current_products` SET `product_type` = 'R' WHERE (`productCode` = '095959');

-- 4C.D
-- drop event first then change
-- ON SCHEDULE EVERY 5 SECOND 
-- STARTS CURRENT_TIMESTAMP

SELECT * FROM `dbsalesv2.0`.salesrepassignments;
-- Insert a sample employee
INSERT INTO employees (employeeNumber, lastName, firstName, extension, email, jobTitle, employee_type) VALUES (1, 'John', 'Doe', 'x1900', 'johndoe@email.com', 'President','Sales Representative');

-- Insert a sample office
INSERT INTO offices (officeCode, city, phone, addressLine1, country, postalCode, territory) VALUES (101, 'Manila', '8 700', 'Taft Avenue', 'Philippines','6816','APAC');

INSERT INTO salesrepresentatives (employeeNumber)
VALUES (1);

-- Insert a sales representative assignment that expires today
INSERT INTO salesrepassignments (employeeNumber, officeCode, startDate, endDate, quota, quota_utilized, salesManagerNumber)
VALUES (1, 101, DATE_SUB(CURDATE(), INTERVAL 7 DAY), CURDATE(), 5000, 1500, '1143');

CALL auto_reassign_salesRep(1);
CALL auto_reassign_salesRep(1166);

-- 4C.E
SELECT * FROM `dbsalesv2.0`.salesrepassignments;
-- insert new assignment for 1166
INSERT INTO `dbsalesv2.0`.`salesrepassignments` (`employeeNumber`, `officeCode`, `startDate`, `endDate`, `quota`) VALUES ('1166', '1', '2024-12-30', '2025-11-21', '100.00');

-- update end date more than one month
UPDATE `dbsalesv2.0`.`salesrepassignments` SET `endDate` = '2025-12-30' WHERE (`employeeNumber` = '1166') and (`officeCode` = '1') and (`startDate` = '2024-11-30');
