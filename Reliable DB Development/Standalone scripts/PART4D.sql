DROP EVENT IF EXISTS update_credit_limits;
DELIMITER $$

CREATE EVENT update_credit_limits
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-11-01 00:00:00'
DO
BEGIN
    -- Update credit limits based on total order amount for each customer in December 2003
    UPDATE customers c
    JOIN (
        SELECT 
            o.customerNumber, 
            SUM(od.quantityOrdered * od.priceEach) AS customerTotalAmount
        FROM 
            orders o
        JOIN 
            orderdetails od ON o.orderNumber = od.orderNumber
        WHERE 
            MONTH(o.orderDate) = 12  -- December
            AND YEAR(o.orderDate) = 2003  -- 2003
        GROUP BY 
            o.customerNumber
    ) AS customerOrders ON c.customerNumber = customerOrders.customerNumber
    SET 
        c.creditLimit = customerOrders.customerTotalAmount * 2;

    -- Additional credit for customers with more than 15 line items in December 2003
    UPDATE customers c
    JOIN (
        SELECT 
            o.customerNumber, 
            MAX(od.quantityOrdered * od.priceEach) AS maxOrderAmount
        FROM 
            orders o
        JOIN 
            orderdetails od ON o.orderNumber = od.orderNumber
        WHERE 
            MONTH(o.orderDate) = 12
            AND YEAR(o.orderDate) = 2003
        GROUP BY 
            o.customerNumber
        HAVING 
            COUNT(*) > 15  -- Total line items, not distinct orders
    ) AS extraCredit ON c.customerNumber = extraCredit.customerNumber
    SET 
        c.creditLimit = c.creditLimit + extraCredit.maxOrderAmount;
END $$

DELIMITER ;