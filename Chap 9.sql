-- Chapter 09 - Designing and Creating Views, Inline Functions and Synonyms 

-- Lesson 1: Designing and Implementing Views and Inline Functions
CREATE VIEW Sales.OrderTotalsByYear
  WITH SCHEMABINDING
AS
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

--You can read from a view just as you would a table. So you can SELECT from it as follows:
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear; 
--Now let's put this example in the context of the basic syntax for the CREATE VIEW statement:

CREATE VIEW [ schema_name . ] view_name [ (column [ ,...n ] ) ]
[ WITH <view_attribute> [ ,...n ] ]
AS select_statement
[ WITH CHECK OPTION ] [ ; ]

--You can specify the set of output columns following the view name. For example, you could rewrite the CREATE VIEW statement for Sales.OrderTotalsByYear and specify the column names right after the view name instead of in the SELECT statement:
CREATE VIEW Sales.OrderTotalsByYear(orderyear, qty)
  WITH SCHEMABINDING 
AS
SELECT
  YEAR(O.orderdate),
  SUM(OD.qty) 
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

--After you have created a view, you can use the ALTER VIEW command to change the view's structure and add or remove the view properties. An ALTER VIEW simply redefines how the view works by re-issuing the entire view definition. For example, you could redefine the Sales.OrderTotalsByYear view to add a new column for the region the order was shipped to, the shipregion column: 
ALTER VIEW Sales.OrderTotalsByYear
  WITH SCHEMABINDING 
AS
SELECT
  O.shipregion,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate), O.shipregion;
GO

--Now you can change the way you SELECT from the view, just as you would a table to include the new column; and you can optionally order the results with an ORDER BY:
SELECT shipregion, orderyear, qty
FROM Sales.OrderTotalsByYear
ORDER BY shipregion;

--You drop a view in the same way you would a table:
DROP VIEW Sales.OrderTotalsByYear;

--When you need to create a new view and conditionally replace the old view, you must first drop the old view and then create the new view. The following example shows one method:
IF OBJECT_ID('Sales.OrderTotalsByYear', 'V') IS NOT NULL
	DROP VIEW Sales.OrderTotalsByYear;
GO
CREATE VIEW Sales.OrderTotalsByYear
...
--To explore view metadata using T-SQL, you can query the sys.views catalog view:
USE TSQL2012;
GO
SELECT name, object_id, principal_id, schema_id, type 
FROM sys.views;

--You can also query the INFORMATION_SCHEMA.TABLES system view, but it is slightly more complex:
SELECT SCHEMA_NAME, TABLE_NAME, TABLE_TYPE 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'VIEW';

--Using sys.views is more reliable, and from it you can join to other catalog views such as sys.sql_modules to get further information.
--An inline table-valued function returns a row set based on a SELECT statement you coded into the function. In effect, you treat the table-valued function as a table and SELECT FROM it. For example, you can create an inline function that would operate just like the Sales.OrderTotalsByYear view, with no parameters, as follows:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
	(
	SELECT
	  YEAR(O.orderdate) AS orderyear,
	  SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
	  JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate)
	);
GO

--In the above example, the SELECT statement was just as complex as the original Sales.OrderTotalsByYear view. If you don't need any additional columns from the table, you could actually simplify the function by selecting from the view directly:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
	(
	SELECT orderyear, qty FROM Sales.OrderTotalsByYear 
	);
GO

--Consider that if you only wanted to see the year 2007, you would just put that in a WHERE clause when selecting from the view. 
SELECT orderyear, qty
FROM [Sales].[OrderTotalsByYear]
WHERE orderyear = 2007; 


--To make the WHERE clause more flexible, you can declare a variable and then filter based on the variable:
DECLARE @orderyear int = 2007;
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear
WHERE orderyear = @orderyear;

--Keeping this in mind, it is now just a quick step to an inline function. Instead of declaring a variable @orderyear, define the parameter @orderyear in the function while filtering the SELECT statement in the same way as previously:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear (@orderyear int)
RETURNS TABLE
AS
RETURN
	(
	SELECT orderyear, qty FROM Sales.OrderTotalsByYear 
	WHERE orderyear = @orderyear
	);
GO

--You can query the function but pass the year you want to see:
SELECT orderyear, qty FROM Sales.fn_OrderTotalsByYear(2007);


-- Lesson 2: Using Synonyms
--To create a synonym, you simply assign a synonym name, and specify the name of the database object it will be assigned to. For example, you could define a synonym called Categories and put it in the dbo schema so that users do not need to remember the schema-object name Production.Categories in their queries. You can issue:
USE TSQL2012;
GO
CREATE SYNONYM dbo.Categories FOR Production.Categories;
GO

--Then the end user can select from Categories without needing to specify a schema:
SELECT categoryid, categoryname, description *  
FROM Categories;

--The basic syntax for creating a synonym is quite simple:
CREATE SYNONYM schema_name.synonym_name FOR object_name

--You can drop a synonym using the DROP SYNONYM statement:
DROP SYNONYM dbo.Categories
--There is no ALTER SYNONYM. As a result, just as with a database schema, to change a synonym you must drop and recreate it.

--For example, suppose the database DB01 has a view called Sales.Reports, and it is on the same server as TSQL2012. Then to query it from TSQL2012, you must write something like:
SELECT report_id, report_name FROM ReportsDB.Sales.Reports

--Now suppose you add a synonym, called simply Sales.Reports:
CREATE SYNONYM Sales.Reports FOR ReportsDB.Sales.Reports 

--The query is now simplified to:
SELECT report_id, report_name FROM Sales.Reports



-- =============================================================
-- Chapter 9, Lesson 1
-- Exercise 1 Building a view for a report
-- =============================================================
--You have been asked to develop the database interface for a report on the TSQL2012 database. The application needs a view that shows the quantity sold and total sales for all sales, by year, per customer and per shipper. The user would also like to be able to filter the results by upper and lower total quantity. 
--1.	Start with the current [Sales].[OrderTotalsByYear] as shown in the Lesson above. Type in the SELECT statement without the view definition:
USE TSQL2012;
GO
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

--2.	Note that the [Sales].[OrderValues] view does contain the computed sales amount, as 
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val

--3.	Combine the two queries:
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

--4.	Now add the columns for custid to return the customer id and the shipperid. Note that you must now change the GROUP BY clause in order to expose those two ids: 
SELECT
  O.custid,
  O.shipperid,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(O.orderdate), O.custid, O.shipperid;

--5.	So far so good, but you need to show the shipper and customer names in the results for the report. So you need to add JOINs to the [Sales].[Customers] table and to the [Sales].[Shippers] table:
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate);

--6.	Now add the customer company name (companyname) and the shipping company name (companyname). You must expand the GROUP BY clause to expose those columns:
SELECT
  C.companyname AS customercompany,
  S.companyname AS shippercompany,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate), C.companyname, S.companyname;

--7.	Now turn this into a view called [Sales].[OrderTotalsByYearCustShip]:
IF OBJECT_ID (N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip;
GO
CREATE VIEW [Sales].[OrderTotalsByYearCustShip]
  WITH SCHEMABINDING
AS
SELECT
  C.companyname AS customercompany,
  S.companyname AS shippercompany,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate), C.companyname, S.companyname;
GO
--Test the view by SELECTing from it:
SELECT SELECT customercompany, shippercompany, orderyear, qty, val 
FROM [Sales].[OrderTotalsByYearCustShip]
ORDER BY customercompany, shippercompany, orderyear;

-- 8.	To clean up, drop the view.
IF OBJECT_ID(N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip

-- =============================================================
-- Chapter 9, Lesson 1
-- Exercise 2 Convert a View into an Inline Function
-- =============================================================
--1.	Now change the view into an inline function that filters by low and high values of the total quantity. Add two parameters called @highqty and @lowqty, both integers, and add a WHERE clause to filter the results. Name the function [Sales].[fn_ OrderTotalsByYearCustShip]:
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYearCustShip', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYearCustShip;
GO
CREATE FUNCTION [Sales].[fn_OrderTotalsByYearCustShip] (@lowqty int, @highqty int)
RETURNS TABLE
AS
RETURN
	(
	SELECT
	  C.companyname AS customercompany,
	  S.companyname AS shippercompany,
	  YEAR(O.orderdate) AS orderyear,
	  SUM(OD.qty) AS qty,
	  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
		 AS NUMERIC(12, 2)) AS val
	FROM Sales.Orders AS O
	  JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
	  JOIN Sales.Customers AS C
		ON O.custid = C.custid
	  JOIN Sales.Shippers AS S
		ON O.shipperid = S.shipperid
	GROUP BY YEAR(O.orderdate), C.companyname, S.companyname
	HAVING SUM(OD.qty) >= @lowqty AND SUM(OD.qty) <= @highqty
	);
GO

-- 2.	Now test the function:
SELECT customercompany, shippercompany, orderyear, qty, val  
FROM [Sales].[fn_OrderTotalsByYearCustShip] (100, 200)
ORDER BY customercompany, shippercompany, orderyear;
--Experiment with other values until you are certain you understand how the function and its filtering is working.

-- 3.	Cleanup: To clean up, just drop the view and the function:
IF OBJECT_ID (N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYearCustShip', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYearCustShip;
GO

-- =============================================================
-- Chapter 9, Lesson 2
-- Exercise 1 Using Synonyms to provide more descriptive names for reporting
-- =============================================================

--1.	Assume the following scenario: the TSQL2012 system has been in production for some time now, and you have been asked to provide access for a new reporting application to the database. However, the current view names are not as descriptive as the reporting users would like, so you will use synonyms to make them more descriptive. Start in the TSQL2012 database: 
USE TSQL2012;
GO

--2.	Now create a special schema for reports
CREATE SCHEMA Reports AUTHORIZATION dbo;
GO

--3.	Create a synonym for the Sales.CustOrders view. Look first at the data:
SELECT custid, ordermonth, qty  FROM Sales.CustOrders;
--You have determined that the data actually shows the customer id, then total of the qty column, by month. Therefore create the TotalCustQtyByMonth synonym and test it:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR Sales.CustOrders;
SELECT  custid, ordermonth, qty  FROM Reports.TotalCustQtyByMonth;

--4.	Next, create a synonym for the Sales.EmpOrders view by inspecting the data first:
SELECT empid, ordermonth, qty, val, numorders FROM Sales.EmpOrders;
--The data shows employee id, then the total qty and val columns, by month. Therefore create the TotalEmpQtyValOrdersByMonth synonym for it and test: 
CREATE SYNONYM Reports.TotalEmpQtyValOrdersByMonth FOR Sales.EmpOrders;
SELECT empid, ordermonth, qty, val, numorders FROM Reports.TotalEmpQtyValOrdersByMonth;

--5.	Next, inspect the data for Sales.OrderTotalsByYear:
SELECT orderyear, qty FROM Sales.OrderTotalsByYear;
--This view shows the total qty value by year, so name the synonym TotalQtyByYear:
CREATE SYNONYM Reports.TotalQtyByYear FOR Sales.OrderTotalsByYear;
SELECT orderyear, qty FROM Reports.TotalQtyByYear;

--6.	Last, inspect the data for Sales.OrderValues:
SELECT orderid, custid, empid, shipperid, orderdate, requireddate, shippeddate, qty, val 
FROM Sales.OrderValues;

--This view shows the total of val and qty for each order, so name the synonym TotalQtyValOrders:
CREATE SYNONYM Reports.TotalQtyValOrders FOR Sales.OrderValues;
SELECT orderid, custid, empid, shipperid, orderdate, requireddate, shippeddate, qty, val 
FROM Reports.TotalQtyValOrders;
--Note that there is no unique key on the combination of columns in the GROUP BY of the Sales.OrderValues view. Right now, the number of rows grouped is also the number or orders, but that is not guaranteed. Your feedback to the development team should be that if this set of columns does define a unique row in the table, they should create a uniqueness constraint (or a unique index) on the table to enforce it. 

--7.	Now inspect the metadata for the synonyms. Note that you can use the SCHEMA_NAME() function to display the schema name without having to join to the sys.schemas table.
SELECT name, object_id, principal_id, schema_id, parent_object_id  FROM sys.synonyms;
SELECT SCHEMA_NAME(schema_id) AS schemaname, name, object_id, principal_id, schema_id, parent_object_id FROM sys.synonyms;

--8.	Now you can optionally clean up the TSQL database and remove your work.
DROP SYNONYM Reports.TotalCustQtyByMonth;
DROP SYNONYM Reports.TotalEmpQtyValOrdersByMonth;
DROP SYNONYM Reports.TotalQtyByYear;
DROP SYNONYM Reports.TotalQtyValOrders;
GO
DROP SCHEMA Reports;
GO


-- =============================================================
-- Chapter 9, Lesson 2
-- Exercise 2 Useing Synonyms to simplify a cross-database query
-- =============================================================

--1.	You want to show the reporting team that they could run their reports from a dedicated reporting database on the server without having to directly query the main TSQL2012 database. You have decided to use synonyms to prototype the strategy. First, create a new reporting database called TSQL2012Reports:
USE Master;
GO
CREATE DATABASE TSQL2012Reports;
GO

--2.	Now in the reporting database, create a schema called Reports
USE TSQL2012Reports;
GO
CREATE SCHEMA Reports AUTHORIZATION dbo;
GO

--3.	As an initial test, create the TotalCustQtyByMonth synonym to the nonexistent local object Sales.CustOrders and test:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR Sales.CustOrders;
GO
SELECT custid, ordermonth, qty FROM Reports.TotalCustQtyByMonth; -- Fails
GO
DROP SYNONYM Reports.TotalCustQtyByMonth;
GO

--4.	Next, create the TotalCustQtyByMonth synonym referencing the Sales.CustOrders view in the TSQL2012 database and test it:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR TSQL2012.Sales.CustOrders;
GO
SELECT custid, ordermonth, qty FROM Reports.TotalCustQtyByMonth; -- Succeeds 
GO

--5.	After you've demonstrated to the reporting team that this scenario can work, clean up and remove the database:
DROP SYNONYM Reports.TotalCustQtyByMonth;
GO
DROP SCHEMA Reports;
GO
USE Master;
GO
DROP DATABASE TSQL2012Reports;
GO
