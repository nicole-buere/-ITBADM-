
-- Audit Tables and Automatic Population Script
-- Extended DB Sales
-- This script will create Audit Tables and triggers to automatically 
-- populate the audit tables as data activities happen on tables

DROP TABLE IF EXISTS audit_products;
CREATE TABLE audit_products (
  activity 					enum('C','U','D') 	DEFAULT NULL,
  activity_timestamp		datetime 			NOT NULL,
  productCode 				varchar(15) 		NOT NULL,
  old_productname 			varchar(70) 		DEFAULT NULL,
  old_productscale 			varchar(10) 		DEFAULT NULL,
  old_vendor 				varchar(50) 		DEFAULT NULL,
  old_productdescription 	text,
  old_buyprice 				double 				DEFAULT NULL,
  old_productcategory 		enum('C','D')		DEFAULT NULL,
  new_productname 			varchar(70) 		DEFAULT NULL,
  new_productscale 			varchar(10) 		DEFAULT NULL,
  new_vendor 				varchar(50) 		DEFAULT NULL,
  new_productdescription 	text,
  new_buyprice 				double 				DEFAULT NULL,
  new_productcategory 		enum('C','D')		DEFAULT NULL,
  dbuser 					varchar(45)	 		DEFAULT NULL,
  latest_audituser 			varchar(45) 		DEFAULT NULL,
  latest_authorizinguser	varchar(45) 		DEFAULT NULL,
  latest_activityreason	 	varchar(45) 		DEFAULT NULL,
  latest_activitymethod 	enum('W','M','D') 	DEFAULT NULL,
  PRIMARY KEY (productCode,activity_timestamp)
);

ALTER TABLE products
  ADD COLUMN latest_audituser 			varchar(45) DEFAULT NULL,
  ADD COLUMN latest_authorizinguser 	varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activityreason 		varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activitymethod 		enum('W','M','D') DEFAULT NULL;
  
DROP TRIGGER IF EXISTS products_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER products_AFTER_INSERT AFTER INSERT ON products FOR EACH ROW BEGIN
	INSERT INTO audit_products VALUES
		('C', NOW(), new.productCode, NULL, NULL, NULL, NULL, NULL, NULL,
		  new.productName, new.productScale, new.productVendor, 
          new.productDescription, new.buyPrice, new.product_category,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS products_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER products_AFTER_UPDATE AFTER UPDATE ON products FOR EACH ROW BEGIN
	INSERT INTO audit_products VALUES
		('U', NOW(), new.productCode, 
		  old.productName, old.productScale, old.productVendor, 
          old.productDescription, old.buyPrice, old.product_category,
		  new.productName, new.productScale, new.productVendor, 
          new.productDescription, new.buyPrice, new.product_category,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS products_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER products_BEFORE_DELETE BEFORE DELETE ON products FOR EACH ROW BEGIN
	INSERT INTO audit_products VALUES
		('D', NOW(), old.productCode, NULL, NULL, NULL, NULL, NULL, NULL,
		  old.productName, old.productScale, old.productVendor, 
          old.productDescription, old.buyPrice, old.product_category,
          USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

DROP TABLE IF EXISTS audit_orders;
CREATE TABLE audit_orders (
  activity 					enum('C','U','D') 	DEFAULT NULL,
  activity_timestamp		datetime 			NOT NULL,
  orderNumber 				int	 				NOT NULL,
  old_orderDate	 			datetime 			DEFAULT NULL,
  old_requiredDate	 		datetime 			DEFAULT NULL,
  old_shippedDate 			datetime 			DEFAULT NULL,
  old_status 				varchar(15) 		DEFAULT NULL,
  old_comments				text,
  old_customerNumber		int					DEFAULT NULL,
  new_orderDate	 			datetime 			DEFAULT NULL,
  new_requiredDate	 		datetime 			DEFAULT NULL,
  new_shippedDate 			datetime 			DEFAULT NULL,
  new_status 				varchar(15) 		DEFAULT NULL,
  new_comments				text,
  new_customerNumber		int					DEFAULT NULL,
  dbuser 					varchar(45)	 		DEFAULT NULL,
  latest_audituser 			varchar(45) 		DEFAULT NULL,
  latest_authorizinguser	varchar(45) 		DEFAULT NULL,
  latest_activityreason	 	varchar(45) 		DEFAULT NULL,
  latest_activitymethod 	enum('W','M','D') 	DEFAULT NULL,
  PRIMARY KEY (orderNumber, activity_timestamp)
);

ALTER TABLE orders
  ADD COLUMN latest_audituser 			varchar(45) DEFAULT NULL,
  ADD COLUMN latest_authorizinguser 	varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activityreason 		varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activitymethod 		enum('W','M','D') DEFAULT NULL;
  
DROP TRIGGER IF EXISTS orders_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER orders_AFTER_INSERT AFTER INSERT ON orders FOR EACH ROW BEGIN
	INSERT INTO audit_orders VALUES
		('C', NOW(), new.orderNumber, NULL, NULL, NULL, NULL, NULL, NULL,
		  new.orderDate, new.requiredDate, new.shippedDate, 
          new.`status`, new.comments, new.customerNumber,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orders_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER orders_AFTER_UPDATE AFTER UPDATE ON orders FOR EACH ROW BEGIN
	INSERT INTO audit_orders VALUES
		('U', NOW(), new.orderNumber, 
		  old.orderDate, old.requiredDate, old.shippedDate, 
          old.`status`, old.comments, old.customerNumber,
		  new.orderDate, new.requiredDate, new.shippedDate, 
          new.`status`, new.comments, new.customerNumber,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orders_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER orders_BEFORE_DELETE BEFORE DELETE ON orders FOR EACH ROW BEGIN
	INSERT INTO audit_orders VALUES
		('D', NOW(), old.orderNumber, NULL, NULL, NULL, NULL, NULL, NULL,
        old.orderDate, old.requiredDate, old.shippedDate, 
		old.`status`, old.comments, old.customerNumber,
		USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

DROP TABLE IF EXISTS audit_orderdetails;
CREATE TABLE audit_orderdetails (
  activity 					enum('C','U','D') 	DEFAULT NULL,
  activity_timestamp		datetime 			NOT NULL,
  orderNumber 				int	 				NOT NULL,
  productCode				varchar(15)			NOT NULL,
  old_quantityOrdered	 	int 				DEFAULT NULL,
  old_priceEach		 		double 				DEFAULT NULL,
  old_orderLineNumber 		smallint 			DEFAULT NULL,
  old_referenceNo 			int					DEFAULT NULL,
  new_quantityOrdered	 	int 				DEFAULT NULL,
  new_priceEach		 		double 				DEFAULT NULL,
  new_orderLineNumber 		smallint 			DEFAULT NULL,
  new_referenceNo 			int					DEFAULT NULL,
  dbuser 					varchar(45)	 		DEFAULT NULL,
  latest_audituser 			varchar(45) 		DEFAULT NULL,
  latest_authorizinguser	varchar(45) 		DEFAULT NULL,
  latest_activityreason	 	varchar(45) 		DEFAULT NULL,
  latest_activitymethod 	enum('W','M','D') 	DEFAULT NULL,
  PRIMARY KEY (orderNumber, productCode, activity_timestamp)
);

ALTER TABLE orderdetails
  ADD COLUMN latest_audituser 			varchar(45) DEFAULT NULL,
  ADD COLUMN latest_authorizinguser 	varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activityreason 		varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activitymethod 		enum('W','M','D') DEFAULT NULL;
  
DROP TRIGGER IF EXISTS orderdetails_AFTER_INSERT;
DELIMITER $$
CREATE	TRIGGER orderdetails_AFTER_INSERT AFTER INSERT ON orderdetails FOR EACH ROW BEGIN
	INSERT INTO audit_orderdetails VALUES
		('C', NOW(), new.orderNumber, new.productCode, NULL, NULL, NULL, NULL, NULL, NULL,
		  new.quantityOrdered, new.priceEach, new.orderLineNumber, 
          new.referenceNo,
          USER(), 
          new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_AFTER_UPDATE;
DELIMITER $$
CREATE TRIGGER orderdetails_AFTER_UPDATE AFTER UPDATE ON orderdetails FOR EACH ROW BEGIN
	INSERT INTO audit_orderdetails VALUES
		('U', NOW(), new.orderNumber, new.productCode, 
		  old.quantityOrdered, old.priceEach, 
          old.orderLineNumber, old.referenceNo,
		  new.quantityOrdered, new.priceEach, 
          new.orderLineNumber, new.referenceNo,
          USER(), new.latest_audituser, new.latest_authorizinguser,
          new.latest_activityreason, new.latest_activitymethod);
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS orderdetails_BEFORE_DELETE;
DELIMITER $$
CREATE TRIGGER orderdetails_BEFORE_DELETE BEFORE DELETE ON orderdetails FOR EACH ROW BEGIN
	INSERT INTO audit_orderdetails VALUES
		('D', NOW(), old.orderNumber, old.productCode, NULL, NULL, NULL, NULL, NULL, NULL,
        old.quantityOrdered, old.priceEach, 
		old.orderLineNumber, old.referenceNo,
		USER(), NULL, NULL, NULL, NULL);
END $$
DELIMITER ;

-- 4C.D 
DROP TABLE IF EXISTS audit_salesrepassignments;
CREATE TABLE audit_salesrepassignments (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    employeeNumber INT,
    officeCode INT,
    startDate DATETIME,
    endDate DATETIME,
    quota DECIMAL(10, 2),
    quota_utilized DECIMAL(10, 2),
    reassigned_by VARCHAR(50),
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(50)
);

-- audit table for current_products (TAN)
DROP TABLE IF EXISTS audit_current_products;
CREATE TABLE audit_current_products (
  activity 					enum('C','U','D') 	DEFAULT NULL,
  activity_timestamp		datetime 			NOT NULL,
  productCode 				varchar(15) 		NOT NULL,
  old_product_type 			enum('R','W') 		DEFAULT NULL,
  old_quantityInStock		smallInt 			DEFAULT NULL,
  new_product_type 			enum('R','W') 		DEFAULT NULL,
  new_quantityInStock		smallInt			DEFAULT NULL,
  dbuser 					varchar(45)	 		DEFAULT NULL,
  latest_audituser 			varchar(45) 		DEFAULT NULL,
  latest_authorizinguser	varchar(45) 		DEFAULT NULL,
  latest_activityreason	 	varchar(45) 		DEFAULT NULL,
  latest_activitymethod 	enum('W','M','D') 	DEFAULT NULL,
  PRIMARY KEY (productCode,activity_timestamp)
);

-- audit table for discontinued_products (TAN)
DROP TABLE IF EXISTS audit_discontinued_products;
CREATE TABLE audit_discontinued_products (
  activity 					enum('C','U','D') 	DEFAULT NULL,
  activity_timestamp		datetime 			NOT NULL,
  productCode 				varchar(15) 		NOT NULL,
  old_reason				varchar(45)			DEFAULT NULL,
  old_inventory_manager		int					DEFAULT NULL,
  old_quantityLeft			smallint			DEFAULT NULL,
  new_reason				varchar(45)			DEFAULT NULL,
  new_inventory_manager		int					DEFAULT NULL,
  new_quantityLeft			smallint			DEFAULT NULL,
  dbuser 					varchar(45)	 		DEFAULT NULL,
  latest_audituser 			varchar(45) 		DEFAULT NULL,
  latest_authorizinguser	varchar(45) 		DEFAULT NULL,
  latest_activityreason	 	varchar(45) 		DEFAULT NULL,
  latest_activitymethod 	enum('W','M','D') 	DEFAULT NULL,
  PRIMARY KEY (productCode,activity_timestamp)
);

-- alter current products to include columns used for audit
ALTER TABLE current_products
  ADD COLUMN latest_audituser 			varchar(45) DEFAULT NULL,
  ADD COLUMN latest_authorizinguser 	varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activityreason 		varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activitymethod 		enum('W','M','D') DEFAULT NULL;

-- alter discontinued products to include columns used for audit
ALTER TABLE discontinued_products
  ADD COLUMN latest_audituser 			varchar(45) DEFAULT NULL,
  ADD COLUMN latest_authorizinguser 	varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activityreason 		varchar(45) DEFAULT NULL,
  ADD COLUMN latest_activitymethod 		enum('W','M','D') DEFAULT NULL;