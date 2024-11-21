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
                "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory FROM offices WHERE officeCode=?"
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

                System.out.println("City: " + city);
                System.out.println("Phone: " + phone);
                System.out.println("Address Line 1: " + addressLine1);
                System.out.println("Address Line 2: " + addressLine2);
                System.out.println("State: " + state);
                System.out.println("Country: " + country);
                System.out.println("Postal Code: " + postalCode);
                System.out.println("Territory: " + territory);
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
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=admin&password=DLSU1234!"
            );
            System.out.println("Connection Successful");
    
            // Start transaction and lock the row for the given officeCode
            conn.setAutoCommit(false);
            PreparedStatement fetchStmt = conn.prepareStatement(
                "SELECT city, phone, addressLine1, addressLine2, state, country, postalCode, territory " +
                "FROM offices WHERE officeCode = ? FOR UPDATE"
            );
            fetchStmt.setString(1, officeCode);
            ResultSet rs = fetchStmt.executeQuery();
    
            // Add a deliberate delay
            TimeUnit.SECONDS.sleep(10); // 10-second delay
            System.out.println("\nPress any key to continue...");
            sc.nextLine(); // Wait for user input to proceed

            if (rs.next()) {
                // Display current values and allow user to update selectively
                city = rs.getString("city");
                phone = rs.getString("phone");
                addressLine1 = rs.getString("addressLine1");
                addressLine2 = rs.getString("addressLine2");
                state = rs.getString("state");
                country = rs.getString("country");
                postalCode = rs.getString("postalCode");
                territory = rs.getString("territory");
    
                System.out.println("Leave fields blank if you don't want to change them.");
                System.out.println("Enter new City (current: " + city + "):");
                String newCity = sc.nextLine();
                if (!newCity.isBlank()) city = newCity;
    
                System.out.println("Enter new Phone (current: " + phone + "):");
                String newPhone = sc.nextLine();
                if (!newPhone.isBlank()) phone = newPhone;
    
                System.out.println("Enter new Address Line 1 (current: " + addressLine1 + "):");
                String newAddressLine1 = sc.nextLine();
                if (!newAddressLine1.isBlank()) addressLine1 = newAddressLine1;
    
                System.out.println("Enter new Address Line 2 (current: " + addressLine2 + "):");
                String newAddressLine2 = sc.nextLine();
                if (!newAddressLine2.isBlank()) addressLine2 = newAddressLine2;
    
                System.out.println("Enter new State (current: " + state + "):");
                String newState = sc.nextLine();
                if (!newState.isBlank()) state = newState;
    
                System.out.println("Enter new Country (current: " + country + "):");
                String newCountry = sc.nextLine();
                if (!newCountry.isBlank()) country = newCountry;
    
                System.out.println("Enter new Postal Code (current: " + postalCode + "):");
                String newPostalCode = sc.nextLine();
                if (!newPostalCode.isBlank()) postalCode = newPostalCode;
    
                System.out.println("Enter new Territory (current: " + territory + "):");
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
                System.out.println("Office updated successfully.");
    
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
    
        System.out.println("Enter Main Office Code for Employee Relocation:");
        String mainOfficeCode = sc.nextLine();
    
        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=admin&password=DLSU1234!"
            );
            System.out.println("Connection Successful");
    
            // Start transaction and lock the row for the given officeCode
            conn.setAutoCommit(false);
            PreparedStatement fetchStmt = conn.prepareStatement(
                "SELECT status FROM offices WHERE officeCode = ? FOR UPDATE"
            );
            fetchStmt.setString(1, officeCode);
            ResultSet rs = fetchStmt.executeQuery();
    
            if (rs.next()) {
                String currentStatus = rs.getString("status");
                if ("inactive".equalsIgnoreCase(currentStatus)) {
                    System.out.println("Office is already inactive.");
                    conn.rollback();
                    return 0;
                }
    
                // Relocate employees to the main office
                PreparedStatement pstmtRelocate = conn.prepareStatement(
                    "UPDATE employees SET officeCode=? WHERE officeCode=?"
                );
                pstmtRelocate.setString(1, mainOfficeCode);
                pstmtRelocate.setString(2, officeCode);
                int relocatedCount = pstmtRelocate.executeUpdate();
    
                // Mark the office as inactive
                PreparedStatement pstmtDeactivate = conn.prepareStatement(
                    "UPDATE offices SET status='inactive' WHERE officeCode=?"
                );
                pstmtDeactivate.setString(1, officeCode);
                pstmtDeactivate.executeUpdate();
    
                // Commit the transaction
                conn.commit();
                System.out.println("Office deactivated successfully. " + relocatedCount + " employees relocated to Main Office.");
    
                pstmtRelocate.close();
                pstmtDeactivate.close();
            } else {
                System.out.println("Office not found.");
                conn.rollback();
            }
    
            // Close resources
            rs.close();
            fetchStmt.close();
            conn.close();
            return 1;
    
        } catch (Exception e) {
            try {
                // Rollback in case of error
                System.out.println("Rolling back transaction due to error.");
                e.printStackTrace();
            } catch (Exception rollbackEx) {
                rollbackEx.printStackTrace();
            }
            return 0;
        }
    }
    

    // Main Method
    public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int choice;

    while (true) {
        System.out.println("\n          Offices Management       \n");
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

        System.out.println("\nPress Enter to return to the main menu...");
        sc.nextLine(); // Wait for user to press Enter
    }
}

}
