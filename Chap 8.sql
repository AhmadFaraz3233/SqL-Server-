-- ===================================================================
-- Chapter 8: Creating Tables and Enforcing Data Integrity
-- ===================================================================

-- -------------------------------------------------------------------
-- Lesson 1: Creating a table
-- -------------------------------------------------------------------
-- Syntax of CREATE TABLE
CREATE TABLE 
    [ database_name . [ schema_name ] . | schema_name . ] table_name 
    [ AS FileTable ]
    ( { <column_definition> | <computed_column_definition> 
        | <column_set_definition> | [ <table_constraint> ] [ ,...n ] } )
    [ ON { partition_scheme_name ( partition_column_name ) | filegroup 
        | "default" } ] 
    [ { TEXTIMAGE_ON { filegroup | "default" } ] 
    [ FILESTREAM_ON { partition_scheme_name | filegroup 
        | "default" } ]
    [ WITH ( <table_option> [ ,...n ] ) ]
[ ; ]

-- Sample table
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	categoryname NVARCHAR(15) NOT NULL,
	description NVARCHAR(200) NOT NULL)
GO
SELECT TOP (10) categoryname FROM Production.Categories;

-- Creating a schema
CREATE SCHEMA Production AUTHORIZATION dbo;
GO

-- The following statement moves the Production.Categories table to the Sales database schema:
ALTER SCHEMA Sales TRANSFER Production.Categories;
-- To move the table back, issue:
ALTER SCHEMA Production TRANSFER Sales.Categories;

-- Naming Tables and Columns 
-- For example, you could create a table as follows:
	CREATE TABLE Production.[Yesterday's News]
-- Or you could write this way:
	CREATE TABLE Production."Tomorrow's Schedule"

-- -- NULL and Default Values
-- Example of a default value
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	categoryname NVARCHAR(15) NOT NULL,
	description NVARCHAR(200) NOT NULL DEFAULT ('')
	) ON [PRIMARY];
GO

-- The Identity Property and Sequence Numbers
-- The most common values for seed and increment are (1,1) as in the TSQL2012 Production.Categories table:
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	…
-- Computed Columns
-- You could compute this in a SELECT statement:
SELECT TOP (10) orderid, productid, unitprice, qty, 
	unitprice * qty AS initialcost -- expression
FROM Sales.OrderDetails;

-- You can take that expression, unitprice * qty AS initialcost, and embed it in the CREATE TABLE statement as a computed column. For example,
CREATE TABLE Sales.OrderDetails
(
  orderid   INT           NOT NULL,
…
  initialcost AS unitprice * qty -- computed column
);

-- Table Compression
-- The following command will add row-level compression to the Production.OrderDetails table as part of the CREATE TABLE statement:
CREATE TABLE Sales.OrderDetails
(
  orderid   INT           NOT NULL,
…
  ) 
	WITH (DATA_COMPRESSION = ROW);
-- You can also ALTER a table to set its compression:
ALTER TABLE Sales.OrderDetails
REBUILD WITH (DATA_COMPRESSION = PAGE);

-- -------------------------------------------------------------------
-- Lesson 2: Using Constraints
-- -------------------------------------------------------------------
-- Primary Key Constraints
-- For example, consider again the TSQL2012 table Production.Categories. This is how it is defined in the TSQL2012.SQL script:
CREATE TABLE Production.Categories
(
  categoryid   INT           NOT NULL IDENTITY,
  categoryname NVARCHAR(15)  NOT NULL,
  description  NVARCHAR(200) NOT NULL,
  CONSTRAINT PK_Categories PRIMARY KEY(categoryid)
);

--Another way of declaring a column as a primary key is to use the ALTER TABLE statement, which you could write as follows:
USE TSQL2012;
ALTER TABLE Production.Categories 
	ADD CONSTRAINT PK_Categories PRIMARY KEY(categoryid);
GO

-- To list the primary key constraints in a database, you can query the sys.key_constraints table filtering on a type of PK:
SELECT * 
FROM sys.key_constraints 
WHERE type = 'PK';
-- Also you can find the unique index that SQL Server uses to enforce a primary key constraint by querying sys.indexes.
SELECT * 
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'Production.Categories', 'U') AND name = 'PK_Categories';

-- Unique Constraints
USE TSQL2012;
ALTER TABLE Production.Categories 
	ADD CONSTRAINT UC_Categories UNIQUE (categoryname);
GO
SELECT * 
FROM sys.key_constraints 
WHERE type = 'UQ';

-- Foreign Key Constraints
USE TSQL2012
GO
ALTER TABLE Production.[Products]  WITH CHECK 
	ADD  CONSTRAINT [FK_Products_Categories] FOREIGN KEY(categoryid)
	REFERENCES Production.Categories (categoryid)
GO
SELECT P.[productname], C.categoryname
FROM Production.[Products] AS P
JOIN Production.Categories AS C
	ON P.categoryid = C.categoryid;
SELECT * 
FROM sys.foreign_keys
WHERE name = 'FK_Products_Categories';

-- Check Constraints
ALTER TABLE Production.[Products]  WITH CHECK 
	ADD  CONSTRAINT [CHK_Products_unitprice] 
	CHECK  (unitprice>=0);
GO
SELECT *
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'Production.Products', N'U');

-- Default Constraints
CREATE TABLE Production.Products
(
  productid    INT          NOT NULL IDENTITY,
  productname  NVARCHAR(40) NOT NULL,
  supplierid   INT          NOT NULL,
  categoryid   INT          NOT NULL,
  unitprice    MONEY        NOT NULL
    CONSTRAINT DFT_Products_unitprice DEFAULT(0),
  discontinued BIT          NOT NULL 
    CONSTRAINT DFT_Products_discontinued DEFAULT(0),
…
);
SELECT * 
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID(N'Production.Products', 'U');


-- =============================================================
-- Chapter 8, Lesson 1
-- Exercise 1 Use ALTER TABLE to Add and Modify Columns
-- =============================================================

--Examine the CREATE TABLE statement below, from the TSQL2012.sql script, that is used to create the Production.Categories table. You will create a similar table by the name of Production].[CategoriesTest] but one column at a time. In the process you will use many of the ALTER TABLE commands for modifying column properties.
/* From TSQL2012.sql:
-- Create table Production.Categories
CREATE TABLE Production.Categories
(
  categoryid   INT           NOT NULL IDENTITY,
  categoryname NVARCHAR(15)  NOT NULL,
  description  NVARCHAR(200) NOT NULL,
  CONSTRAINT PK_Categories PRIMARY KEY(categoryid)
);
*/
--Start a new query window in SQL 2012 Management Studio, and make sure a fresh copy of the TSQL 2012 database is on the server. In this exercise you will create an extra table and then drop it in the TSQL2012 database.
--1. 	Start a new query window in SSMS
--2.	Create the table with one column. Execute the following statements in order to create our copy of the original table, but to start with, just one column:
USE TSQL2012;
GO
CREATE TABLE Production.CategoriesTest
(
  categoryid   INT           NOT NULL IDENTITY
);
GO
--3.	Adding columns: Add the categoryname and description columns matching the original table:
ALTER TABLE Production.CategoriesTest
	ADD categoryname NVARCHAR(15) NOT NULL;
GO
ALTER TABLE Production.CategoriesTest
	ADD description NVARCHAR(200) NOT NULL;
GO
--4.	Inserting data with an Identity property. Now you will attempt an insert into the copy table from the original table, but the Insert will fail. Execute the following:
INSERT Production.CategoriesTest (categoryid, categoryname, description)
	SELECT categoryid, categoryname, description
	FROM Production.Categories;
GO
--5.	Try again with IDENTITY_INSERT ON:
SET IDENTITY_INSERT Production.CategoriesTest ON;
INSERT Production.CategoriesTest (categoryid, categoryname, description)
	SELECT categoryid, categoryname, description
	FROM Production.Categories;
GO
SET IDENTITY_INSERT Production.CategoriesTest OFF;
GO

-- 6.	To clean up, you can drop the table. You can skip this step if you are going to the next exercise.
IF OBJECT_ID('Production.CategoriesTest','U') IS NOT NULL
    DROP TABLE Production.CategoriesTest;
GO


-- =============================================================
-- Chapter 8, Lesson 1
-- Exercise 2	Working with NULL columns in tables
-- =============================================================
--1.	Create and populate the table from the previous exercise by executing the following code. You can skip this test if you still have the table in TSQL2012 from the previous exercise.
-- Create table Production.CategoriesTest
CREATE TABLE Production.CategoriesTest
(
  categoryid   INT           NOT NULL IDENTITY,
  categoryname NVARCHAR(15)  NOT NULL,
  description  NVARCHAR(200) NOT NULL,
  CONSTRAINT PK_CategoriesTest PRIMARY KEY(categoryid)
);
-- Populate the table Production.CategoriesTest
SET IDENTITY_INSERT Production.CategoriesTest ON;
INSERT Production.CategoriesTest (categoryid, categoryname, description)
    SELECT categoryid, categoryname, description
    FROM Production.Categories;
GO
SET IDENTITY_INSERT Production.CategoriesTest OFF;
GO

--2.	Column size: Make the description column larger
ALTER TABLE Production.CategoriesTest
	ALTER COLUMN description NVARCHAR(500) NOT NULL;
GO


--3.	NULLs: Test for the existence of NULL in the description column
SELECT description
	FROM Production.CategoriesTest 
	WHERE categoryid = 8; -- Seaweed and fish

--4.	NULLs: Attempt to change a value in the description column to NULL. This fails:
UPDATE Production.CategoriesTest
	SET [description ] = NULL 
	WHERE categoryid = 8;
GO

--5.	Nulls: Make the description column allow NULL
ALTER TABLE Production.CategoriesTest
	ALTER COLUMN description NVARCHAR(500) NULL ;
GO

--6.	Nulls: Retry the update
UPDATE Production.CategoriesTest
	SET [description ] = NULL 
	WHERE categoryid = 8;
GO

--7.	NULLs: Attempt to change the column back to NOT NULL
ALTER TABLE Production.CategoriesTest
	ALTER COLUMN description NVARCHAR(500) NOT NULL ;
GO

--8.	Nulls: Retry the update
UPDATE Production.CategoriesTest
	SET [description ] = 'Seaweed and fish' 
	WHERE categoryid = 8;
GO
--9.	NULLs: Change the description column back to NOT NULL
ALTER TABLE Production.CategoriesTest
	ALTER COLUMN description NVARCHAR(500) NOT NULL ;
GO
--10.	Cleanup: Drop the table
IF OBJECT_ID('Production.CategoriesTest','U') IS NOT NULL
	DROP TABLE Production.CategoriesTest;
GO


-- =============================================================
-- Chapter 8, Lesson 2
-- Exercise 1	Working with Primary and Foreign Key Constraints
-- =============================================================

-- The following is the CREATE TABLE statement for Production.Products, taken from TSQL2012.sql:
/*
-- Create table Production.Products
CREATE TABLE Production.Products
(
  productid    INT          NOT NULL IDENTITY,
  productname  NVARCHAR(40) NOT NULL,
  supplierid   INT          NOT NULL,
  categoryid   INT          NOT NULL,
  unitprice    MONEY        NOT NULL
    CONSTRAINT DFT_Products_unitprice DEFAULT(0),
  discontinued BIT          NOT NULL 
    CONSTRAINT DFT_Products_discontinued DEFAULT(0),
  CONSTRAINT PK_Products PRIMARY KEY(productid),
  CONSTRAINT FK_Products_Categories FOREIGN KEY(categoryid)
    REFERENCES Production.Categories(categoryid),
  CONSTRAINT FK_Products_Suppliers FOREIGN KEY(supplierid)
    REFERENCES Production.Suppliers(supplierid),
  CONSTRAINT CHK_Products_unitprice CHECK(unitprice >= 0)
);
In this exersize, you will test the primary key and foreign key constraints, as well as the check constraints
In addition, you will use ALTER TABLE to drop, test, and add a foriegn key constraint back into the table.
*/

-- 1. Test the primary key:
SELECT productname FROM Production.Products WHERE productid = 1;
SET IDENTITY_INSERT Production.Products ON;
GO
INSERT INTO Production.Products (productid, productname,supplierid,categoryid,unitprice,discontinued)
     VALUES (1, N'Product TEST', 1, 1, 18, 0);
GO
SET IDENTITY_INSERT Production.Products OFF;

-- 2. Now insert a new row letting the Identity property assign a new productid
INSERT INTO Production.Products (productname,supplierid,categoryid,unitprice,discontinued)
     VALUES (N'Product TEST', 1, 1, 18, 0);
GO
-- 3. Delete the row 
DELETE FROM Production.Products WHERE productname = N'Product TEST';
GO
-- 4. Try again with an invalid categoryid = 99; Insert fails because of foreign key constraint
INSERT INTO Production.Products (productname,supplierid,categoryid,unitprice,discontinued)
     VALUES (N'Product TEST', 1, 99, 18, 0);
GO
-- 5. Drop the foreign key constraint
ALTER TABLE Production.Products DROP CONSTRAINT FK_Products_Categories;
GO
-- 6. Try the insert now with the invalid categoryid = 99; Insert succeeds
INSERT INTO Production.Products (productname,supplierid,categoryid,unitprice,discontinued)
     VALUES (N'Product TEST', 1, 99, 18, 0);
GO
-- 7. Try to add the foreign key constraint back in WITH CHECK:
ALTER TABLE Production.Products  WITH CHECK 
	ADD  CONSTRAINT FK_Products_Categories FOREIGN KEY(categoryid)
	REFERENCES Production.Categories (categoryid);
GO
-- 8. Update the row so that it has a valid categoryid:
UPDATE Production.Products
	SET categoryid = 1 
	WHERE productname = N'Product TEST';
GO
-- 9. Now try to add the foreign key constraint back to the table: succeeds
ALTER TABLE Production.Products  WITH CHECK 
	ADD  CONSTRAINT FK_Products_Categories FOREIGN KEY(categoryid)
	REFERENCES Production.Categories (categoryid);
GO
-- 10. Cleanup: Drop the test row from the table
DELETE FROM Production.Products WHERE productname = N'Product TEST';
GO

-- =============================================================
-- Chapter 8, Lesson 2
-- Exercise 2	Working with Unique Constraints
-- =============================================================
-- 1.	Verify that all productnames in Production.Products are unique:
USE TSQL2012;
GO
SELECT productname, COUNT(*) AS productnamecount
FROM Production.Products
GROUP BY productname
HAVING COUNT(*) > 1;

-- 2.	Inspect the productname for productid = 1; value is 'Product HHYDP'
SELECT productname
FROM Production.Products
WHERE productid = 1;

-- 3.	Use the UPDATE statement to test whether there can be a duplicate product name: 
UPDATE Production.Products
    SET productname = 'Product RECZE'
    WHERE productid = 1;

-- 4.	Verify that there are duplicates:
SELECT productname, COUNT(*) AS productnamecount
FROM Production.Products
GROUP BY productname
HAVING COUNT(*) > 1;

-- 5.	Now try to add a unique constraint. Note that it fails.
ALTER TABLE Production.Products
    ADD CONSTRAINT U_Productname UNIQUE (productname);

-- 6.	Restore the original product name:
UPDATE Production.Products
    SET productname = 'Product HHYDP'
    WHERE productid = 1;

-- 7.	Try a second time to add the unique constraint
ALTER TABLE Production.Products
    ADD  CONSTRAINT U_Productname UNIQUE (productname);
-- 8.	To clean up, drop the unique constraint:
ALTER TABLE Production.Products
    DROP  CONSTRAINT U_Productname;
