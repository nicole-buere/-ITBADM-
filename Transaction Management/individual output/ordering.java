/*
javac -cp .;mysql-connector-j-9.0.0.jar ordering.java
-- to compile
*/ 



/*
java -cp .;mysql-connector-j-9.0.0.jar ordering
-- to run
*/ 



import java.sql.*;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

public class ordering {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "DLSU1234!";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        try (Connection connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            System.out.println("--------------------------------------------------");
            System.out.println("Connected to the database.");

            while (true) {
                System.out.println("\n[Order Management]");
                System.out.println("--------------------------------------------------");
                System.out.println("Menu:");
                System.out.println("1. Place an Order");
                System.out.println("2. Update an Order");
                System.out.println("3. Cancel an Order");
                System.out.println("4. Exit");
                System.out.println("--------------------------------------------------");
                System.out.print("Enter your choice: ");
                int choice = scanner.nextInt();

                switch (choice) {
                    case 1 -> placeOrder(connection, scanner);
                    case 2 -> updateOrder(connection, scanner);
                    case 3 -> cancelOrder(connection, scanner);
                    case 4 -> {
                        System.out.println("Exiting the system. Goodbye!");
                        return;
                    }
                    default -> System.out.println("Invalid choice. Please select from the menu.");
                }
            }
        } catch (SQLException e) {
            System.err.println("Database connection error: " + e.getMessage());
        }
    }

    private static void placeOrder(Connection connection, Scanner scanner) throws SQLException {
        scanner.nextLine(); // Consume newline
    
        // Input Required Date with Validation
        String requiredDate;
        while (true) {
            System.out.print("Enter Required Date (YYYY-MM-DD): ");
            requiredDate = scanner.nextLine();
    
            try {
                java.sql.Date orderDate = new java.sql.Date(System.currentTimeMillis()); // Current date as order date
                java.sql.Date requiredSqlDate = java.sql.Date.valueOf(requiredDate);
    
                if (requiredSqlDate.before(orderDate)) {
                    System.out.println("Invalid Required Date. It cannot be earlier than today's date (" + orderDate + ").");
                } else {
                    break; // Valid required date
                }
            } catch (IllegalArgumentException e) {
                System.out.println("Invalid date format. Please enter in YYYY-MM-DD format.");
            }
        }
    
        System.out.print("Comment: ");
        String strComment = scanner.nextLine();
        System.out.print("Enter Customer Number: ");
        int customerNumber = scanner.nextInt();
        scanner.nextLine(); // Consume newline
    
        connection.setAutoCommit(false);
        try {
            System.out.println("\nGenerating order number...");
            int orderNumber = generateOrderNumber(connection);
            System.out.println("Order number generated: " + orderNumber);
    
            // Insert into Orders
            String insertOrderSQL = "INSERT INTO orders (orderNumber, orderDate, requiredDate, shippedDate, status, comments, customerNumber) VALUES (?, CURDATE(), ?, NULL, 'In Process', ?, ?)";
            try (PreparedStatement orderStmt = connection.prepareStatement(insertOrderSQL)) {
                orderStmt.setInt(1, orderNumber);
                orderStmt.setString(2, requiredDate);
                orderStmt.setString(3, strComment);
                orderStmt.setInt(4, customerNumber);
                orderStmt.executeUpdate();
                System.out.println("Order created successfully.");
            }
    
            // Add Products to Order
            int nLineNumber = 0;
            boolean addMoreProducts = true;
            while (addMoreProducts) {
                System.out.print("Enter Product Code: ");
                String productCode = scanner.nextLine();
    
                String productCheckSQL = "SELECT * FROM products WHERE productCode = ? FOR UPDATE";
                try (PreparedStatement productStmt = connection.prepareStatement(productCheckSQL)) {
                    productStmt.setString(1, productCode);
                    ResultSet productResult = productStmt.executeQuery();
    
                    if (productResult.next()) {
                        int availableQuantity = productResult.getInt("quantityInStock");
                        double msrp = productResult.getDouble("MSRP");
    
                        System.out.println("\nProduct locked for order. Press any key to continue...");
                        scanner.nextLine();
    
                        System.out.print("Enter Quantity to Order: ");
                        int quantityOrdered = scanner.nextInt();
                        scanner.nextLine(); // Consume newline
    
                        if (quantityOrdered > availableQuantity) {
                            System.out.println("Insufficient stock. Available: " + availableQuantity);
                            continue;
                        }
    
                        System.out.print("Enter Price Each: ");
                        double priceEach = scanner.nextDouble();
                        scanner.nextLine(); // Consume newline
    
                        if (priceEach < msrp) {
                            System.out.println("Price cannot be below MSRP: " + msrp);
                            continue;
                        }
    
                        nLineNumber++;
                        String insertOrderDetailsSQL = "INSERT INTO orderdetails (orderNumber, productCode, quantityOrdered, priceEach, orderLineNumber) VALUES (?, ?, ?, ?, ?)";
                        try (PreparedStatement orderDetailsStmt = connection.prepareStatement(insertOrderDetailsSQL)) {
                            orderDetailsStmt.setInt(1, orderNumber);
                            orderDetailsStmt.setString(2, productCode);
                            orderDetailsStmt.setInt(3, quantityOrdered);
                            orderDetailsStmt.setDouble(4, priceEach);
                            orderDetailsStmt.setInt(5, nLineNumber);
                            orderDetailsStmt.executeUpdate();
                            System.out.println("Order details updated successfully.");
                        }
    
                        String updateProductSQL = "UPDATE products SET quantityInStock = quantityInStock - ? WHERE productCode = ?";
                        try (PreparedStatement updateProductStmt = connection.prepareStatement(updateProductSQL)) {
                            updateProductStmt.setInt(1, quantityOrdered);
                            updateProductStmt.setString(2, productCode);
                            updateProductStmt.executeUpdate();
                            System.out.println("Product inventory updated.");
                        }
                    } else {
                        System.out.println("Product not found.");
                    }
                }
    
                System.out.print("Add another product? (yes/no): ");
                String response = scanner.nextLine();
                addMoreProducts = response.equalsIgnoreCase("yes");
            }
    
            connection.commit();
            System.out.println("Order processing complete.");
        } catch (Exception e) {
            System.err.println("Error processing order. Rolling back changes...");
            e.printStackTrace();
            connection.rollback();
        } finally {
            connection.setAutoCommit(true);
        }
    }
    

    private static void updateOrder(Connection connection, Scanner scanner) throws SQLException {
        System.out.println("Enter Order Number to Update: ");
        int orderNumber = scanner.nextInt();
        scanner.nextLine(); // Consume newline
    
        connection.setAutoCommit(false);
    
        try {
            System.out.println("Press enter key to start retrieving the order details...");
            scanner.nextLine();
    
            String fetchOrderSQL = "SELECT orderNumber, orderDate, requiredDate, shippedDate, status, comments, customerNumber FROM orders WHERE orderNumber = ? FOR UPDATE";
            PreparedStatement pstmt = connection.prepareStatement(fetchOrderSQL);
            pstmt.setInt(1, orderNumber);
    
            ResultSet rs = pstmt.executeQuery();
    
            if (rs.next()) {
                // Retrieve and display order details
                int currentOrderNumber = rs.getInt("orderNumber");
                java.sql.Date orderDate = rs.getDate("orderDate");
                java.sql.Date requiredDate = rs.getDate("requiredDate");
                java.sql.Date shippedDate = rs.getDate("shippedDate");
                String currentStatus = rs.getString("status");
                String comments = rs.getString("comments");
                int customerNumber = rs.getInt("customerNumber");
    
                System.out.println("--------------------------------------------------");
                System.out.println("Order Number:   " + currentOrderNumber);
                System.out.println("Order Date:     " + orderDate);
                System.out.println("Required Date:  " + requiredDate);
                System.out.println("Shipped Date:   " + (shippedDate != null ? shippedDate : "Not Shipped"));
                System.out.println("Status:         " + currentStatus);
                System.out.println("Comments:       " + comments);
                System.out.println("Customer Number:" + customerNumber);
                System.out.println("--------------------------------------------------");
    
                rs.close();
                pstmt.close();
    
                // Rule: No updates allowed if the status is "Completed"
                if ("Completed".equalsIgnoreCase(currentStatus)) {
                    System.out.println("No updates allowed for orders with status 'Completed'.");
                    connection.rollback();
                    return;
                }
    
                System.out.println("What would you like to update?");
                System.out.println("[1] Required Date");
                System.out.println("[2] Status");
                System.out.println("[3] Both Required Date and Status");
                System.out.print("Enter your choice: ");
                int choice = scanner.nextInt();
                scanner.nextLine(); // Consume newline
    
                boolean updatedRequiredDate = false;
                boolean updatedStatus = false;
    
                if (choice == 1 || choice == 3) {
                    // Update Required Date
                    while (true) {
                        System.out.print("Enter new Required Date (YYYY-MM-DD): ");
                        String newRequiredDateStr = scanner.nextLine();
    
                        try {
                            java.sql.Date newRequiredDate = java.sql.Date.valueOf(newRequiredDateStr);
                            if (newRequiredDate.before(orderDate)) {
                                System.out.println("Invalid Required Date. It cannot be earlier than the Order Date (" + orderDate + ").");
                            } else {
                                String updateRequiredDateSQL = "UPDATE orders SET requiredDate = ? WHERE orderNumber = ?";
                                try (PreparedStatement updateRequiredDateStmt = connection.prepareStatement(updateRequiredDateSQL)) {
                                    updateRequiredDateStmt.setDate(1, newRequiredDate);
                                    updateRequiredDateStmt.setInt(2, currentOrderNumber);
                                    updateRequiredDateStmt.executeUpdate();
                                    System.out.println("Required Date updated successfully to " + newRequiredDate + ".");
                                    updatedRequiredDate = true;
                                }
                                break; // Exit loop after successful update
                            }
                        } catch (IllegalArgumentException e) {
                            System.out.println("Invalid date format. Please enter in YYYY-MM-DD format.");
                        }
                    }
                }
    
                if (choice == 2 || choice == 3) {
                    // Update Status
                    System.out.println("Choose a new status:");
                    System.out.println("[1] Shipped");
                    System.out.println("[2] Completed");
                    System.out.print("Enter your choice: ");
                    int statusChoice = scanner.nextInt();
                    scanner.nextLine(); // Consume newline
    
                    String newStatus = null;
    
                    // Validate the choice and determine the new status
                    if (statusChoice == 1) {
                        newStatus = "Shipped";
                        if (!"In Process".equalsIgnoreCase(currentStatus)) {
                            System.out.println("Invalid choice. Only 'In Process' can be changed to 'Shipped'.");
                            connection.rollback();
                            return;
                        }
                    } else if (statusChoice == 2) {
                        newStatus = "Completed";
                        if (!"Shipped".equalsIgnoreCase(currentStatus)) {
                            System.out.println("Invalid choice. Only 'Shipped' can be changed to 'Completed'.");
                            connection.rollback();
                            return;
                        }
                    } else {
                        System.out.println("Invalid choice. No updates made.");
                        connection.rollback();
                        return;
                    }
    
                    // Update status (and shippedDate if transitioning to "Shipped")
                    String updateOrderSQL;
                    if ("Shipped".equalsIgnoreCase(newStatus)) {
                        updateOrderSQL = "UPDATE orders SET status = ?, shippedDate = CURDATE() WHERE orderNumber = ?";
                    } else {
                        updateOrderSQL = "UPDATE orders SET status = ? WHERE orderNumber = ?";
                    }
    
                    pstmt = connection.prepareStatement(updateOrderSQL);
                    pstmt.setString(1, newStatus);
                    pstmt.setInt(2, orderNumber);
                    pstmt.executeUpdate();
                    System.out.println("Status updated successfully to " + newStatus + ".");
                    updatedStatus = true;
                }
    
                if (updatedRequiredDate || updatedStatus) {
                    System.out.println("Update Successful. Press enter key to commit changes...");
                    scanner.nextLine();
                    connection.commit();
                    System.out.println("Order updated successfully.");
                } else {
                    System.out.println("No updates were made.");
                    connection.rollback();
                }
            } else {
                System.out.println("Order not found.");
                connection.rollback();
            }
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
            connection.rollback();
        } finally {
            connection.setAutoCommit(true); // Restore default auto-commit behavior
        }
    }
    
    
    


    private static void cancelOrder(Connection connection, Scanner scanner) throws SQLException {
        System.out.print("Enter Order Number to Cancel: ");
        int orderNumber = scanner.nextInt();
        scanner.nextLine(); // Consume the newline
    
        // Start a transaction
        connection.setAutoCommit(false);
    
        try {
            System.out.println("Processing cancellation...");
            System.out.println("--------------------------------------------------");
    
            // Check the order status and lock the row
            String checkOrderSQL = "SELECT status FROM orders WHERE orderNumber = ? FOR UPDATE";
            try (PreparedStatement checkStmt = connection.prepareStatement(checkOrderSQL)) {
                checkStmt.setInt(1, orderNumber);
                ResultSet rs = checkStmt.executeQuery();
    
                System.out.println("Checking order status...");
                TimeUnit.SECONDS.sleep(2); // Pause for 2 seconds to simulate processing delay
    
                if (rs.next()) {
                    String status = rs.getString("status");
    
                    if (!"In Process".equalsIgnoreCase(status)) {
                        System.out.println("Only orders with 'In Process' status can be canceled. Current status: " + status);
                        connection.rollback(); // Rollback if order cannot be canceled
                        return;
                    }
                } else {
                    System.out.println("Order not found.");
                    connection.rollback();
                    return;
                }
            }
    
            // Ask for confirmation to cancel the order
            System.out.println("Are you sure you want to cancel this order? (yes/no): ");
            String confirmation = scanner.nextLine();
    
            if (!"yes".equalsIgnoreCase(confirmation)) {
                System.out.println("Order cancellation aborted.");
                connection.rollback(); // Rollback transaction if the user cancels
                return;
            }
    
            // Retrieve order details and lock the rows for the associated products
            String retrieveOrderDetailsSQL = """
                SELECT od.productCode, od.quantityOrdered, p.quantityInStock
                FROM orderdetails od
                JOIN products p ON od.productCode = p.productCode
                WHERE od.orderNumber = ? FOR UPDATE
                """;
            try (PreparedStatement productStmt = connection.prepareStatement(retrieveOrderDetailsSQL)) {
                productStmt.setInt(1, orderNumber);
                ResultSet productRs = productStmt.executeQuery();
    
                System.out.println("Retrieving order details...");
                TimeUnit.SECONDS.sleep(3); // Pause for 3 seconds to simulate data retrieval delay
                System.out.println("--------------------------------------------------");
    
                while (productRs.next()) {
                    String productCode = productRs.getString("productCode");
                    int quantityInStock = productRs.getInt("quantityInStock");
                    int quantityOrdered = productRs.getInt("quantityOrdered");
    
                    // Update stock
                    String updateStockSQL = "UPDATE products SET quantityInStock = quantityInStock + ? WHERE productCode = ?";
                    try (PreparedStatement updateStockStmt = connection.prepareStatement(updateStockSQL)) {
                        updateStockStmt.setInt(1, quantityOrdered);
                        updateStockStmt.setString(2, productCode);
                        updateStockStmt.executeUpdate();
                    }
    
                    // Log details for each product updated
                    System.out.println("Product Code: " + productCode);
                    System.out.println("Quantity Restored: " + quantityOrdered);
                    System.out.println("Quantity In Stock (Updated): " + (quantityInStock + quantityOrdered));
                    System.out.println("--------------------------------------------------");
                    TimeUnit.SECONDS.sleep(1); // Pause for 1 second after processing each product
                }
            }
    
            // Update order status to "Canceled"
            String updateOrderStatusSQL = "UPDATE orders SET status = 'Canceled' WHERE orderNumber = ?";
            try (PreparedStatement cancelStmt = connection.prepareStatement(updateOrderStatusSQL)) {
                cancelStmt.setInt(1, orderNumber);
                int rowsAffected = cancelStmt.executeUpdate();
    
                if (rowsAffected > 0) {
                    System.out.println("Order status updated to 'Canceled'.");
                } else {
                    System.out.println("Failed to update the order status.");
                    connection.rollback(); // Rollback if the update fails
                    return;
                }
            }
    
            // Commit the transaction
            connection.commit();
            System.out.println("Order cancellation completed successfully.");
        } catch (Exception e) {
            System.err.println("Error canceling order. Rolling back changes...");
            e.printStackTrace();
            connection.rollback(); // Rollback transaction on error
        } finally {
            connection.setAutoCommit(true); // Restore default auto-commit behavior
        }
    }
    
    

    private static int generateOrderNumber(Connection connection) throws SQLException {
        String getMaxOrderSQL = "SELECT MAX(orderNumber) FROM orders FOR UPDATE";
        try (Statement stmt = connection.createStatement()) {
            ResultSet rs = stmt.executeQuery(getMaxOrderSQL);
            if (rs.next()) {
                return rs.getInt(1) + 1;
            }
        }
        return 1;
    }
}

