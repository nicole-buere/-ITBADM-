-- TRIGGERS FOR 4b.a
DELIMITER $$
DROP TRIGGER IF EXISTS `product_BEFORE_INSERT`;
CREATE TRIGGER product_BEFORE_INSERT BEFORE INSERT ON `dbsalesV2.0`.`products` FOR EACH ROW BEGIN
    -- Automatically sets product category to 'C' (Current) if not defined
    IF NEW.product_category IS NULL THEN
        SET new.product_category = 'C';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `product_AFTER_INSERT`;
CREATE TRIGGER product_AFTER_INSERT AFTER INSERT ON `dbsalesV2.0`.`products` FOR EACH ROW BEGIN
	DECLARE msrp_value DECIMAL(9,2);
    
    -- Automatically insert the new product into the current_products table
    INSERT INTO `dbsalesV2.0`.`current_products` (`productCode`, `product_type`)
    VALUES (new.productCode, new.product_type);

    -- Check the product type to insert it into the appropriate table
    IF NEW.product_type = 'R' THEN
        -- Insert into product_retail if the product is for retail
        INSERT INTO `dbsalesV2.0`.`product_retail` (`productCode`)
        VALUES (new.productCode);
        
    ELSEIF NEW.product_type = 'W' THEN
		SET msrp_value = getMSRP(new.productCode);
        -- Insert into product_wholesale if the product is for wholesale
        INSERT INTO `dbsalesV2.0`.`product_wholesale` (`productCode`, `MSRP`)
        VALUES (new.productCode, msrp_value);
    END IF;

END$$
DELIMITER ;

-- TRIGGER FOR 4b.d
DELIMITER $$
DROP TRIGGER IF EXISTS `current_product_BEFORE_UPDATE`;
CREATE TRIGGER `current_product_BEFORE_UPDATE`BEFORE UPDATE ON `dbsalesV2.0`.`current_products`FOR EACH ROW BEGIN
    DECLARE errormessage VARCHAR(200);
    -- Check if the product type is being modified
    IF OLD.product_type != NEW.product_type THEN
		SET errormessage = CONCAT('Product type for ', new.productCode, ' cannot be modified from ', old.product_type, ' to ', new.product_type);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errormessage;
    END IF;
END$$
DELIMITER ;