DELIMITER $$

CREATE EVENT update_credit_limits
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-12-01 00:00:00'
DO
BEGIN
    DECLARE customer_id INT;
    DECLARE total_order_amount DECIMAL(10, 2);
    DECLARE max_order_amount DECIMAL(10, 2);
    DECLARE order_count INT;
    DECLARE done INT DEFAULT 0;
    
    -- Cursor to loop through each customer
    DECLARE cur CURSOR FOR
        SELECT customerNumber
        FROM customers;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- Open the cursor to process each customer
    OPEN cur;
    
    loop_customers: LOOP
        FETCH cur INTO customer_id;
        IF done THEN
            LEAVE loop_customers;
        END IF;
        
        -- Calculate the total order amount for the customer this month
        SELECT SUM(orderdetails.priceEach * orderdetails.quantityOrdered)
        INTO total_order_amount
        FROM orders
        JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber
        WHERE orders.customerNumber = customer_id
          AND MONTH(orders.orderDate) = MONTH(CURRENT_DATE - INTERVAL 1 MONTH)
          AND YEAR(orders.orderDate) = YEAR(CURRENT_DATE - INTERVAL 1 MONTH);
        
        -- Calculate the number of orders placed by the customer this month
        SELECT COUNT(*)
        INTO order_count
        FROM orders
        WHERE customerNumber = customer_id
          AND MONTH(orderDate) = MONTH(CURRENT_DATE - INTERVAL 1 MONTH)
          AND YEAR(orderDate) = YEAR(CURRENT_DATE - INTERVAL 1 MONTH);
        
        -- Set the credit limit to twice the total order amount
        IF total_order_amount IS NOT NULL THEN
            UPDATE customers
            SET creditLimit = total_order_amount * 2
            WHERE customerNumber = customer_id;
        END IF;

        -- If the customer made more than 15 orders, give an extra credit limit
        IF order_count > 15 THEN
            -- Calculate the maximum single order amount for the customer this month
            SELECT MAX(orderdetails.priceEach * orderdetails.quantityOrdered)
            INTO max_order_amount
            FROM orders
            JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber
            WHERE orders.customerNumber = customer_id
              AND MONTH(orders.orderDate) = MONTH(CURRENT_DATE - INTERVAL 1 MONTH)
              AND YEAR(orders.orderDate) = YEAR(CURRENT_DATE - INTERVAL 1 MONTH);
            
            -- Increase the credit limit by the highest single order amount
            UPDATE customers
            SET creditLimit = creditLimit + max_order_amount
            WHERE customerNumber = customer_id;
        END IF;
        
    END LOOP;
    
    -- Close the cursor
    CLOSE cur;

END $$

DELIMITER ;
