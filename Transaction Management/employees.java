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

    // Method to view employee details
    public int viewEmployee() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Employee Number:");
        employeeNumber = sc.nextLine();

        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=root&password=p@ssword"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);
            
            // select the employee and issue a READ lock to the row
            PreparedStatement pstmt = conn.prepareStatement(
                "SELECT lastName, firstName, extension, email, officeCode, reportsTo, jobTitle FROM employees WHERE employeeNumber=? AND active='Y' LOCK IN SHARE MODE"
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
    // overall sales manager is the employee who's title is only 'Sales Manager' with no extra text added 
    public int deactivateEmployee() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter Employee Number to Deactivate:");
        employeeNumber = sc.nextLine();

        try {
            int overallSalesManagerNum;
            int customerReassignCount;
            int deleteCount;
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/dbsales?useTimezone=true&serverTimezone=UTC&user=root&password=p@ssword"
            );
            System.out.println("Connection Successful");
            conn.setAutoCommit(false);

            // lock employees table
            PreparedStatement pstmtEmployeesTable = conn.prepareStatement(
                "SELECT MAX(employeeNumber)+1 FROM employees FOR UPDATE"  
            );
            System.out.println("Locking employees table");
            pstmtEmployeesTable.executeQuery();
            TimeUnit.SECONDS.sleep(5);

            // find an employee with that employee number
            PreparedStatement pstmtEmployee = conn.prepareStatement(
                "SELECT reportsTo FROM employees WHERE employeeNumber=? AND active='Y'"
            );
            pstmtEmployee.setString(1, employeeNumber);

            System.out.println("Searching for employee with number " + employeeNumber);
            ResultSet rsEmployees = pstmtEmployee.executeQuery();
            TimeUnit.SECONDS.sleep(5);

            // if an employee was found in the table
            if(rsEmployees.isBeforeFirst()) {

                // lock customers table
                PreparedStatement pstmtCustomersTable = conn.prepareStatement(
                    "SELECT MAX(customerNumber)+1 FROM customers FOR UPDATE"  
                );
                System.out.println("Locking customers table");
                pstmtCustomersTable.executeQuery();
                TimeUnit.SECONDS.sleep(5);

                // Relocate customers to overall sales manager
                PreparedStatement pstmtRelocate = conn.prepareStatement(
                    "UPDATE customers SET salesRepEmployeeNumber=? WHERE salesRepEmployeeNumber=?"
                );
                // get the overall sales manager of the employee
                if (rsEmployees.next()) {
                    overallSalesManagerNum = rsEmployees.getInt("reportsTo");

                    pstmtRelocate.setInt(1, overallSalesManagerNum);
                    pstmtRelocate.setString(2, employeeNumber);
                    System.out.println("Relocating customers who were assigned to that employee to the overall sales manager");
                    customerReassignCount = pstmtRelocate.executeUpdate();
                    TimeUnit.SECONDS.sleep(5);

                } else {
                    System.out.println("Employee's overall sales maanger not found.");
                }



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
                    System.out.println("Employee deactivated successfully. " + "X" + " customers reassigned to overall sales manager whose number\n" + employeeReassignCount + " employees have been moved to no longer report to this employee.\n");
                }

                // close prepared statements
                pstmtCustomersTable.close();
                pstmtRelocate.close();
                pstmtClear.close();
                pstmtDelete.close();
            }
            else {
                System.out.println("No active employee with that number exists.");
            }
            pstmtEmployeesTable.close();
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
