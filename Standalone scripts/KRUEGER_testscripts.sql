-- Test Cases

-- 4A.D

-- In Process
SELECT * FROM orders 
WHERE orderNumber = 10421; 

SELECT * FROM orderdetails 
WHERE orderNumber = 10421; 

UPDATE orderdetails 
SET quantityOrdered = 60, priceEach = 200
WHERE orderNumber = 10421 AND productCode = "S18_2795";

UPDATE orderdetails 
SET orderLineNumber = 5
WHERE orderNumber = 10421 AND productCode = "S18_2795";

-- ******************************************************************
-- Shipped
SELECT * FROM orders 
WHERE orderNumber = 10100; 

SELECT * FROM orderdetails 
WHERE orderNumber = 10100; 

UPDATE orderdetails 
SET quantityOrdered = 60, priceEach = 200
WHERE orderNumber = 10100 AND productCode = "S18_1749";

INSERT INTO couriers (courierName
					  , address)
VALUES ("FedEx"
		, "Manila Philippines");

INSERT INTO shipments (referenceNo
					   , courierName)
VALUES (1
		, "FedEx");

UPDATE orderdetails 
SET referenceNo = 1
WHERE orderNumber = 10100 AND productCode = "S18_1749";

-- ******************************************************************

-- In Process
SELECT * FROM orders 
WHERE orderNumber = 10421; 

SELECT * FROM orderdetails 
WHERE orderNumber = 10421; 

DELETE FROM orderdetails
WHERE orderNumber = 10421 AND productCode = "S24_2022";

-- ******************************************************************
-- Shipped
SELECT * FROM orders 
WHERE orderNumber = 10100; 

SELECT * FROM orderdetails 
WHERE orderNumber = 10100; 

DELETE FROM orderdetails
WHERE orderNumber = 10100 AND productCode = "S24_3969";

-- ******************************************************************

-- 4B.B

SELECT * FROM products;

INSERT INTO products (productCode
                     , productName
                     , productScale
                     , productVendor
                     , productDescription
                     , buyPrice
                     , product_category)
VALUES ("S73_1234"
        , "Test product"
        , "1:72"
        , "Test vendor"
        , "Test description"
        , 100
        , "C");

SELECT * FROM productlines;

INSERT INTO productlines (productLine
						 ,textDescription)
     VALUES ("New Productline"
		     ,"Test description" );
        
SELECT * FROM product_productlines
WHERE productCode = "S73_1234";

INSERT INTO product_productlines (productCode
								 ,productline)
	 VALUES ("S73_1234"
			,"New Productline");
        
DELETE 
  FROM product_productlines
 WHERE productCode = "S73_1234" 
   AND productline = "New Productline";

UPDATE product_productlines
   SET productline = "New Productline"
 WHERE productCode = "S10_1949";
 
SELECT * 
  FROM product_productlines
 WHERE productCode = "S10_1949";
 
 -- ******************************************************************
 
 -- 4C.F
 
 SELECT * 
   FROM employees
  WHERE employee_type = "Sales Representative";
  
SELECT *
  FROM salesrepassignments
 WHERE employeeNumber = "1702";
 
UPDATE employees
   SET employee_type = "Sales Manager"
 WHERE employeeNumber = "1702";