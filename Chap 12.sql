---------------------------------------------------------------------
-- TK 70-461 - Chapter 12 - Implementing Transactions, Error Handling and Dynamic SQL
-- Code
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Lesson 01 - Lesson 1: Managing Transactions and Concurrency
---------------------------------------------------------------------

-- Implicit Transactions
SET IMPLICIT_TRANSACTIONS ON;
-- You can also issue the command:
SET ANSI_DEFAULTS ON;
-- This command just effectively issues the first command for you.

USE TSQL2012;
BEGIN TRANSACTION Tran1;
ROLLBACK TRAN;

-- Mark a Transaction
USE TSQL2012;
BEGIN TRAN Tran1 WITH MARK;
	-- <transaction work>
COMMIT TRAN; -- or ROLLBACK TRAN
-- <other work>

-- Later, supposing you need to restore the database to the transaction mark:
RESTORE DATABASE TSQ2012 FROM DISK = 'C:SQLBackups\TSQL2012.bak'
	WITH NORECOVERY;
GO
RESTORE LOG TSQL2012 FROM DISK = 'C:\SQLBackups\TSQL2012.trn'
	WITH STOPATMARK = 'Tran1';
GO


---------------------------------------------------------------------
-- Lesson 02 - Lesson 2: Implementing Error Handling
---------------------------------------------------------------------

RAISERROR ('Error in usp_InsertCategories stored procedure', 16, 0);

-- Formatting the RAISERROR string
RAISERROR ('Error in % stored procedure', 16, 0, N'usp_InsertCategories');

-- In addition, you can use a variable: 
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
RAISERROR (@message, 16, 0, N'usp_InsertCategories');

-- And you can add the formatting outside RAISERROR using the FORMATMESSAGE function:
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
RAISERROR (@message, 16, 0);

-- THROW and RAISERROR
-- You can issue a simple THROW as follows:
THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;

-- Because THROW does not allow formatting of the message parameter, you can use FORMATMESSAGE()
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
THROW 50000, @message, 0;

-- There are some additional important differences between THROW and RAISERROR:
-- RAISERROR does not normally terminate a batch:
RAISERROR ('Hi there', 16, 0);
PRINT 'RAISERROR error'; -- Prints
GO

-- However, THROW does terminate the batch:
THROW 50000, 'Hi there', 0;
PRINT 'THROW error'; -- Does not print
GO

-- TRY_CONVERT()
-- The first statement returns a NULL, signaling that the conversion will not work. 
-- The second statement returns the converted datetime value as a datetime data type. 
SELECT TRY_CONVERT(DATETIME, '1752-12-31');
SELECT TRY_CONVERT(DATETIME, '1753-01-01');

-- TRY_PARSE() allows you to take an input string containing data of an indeterminate data type and test whether or not it can be converted to a specific data type. 
-- The following example attempts to parse two strings:
SELECT TRY_PARSE('1' AS INTEGER);
SELECT TRY_PARSE('B' AS INTEGER);


-- Calling the error functions from the CATCH block:
BEGIN CATCH
	-- Error handling
	SELECT ERROR_NUMBER() AS errornumber
		, ERROR_MESSAGE() AS errormessage
		, ERROR_LINE() AS errorline
		, ERROR_SEVERITY() AS errorseverity
		, ERROR_STATE() AS errorstate;
END CATCH;

---------------------------------------------------------------------
-- Lesson 03 - Lesson 3: Using Dynamic SQL
---------------------------------------------------------------------

-- Dynamic SQL Overview
-- Sample query:
USE TSQL2012;
GO
SELECT COUNT(*) AS ProductRowCount  FROM [Production].[Products];

-- Now suppose you want to substitute a variable for the table and schema name:
USE TSQL2012;
GO
DECLARE @tablename  AS NVARCHAR(261) = N'[Production].[Products]';
SELECT COUNT(*) FROM @tablename;

-- But concatenate that variable with a string literal, and you can print out the command:
USE TSQL2012;
GO
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
PRINT N'SELECT COUNT(*) FROM ' + @tablename;

-- Or you can use the SELECT statement to get the same effect but in a result set:
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
SELECT N'SELECT COUNT(*) FROM ' + @tablename;

-- In each case, the result is valid T-SQL:
SELECT COUNT(*) AS ProductRowCount FROM [Production].[Products];

-- You can copy this to a query window and execute it manually, 
-- or you can embed it and execute it immediately using the EXECUTE command 
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
EXECUTE(N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename);


-- Embedded strings and string delimiters
-- Notice the embedded single quote (apostrophe):
USE TSQL2012;
GO
SELECT custid, companyname, contactname, contacttitle, address
 FROM [Sales].[Customers]
WHERE address = N'5678 rue de l'Abbaye ';


-- Embed a second single quote to signal a single quote and not a string delimiter:
SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N'5678 rue de l''Abbaye';


-- Using a PRINT statement
PRINT N'SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N''5678 rue de l''''Abbaye'';';

-- An alternative is to use the QUOTENAME function
PRINT QUOTENAME(N'5678 rue de l''Abbaye', '''');

-- Using the EXECUTE command:
-- Executing a string variable:
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000)
	, @tablename AS NVARCHAR(261) = '[Production].[Products]';
SET @SQLString = N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename;
EXEC(@SQLString);

-- Executing concatenated variables.
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(MAX)
	, @tablename AS NVARCHAR(261) = '[Production].[Products]';
SET @SQLString = N'SELECT COUNT(*) AS TableRowCount FROM ' 
EXEC(@SQLString + @tablename);

-- Using sp_executesql
-- Sending the input in as a parameter
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000), @address AS NVARCHAR(60);
SET @SQLString = N'
SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = @address';
SET @address = N'5678 rue de l''Abbaye'; 
EXEC sp_executesql 
	@statement = @SQLString
	, @params = N'@address NVARCHAR(60)'
	, @address = @address;


	---------------------------------------------------------------------
-- TK 70-461 - Chapter 12 - Implementing Transactions, Error Handling and Dynamic SQL
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Managing Transactions and Concurrency
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Managing Transactions and Concurrency
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 Working with Transaction Modes
---------------------------------------------------------------------

-- 1. Implicit Transactions
USE TSQL2012;
SET IMPLICIT_TRANSACTIONS ON;
SELECT @@TRANCOUNT; -- 0
SET IDENTITY_INSERT Production.Products ON;
-- Issue DML or DDL command here
INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
	VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
SELECT @@TRANCOUNT; -- 1
COMMIT TRAN;
SET IDENTITY_INSERT Production.Products OFF;
SET IMPLICIT_TRANSACTIONS OFF;
-- Remove the inserted row
DELETE FROM Production.Products WHERE productid = 101; -- Note the row is deleted


-- 2. Explicit Transactions
USE TSQL2012;
SELECT @@TRANCOUNT; -- 0
BEGIN TRAN;
	SELECT @@TRANCOUNT; -- 1
	SET IDENTITY_INSERT Production.Products ON;
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
	SELECT @@TRANCOUNT; -- 1
	SET IDENTITY_INSERT Production.Products OFF;
COMMIT TRAN;
-- Remove the inserted row
DELETE FROM Production.Products WHERE productid = 101; -- Note the row is deleted

-- 3. Nested Transactions with COMMIT TRAN
USE TSQL2012;
SELECT @@TRANCOUNT; -- = 0
BEGIN TRAN;
	SELECT @@TRANCOUNT; -- = 1
	BEGIN TRAN;
		SELECT @@TRANCOUNT; -- = 2
		-- Issue data modification or DDL commands here
	COMMIT
	SELECT @@TRANCOUNT; -- = 1
COMMIT TRAN;
SELECT @@TRANCOUNT; -- = 0

-- 4. Nested Transactions with ROLLBACK TRAN
one ROLLBACK is required.
USE TSQL2012;
SELECT @@TRANCOUNT; -- = 0
BEGIN TRAN;
	SELECT @@TRANCOUNT; -- = 1
	BEGIN TRAN;
		SELECT @@TRANCOUNT; -- = 2
		-- Issue data modification or DDL command here
	ROLLBACK; -- rolls back the entire transaction at this point
SELECT @@TRANCOUNT; -- = 0


---------------------------------------------------------------------
-- Exercise 2 Work with Blocking and Deadlocking
---------------------------------------------------------------------

-- 1. Writers blocking writers:

-- Session 1:
USE TSQL2012;

BEGIN TRAN;
UPDATE HR.Employees
SET postalcode = N'10004'
WHERE empid = 1;

-- <more work>

COMMIT TRAN;

-- Cleanup:
UPDATE HR.Employees
SET postalcode = N'10003'
WHERE empid = 1;


-- Session 2:
USE TSQL2012;

UPDATE HR.Employees
SET phone = N'555-9999'
WHERE empid = 1;

-- <blocked>

-- <Results returned>


-- 2. Writers blocking readers
-- Session 1
USE TSQL2012;
BEGIN TRAN;

UPDATE HR.Employees
SET postalcode = N'10004'
WHERE empid = 1

COMMIT TRAN;

-- Cleanup:
UPDATE HR.Employees
SET postalcode = N'10003'
WHERE empid = 1;


-- Session 2
USE TSQL2012;
GO

SELECT lastname, firstname
FROM HR.Employees

<blocked>

<Results returned>


---------------------------------------------------------------------
-- Exercise 3. Working with Transaction Isolation Levels
---------------------------------------------------------------------

-- 1.	Working with READ COMMITTED
-- Session 1
USE TSQL2012;
BEGIN TRAN;

UPDATE HR.Employees
SET postalcode = N'10006'
WHERE empid = 1; 

COMMIT TRAN;

-- Cleanup:
UPDATE HR.Employees
SET postalcode = N'10003'
WHERE empid = 1;


-- Session 2
USE TSQL2012;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; 

SELECT lastname, firstname
FROM HR.Employees;

<blocked>

<Results returned>



-- 2. Working with READ UNCOMMITTED
-- Session 1
USE TSQL2012;
BEGIN TRAN;

UPDATE HR.Employees
SET region = N'1004'
WHERE empid = 1; 

ROLLBACK TRAN;
 
<region for empid = 1 rolled back to original value>

-- Cleanup:
UPDATE HR.Employees
SET region = N'1003'
WHERE empid = 1;

-- Session 2
USE TSQL2012;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

SELECT lastname, firstname, region
FROM HR.Employees 

<Results returned: region = 1004 for empid = 1>

SELECT lastname, firstname, region
FROM HR.Employees;

<Results returned: region = original value for empid = 1>

3. Using a table hint to implement READ UNCOMMITTED in a single command:
SELECT lastname, firstname
FROM HR.Employees WITH (READUNCOMMITTED);

4. Using READ COMMITTED SNAPSHOT
-- Session 1
USE TSQL2012;
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT ON;
BEGIN TRAN;

UPDATE HR.Employees
SET postalcode = N'10007'
WHERE empid = 1;

ROLLBACK TRAN; 

<region for empid = 1 rolled back to original value>

-- Cleanup:
UPDATE HR.Employees
SET postalcode = N'10003'
WHERE empid = 1;

-- Session 2
USE TSQL2012;

SELECT lastname, firstname, region
FROM HR.Employees;

<Results returned show region in original state for empid = 1>


---------------------------------------------------------------------
-- Lesson 02 - Implementing Error Handling
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Error Handling 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 Unstructured Error Handling
---------------------------------------------------------------------
-- 1. Using @@ERROR. 
USE TSQL2012;
GO
DECLARE @errnum AS int;
BEGIN TRAN;
SET IDENTITY_INSERT Production.Products ON;
INSERT INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
	VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
SET @errnum = @@ERROR;
IF @errnum <> 0 -- Handle the error
	BEGIN 
		PRINT 'Insert into Production.Products failed with error ' + CAST(@errnum AS VARCHAR);
	END

-- 2. Unstructured error handling in a transaction
USE TSQL2012;
GO
DECLARE @errnum AS int;
BEGIN TRAN;
	SET IDENTITY_INSERT Production.Products ON;
	-- Insert #1 will fail because of duplicate primary key
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
		VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
	SET @errnum = @@ERROR;
	IF @errnum <> 0
		BEGIN 
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			PRINT 'Insert #1 into Production.Products failed with error ' + CAST(@errnum AS VARCHAR);
		END; 
	-- Insert #2 will succeed
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
	SET @errnum = @@ERROR;
	IF @errnum <> 0
		BEGIN 
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			PRINT 'Insert #2 into Production.Products failed with error ' + CAST(@errnum AS VARCHAR);
		END; 
	SET IDENTITY_INSERT Production.Products OFF;
	IF @@TRANCOUNT > 0 COMMIT TRAN;
-- Remove the inserted row
DELETE FROM Production.Products WHERE productid = 101;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows'; 


---------------------------------------------------------------------
-- Exercise 2 Using XACT_ABORT to handle errors
---------------------------------------------------------------------
-- 1. Using XACT_ABORT and encountering an error. 
USE TSQL2012;
GO
SET XACT_ABORT ON;
PRINT 'Before error';
SET IDENTITY_INSERT Production.Products ON;
INSERT INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
	VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
SET IDENTITY_INSERT Production.Products OFF;
PRINT 'After error';
GO
PRINT 'New batch';
SET XACT_ABORT OFF;

-- 2. Using THROW with XACT_ABORT. 
USE TSQL2012;
GO
SET XACT_ABORT ON;
PRINT 'Before error';
THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;
PRINT 'After error';
GO
PRINT 'New batch';
SET XACT_ABORT OFF;

-- 3. Using XACT_ABORT in a transaction
USE TSQL2012;
GO
DECLARE @errnum AS int;
SET XACT_ABORT ON; 
BEGIN TRAN;
	SET IDENTITY_INSERT Production.Products ON;
	-- Insert #1 will fail because of duplicate primary key
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
		VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
	SET @errnum = @@ERROR;
	IF @errnum <> 0
		BEGIN 
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			PRINT 'Error in first INSERT';
		END; 
	-- Insert #2 no longer succeeds
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 	unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
	SET @errnum = @@ERROR;
	IF @errnum <> 0
		BEGIN 
			-- Take actions based on the error
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			PRINT 'Error in second INSERT';
		END; 
	SET IDENTITY_INSERT Production.Products OFF;
	IF @@TRANCOUNT > 0 COMMIT TRAN;
GO
 
DELETE FROM Production.Products WHERE productid = 101;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows'; 
SET XACT_ABORT OFF;
GO
SELECT XACT_STATE(), @@TRANCOUNT;

---------------------------------------------------------------------
-- Exercise 3 Structured Error Handling with TRY/CATCH
---------------------------------------------------------------------
-- 1. Starting out with TRY/CATCH
USE TSQL2012;
GO
BEGIN TRY
BEGIN TRAN;
	SET IDENTITY_INSERT Production.Products ON;
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
		VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);
	SET IDENTITY_INSERT Production.Products OFF;
COMMIT TRAN;
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() = 2627 -- Duplicate key violation
		BEGIN
			PRINT 'Primary Key violation';
		END
	ELSE IF ERROR_NUMBER() = 547 -- Constraint violations
		BEGIN
			PRINT 'Constraint violation';
		END
	ELSE
		BEGIN
			PRINT 'Unhandled error';
		END;
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;

-- 2. Now revise the CATCH block using variables to capture error information and re-raise the error using RAISERROR. 
USE TSQL2012;
GO
SET NOCOUNT ON;
DECLARE @error_number AS INT, @error_message AS NVARCHAR(1000), @error_severity AS INT;
BEGIN TRY
BEGIN TRAN;
	SET IDENTITY_INSERT Production.Products ON;
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 		unitprice, discontinued)
		VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 		unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);
	SET IDENTITY_INSERT Production.Products OFF;
	COMMIT TRAN;
END TRY
BEGIN CATCH
	SELECT XACT_STATE() as 'XACT_STATE', @@TRANCOUNT as '@@TRANCOUNT';
	SELECT @error_number = ERROR_NUMBER(), @error_message = ERROR_MESSAGE(), @error_severity = ERROR_SEVERITY();
	RAISERROR (@error_message, @error_severity, 1);
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;


-- 3. Next, use a THROW statement without parameters re-raise (re-throw) the original error message and send it back to the client. 
USE TSQL2012;
GO
BEGIN TRY
BEGIN TRAN;
	SET IDENTITY_INSERT Production.Products ON;
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 		unitprice, discontinued)
		VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
	INSERT INTO Production.Products(productid, productname, supplierid, categoryid, 		unitprice, discontinued)
		VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);
	SET IDENTITY_INSERT Production.Products OFF;
COMMIT TRAN;
END TRY
BEGIN CATCH
	SELECT XACT_STATE() as 'XACT_STATE', @@TRANCOUNT as '@@TRANCOUNT';
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	THROW;
END CATCH;
GO
SELECT XACT_STATE() as 'XACT_STATE', @@TRANCOUNT as '@@TRANCOUNT';



---------------------------------------------------------------------
-- Lesson 3 - Using Dynamic SQL
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Dynamic SQL
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 Generating T-SQL Strings and QUOTENAME
---------------------------------------------------------------------
-- 1. Using a variable to generate T-SQL strings
USE TSQL2012;
GO
DECLARE @address AS NVARCHAR(60) = N'5678 rue de l''Abbaye';
PRINT N'SELECT *
FROM [Sales].[Customers]
WHERE address = '+ @address;

-- 2. Now embed the variable with QUOTENAME before concatenating it to the PRINT statement. 
USE TSQL2012;
GO
DECLARE @address AS NVARCHAR(60) = '5678 rue de l''Abbaye';
PRINT N'SELECT *
FROM [Sales].[Customers]
WHERE address = '+ QUOTENAME(@address, '''') + ';';

---------------------------------------------------------------------
-- Exercise 2 Preventing SQL Injection
---------------------------------------------------------------------
-- 1. Open Management Studio and load the following stored procedure script into a query window. 
USE TSQL2012;
GO
IF OBJECT_ID('Sales.ListCustomersByAddress') IS NOT NULL
	DROP PROCEDURE Sales.ListCustomersByAddress;
GO
CREATE PROCEDURE Sales.ListCustomersByAddress
	@address NVARCHAR(60)
AS
	DECLARE @SQLString AS NVARCHAR(4000);
SET @SQLString = N'
SELECT companyname, contactname 
FROM Sales.Customers WHERE address = ''' + @address + '''';
	-- PRINT @SQLString;
EXEC(@SQLString);
RETURN;
GO

-- 2. The stored procedure works as expected when the input parameter @address is normal. 
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N'8901 Tsawassen Blvd.'; 

-- 3. To simulate the hacker passing in a single quote, call the stored procedure with two single quotes as a delimited string. 
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N'''';

-- 4. Now insert a comment marker after the single quote, so that the final string delimiter is ignored:
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N''' -- ';

-- 5. All that remains is to inject the malicious code. 
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N''' SELECT 1 -- ';

-- 6. Now revise the stored procedure to use sp_executesql and bring in the address as a parameter to the stored procedure
USE TSQL2012;
GO
IF OBJECT_ID('Sales.ListCustomersByAddress') IS NOT NULL 
	DROP PROCEDURE Sales.ListCustomersByAddress;
GO
CREATE PROCEDURE Sales.ListCustomersByAddress
	@address AS NVARCHAR(60)
AS
DECLARE @SQLString AS NVARCHAR(4000);
SET @SQLString = N'
SELECT companyname, contactname 
FROM Sales.Customers WHERE address = @address';
EXEC sp_executesql
	@statement = @SQLString
	, @params = N'@address NVARCHAR(60)'
	, @address = @address;
RETURN;
GO

-- 7. Now enter a valid address using the revised stored procedure. 
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N'8901 Tsawassen Blvd.'; 

-- 8. Execute again the remaining steps to ensure that no unexpected data is returned:
USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = N'''';
EXEC Sales.ListCustomersByAddress @address = N''' -- ';
EXEC Sales.ListCustomersByAddress @address = N''' SELECT 1 -- ';


---------------------------------------------------------------------
-- Exercise 3 Using output parameters with sp_executesql
---------------------------------------------------------------------
-- 1. Open Management Studio and enter the following script into a query window. 
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000); 
SET @SQLString = N'SELECT COUNT(*) FROM Production.Products';
EXEC(@SQLString);

-- 2. You can use sp_executesql to capture and return values back to the caller using output parameters. 
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000)
	, @outercount AS int; 
SET @SQLString = N'SET @innercount = (SELECT COUNT(*) FROM Production.Products)';
EXEC sp_executesql 
	@statment = @SQLString
	, @params = N'@innercount AS int OUTPUT'
	, @innercount = @outercount OUTPUT;
SELECT @outercount AS  'RowCount';
