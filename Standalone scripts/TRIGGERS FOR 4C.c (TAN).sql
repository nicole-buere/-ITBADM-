-- for requirement 4C-c
-- by Josef Michael T. Tan

-- PART 4C.C (TAN)
-- create a column in the employees table that signifies whether an employee is active or not
ALTER TABLE `dbsalesv2.0`.`employees` 
ADD COLUMN `activeRecord` ENUM('Y', 'N') NULL AFTER `employee_type`;

-- set a value for the new column for those rows who don't have any value in that column
UPDATE `dbsalesv2.0`.employees
SET activeRecord = 'Y'
WHERE activeRecord IS NULL;
