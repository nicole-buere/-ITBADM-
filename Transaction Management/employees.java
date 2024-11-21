import java.sql.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

/*
 javac -cp ".;mysql-connector-j-9.0.0.jar" employees.java
 java -cp ".;mysql-connector-j-9.0.0.jar" employees.java
 */

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
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=root&password=MyNewPass"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);
            
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT lastName, firstName, extension, email, officeCode, reportsTo, jobTitle FROM employees WHERE employeeNumber=? LOCK IN SHARE MODE"
            );
            pstmt.setString(1, employeeNumber);

            /* 
            System.out.println("Press enter key to start retrieving the data");
            sc.nextLine();
            */

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

                System.out.println("\nName: " + firstName + " " + lastName);
                System.out.println("Extension: " + extension);
                System.out.println("Email: " + email);
                System.out.println("Office Code: " + officeCode);
                System.out.println("Reports to employee number: " + reportsTo);
                System.out.println("Job Title: " + jobTitle + "\n");

            } else {
                System.out.println("Employee not found.");
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
    public int deactivateEmployee() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Employee Number to Deactivate:");
        employeeNumber = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=root&password=MyNewPass"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);

            // find an employee with that employee number and lock those employees
            PreparedStatement pstmtEmployee = conn.prepareStatement(
                "SELECT employeeNumber FROM employees WHERE employeeNumber=? FOR UPDATE"
            );
            pstmtEmployee.setString(1, employeeNumber);

            System.out.println("Searching for employee with number " + employeeNumber);
            ResultSet rsEmployees = pstmtEmployee.executeQuery();
            TimeUnit.SECONDS.sleep(5);

            // if an employee was found in the table
            if(rsEmployees.isBeforeFirst()) {

                // Relocate employees to the main office
                // 1143 is the employee number of the overall sales manager
                PreparedStatement pstmtRelocate = conn.prepareStatement(
                    "UPDATE customers SET salesRepEmployeeNumber='1143' WHERE salesRepEmployeeNumber=?"
                );
                pstmtRelocate.setString(1, employeeNumber);
                System.out.println("Relocating customers who were assigned to that employee to the overall sales manager");
                int reassignCount = pstmtRelocate.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                // clear the 'reportsTo' fields for employees who report to the employee who will be deactivated
                PreparedStatement pstmtClear = conn.prepareStatement("UPDATE employees SET reportsTo=NULL WHERE reportsTo=?");
                pstmtClear.setString(1, employeeNumber);
                System.out.println("Clearing employee 'reportsTo' fields who were assigned to employee number " + employeeNumber);
                pstmtClear.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                // Remove the employee
                PreparedStatement pstmtDelete = conn.prepareStatement("DELETE FROM employees WHERE employeeNumber=?");
                pstmtDelete.setString(1, employeeNumber);
                System.out.println("Removing employee record");
                int deleteCount = pstmtDelete.executeUpdate();
                TimeUnit.SECONDS.sleep(5);

                conn.commit();
                if(deleteCount == 0) {
                    System.out.println("No employee found with that number, no deactivation was done.");
                } 
                else {
                    System.out.println("Employee deactivated successfully. " + reassignCount + " customers reassigned to overall sales manager.\n");
                }

                // close prepared statements
                pstmtRelocate.close();
                pstmtClear.close();
                pstmtDelete.close();
            }
            else {
                System.out.println("No employee with that number exists.");
            }
            pstmtEmployee.close();
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
            System.out.println("Enter [1] View Employee [2] Deactivate Employee: ");
            choice = sc.nextInt();
            sc.nextLine(); // Consume newline character

            employees employee = new employees();

            if (choice == 1) employee.viewEmployee();
                else if (choice == 2) employee.deactivateEmployee();
                    else if (choice == 0) break;

            System.out.println("Press enter key to continue....");
            sc.nextLine();
        }

        sc.close();
    }
}
