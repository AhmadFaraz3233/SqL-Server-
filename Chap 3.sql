
-- Chapter 03 - Filtering and Sorting Data

-- Lesson 01 - Filtering Data with Predicates


USE TSQL2012;

-- content of Employees table
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees

-- employees from the United States
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = N'USA';

-- employees from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';

-- employees that are not from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';

-- employees that are not from Washington State, resolving the NULL problem
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region IS NULL;

-- orders shipped on a given date
DECLARE @dt AS DATETIME = '20070212';

-- incorrect treatment of NULLs
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE shippeddate = @dt;

-- correct treatment but not SARG
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE COALESCE(shippeddate, '19000101') = COALESCE(@dt, '19000101');

-- correct treatment and also a SARG
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE shippeddate = @dt
   OR (shippeddate IS NULL AND @dt IS NULL);


-- Combining Predicates

-- Filtering Character Data

-- regular character string
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = 'Davis';

-- Unicode character string
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'Davis';

-- employees whose last name starts with the letter D.
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

---------------------------------------------------------------------
-- Filtering Date and Time Data
---------------------------------------------------------------------

-- language-dependent literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/07';

-- language-neutral literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20070212';

-- not SARG
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE YEAR(orderdate) = 2007 AND MONTH(orderdate) = 2;

-- SARG
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate >= '20070201' AND orderdate < '20070301';


-- Sorting Data


-- query with no ORDER BY doesn't guarantee presentation ordering
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA';

-- Simple ORDER BY example
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;

-- use descending order
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city DESC;

-- order by multiple columns
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city, empid;

-- order by ordinals (bad practice)
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- change SELECT list but forget to change ordinals in ORDER BY
SELECT empid, city, firstname, lastname, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- order by elements not in SELECT
SELECT empid, city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;

-- when DISTINCT specified, can only order by elements in SELECT

-- following fails
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;

-- following succeeds
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;

-- can refer to column aliases asigned in SELECT
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthmonth;

-- NULLs sort first
SELECT orderid, shippeddate
FROM Sales.Orders
WHERE custid = 20
ORDER BY shippeddate;


-- Filtering Data with TOP and OFFSET-FETCH

-- Filtering Data with TOP

-- return the three most recent orders
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- can use percent
SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
GO

-- can use expression, like parameter or variable, as input
DECLARE @n AS BIGINT = 5;

SELECT TOP (@n) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
GO

-- no ORDER BY, ordering is arbitrary
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders;

-- be explicit about arbitrary ordering
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL);

-- non-deterministic ordering even with ORDER BY since ordering isn't unique
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- return all ties
SELECT TOP (3) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- break ties
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;


-- Filtering Data with OFFSET-FETCH
-- skip 50 rows, fetch next 25 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

-- fetch first 25 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;
Go
-- skip 50 rows, return all the rest
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS;

-- ORDER BY is mandatory; return some 3 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL)
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;
GO

-- can use expressions as input
DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 3;

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO




-- Exercises

-- Exercise 1: Use the WHERE Clause to Filter Rows with NULLs

-- 2.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE shippeddate = NULL;

-- 3.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE shippeddate IS NULL;

---------------------------------------------------------------------
-- Exercise 2: Use the WHERE Clause to Filter a Range of Dates
---------------------------------------------------------------------

-- 1.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20080211' AND '20080212 23:59:59.999';

-- 2.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080211' AND orderdate < '20080213';

-- Lesson 02 - Sorting Data

-- Exercise 1: Use the ORDER BY Clause with Nondeterministic Ordering

-- 2.

SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77;

-- 3.

SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid;

-- Exercise 2: Use the ORDER BY Clause with Deterministic Ordering

-- 1.

SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid, shippeddate DESC;

-- 2.

SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid, shippeddate DESC, orderid DESC;

-- Lesson 03 - Filtering Data with TOP and OFFSET
-- Exercise 1 - Using the TOP Option

-- 2.
-- five most expensive products
SELECT TOP (5) productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC;

-- 3.
-- five most expensive products, with ties
SELECT TOP (5) WITH TIES productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC;

-- 4.
-- five most expensive products, breaking ties
SELECT TOP (5) productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC, productid DESC;

---------------------------------------------------------------------
-- Exercise 2 - Using the OFFSET-FETCH Option
---------------------------------------------------------------------

-- five products at a time, sorted by unitprice, productid

-- 2.
-- first 5 rows
SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 0 ROWS FETCH FIRST 5 ROWS ONLY;

-- 3.
-- rows 6 through 10
SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- 4.
-- rows 11 through 15
SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
