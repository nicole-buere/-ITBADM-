import java.util.Scanner;

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int choice;

        while (true) {
            System.out.println("\nTransaction Management\n");
            System.out.println("[1] Product Management");
            System.out.println("[2] Employee Management");
            System.out.println("[3] Offices Management");
            System.out.println("[4] Order Management");
            System.out.println("[0] Exit\n");
            System.out.print("\nEnter your choice: ");

            choice = sc.nextInt();
            sc.nextLine(); // Consume newline character

            switch (choice) {
                case 1:
                   products product = new products();
                    break;
                case 2:
                    employees employee = new products();
                    break;
                case 3:
                    offices office = new offices();
                    break;
                case 0:
                    orders order = new orders();
                    return;
                default:
                    System.out.println("Invalid choice. Please select a valid option.");
            }

            System.out.println("\nPress Enter to return to the main menu...");
            sc.nextLine(); // Wait for user to press Enter
        }
    }
}
