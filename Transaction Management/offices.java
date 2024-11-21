import java.sql.*;
import java.util.*;

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

    public Offices() {}

    // Method to view office details
    public int viewOffice() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Office Code:");
        officeCode = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=admin&password=DLSU1234!"
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

            System.out.println("Enter new City:");
            city = sc.nextLine();
            System.out.println("Enter new Phone:");
            phone = sc.nextLine();
            System.out.println("Enter new Address Line 1:");
            addressLine1 = sc.nextLine();
            System.out.println("Enter new Address Line 2 (or leave blank):");
            addressLine2 = sc.nextLine();
            System.out.println("Enter new State (or leave blank):");
            state = sc.nextLine();
            System.out.println("Enter new Country:");
            country = sc.nextLine();
            System.out.println("Enter new Postal Code:");
            postalCode = sc.nextLine();
            System.out.println("Enter new Territory:");
            territory = sc.nextLine();

            PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE offices SET city=?, phone=?, addressLine1=?, addressLine2=?, state=?, country=?, postalCode=?, territory=? WHERE officeCode=?"
            );
            pstmt.setString(1, city);
            pstmt.setString(2, phone);
            pstmt.setString(3, addressLine1);
            pstmt.setString(4, addressLine2);
            pstmt.setString(5, state);
            pstmt.setString(6, country);
            pstmt.setString(7, postalCode);
            pstmt.setString(8, territory);
            pstmt.setString(9, officeCode);

            pstmt.executeUpdate();
            System.out.println("Office updated successfully.");

            pstmt.close();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println(e.getMessage());
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
            conn.setAutoCommit(false);

            // Relocate employees to the main office
            PreparedStatement pstmtRelocate = conn.prepareStatement(
                "UPDATE employees SET officeCode=? WHERE officeCode=?"
            );
            pstmtRelocate.setString(1, mainOfficeCode);
            pstmtRelocate.setString(2, officeCode);
            int relocatedCount = pstmtRelocate.executeUpdate();

            // Remove the office
            PreparedStatement pstmtDelete = conn.prepareStatement("DELETE FROM offices WHERE officeCode=?");
            pstmtDelete.setString(1, officeCode);
            pstmtDelete.executeUpdate();

            conn.commit();
            System.out.println("Office deactivated successfully. " + relocatedCount + " employees relocated to Main Office.");

            pstmtRelocate.close();
            pstmtDelete.close();
            conn.close();
            return 1;

        } catch (Exception e) {
            System.out.println(e.getMessage());
            return 0;
        }
    }

    // Main Method
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int choice;

        System.out.println("Press 0 to exit....");
        while (true) {
            System.out.println("Enter [1] View Office [2] Update Office [3] Deactivate Office:");
            choice = sc.nextInt();
            sc.nextLine(); // Consume newline character

            Offices office = new Offices();

            if (choice == 1) office.viewOffice();
            else if (choice == 2) office.updateOffice();
            else if (choice == 3) office.deactivateOffice();
            else if (choice == 0) break;

            System.out.println("Press enter key to continue....");
            sc.nextLine();
        }
    }
}
