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


