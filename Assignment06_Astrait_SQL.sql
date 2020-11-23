--*************************************************************************--
-- Title: Assignment06
-- Author: AlexStrait
-- Desc: This file demonstrates how to Create Views
-- Change Log: When,Who,What
-- 2020-11-22,AlexStrait,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_StraitAlex')
	 Begin 
	  Alter Database [Assignment06DB_StraitAlex] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_StraitAlex;
	 End
	Create Database Assignment06DB_StraitAlex;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_StraitAlex;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
--Select * From Categories;
--go
--Select * From Products;
--go
--Select * From Employees;
--go
--Select * From Inventories;
--go

/********************************* Questions and Answers *********************************/


-- Question 1 (5 pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
Create -- Drop
View vCategories With SCHEMABINDING
AS
	Select
	CategoryID, 
	CategoryName
	From dbo.Categories;
go

Create -- Drop
View vEmployees With SCHEMABINDING
AS
	Select
	EmployeeID,
	EmployeeFirstName,
	EmployeeLastName,
	ManagerID
	From dbo.Employees;
go

Create -- Drop
View vInventories With SCHEMABINDING
AS
	Select
InventoryID,
InventoryDate,
EmployeeID,
ProductID,
Count
	From dbo.Inventories;
go

Create -- Drop
View vProducts With SCHEMABINDING
AS
	Select
	ProductID, 
	ProductName,
	CategoryID,
	UnitPrice
	From dbo.Products;
go

-- Question 2 (5 pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

Deny Select On Categories to Public;
Grant Select On vCategories to Public;
go

Deny Select On Employees to Public;
Grant Select On vEmployees to Public;
go

Deny Select On Inventories to Public;
Grant Select On vInventories to Public;
go

Deny Select On Products to Public;
Grant Select On vProducts to Public;
go

-- Question 3 (10 pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

Create 
View vProductCostsAndCategories
As 
	Select
		CategoryName,
		ProductName,
		UnitPrice
	From vCategories 
	JOIN vProducts
	On vCategories.CategoryID = vProducts.CategoryID;
go

Select * from vProductCostsAndCategories
Order By CategoryName, ProductName;
go


-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,UnitPrice
-- Beverages,Chai,18.00
-- Beverages,Chang,19.00
-- Beverages,Chartreuse verte,18.00


-- Question 4 (10 pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

Create -- Drop
View vInventoryCounts
AS
	Select
		ProductName,
		Count,
		InventoryDate
	From vInventories 
	Join vProducts
	On vInventories.ProductID = vProducts.ProductID;
go

Select * From vInventoryCounts
Order By ProductName, InventoryDate, Count;
go

-- Here is an example of some rows selected from the view:
--ProductName,InventoryDate,Count
--Alice Mutton,2017-01-01,15
--Alice Mutton,2017-02-01,78
--Alice Mutton,2017-03-01,83


-- Question 5 (10 pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

Create -- Drop
View vInventoryCheckByEmployee
As
	Select
		Distinct InventoryDate,
		EmployeeName = EmployeeFirstName + ' ' + EmployeeLastName
	From vInventories
	Join vEmployees
	On vInventories.EmployeeID = vEmployees.EmployeeID;
go

Select * From vInventoryCheckByEmployee
Order By InventoryDate;
go

-- Here is an example of some rows selected from the view:
-- InventoryDate,EmployeeName
-- 2017-01-01,Steven Buchanan
-- 2017-02-01,Robert King
-- 2017-03-01,Anne Dodsworth


-- Question 6 (10 pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

Create -- Drop
View vInventoriesByProductsByCategories
As
	Select 
		CategoryName,
		ProductName,
		InventoryDate, 
		Count
	From vCategories
	Join vProducts
	On vCategories.CategoryID = vProducts.CategoryID
	Join vInventories
	On vProducts.ProductID = vInventories.ProductID;
go

Select * From vInventoriesByProductsByCategories
Order By CategoryName, ProductName, InventoryDate, Count;
go


-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count
-- Beverages,Chai,2017-01-01,72
-- Beverages,Chai,2017-02-01,52
-- Beverages,Chai,2017-03-01,54


-- Question 7 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

Create -- Drop
View vInventoriesByProductsByEmployees
As
	Select
		CategoryName,
		ProductName,
		InventoryDate,
		Count,
		EmployeeName = EmployeeFirstName + ' ' + EmployeeLastName
	From vCategories
	Join vProducts
	On vCategories.CategoryID = vProducts.CategoryID
	Join vInventories
	On vProducts.ProductID = vInventories.ProductID
	Join vEmployees
	On vInventories.EmployeeID = vEmployees.EmployeeID;
go

Select * From vInventoriesByProductsByEmployees
Order By InventoryDate, CategoryName, ProductName, EmployeeName;
go

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chartreuse verte,2017-01-01,61,Steven Buchanan


-- Question 8 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

Create -- Drop
View vInventoriesForChaiAndChangByEmployees
As
	Select
		CategoryName,
		ProductName,
		InventoryDate,
		Count,
		EmployeeName = EmployeeFirstName + ' ' + EmployeeLastName
	From vCategories
	Join vProducts
	On vCategories.CategoryID = vProducts.CategoryID
	Join vInventories
	On vProducts.ProductID = vInventories.ProductID
	Join vEmployees
	On vInventories.EmployeeID = vEmployees.EmployeeID
	Where ProductName LIKE 'Chai' OR ProductName LIKE 'Chang';
go

Select * From vInventoriesForChaiAndChangByEmployees;
go

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chai,2017-02-01,52,Robert King


-- Question 9 (10 pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

Create -- Drop
View vEmployeesByManager
As
	Select 
		[Manager] = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName,
		[Employee] = Emp.EmployeeFirstName + ' '  + Emp.EmployeeLastName
	From Employees As Emp Join Employees As Mgr
	On Emp.ManagerID = Mgr.EmployeeID;
go

Select * From vEmployeesByManager
Order By Manager, Employee;
go
-- Here is an example of some rows selected from the view:
-- Manager,Employee
-- Andrew Fuller,Andrew Fuller
-- Andrew Fuller,Janet Leverling
-- Andrew Fuller,Laura Callahan


-- Question 10 (10 pts): How can you create one view to show all the data from all four 
-- BASIC Views?

Create -- Drop
View vInventoriesByProductsByCategoriesByEmployees
As
	Select 
		Cat.CategoryID,
		Cat.CategoryName,
		Prod.ProductID,
		Prod.ProductName,
		Prod.UnitPrice,
		InventoryID,
		InventoryDate,
		Count,
		Emp.EmployeeID,
		EmployeeName = Emp.EmployeeFirstName + ' ' + Emp.EmployeeLastName,
		ManagerName = Mgr.EmployeeFirstName + ' ' + Mgr.EmployeeLastName
	From vCategories As Cat
		Join vProducts As Prod
		On Cat.CategoryID = Prod.CategoryID
		Join vInventories As Inv
		On Prod.ProductID = Inv.ProductID
		Join vEmployees as Emp
		On Inv.EmployeeID = Emp.EmployeeID
		Join vEmployees as Mgr
		On Emp.ManagerID = Mgr.EmployeeID;
go

Select * From vInventoriesByProductsByCategoriesByEmployees
Order By CategoryName, ProductID;
go

-- Here is an example of some rows selected from the view:
-- CategoryID,CategoryName,ProductID,ProductName,UnitPrice,InventoryID,InventoryDate,Count,EmployeeID,Employee,Manager
-- 1,Beverages,1,Chai,18.00,1,2017-01-01,72,5,Steven Buchanan,Andrew Fuller
-- 1,Beverages,1,Chai,18.00,78,2017-02-01,52,7,Robert King,Steven Buchanan
-- 1,Beverages,1,Chai,18.00,155,2017-03-01,54,9,Anne Dodsworth,Steven Buchanan


/***************************************************************************************/