-- Chapter 04 - Combining Sets
-- add row to Production.Suppliers
USE TSQL2012;

INSERT INTO Production.Suppliers(companyname, contactname, contacttitle, address, city, postalcode, country, phone)
  VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi', N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

-- Lesson 01 - Using Joins

-- Cross Joins

-- a cross join returning a row for each day of the week
-- and shift number out of three
SELECT D.n AS theday, S.n AS shiftno  
FROM dbo.Nums AS D
  CROSS JOIN dbo.Nums AS S
WHERE D.n <= 7
  AND S.N <= 3
ORDER BY theday, shiftno;

-- Inner Joins

-- suppliers from Japan and products they supply
-- suppliers without products not included
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- same meaning
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
    AND S.country = N'Japan';

-- employees and their managers
-- employee without manager (CEO) not included
SELECT E.empid,
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  INNER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;

-- Outer Joins

-- suppliers from Japan and products they supply
-- suppliers without products included
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- return all suppliers
-- show products for only suppliers from Japan
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
   AND S.country = N'Japan';

-- employees and their managers
-- employee without manager (CEO) included
SELECT E.empid,
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  LEFT OUTER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;

-- attempt to include product category from Production.Categories table
-- inner join nullifies outer part of outer join
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
  INNER JOIN Production.Categories AS C
    ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';

-- fix using parentheses
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S
  LEFT OUTER JOIN 
    (Production.Products AS P
       INNER JOIN Production.Categories AS C
         ON C.categoryid = P.categoryid)
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

---------------------------------------------------------------------
-- Lesson 02 - Using Subqueries, Table Expressions and the APPLY Operator
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using Subqueries
---------------------------------------------------------------------


-- Self-Contained Subqueries

-- scalar subqueries
-- products with minimum price
SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice =
  (SELECT MIN(unitprice)
   FROM Production.Products);
   
-- multi-valued subqieries
-- products supplied by suppliers from Japan
SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid IN
  (SELECT supplierid
   FROM Production.Suppliers
   WHERE country = N'Japan');

-- Correlated Subqueries

-- products with minimum unitprice per category
SELECT categoryid, productid, productname, unitprice
FROM Production.Products AS P1
WHERE unitprice =
  (SELECT MIN(unitprice)
   FROM Production.Products AS P2
   WHERE P2.categoryid = P1.categoryid);

-- customers who placed an order on February 12, 2007
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20070212');

-- customers who did not place an order on February 12, 2007
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20070212');

---------------------------------------------------------------------
-- Table Expressions
---------------------------------------------------------------------

-- Derived Tables

-- row numbers for products
-- partitioned by categoryid, ordered by unitprice, productid
SELECT
  ROW_NUMBER() OVER(PARTITION BY categoryid
                    ORDER BY unitprice, productid) AS rownum,
  categoryid, productid, productname, unitprice
FROM Production.Products;

-- two products with lowest prices per category
SELECT categoryid, productid, productname, unitprice
FROM (SELECT
        ROW_NUMBER() OVER(PARTITION BY categoryid
                          ORDER BY unitprice, productid) AS rownum,
        categoryid, productid, productname, unitprice
      FROM Production.Products) AS D
WHERE rownum <= 2;

-- CTEs

-- two products with lowest prices per category
WITH C AS
(
  SELECT
    ROW_NUMBER() OVER(PARTITION BY categoryid
                      ORDER BY unitprice, productid) AS rownum,
    categoryid, productid, productname, unitprice
  FROM Production.Products
)
SELECT categoryid, productid, productname, unitprice
FROM C
WHERE rownum <= 2;

-- Recursive CTE
-- management chain leading to given employee
WITH EmpsCTE AS
(
  SELECT empid, mgrid, firstname, lastname, 0 AS distance
  FROM HR.Employees
  WHERE empid = 9

  UNION ALL

  SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
  FROM EmpsCTE AS S
    JOIN HR.Employees AS M
      ON S.mgrid = M.empid
)
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;
GO

-- Views

-- view representing ranked products per category by unitprice
IF OBJECT_ID(N'Sales.RankedProducts', N'V') IS NOT NULL DROP VIEW Sales.RankedProducts;
GO
CREATE VIEW Sales.RankedProducts
AS

SELECT
  ROW_NUMBER() OVER(PARTITION BY categoryid
                    ORDER BY unitprice, productid) AS rownum,
  categoryid, productid, productname, unitprice
FROM Production.Products;
GO

SELECT categoryid, productid, productname, unitprice
FROM Sales.RankedProducts
WHERE rownum <= 2;

-- Inline Table-Valued Functions

-- management chain leading to given employee
IF OBJECT_ID(N'HR.GetManagers', N'IF') IS NOT NULL DROP FUNCTION HR.GetManagers;
GO
CREATE FUNCTION HR.GetManagers(@empid AS INT) RETURNS TABLE
AS

RETURN
  WITH EmpsCTE AS
  (
    SELECT empid, mgrid, firstname, lastname, 0 AS distance
    FROM HR.Employees
    WHERE empid = @empid

    UNION ALL

    SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
    FROM EmpsCTE AS S
      JOIN HR.Employees AS M
        ON S.mgrid = M.empid
  )
  SELECT empid, mgrid, firstname, lastname, distance
  FROM EmpsCTE;
GO

SELECT *
FROM HR.GetManagers(9) AS M;

---------------------------------------------------------------------
-- APPLY
---------------------------------------------------------------------

-- two products with lowest unit prices for given supplier
SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid = 1
ORDER BY unitprice, productid
OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY;

-- CROSS APPLY
-- two products with lowest unit prices for each supplier from Japan
-- exclude suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY (SELECT productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid
               OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY) AS A
WHERE S.country = N'Japan';

-- OUTER APPLY
-- two products with lowest unit prices for each supplier from Japan
-- include suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY (SELECT productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid
               OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY) AS A
WHERE S.country = N'Japan';


-- Lesson 03 - Using Set Operators

-- UNION and UNION ALL

-- locations that are employee locations or customer locations or both
SELECT country, region, city
FROM HR.Employees

UNION

SELECT country, region, city
FROM Sales.Customers;

-- with UNION ALL duplicates are not discarded
SELECT country, region, city
FROM HR.Employees

UNION ALL

SELECT country, region, city
FROM Sales.Customers;


-- INTERSECT

-- locations that are both employee and customer locations
SELECT country, region, city
FROM HR.Employees

INTERSECT

SELECT country, region, city
FROM Sales.Customers;

-- EXCEPT

-- locations that are employee locations but not customer locations
SELECT country, region, city
FROM HR.Employees

EXCEPT

SELECT country, region, city
FROM Sales.Customers;

-- cleanup
DELETE FROM Production.Suppliers WHERE supplierid > 29;
IF OBJECT_ID(N'Sales.RankedProducts', N'V') IS NOT NULL DROP VIEW Sales.RankedProducts;
IF OBJECT_ID(N'HR.GetManagers', N'IF') IS NOT NULL DROP FUNCTION HR.GetManagers;


select * from Production.Suppliers

-- Exercises

-- Lesson 01 - Using Joins
-- Practice - Using Joins
-- Exercise 1 - Match Customers and Orders with Inner Joins
---------------------------------------------------------------------

-- 2.
-- customers and their orders

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

-- Exercise 2 - Match Customers and Orders with Outer Joins
-- 1.
-- customers and their orders, including customers without orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

-- 2.
-- customers without orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderid IS NULL;

-- 3.
-- all customers; orders from February 2008
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
   AND O.orderdate >= '20080201'
   AND O.orderdate < '20080301';

-- Lesson 02 - Using Subqueries, Table Expressions and the APPLY Operator
-- Practice - Using Subqueries, Table Expressions and the APPLY Operator
-- Exercise 1 - Products with Minimum Unit Price per 
-- 2.
-- query returning minimum unit price per category
SELECT categoryid, MIN(unitprice) AS mn
FROM Production.Products
GROUP BY categoryid;

-- 3.
-- join to return products with minimum unit price per category
WITH CatMin AS
(
  SELECT categoryid, MIN(unitprice) AS mn
  FROM Production.Products
  GROUP BY categoryid
)
SELECT P.categoryid, P.productid, P.productname, P.unitprice
FROM Production.Products AS P
  INNER JOIN CatMin AS M
    ON P.categoryid = M.categoryid
    AND P.unitprice = M.mn;

---------------------------------------------------------------------
-- Exercise 2 - N Products with Lowest Unit Price per Supplier
---------------------------------------------------------------------

-- 1.
-- inline function returning the @n products with the lowest unit prices for supplier @supplierid
IF OBJECT_ID(N'Production.GetTopProducts', N'IF') IS NOT NULL DROP FUNCTION Production.GetTopProducts;
GO
CREATE FUNCTION Production.GetTopProducts(@supplierid AS INT, @n AS BIGINT) RETURNS TABLE
AS

RETURN
  SELECT productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supplierid
  ORDER BY unitprice, productid
  OFFSET 0 ROWS FETCH FIRST @n ROWS ONLY;
GO

-- 2.
-- test function
SELECT * FROM Production.GetTopProducts(1, 2) AS P;

-- 3.
-- CROSS APPLY
-- two products with lowest unit prices for each supplier from Japan
-- exclude suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';

-- 4.
-- OUTER APPLY
-- two products with lowest unit prices for each supplier from Japan
-- include suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';

-- 5.
-- cleanup
IF OBJECT_ID(N'Production.GetTopProducts', N'IF') IS NOT NULL DROP FUNCTION Production.GetTopProducts;

---------------------------------------------------------------------
-- Lesson 03 - Using Set Operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Set Operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Using the EXCEPT Set Operator
---------------------------------------------------------------------

-- 2.
-- return employees who handled orders for customer 1 but not customer 2
SELECT empid
FROM Sales.Orders
WHERE custid = 1

EXCEPT

SELECT empid
FROM Sales.Orders
WHERE custid = 2;

---------------------------------------------------------------------
-- Exercise 2 - Using the INTERSECT Set Operator
---------------------------------------------------------------------

-- 1.
-- return employees who handled orders for both customer 1 and customer 2
SELECT empid
FROM Sales.Orders
WHERE custid = 1

INTERSECT

SELECT empid
FROM Sales.Orders
WHERE custid = 2;
