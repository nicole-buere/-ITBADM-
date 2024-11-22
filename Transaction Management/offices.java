// add column to deactivate office
// ALTER TABLE offices ADD COLUMN status ENUM('active', 'inactive') DEFAULT 'active';

// to compile
// javac -cp ".;mysql-connector-j-9.0.0.jar" offices.java

// to run
// java -cp ".;mysql-connector-j-9.0.0.jar" offices.java

import java.sql.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

public class offices {

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
                "jdbc:mysql://localhost:3306/dbsales?useSSL=false&serverTimezone=UTC"

            );
            System.out.println("Connection Successful");
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory, status FROM offices WHERE officeCode=?"
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
    public int updateOffice() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Office Code to Update:");
        officeCode = sc.nextLine();
    
        try {
            // Establish a connection to the database
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC"
            );
            System.out.println("Connection Successful");
    
            System.out.println("Press Enter key to start retrieving the data...");
            sc.nextLine(); // Wait for user input before retrieving data
    
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
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC"
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
    
    
    

    // Main Method
    public static void main(String[] args) {
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
