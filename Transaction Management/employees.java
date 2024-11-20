import java.sql.*;
import java.util.*;

// Josef Tan
// WIP, currently looking at other works and going off that

public class employees {

    public String employeeNumber;
    public String lastName;
    public String firstName;
    public String extension;
    public String email;
    public int officeCode;
    public int reportsTo;
    public String jobTitle;

    public employees() {}

    // Method to view office details
    public int viewEmployee() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Employee Number:");
        employeeNumber = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=admin&password=DLSU1234!"
            );
            System.out.println("Connection Successful");
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT lastName, firstName, extension, email, officeCode, reportsTo, jobTitle FROM employees WHERE employeeNumber=?"
            );
            pstmt.setString(1, employeeNumber);

            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();

            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                lastName = rs.getString("lastName");
                firstName = rs.getString("firstName");
                extension = rs.getString("extension");
                email = rs.getString("email");
                officeCode = rs.getInt("officeCode");
                reportsTo = rs.getInt("reportsTo");
                jobTitle = rs.getString("jobTitle");

                System.out.println("Name: " + firstName + " " + lastName);
                System.out.println("Extension: " + extension);
                System.out.println("Email: " + email);
                System.out.println("Office Code: " + officeCode);
                System.out.println("Reports to employee number: " + reportsTo);
                System.out.println("Job Title: " + jobTitle);

            } else {
                System.out.println("Employee not found.");
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

    /*
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
    */
    /*  Method to deactivate an office and relocate employees
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
    */
    // Main Method
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int choice;

        System.out.println("Press 0 to exit....");
        while (true) {
            System.out.println("Enter [1] View Office [2] Deactivate Emloyee: ");
            choice = sc.nextInt();
            sc.nextLine(); // Consume newline character

            employees employee = new employees();

            if (choice == 1) employee.viewEmployee();
                else if (choice == 2) employee.viewEmployee();
                    else if (choice == 0) break;

            System.out.println("Press enter key to continue....");
            sc.nextLine();
        }
    }
}
