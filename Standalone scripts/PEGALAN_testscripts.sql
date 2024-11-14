-- SELECT * FROM view_product_msrp WHERE productCode = 'S10_2016';


-- TEST 1
-- Insert a new product to verify it appears in the view
INSERT INTO products (
    productCode, 
    productName, 
    productScale, 
    productVendor, 
    productDescription, 
    buyPrice, 
    product_category
) 
VALUES (
    'S10_9999', 
    'Test Product', 
    '1:24', 
    'Test Vendor', 
    'This is a test product description', 
    100.00, 
    'C'
);

INSERT INTO current_products (
    productCode,
    product_type,
    quantityInStock
) 
VALUES (
    'S10_9999', 
    'R',   -- Assuming product type is 'R' (retail)
    50     -- Assuming there are 50 units in stock
);
INSERT INTO product_retail (productCode)
VALUES ('S10_9999');
INSERT INTO product_pricing (productCode, startdate, enddate, MSRP)
VALUES ('S10_9999', '2024-11-01', '2025-11-01', 150.00);

-- Verify the new product is added to the view and MSRP is generated
SELECT * FROM view_product_msrp WHERE productCode = 'S10_9999';

-- Test 2

-- Insert a new product with different attributes into the products table
INSERT INTO products (
    productCode, 
    productName, 
    productScale, 
    productVendor, 
    productDescription, 
    buyPrice, 
    product_category
) 
VALUES (
    'S10_1001', 
    'Vintage Car Model', 
    '1:18', 
    'Vintage Vendor', 
    'This is a vintage car model description.', 
    120.00, 
    'C'
);

-- Insert the product into current_products with different attributes
INSERT INTO current_products (
    productCode,
    product_type,
    quantityInStock
) 
VALUES (
    'S10_1001', 
    'W',   -- 'W' for wholesale
    100    -- Assuming there are 100 units in stock
);

-- Insert into product_retail (since product is not discontinued)
INSERT INTO product_retail (productCode)
VALUES ('S10_1001');

-- Insert into product_pricing for MSRP
INSERT INTO product_pricing (productCode, startdate, enddate, MSRP)
VALUES ('S10_1001', '2024-11-01', '2025-11-01', 180.00);

-- Verify using the view
SELECT * FROM view_product_msrp WHERE productCode = 'S10_1001'; -- RETURNS NULL MSRP

-- TEST 3
-- Insert a discontinued product
INSERT INTO products (
    productCode, 
    productName, 
    productScale, 
    productVendor, 
    productDescription, 
    buyPrice, 
    product_category
) 
VALUES (
    'S10_2002', 
    'Old Plane Model', 
    '1:50', 
    'Old Vendor', 
    'This is an old plane model that has been discontinued.', 
    90.00, 
    'D'
);

-- Insert into current_products (note the category is 'D' for discontinued)
INSERT INTO current_products (
    productCode,
    product_type,
    quantityInStock
) 
VALUES (
    'S10_2002', 
    'R',   -- Retail product, though it's marked discontinued
    0      -- No stock
);

-- Verify using the view to see if MSRP appears
SELECT * FROM view_product_msrp WHERE productCode = 'S10_2002';

-- TEST 4 
-- Update the MSRP of an existing product
UPDATE product_pricing
SET MSRP = 175.00
WHERE productCode = 'S10_9999' AND startdate = '2024-11-01' AND enddate = '2025-11-01';

-- Verify if the updated MSRP is reflected in the view
SELECT * FROM view_product_msrp WHERE productCode = 'S10_9999';

-- TEST 5
-- Insert a new product without adding MSRP entry
INSERT INTO products (
    productCode, 
    productName, 
    productScale, 
    productVendor, 
    productDescription, 
    buyPrice, 
    product_category
) 
VALUES (
    'S10_4004', 
    'Test Product No MSRP', 
    '1:32', 
    'Test Vendor', 
    'This product does not have an MSRP yet.', 
    50.00, 
    'C'
);

-- Insert into current_products
INSERT INTO current_products (
    productCode,
    product_type,
    quantityInStock
) 
VALUES (
    'S10_4004', 
    'R',   -- Retail type
    15     -- 15 units in stock
);

-- Verify in the view; the MSRP should be NULL since no entry in `product_pricing` table
SELECT * FROM view_product_msrp WHERE productCode = 'S10_4004';




-- Update the MSRP of an existing product
UPDATE product_pricing
SET MSRP = 175.00
WHERE productCode = 'S10_9999' AND startdate = '2024-11-01' AND enddate = '2025-11-01';

-- Verify if the updated MSRP is reflected in the view
SELECT * FROM view_product_msrp WHERE productCode = 'S10_9999';



SELECT * FROM products;
SELECT * FROM view_product_msrp;

-- PART 4A.F tests

SELECT * FROM customers;
SELECT* FROM orders;
SELECT * FROM products;

-- Test Case 1: Order older than 7 days, not shipped yet
-- Insert orders with `orderDate` more than 7 days ago and `shippedDate` still NULL

-- Set the max order number
SET @max_order_number = (SELECT IFNULL(MAX(ordernumber), 0) + 1 FROM orders);

-- Insert a new order (let the trigger handle the orderDate)
INSERT INTO orders (
    ordernumber,
    orderDate,
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
)
VALUES (
    (@max_order_number),  -- Manually set orderNumber to be the highest current orderNumber
    DATE_SUB(NOW(), INTERVAL 8 DAY),  -- Set the order date to 7 days ago
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 7 DAY), INTERVAL 10 DAY), -- Set the required date to 10 days after the order date
    NULL,  -- No shipped date yet
    'In Process',  -- Initial status
    '',  -- comments
    128  -- Customer number
);

-- Verify the order was cancelled
SELECT * 
FROM orders
ORDER BY orderNumber DESC;


-- Test Case 2:  Order Shipped within 7 Days

SET @max_order_number = (SELECT IFNULL(MAX(ordernumber), 0) + 1 FROM orders);

-- Insert a new order where it ships within 7 days from order date
INSERT INTO orders (
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
)
VALUES (
    (@max_order_number),  -- Manually set orderNumber to be the highest current orderNumber
    DATE_SUB(CURDATE(), INTERVAL 7 DAY),        -- Set the order date to 7 days ago
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 7 DAY), INTERVAL 10 DAY), -- Required date is 10 days after the order date
    DATE_SUB(CURDATE(), INTERVAL 5 DAY),        -- Shipped 5 days ago, which is within the 7-day window from the order date
    'In Process',                               -- Initial status of the order
    'Should not be cancelled because it is shipped within a week', -- Comments about the order
    124                                         -- Customer number
);

-- Verify the order was NOT cancelled
SELECT * 
FROM orders
ORDER BY orderNumber DESC;


-- Test case 3: Order older than 7 days with "Completed" status, should not be auto-cancelled

SET @max_order_number = (SELECT IFNULL(MAX(ordernumber), 0) + 1 FROM orders);

-- Insert an order that is older than 7 days, has a "Completed" status, and should not be auto-cancelled
INSERT INTO orders (
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
)
VALUES (
    @max_order_number,  -- Manually set orderNumber to be the highest current orderNumber
    DATE_SUB(CURDATE(), INTERVAL 15 DAY),       -- Set the order date to 15 days ago
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 15 DAY), INTERVAL 10 DAY),  -- Required date is 10 days after order date
    DATE_SUB(CURDATE(), INTERVAL 5 DAY),        -- Set shipped date to 5 days ago
    'Completed',                                -- Set status to "Completed" which should not be cancelled
    'This order should not be auto-cancelled due to its completed status.',
    124                                         -- Customer number
);

-- Verify the order was NOT cancelled
SELECT * 
FROM orders
ORDER BY orderNumber DESC;

-- Test Case 4: Set up an order exactly 7 days old, with status "In Process"

-- Get the next available order number
SET @max_order_number = (SELECT IFNULL(MAX(orderNumber), 0) + 1 FROM orders);

-- Insert an order that is exactly 7 days old and should not be auto-cancelled
INSERT INTO orders (
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
)
VALUES (
    @max_order_number,                             -- Manually set orderNumber to be the highest current orderNumber + 1
    DATE_SUB(CURDATE(), INTERVAL 7 DAY),           -- Set the order date to exactly 7 days ago
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 7 DAY), INTERVAL 10 DAY),  -- Required date is 10 days after order date
    NULL,                                          -- No shipped date yet (order is still in process)
    'In Process',                                  -- Set status to "In Process" which is subject to auto-cancellation
    'Order exactly 7 days old, should not be auto-cancelled.',  -- Comment indicating this is a test case
    125                                            -- Customer number
);

-- Verify the order was NOT cancelled by the auto-cancellation procedure
SELECT * 
FROM orders
ORDER BY orderNumber DESC;


-- Test Case 5: Order exactly 8 days old, should be auto-cancelled
-- Set the next available order number
SET @max_order_number = (SELECT IFNULL(MAX(orderNumber), 0) + 1 FROM orders);

-- Insert an order that is 8 days old, has a status of "In Process", and should be auto-cancelled
INSERT INTO orders (
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
)
VALUES (
    @max_order_number,                             -- Manually set orderNumber to be the highest current orderNumber
    DATE_SUB(CURDATE(), INTERVAL 8 DAY),           -- Set the order date to exactly 8 days ago
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 8 DAY), INTERVAL 10 DAY),  -- Required date is 10 days after order date
    NULL,                                          -- Shipped date is NULL
    'In Process',                                  -- Set status to "In Process" which should be cancelled
    'This order should be auto-cancelled as it is 8 days old without shipment.',
    124                                            -- Customer number
);

-- Call the procedure to auto-cancel unshipped orders
CALL procedure_auto_cancel_unshipped_orders();

-- Verify that the order was cancelled
SELECT * 
FROM orders
WHERE orderNumber = @max_order_number;


-- Credit limit test scripts

ALTER TABLE customers
ADD COLUMN latest_audituser VARCHAR(45) DEFAULT NULL,
ADD COLUMN latest_activityreason VARCHAR(100) DEFAULT NULL;


SELECT * FROM customers; 

-- Check orders of specific customer
SELECT 
	o.customerNumber,
    o.orderNumber,
    o.orderDate,
    o.status,
    od.productCode,
    od.quantityOrdered,
    od.priceEach,
    (od.quantityOrdered * od.priceEach) AS totalAmount
FROM 
    orders o
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
WHERE 
    o.customerNumber = 144;
    
    -- Check how many unique orders a customer placed in specific month and day
SELECT 
    o.customerNumber,
    COUNT( o.orderNumber) AS total_orders
FROM 
    orders o
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
WHERE 
    o.customerNumber = 144					-- 144 (for more than 15 orders)
    AND MONTH(o.orderDate) = 11 			-- 11 (for more than 15 orders)
    AND YEAR(o.orderDate) = 2004;			-- 2004 (for more than 15 orders)
    
    
    -- Check total order amount in a month
    SELECT 
		o.customerNumber,
		SUM(od.quantityOrdered * od.priceEach) AS total_order_amount
	FROM 
		orders o
	JOIN 
		orderdetails od ON o.orderNumber = od.orderNumber
	WHERE 
		o.customerNumber = 144
		AND MONTH(o.orderDate) = 11
		AND YEAR(o.orderDate) = 2004;
        
        
	-- Check order with highest total amount 
	SELECT 
		MAX(od.quantityOrdered * od.priceEach) AS highest_total_amount
	FROM 
		orders o
	JOIN 
		orderdetails od ON o.orderNumber = od.orderNumber
	WHERE 
		o.customerNumber = 144
		AND MONTH(o.orderDate) = 11
		AND YEAR(o.orderDate) = 2004;
    
    
-- Check credit limit
SELECT customerNumber, creditLimit, latest_audituser, latest_activityreason
FROM customers
WHERE customerNumber = 144;

