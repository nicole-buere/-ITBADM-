-- for requirement 4C-a
-- by Josef Michael T. Tan

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