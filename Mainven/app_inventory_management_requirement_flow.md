### Project: iOS Inventory Stock Management Application

This document outlines a detailed, phased plan for developing an iOS inventory stock management application. The technical requirements and the specific Cost of Goods Sold (COGS) formulas are provided for reference during development.

---

### **Technical Specifications & Core Requirements**

* **Platform:** iOS
* **Database:** Core Data for local data persistence.
* **Data Tables:**
    * `Product`: Stores product details.
    * `Supplier`: Stores supplier information.
    * `Customer`: Stores customer information.
    * `TransactionPurchase`: Records product purchases.
    * `TransactionSales`: Records product sales.
    * `PurchaseItem`: Links a purchase transaction to products.
    * `SaleItem`: Links a sales transaction to products.

#### **Cost of Goods Sold (COGS) Calculation**

The application must accurately calculate the COGS for each product based on the following formulas. This calculation should be automated and applied whenever a new product is added or an existing product's stock is replenished.

**1. Initial Stock COGS Formula:**
This formula is used when a new product is first added to the inventory.
`$$COGS = \frac{q \times h}{q}$$`
* `q` = quantity of initial stock
* `h` = price per product of initial stock

**2. Additional Stock COGS Formula (Weighted Average):**
This formula is used when adding more stock of an existing product. It calculates a new weighted-average cost per product.
`$$COGS = \frac{q_1 \times h_1 + q_2 \times h_2}{q_1 + q_2}$$`
* `q₁` = initial quantity
* `h₁` = initial cost price per product
* `q₂` = quantity of additional stock
* `h₂` = cost price per product of additional stock

---

### **Phase 1: Core Features (Minimum Viable Product)**

This phase focuses on building the essential components of the application to allow users to manage their inventory, suppliers, and customers.

#### **1. Project Setup and Data Modeling**
* **Platform:** iOS
* **Database:** Core Data for local data management.
* **Database Schema:**
    * `Product`: Stores product details (`productID`, `name`, `image`, `costPrice`, `minimumSalePrice`, `stockQuantity`, `stockValue`).
    * `Supplier`: Stores supplier information (`supplierID`, `name`, `location`, `phoneNumber`).
    * `Customer`: Stores customer information (`customerID`, `name`, `location`, `phoneNumber`).
    * `TransactionPurchase`: Records product purchases (`transactionID`, `date`, `note`, `supplierID`).
    * `TransactionSale`: Records product sales (`transactionID`, `date`, `note`, `customerID`).
    * `PurchaseItem`: Links `TransactionPurchase` to `Product` (`purchaseItemID`, `productID`, `quantity`, `costPrice`).
    * `SaleItem`: Links `TransactionSale` to `Product` (`saleItemID`, `productID`, `quantity`, `minimumSalePrice`).

#### **2. Inventory Management**
* **Products Tab:** A central view for managing product inventory.
    * Display a list of product cards, each showing:
        * **Product Name** and **Image**.
        * **Cost Price** (COGS) and **Sale Price**.
        * **Current Stock Quantity**.
        * **Total Stock Value** (calculated as `Stock Quantity * Cost Price`).
    * Support `CRUD` (Create, Read, Update, Delete) operations for products.

#### **3. Supplier & Customer Management**
* **Supplier and Customer Modals:** Implement a reusable modal view for managing both suppliers and customers.
    * **Display:** A list of cards, each with a name, location, and phone number.
    * **Actions:** Buttons to add a new contact and options to edit or delete existing ones.

#### **4. Purchase Transactions**
* **Transaction Purchase Tab:** Record incoming inventory from suppliers.
    * **Add Transaction:**
        * A sticky button in the bottom right corner opens a new transaction view.
        * **Supplier Section:** Select an existing supplier from a modal list or add a new one.
        * **Product Section:**
            * Add multiple products to a single transaction.
            * For each product, a user can select an existing product from the database (auto-filling name, sale price, and image) or add a new one.
            * Input fields for **Product Name**, **Cost Price**, **Sale Price**, **Quantity**, and **Unit**.
            * **Final Cost Price (COGS):** This field is disabled and automatically calculated based on the COGS formulas provided above.
        * **Additional Details:** Input fields for the transaction date and an optional note.
    * **Processing:**
        * When saved, the app will update the `stockQuantity` and `costPrice` (using the COGS formula) for each product in the `Product` table and save the transaction details to the `TransactionPurchase` and `PurchaseItem` tables.
    * **Transaction List:** Display a list of purchase transaction cards showing the supplier name, total purchase value, and date, with options to edit or delete.
    * **View Details:** Tapping a transaction card shows a bottom sheet with a detailed list of purchased products.

#### **5. Sales Transactions**
* **Transaction Sales Tab:** Record outgoing inventory to customers.
    * **Add Transaction:**
        * A sticky button opens a new transaction view.
        * **Customer Section:** Select an existing customer from a modal list or add a new one.
        * **Product Section:**
            * Add multiple products to a single transaction.
            * Select existing products from the database, which auto-fills the name, sale price, and image.
            * Input fields for **Product Name**, **Sale Price**, and **Quantity**.
        * **Additional Details:** Input fields for the transaction date and an optional note.
    * **Processing:**
        * When saved, the app will **decrease** the `stockQuantity` for each product in the `Product` table and save the transaction details to the `TransactionSale` and `SaleItem` tables.
    * **Transaction List:** Display a list of sales transaction cards showing the customer name, total sale value, and date, with options to edit or delete.
    * **View Details:** Tapping a transaction card shows a bottom sheet with a detailed list of sold products.

---

### **Phase 2: Reporting & Analytics**

This phase introduces reporting features to provide the user with valuable insights into their business performance.

* **Home Tab:** A dashboard for daily performance tracking.
    * **Inventory Snapshot:** Show the total product stock and total money value of all stock for a specific date selected by the user.
    * **Daily Performance:**
        * Display total revenue (sum of `SalePrice * Quantity`) and total profit (Total Revenue - Total Purchase Price) for the selected day.
        * **Total Purchase Price** is calculated using the COGS for each product sold.
    * **Top 10 Products:** Display a list of the top 10 best-selling products. Users can filter this list by a specific date range.

---

### **Phase 3: Advanced Features**

This final phase focuses on adding additional functionality to improve usability and offer a more comprehensive experience.

* **Barcode Scanning:** Implement the ability to scan barcodes to quickly add or search for products during a transaction, eliminating manual input.
* **User Roles & Permissions:** For multi-user environments, introduce different user roles (e.g., admin, manager, staff) with varying levels of access to data and features.
* **Data Export & Reporting:** Allow users to export transaction data and reports (e.g., product lists, sales summaries) to common formats like CSV or PDF.
* **Notification System:** Create push notifications or in-app alerts for low stock levels or when a product is nearing its expiry date.