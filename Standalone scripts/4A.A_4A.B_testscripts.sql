-- 4A.A Test scripts
-- Test Script for Trigger: orders_BEFORE_INSERT

-- Test Case 1: Insert a valid order
-- Expectation: The order should be inserted successfully
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Required date is 5 days from now (valid)
    NULL,                             -- No shipped date for new order
    NULL,                             -- Status will be set by trigger
    'Test order with valid required date',
    121                               -- Valid customer number
);

-- Test Case 2: Insert an order with a required date less than 3 days from order date
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 2 DAY),  -- Required date is only 2 days from now (invalid)
    NULL,
    NULL,
    'Test order with invalid required date',
    121
);

-- Test Case 3: Insert an order with a shipped date specified
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Valid required date
    NOW(),                            -- Shipped date is set (invalid for new order)
    NULL,
    'Test order with shipped date set for new order',
    121
);

-- Test Case 4: Insert an order without a customer number
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Valid required date
    NULL,
    NULL,
    'Test order without customer number',
    NULL                              -- Customer number is NULL (invalid)
);

-- Test Case 5: Insert an order with a required date exactly 3 days from order date
-- Expectation: The order should be inserted successfully
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 3 DAY),  -- Required date is exactly 3 days from now (valid)
    NULL,
    NULL,
    'Test order with required date exactly 3 days from now',
    121                              -- Valid customer number
);

-- Verify inserted orders
SELECT * FROM orders ORDER BY ordernumber DESC;


-- Test Script for Trigger: orders_BEFORE_INSERT

-- Test Case 1: Insert a valid order
-- Expectation: The order should be inserted successfully
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Required date is 5 days from now (valid)
    NULL,                             -- No shipped date for new order
    NULL,                             -- Status will be set by trigger
    'Test order with valid required date',
    121                               -- Valid customer number
);

-- Test Case 2: Insert an order with a required date less than 3 days from order date
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 2 DAY),  -- Required date is only 2 days from now (invalid)
    NULL,
    NULL,
    'Test order with invalid required date',
    121
);

-- Test Case 3: Insert an order with a shipped date specified
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Valid required date
    NOW(),                            -- Shipped date is set (invalid for new order)
    NULL,
    'Test order with shipped date set for new order',
    121
);

-- Test Case 4: Insert an order without a customer number
-- Expectation: Trigger should signal an error
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 5 DAY),  -- Valid required date
    NULL,
    NULL,
    'Test order without customer number',
    NULL                              -- Customer number is NULL (invalid)
);

-- Test Case 5: Insert an order with a required date exactly 3 days from order date
-- Expectation: The order should be inserted successfully
INSERT INTO orders (
    requiredDate,
    shippedDate,
    status,
    comments,
    customerNumber
) VALUES (
    DATE_ADD(NOW(), INTERVAL 3 DAY),  -- Required date is exactly 3 days from now (valid)
    NULL,
    NULL,
    'Test order with required date exactly 3 days from now',
    121                              -- Valid customer number
);

-- Verify inserted orders
SELECT * FROM orders ORDER BY ordernumber DESC;

-- Test Script for Part 4A.B
-- Test Script for Trigger: orderdetails_BEFORE_INSERT

-- Test Case 1: Insert a valid order detail
-- Expectation: The order detail should be inserted successfully
INSERT INTO orderdetails (
    ordernumber,
    productCode,
    quantityOrdered,
    priceEach
) VALUES (
    10102,                        -- Existing order number
    'S10_1678',               -- Existing product code
    5,                        -- Quantity within available stock
    getMSRP('S10_1678') * 1.1 -- Price within allowed range (10% above MSRP)
);

-- Test Case 2: Insert an order detail with price below 80% of MSRP
-- Expectation: Trigger should signal an error
INSERT INTO orderdetails (
    ordernumber,
    productCode,
    quantityOrdered,
    priceEach
) VALUES (
    1,                        -- Existing order number
    'S10_1678',               -- Existing product code
    5,                        -- Valid quantity
    getMSRP('S10_1678') * 0.7 -- Price below 80% of MSRP (invalid)
);

-- Test Case 3: Insert an order detail with price above 200% of MSRP
-- Expectation: Trigger should signal an error
INSERT INTO orderdetails (
    ordernumber,
    productCode,
    quantityOrdered,
    priceEach
) VALUES (
    1,                        -- Existing order number
    'S10_1678',               -- Existing product code
    5,                        -- Valid quantity
    getMSRP('S10_1678') * 2.5 -- Price above 200% of MSRP (invalid)
);


-- Verify inserted order details
SELECT * FROM orderdetails ORDER BY ordernumber, orderlinenumber DESC;



