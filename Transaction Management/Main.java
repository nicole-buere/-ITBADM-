// compile first: javac -cp ".;mysql-connector-j-9.0.0.jar" Main.java 
// then run: java -cp ".;mysql-connector-j-9.0.0.jar" Main.java 

import java.sql.*;
import java.util.*;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int choice;

        while (true) {
            System.out.println("\nTransaction Management Menu:\n");
            System.out.println("[1] Product Management");
            System.out.println("[2] Employee Management");
            System.out.println("[3] Offices Management");
            System.out.println("[4] Order Management");
            System.out.println("[0] Exit Transaction Management\n");

            // Input validation
            while (true) {
                System.out.print("Enter your choice: ");
                if (sc.hasNextInt()) {
                    choice = sc.nextInt();
                    sc.nextLine(); // Consume newline character
                    break; // Valid input, exit the validation loop
                } else {
                    System.out.println("Invalid input. Please enter a valid number.");
                    sc.nextLine(); // Clear the invalid input
                }
            }

            // Handle valid input
            switch (choice) {
                case 1:
                    products product = new products();
                    product.displayMenu();
                    break;
                case 2:
                    employees employee = new employees();
                    employee.displayMenu(); 
                    break;
                case 3:
                    offices office = new offices();
                    office.displayMenu();
                    break;
                case 4:
                    ordering order = new ordering();
                    order.displayMenu();
                    break;
                case 0:
                    System.out.println("Exiting the Transaction Management System...");
                    return;
                default:
                    System.out.println("Invalid choice. Please select a valid option.");
            }

            System.out.println("\nPress Enter to return to the main menu...");
            sc.nextLine(); // Wait for user to press Enter
        }
    }
}

// Product Management - BUERE
class products {
   
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
                System.out.println("Product not found. Press enter key to end transaction and go back to the menu");
                sc.nextLine();
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
            System.out.println("Press enter key to end transaction and go back to the menu");
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
                System.out.println("Product not found. Press enter key to end transaction and go back to the menu");
                sc.nextLine();
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
                System.out.println("This product is deactivated and cannot be updated. Press enter key to end transaction and go back to the menu");
                sc.nextLine();
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
                System.out.print("\nEnter your desired quantity for the product (must be greater than 0): ");
                if (sc.hasNextInt()) {
                    newQuantity = sc.nextInt();
                    sc.nextLine(); // Consume the remaining newline
                    if (newQuantity > 0) {
                        validInput = true;
                    } else {
                        System.out.println("Error: Quantity must be greater than 0. Please try again.");
                    }
                } else {
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
            System.out.println("Product quantity has been successfully updated. Press enter key to end transaction and go back to the menu");
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
                System.out.println("Product not found. Press enter key to end transaction and go back to the menu");
                sc.nextLine();
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
                System.out.println("This product is already deactivated and cannot be deactivated again. Press enter key to end transaction and go back to the menu");
                sc.nextLine();
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
            System.out.println("The product has been successfully deactivated. Press enter key to go back to the menu...");
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

    // menu for product management
    public void displayMenu() {
        Scanner sc = new Scanner(System.in);
        int choice = 0;

        while (true) {
            System.out.println("\nProduct Management Menu:");
            System.out.println("[1] Get Product Information");
            System.out.println("[2] Update Product Quantity");
            System.out.println("[3] Deactivate a Product");
            System.out.println("[0] Exit to the Product Management Menu");
            System.out.print("\nEnter your choice: ");

            // Input validation
            if (sc.hasNextInt()) {
                choice = sc.nextInt();
                sc.nextLine(); // Consume newline character
            } else {
                System.out.println("Invalid input. Please enter a number.");
                sc.nextLine(); // Clear invalid input
                continue;
            }

            if (choice == 0) {
                System.out.println("Returning to the Transaction Management Main Menu...");
                break;
            }

            // Execute choice
            switch (choice) {
                case 1:
                    getInfo();
                    break;
                case 2:
                    updateQuantity();
                    break;
                case 3:
                    deactivateProduct();
                    break;
                default:
                    System.out.println("Invalid choice. Please select a valid option.");
            }
        }
    }

}

// Employee Management - TAN
class employees {

    public String employeeNumber;
    public String lastName;
    public String firstName;
    public String extension;
    public String email;
    public int officeCode;
    public int reportsTo;
    public String jobTitle;
    public String active;

    public employees() {}

    // Method to view employee details
    public int viewEmployee() {
        Scanner sc = new Scanner(System.in);
        System.out.print("\nEnter Employee Number to View: ");
        employeeNumber = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);
            
            // select the employee and issue a READ lock to the row
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT lastName, firstName, extension, email, officeCode, reportsTo, jobTitle, active FROM employees WHERE employeeNumber=? LOCK IN SHARE MODE"
            );
            pstmt.setString(1, employeeNumber);

            /* 
            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();
            */

            System.out.println("Searching for employee with number " + employeeNumber);
            ResultSet rs = pstmt.executeQuery();
            TimeUnit.SECONDS.sleep(5);
            if (rs.next()) {
                lastName = rs.getString("lastName");
                firstName = rs.getString("firstName");
                extension = rs.getString("extension");
                email = rs.getString("email");
                officeCode = rs.getInt("officeCode");
                reportsTo = rs.getInt("reportsTo");
                jobTitle = rs.getString("jobTitle");
                active = rs.getString("active");

                System.out.println("\nName: " + firstName + " " + lastName);
                System.out.println("Extension: " + extension);
                System.out.println("Email: " + email);
                System.out.println("Office Code: " + officeCode);
                System.out.println("Reports to employee number: " + reportsTo);
                System.out.println("Job Title: " + jobTitle + "");
                if(active == "Y") {
                    System.out.println("Status: Active\n");
                } else {
                    System.out.println("Status: Deactivated\n");
                }

            } else {
                System.out.println("No employee with the employee number " + employeeNumber + " exists");
            }

            rs.close();
            pstmt.close();
            conn.commit();
            conn.close();
            //sc.close();
            return 1;

        } catch (Exception e) {
            System.out.println(e.getMessage());
            //sc.close();
            return 0;
        }
    }

    //  deactivate employees and reassign customers who were orginally assigned to that employee to go to the overall sales manager
    // overall sales manager is the employee who's title is only 'Sales Manager' with no extra text added 
    public int deactivateEmployee() {
        Scanner sc = new Scanner(System.in);
        // overall sales manager employee Number is 1165 in Orignial DB Sales
        int overallSalesManagerNum = 1165;
        System.out.print("\nEnter Employee Number to Deactivate: ");
        employeeNumber = sc.nextLine();

        try {
            int customerReassignCount = 0;
            int deleteCount;
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);

            // find an employee with that employee number and lock that row
            PreparedStatement pstmtEmployee = conn.prepareStatement(
                "SELECT reportsTo FROM employees WHERE employeeNumber=? AND active='Y' FOR UPDATE"
            );
            pstmtEmployee.setString(1, employeeNumber);

            System.out.println("Searching for employee with number " + employeeNumber);
            ResultSet rsEmployees = pstmtEmployee.executeQuery();
            TimeUnit.SECONDS.sleep(5);

            // if an employee was found in the table
            if(rsEmployees.isBeforeFirst()) {

                // lock employees table
                PreparedStatement pstmtEmployeesTable = conn.prepareStatement(
                    "SELECT reportsTo FROM employees WHERE reportsTo=?FOR UPDATE"  
                );
                pstmtEmployeesTable.setString(1, employeeNumber);
                System.out.println("Locking employees who report to employee number " + employeeNumber);
                pstmtEmployeesTable.executeQuery();
                TimeUnit.SECONDS.sleep(5);

                // lock customers table
                PreparedStatement pstmtCustomersTable = conn.prepareStatement(
                    "SELECT salesRepEmployeeNumber FROM customers WHERE salesRepEmployeeNumber=? FOR UPDATE"  
                );
                pstmtCustomersTable.setString(1, employeeNumber);
                System.out.println("Locking customers who's sales rep is employee number " + employeeNumber);
                pstmtCustomersTable.executeQuery();
                TimeUnit.SECONDS.sleep(5);

                // Relocate customers to overall sales manager
                PreparedStatement pstmtRelocate = conn.prepareStatement(
                    "UPDATE customers SET salesRepEmployeeNumber=? WHERE salesRepEmployeeNumber=?"
                );
                // get the overall sales manager of the employee
                pstmtRelocate.setInt(1, overallSalesManagerNum);
                pstmtRelocate.setString(2, employeeNumber);
                System.out.println("Relocating customers who were assigned to that employee to the overall sales manager");
                customerReassignCount = pstmtRelocate.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                // clear the 'reportsTo' fields for employees who report to the employee who will be deactivated
                PreparedStatement pstmtClear = conn.prepareStatement("UPDATE employees SET reportsTo=NULL WHERE reportsTo=? AND active='Y'");
                pstmtClear.setString(1, employeeNumber);
                System.out.println("Clearing employee 'reportsTo' fields for those who report to employee number " + employeeNumber);
                int employeeReassignCount = pstmtClear.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                // Remove the employee
                PreparedStatement pstmtDelete = conn.prepareStatement("UPDATE employees SET active='N' WHERE employeeNumber=?");
                pstmtDelete.setString(1, employeeNumber);
                System.out.println("Deactivating employee record");
                deleteCount = pstmtDelete.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                conn.commit();
                if(deleteCount == 0) {
                    System.out.println("No active employee found with that number, no deactivation was done.");
                } 
                else {
                    System.out.println("Employee deactivated successfully. " + customerReassignCount + " customers reassigned to overall sales manager whose number is " + overallSalesManagerNum + "\n" + employeeReassignCount + " employees have been moved to no longer report to this employee.\n");
                }

                // close prepared statements
                pstmtEmployeesTable.close();
                pstmtCustomersTable.close();
                pstmtRelocate.close();
                pstmtClear.close();
                pstmtDelete.close();
            }
            else {
                System.out.println("No active employee with that number exists.");
            }
            pstmtEmployee.close();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println(e.getMessage());
            return 0;
        }

    }
    
    // menu for employee management
    public void displayMenu() {
        Scanner sc = new Scanner(System.in);
        int choice;

        while (true) {
            System.out.println("Employee Management Menu:\n[1] View Employee\n[2] Deactivate Employee\n[0] Exit Employee Management\n");
            System.out.print("Enter your choice: ");
            choice = sc.nextInt();
            sc.nextLine(); // Consume newline character

            employees employee = new employees();

            switch (choice) {
                case 1:
                    employee.viewEmployee();
                    break;
                case 2:
                    employee.deactivateEmployee();
                    break;
                case 0:
                    System.out.println("Exiting Employee Management.");
                    return;
                default:
                    System.out.println("Invalid choice. Please select a valid option.");
            }

            System.out.println("\nPress Enter to return to the employee management menu...");
            sc.nextLine(); // Wait for user to press Enter
        }
        
    }
}


// Offices Management - PEGALAN
class offices {

    public String officeCode;
    public String city;
    public String phone;
    public String addressLine1;
    public String addressLine2;
    public String state;
    public String country;
    public String postalCode;
    public String territory;
    public String status;


    public offices() {}

    // Method to view office details
    public int viewOffice() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Office Code:");
        officeCode = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!"

            );
            System.out.println("Connection Successful");
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory, status FROM offices WHERE officeCode=?FOR SHARE"
            );
            pstmt.setString(1, officeCode);

            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();

            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                city = rs.getString("city");
                phone = rs.getString("phone");
                addressLine1 = rs.getString("addressLine1");
                addressLine2 = rs.getString("addressLine2");
                state = rs.getString("state");
                country = rs.getString("country");
                postalCode = rs.getString("postalCode");
                territory = rs.getString("territory");
                status = rs.getString("status");

                System.out.println("City: " + city);
                System.out.println("Phone: " + phone);
                System.out.println("Address Line 1: " + addressLine1);
                System.out.println("Address Line 2: " + addressLine2);
                System.out.println("State: " + state);
                System.out.println("Country: " + country);
                System.out.println("Postal Code: " + postalCode);
                System.out.println("Territory: " + territory);
                System.out.println("Status: " + status);
            } else {
                System.out.println("Office not found.");
            }

            rs.close();
            pstmt.close();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println(e.getMessage());
            return 0;
        }
    }

    // Method to update office information
    // Method to update office information
public int updateOffice() {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter Office Code to Update:");
    officeCode = sc.nextLine();

    try {
        // Establish a connection to the database
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!"
        );
        System.out.println("Connection Successful");

        System.out.println("Press Enter key to start retrieving the data...");
        sc.nextLine(); // Wait for user input before retrieving data

        // Check the status of the office
        PreparedStatement statusCheckStmt = conn.prepareStatement(
            "SELECT status FROM offices WHERE officeCode = ?"
        );
        statusCheckStmt.setString(1, officeCode);
        ResultSet statusRs = statusCheckStmt.executeQuery();

        if (statusRs.next()) {
            String currentStatus = statusRs.getString("status");

            // If the office is inactive, block the update
            if ("inactive".equalsIgnoreCase(currentStatus)) {
                System.out.println("Office is deactivated and cannot be updated.");
                statusRs.close();
                statusCheckStmt.close();
                conn.close();
                return 0;
            }
        } else {
            System.out.println("Office not found.");
            statusRs.close();
            statusCheckStmt.close();
            conn.close();
            return 0;
        }

        // Proceed with update if office is active
        // Lock the row for the given officeCode and fetch data
        conn.setAutoCommit(false); // Start transaction
        PreparedStatement fetchStmt = conn.prepareStatement(
            "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory " +
            "FROM offices WHERE officeCode = ? FOR UPDATE"
        );
        fetchStmt.setString(1, officeCode);
        ResultSet rs = fetchStmt.executeQuery();

        if (rs.next()) {
            // Display current data
            city = rs.getString("city");
            phone = rs.getString("phone");
            addressLine1 = rs.getString("addressLine1");
            addressLine2 = rs.getString("addressLine2");
            state = rs.getString("state");
            country = rs.getString("country");
            postalCode = rs.getString("postalCode");
            territory = rs.getString("territory");

            System.out.println("\nCurrent Data for Office Code: " + officeCode);
            System.out.println("City: " + city);
            System.out.println("Phone: " + phone);
            System.out.println("Address Line 1: " + addressLine1);
            System.out.println("Address Line 2: " + addressLine2);
            System.out.println("State: " + state);
            System.out.println("Country: " + country);
            System.out.println("Postal Code: " + postalCode);
            System.out.println("Territory: " + territory);

            // Prompt user for new information
            System.out.println("\nEnter new information (leave blank to keep current data):");
            System.out.print("New City (current: " + city + "): ");
            String newCity = sc.nextLine();
            if (!newCity.isBlank()) city = newCity;

            System.out.print("New Phone (current: " + phone + "): ");
            String newPhone = sc.nextLine();
            if (!newPhone.isBlank()) phone = newPhone;

            System.out.print("New Address Line 1 (current: " + addressLine1 + "): ");
            String newAddressLine1 = sc.nextLine();
            if (!newAddressLine1.isBlank()) addressLine1 = newAddressLine1;

            System.out.print("New Address Line 2 (current: " + addressLine2 + "): ");
            String newAddressLine2 = sc.nextLine();
            if (!newAddressLine2.isBlank()) addressLine2 = newAddressLine2;

            System.out.print("New State (current: " + state + "): ");
            String newState = sc.nextLine();
            if (!newState.isBlank()) state = newState;

            System.out.print("New Country (current: " + country + "): ");
            String newCountry = sc.nextLine();
            if (!newCountry.isBlank()) country = newCountry;

            System.out.print("New Postal Code (current: " + postalCode + "): ");
            String newPostalCode = sc.nextLine();
            if (!newPostalCode.isBlank()) postalCode = newPostalCode;

            System.out.print("New Territory (current: " + territory + "): ");
            String newTerritory = sc.nextLine();
            if (!newTerritory.isBlank()) territory = newTerritory;

            // Update the row
            PreparedStatement updateStmt = conn.prepareStatement(
                "UPDATE offices SET city=?, phone=?, addressLine1=?, addressLine2=?, state=?, country=?, postalCode=?, territory=? WHERE officeCode=?"
            );
            updateStmt.setString(1, city);
            updateStmt.setString(2, phone);
            updateStmt.setString(3, addressLine1);
            updateStmt.setString(4, addressLine2);
            updateStmt.setString(5, state);
            updateStmt.setString(6, country);
            updateStmt.setString(7, postalCode);
            updateStmt.setString(8, territory);
            updateStmt.setString(9, officeCode);

            updateStmt.executeUpdate();
            System.out.println("\nUpdate Successful. Press Enter key to continue...");
            sc.nextLine(); // Wait for user input before returning

            // Commit the transaction
            conn.commit();

            updateStmt.close();
        } else {
            System.out.println("Office not found.");
        }

        // Close resources
        rs.close();
        fetchStmt.close();
        conn.close();
        return 1;

    } catch (SQLTimeoutException e) {
        System.out.println("Operation timed out while waiting for the lock.");
        return 0;
    } catch (Exception e) {
        e.printStackTrace();
        return 0;
    }
}

    

    // Method to deactivate an office and relocate employees
    public int deactivateOffice() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Office Code to Deactivate:");
        officeCode = sc.nextLine();
    
        if ("1".equals(officeCode)) {
            System.out.println("Office Code 1 cannot be deactivated as it is the Main Office.");
            return 0;
        }
    
        try {
            // Establish a connection to the database
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC","root", "DLSU123!"
            );
            System.out.println("Connection Successful");
    
            System.out.println("Press Enter key to start retrieving the data before deactivation...");
            sc.nextLine(); // Wait for user to proceed
    
            // Lock the row for the given officeCode and fetch data
            conn.setAutoCommit(false); // Start transaction
            PreparedStatement fetchStmt = conn.prepareStatement(
                "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory, status " +
                "FROM offices WHERE officeCode = ? FOR UPDATE"
            );
            fetchStmt.setString(1, officeCode);
            ResultSet rs = fetchStmt.executeQuery();
    
            if (rs.next()) {
                // Display current data
                String city = rs.getString("city");
                String phone = rs.getString("phone");
                String addressLine1 = rs.getString("addressLine1");
                String addressLine2 = rs.getString("addressLine2");
                String state = rs.getString("state");
                String country = rs.getString("country");
                String postalCode = rs.getString("postalCode");
                String territory = rs.getString("territory");
                String status = rs.getString("status");
    
                System.out.println("\nCurrent Data for Office Code: " + officeCode);
                System.out.println("City: " + city);
                System.out.println("Phone: " + phone);
                System.out.println("Address Line 1: " + addressLine1);
                System.out.println("Address Line 2: " + addressLine2);
                System.out.println("State: " + state);
                System.out.println("Country: " + country);
                System.out.println("Postal Code: " + postalCode);
                System.out.println("Territory: " + territory);
                System.out.println("Status: " + status);
    
                // Check if the office is already inactive
                if ("inactive".equalsIgnoreCase(status)) {
                    System.out.println("\nThe office is already inactive. No further action is required.");
                    conn.rollback();
                    return 0;
                }
    
                System.out.println("\nPress Enter key to confirm deactivation...");
                sc.nextLine(); // Wait for user confirmation
    
                // Relocate employees of the deactivated office to officeCode '1'
                PreparedStatement pstmtRelocate = conn.prepareStatement(
                    "UPDATE employees SET officeCode = '1' WHERE officeCode = ?"
                );
                pstmtRelocate.setString(1, officeCode);
                int relocatedCount = pstmtRelocate.executeUpdate();
    
                // Mark the office as inactive
                PreparedStatement pstmtDeactivate = conn.prepareStatement(
                    "UPDATE offices SET status='inactive' WHERE officeCode=?"
                );
                pstmtDeactivate.setString(1, officeCode);
                pstmtDeactivate.executeUpdate();
    
                System.out.println("\nOffice deactivated successfully. " + relocatedCount + " employees relocated to Main Office.");
    
                // Commit the transaction
                conn.commit();
    
                pstmtRelocate.close();
                pstmtDeactivate.close();
            } else {
                System.out.println("Office not found.");
            }
    
            // Close resources
            rs.close();
            fetchStmt.close();
            conn.close();
            return 1;
    
        } catch (SQLTimeoutException e) {
            System.out.println("Operation timed out while waiting for the lock.");
            return 0;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
    
    
    

    // menu for office management
    public void displayMenu() {
    Scanner sc = new Scanner(System.in);
    int choice;

    while (true) {
        System.out.println("\nOffices Management\n");
        System.out.println("[1] View Office");
        System.out.println("[2] Update Office");
        System.out.println("[3] Deactivate Office");
        System.out.println("[0] Exit\n");
        System.out.print("\nEnter your choice: ");
        
        choice = sc.nextInt();
        sc.nextLine(); // Consume newline character

        offices office = new offices();

        switch (choice) {
            case 1:
                office.viewOffice();
                break;
            case 2:
                office.updateOffice();
                break;
            case 3:
                office.deactivateOffice();
                break;
            case 0:
                System.out.println("Exiting Offices Management.");
                return;
            default:
                System.out.println("Invalid choice. Please select a valid option.");
        }

        System.out.println("\nPress Enter to return to the offices management menu...");
        sc.nextLine(); // Wait for user to press Enter
    }
}

}

// Order Management
class ordering {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "DLSU123!";

    public void displayMenu() {
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