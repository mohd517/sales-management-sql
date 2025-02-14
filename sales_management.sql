--  Create Database
CREATE DATABASE SalesDB;
USE SalesDB;

--  Create Tables (DDL)
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Address TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10,2),
    Status ENUM('Pending', 'Shipped', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

--  Insert Sample Data (DML)
INSERT INTO Customers (Name, Email, Phone, Address) VALUES
('John Doe', 'john@example.com', '123-456-7890', '123 Main St'),
('Jane Smith', 'jane@example.com', '987-654-3210', '456 Elm St');

INSERT INTO Products (ProductName, Category, Price, StockQuantity) VALUES
('Laptop', 'Electronics', 800.00, 50),
('Smartphone', 'Electronics', 600.00, 100);

INSERT INTO Orders (CustomerID, TotalAmount, Status) VALUES
(1, 1400.00, 'Shipped'),
(2, 600.00, 'Pending');

INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price) VALUES
(1, 1, 1, 800.00),
(1, 2, 1, 600.00),
(2, 2, 1, 600.00);

--  Stored Procedure: Place an Order
DELIMITER //
CREATE PROCEDURE PlaceOrder(IN custID INT, IN prodID INT, IN qty INT)
BEGIN
    DECLARE prodPrice DECIMAL(10,2);
    
    -- Get the product price
    SELECT Price INTO prodPrice FROM Products WHERE ProductID = prodID;

    -- Insert order
    INSERT INTO Orders (CustomerID, TotalAmount, Status) 
    VALUES (custID, prodPrice * qty, 'Pending');

    -- Insert order details
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
    VALUES (LAST_INSERT_ID(), prodID, qty, prodPrice);
END //
DELIMITER ;

--  View: Customer Order History
CREATE VIEW CustomerOrderHistory AS
SELECT o.OrderID, c.Name AS CustomerName, o.OrderDate, o.TotalAmount, o.Status
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID;

--  Trigger: Update Stock Quantity After Order
DELIMITER //
CREATE TRIGGER UpdateStock AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    UPDATE Products 
    SET StockQuantity = StockQuantity - NEW.Quantity 
    WHERE ProductID = NEW.ProductID;
END //
DELIMITER ;

--  Extract-Transform-Load (ETL) Queries
-- Extract Data
SELECT * FROM Customers;
SELECT * FROM Orders;

-- Transform Data: Aggregate Sales Per Customer
SELECT 
    c.Name, 
    o.OrderID, 
    o.OrderDate, 
    SUM(od.Quantity * od.Price) AS OrderTotal
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID;

-- Load Transformed Data into Reporting Table
CREATE TABLE OrderSummary AS
SELECT 
    c.Name AS CustomerName, 
    o.OrderID, 
    o.OrderDate, 
    SUM(od.Quantity * od.Price) AS TotalSpent
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID;

--  Performance Optimization Queries
-- Create Indexes
CREATE INDEX idx_orders_customer ON Orders(CustomerID);
CREATE INDEX idx_orderdetails_order ON OrderDetails(OrderID);

-- Optimized Query Example
SELECT OrderID, TotalAmount, Status FROM Orders WHERE CustomerID = 1;
