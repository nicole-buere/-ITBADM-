// compile first: javac -cp ".;mysql-connector-j-9.0.0.jar" products.java
// then run: java -cp ".;mysql-connector-j-9.0.0.jar" products.java

// ALTER TABLE products ADD COLUMN status ENUM('ACTIVE', 'DEACTIVATED') DEFAULT 'ACTIVE';
// Update status of product to deactivated (if there's new column for status)
            /*try (PreparedStatement updateStmt = conn.prepareStatement(
                "UPDATE products SET status = 'DEACTIVATED' WHERE productCode = ?"
                )) {
                updateStmt.setString(1, productCode);
                updateStmt.executeUpdate();
                }*/

import java.sql.*;
import java.util.*;

public class products {
   
    public String   productCode;
    public String   productName;
    public String   productLine;
    public int      quantityInStock;
    public float    buyPrice;
    public float    MSRP;  
  
    public products() {}

    // viewing of a product 
    public int getInfo() {
        Scanner sc = new Scanner(System.in);

        System.out.println();
        System.out.println("----- Get Product Information -----");
        System.out.println();
        System.out.println("Enter Product Code:");
        productCode = sc.nextLine();

        try {
        // Establish database connection
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!");
            System.out.println("Connection Successful");

        // Disable autocommit
            conn.setAutoCommit(false);

        // Retrieve product details
            PreparedStatement pstmt = conn.prepareStatement("SELECT productName, productLine, quantityInStock, buyPrice, MSRP FROM products WHERE productCode=?FOR SHARE");
            pstmt.setString(1, productCode);

            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();

        // check if the product exists
            ResultSet rs = pstmt.executeQuery();
            if (!rs.next()) {
                // if product does not exists print this and go back to main menu
                System.out.println();
                System.out.println("Product not found. Returning to the main menu...");
                rs.close();
                pstmt.close();
                conn.close();
                return 0;
            }

            // If product exists, retrieve and display its details
            productName = rs.getString("productName");
            productLine = rs.getString("productLine");
            quantityInStock = rs.getInt("quantityInStock");
            buyPrice = rs.getFloat("buyPrice");
            MSRP = rs.getFloat("MSRP");

            System.out.println("---------------------------------------------------------------");
            System.out.println("Product Name: " + productName);
            System.out.println("Product Line: " + productLine);
            System.out.println("Quantity:     " + quantityInStock);
            System.out.println("Buy Price:    " + buyPrice);
            System.out.println("MSRP:         " + MSRP);
            System.out.println("---------------------------------------------------------------");

            System.out.println();
            System.out.println("Press enter key to end transaction and go back to the main menu");
            sc.nextLine();

            // Close resources and commit transaction
            rs.close();
            pstmt.close();
            conn.commit();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
            return 0;
        }
    }


    // update of existing product quantity
    public int updateQuantity() {
        int newQuantity = 0;
        Scanner sc = new Scanner(System.in);

        System.out.println();
        System.out.println("----- Update Product Quantity -----");
        System.out.println();
        System.out.println("Enter Product Code:");
        productCode = sc.nextLine();

        try {
            // Establish database connection
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!");
            System.out.println("Connection Successful");
        
            // Disable autocommit
            conn.setAutoCommit(false);

            // Retrieve product details
            PreparedStatement pstmt = conn.prepareStatement("SELECT productName, productLine, quantityInStock, buyPrice, MSRP FROM products WHERE productCode=?FOR UPDATE");
            pstmt.setString(1, productCode);

            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();

            ResultSet rs = pstmt.executeQuery();

            // check if the product exists, if not go back to main menu
            if (!rs.next()) {
                System.out.println();
                System.out.println("Product not found. Returning to the main menu...");
                rs.close();
                pstmt.close();
                conn.close();
                return 0;
            }

            // Retrieve product details
            productName = rs.getString("productName");
            productLine = rs.getString("productLine");
            quantityInStock = rs.getInt("quantityInStock");
            buyPrice = rs.getFloat("buyPrice");
            MSRP = rs.getFloat("MSRP");

            // Check if product is deactivated, (cannot update deactivated products)
            if (productName.startsWith("DEACTIVATED")) {
                System.out.println();
                System.out.println("This product is deactivated and cannot be updated. Returning to the main menu...");
                rs.close();
                pstmt.close();
                conn.close();
                return 0;
            }

            // if product exists and status is not deactivated Display product details
            System.out.println("---------------------------------------------------------------");
            System.out.println("Product Name: " + productName);
            System.out.println("Product Line: " + productLine);
            System.out.println("Quantity:     " + quantityInStock);
            System.out.println("Buy Price:    " + buyPrice);
            System.out.println("MSRP:         " + MSRP);
            System.out.println("---------------------------------------------------------------");

            rs.close();

            System.out.println();
            System.out.println("Press enter key to enter new values for product quantity");
            sc.nextLine();

            // prompt user to enter new quantity and validate input
            boolean validInput = false;
            while (!validInput) {
                System.out.println();
                System.out.println("Enter your desired quantity for the product (must be greater than 0):");
                try {
                    newQuantity = sc.nextInt();
                    if (newQuantity > 0) {
                    validInput = true;
                    } else {
                    System.out.println("Error: Quantity must be greater than 0. Please try again.");
                    }
                } catch (Exception e) {
                    System.out.println("Error: Invalid input. Please enter a valid integer.");
                    sc.next(); // Clear invalid input
                }
            }

            // update the quantity in the database
            pstmt = conn.prepareStatement("UPDATE products SET quantityInStock = ? WHERE productCode = ?");
            pstmt.setInt(1, newQuantity);
            pstmt.setString(2, productCode);
            pstmt.executeUpdate();

            System.out.println();
            System.out.println("Product quantity has been successfully updated. Press enter key to go back to the main menu...");
            sc.nextLine();

            pstmt.close();
            conn.commit();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
            return 0;
        }
    }



    // deactivate a product
    public int deactivateProduct() {
        Scanner sc = new Scanner(System.in);

        System.out.println();
        System.out.println("----- Deactivate a Product -----");
        System.out.println();
        System.out.println("Enter Product Code:");
        productCode = sc.nextLine();

        try {
            // Establish database connection
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!");
            System.out.println("Connection Successful");

            // Disable autocommit
            conn.setAutoCommit(false);

            // Retrieve product details with write lock
            PreparedStatement pstmt = conn.prepareStatement("SELECT productName, productLine, quantityInStock, buyPrice, MSRP FROM products WHERE productCode=?FOR UPDATE");
            pstmt.setString(1, productCode);

            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();

            ResultSet rs = pstmt.executeQuery();

            // check if the product exists, if not go back to main menu
            if (!rs.next()) {
                System.out.println();
                System.out.println("Product not found. Returning to the main menu...");
                rs.close();
                pstmt.close();
                conn.close();
                return 0;
            }

            // Retrieve product details
            productName = rs.getString("productName");
            productLine = rs.getString("productLine");
            quantityInStock = rs.getInt("quantityInStock");
            buyPrice = rs.getFloat("buyPrice");
            MSRP = rs.getFloat("MSRP");

            // check if the product is already deactivated
            if (productName.startsWith("DEACTIVATED")) {
                System.out.println();
                System.out.println("This product is already deactivated and cannot be deactivated again. Returning to the main menu...");
                rs.close();
                pstmt.close();
                conn.close();
                return 0;
        }

            // if product exists and not deactivated, display product details
            System.out.println("---------------------------------------------------------------");
            System.out.println("Product Name: " + productName);
            System.out.println("Product Line: " + productLine);
            System.out.println("Quantity:     " + quantityInStock);
            System.out.println("Buy Price:    " + buyPrice);
            System.out.println("MSRP:         " + MSRP);
            System.out.println("---------------------------------------------------------------");

            rs.close();

            System.out.println();
            System.out.println("Press enter key to confirm the deactivation of the product");
            sc.nextLine();

            // place 'DEACTIVATED' before the product name
            pstmt = conn.prepareStatement("UPDATE products SET productName = CONCAT('DEACTIVATED ', productName) WHERE productCode = ?");
            pstmt.setString(1, productCode);
            pstmt.executeUpdate();

            System.out.println();
            System.out.println("The product has been successfully deactivated. Press enter key to go back to the main menu...");
            sc.nextLine();

            // Close resources and commit transaction
            pstmt.close();
            conn.commit();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
            return 0;
        }
    }


    
    
    public static void main(String args[]) {
        Scanner sc = new Scanner(System.in);
        int choice = 0;

        System.out.println();
        System.out.println("Product Management Menu:");
        System.out.println("[1] Get Product Information");
        System.out.println("[2] Update Product Quantity");
        System.out.println("[3] Deactivate a Product");
        System.out.println();
        System.out.println("Press [0] to exit.");

        while ((choice = sc.nextInt()) != 0) {
            products p = new products();

            switch (choice) {
                case 1:
                    p.getInfo();
                    break;
                case 2:
                    p.updateQuantity();
                    break;
                case 3:
                    p.deactivateProduct();
                    break;
                default:
                System.out.println("Invalid choice. Please select a valid option.");
        }

            System.out.println("\nProduct Management Menu:");
            System.out.println("[1] Get Product Information");
            System.out.println("[2] Update Product Quantity");
            System.out.println("[3] Deactivate a Product");
            System.out.println();
            System.out.println("Press [0] to exit.");
        }

        System.out.println("Exiting Product Management System. Goodbye!");
    } 
}