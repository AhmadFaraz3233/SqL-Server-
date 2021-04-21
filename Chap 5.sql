-- Chapter 05 - Grouping and Windowing 
-- Lesson 01 - Writing Grouped Queries
-- Working With a Single Grouping ---------------------------------------------------------------------

-- grouped query without GROUP BY clause
USE TSQL2012;

SELECT COUNT(*) AS numorders
FROM Sales.Orders;

-- grouped query with GROUP BY clause
SELECT shipperid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid;

-- grouping set with multiple elements
SELECT shipperid, YEAR(shippeddate) AS shippedyear,
   COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid, YEAR(shippeddate);

-- filtering groups
SELECT shipperid, YEAR(shippeddate) AS shippedyear,
   COUNT(*) AS numorders
FROM Sales.Orders
WHERE shippeddate IS NOT NULL
GROUP BY shipperid, YEAR(shippeddate)
HAVING COUNT(*) < 100;

-- general aggregate functions ignore NULLs
SELECT shipperid,
  COUNT(*) AS numorders,
  COUNT(shippeddate) AS shippedorders,
  MIN(shippeddate) AS firstshipdate,
  MAX(shippeddate) AS lastshipdate,
  SUM(val) AS totalvalue
FROM Sales.OrderValues
GROUP BY shipperid;

-- aggregating distinct cases
SELECT shipperid, COUNT(DISTINCT shippeddate) AS numshippingdates
FROM Sales.Orders
GROUP BY shipperid;
GO
Use TSQL2012
-- grouped query cannot refer to detail elements after grouping
SELECT S.shipperid, S.companyname, COUNT(*) AS numorders
FROM Sales.Shippers AS S
  JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid;
GO

-- solution 1: add column to grouping set
SELECT S.shipperid, S.companyname,
  COUNT(*) AS numorders
FROM Sales.Shippers AS S
  INNER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid, S.companyname;

-- solution 2: apply an aggregate to the column
SELECT S.shipperid,
  MAX(S.companyname) AS companyname,
  COUNT(*) AS numorders
FROM Sales.Shippers AS S
  INNER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid;

-- solution 3: join after aggregating
WITH C AS
(
  SELECT shipperid, COUNT(*) AS numorders
  FROM Sales.Orders
  GROUP BY shipperid
)
SELECT S.shipperid, S.companyname, numorders
FROM Sales.Shippers AS S
  INNER JOIN C
    ON S.shipperid = C.shipperid;


-- Working With Multiple Grouping Sets

-- using the GROUPING SETS clause
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE shippeddate IS NOT NULL -- exclude unshipped orders
GROUP BY GROUPING SETS
(
  ( shipperid, YEAR(shippeddate) ),
  ( shipperid                    ),
  ( YEAR(shippeddate)            ),
  (                              )
);

-- using the CUBE clause
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY CUBE( shipperid, YEAR(shippeddate) );

-- using the ROLLUP clause
SELECT shipcountry, shipregion, shipcity, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );

-- GROUPING and GROUPING_ID

-- GROUPING
SELECT
  shipcountry, GROUPING(shipcountry) AS grpcountry,
  shipregion , GROUPING(shipregion) AS grpregion,
  shipcity   , GROUPING(shipcity) AS grpcity,
  COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );

-- GROUPING_ID
SELECT GROUPING_ID( shipcountry, shipregion, shipcity ) AS grp_id,
  shipcountry, shipregion, shipcity,
  COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );


-- Lesson 02 - Pivoting and Unpivoting 

-- Pivoting Data

-- show customer IDs on rows, shipper IDs on columns, total freight in intersection
WITH PivotData AS
(
  SELECT
    custid   , -- grouping column
    shipperid, -- spreading column
    freight    -- aggregation column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- when applying PIVOT to Orders table direclty get a result row for each order
SELECT custid, [1], [2], [3]
FROM Sales.Orders
  PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

---------------------------------------------------------------------
-- Unpivoting Data
---------------------------------------------------------------------

-- sample data for UNPIVOT example
USE TSQL2012;
IF OBJECT_ID(N'Sales.FreightTotals', N'U') IS NOT NULL DROP TABLE Sales.FreightTotals;
GO

WITH PivotData AS
(
  SELECT
    custid   , -- grouping column
    shipperid, -- spreading column
    freight    -- aggregation column
  FROM Sales.Orders
)
SELECT *
INTO Sales.FreightTotals
FROM PivotData
  PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

SELECT * FROM Sales.FreightTotals;

-- unpivot data
SELECT custid, shipperid, freight
FROM Sales.FreightTotals
  UNPIVOT( freight FOR shipperid IN([1],[2],[3]) ) AS U;

-- cleanup
IF OBJECT_ID(N'Sales.FreightTotals', N'U') IS NOT NULL DROP TABLE Sales.FreightTotals;

---------------------------------------------------------------------
-- Lesson 03 - Using Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Window Aggregate Functions
---------------------------------------------------------------------

-- partitioning

-- returning detail as well as aggregates
SELECT custid, orderid, 
  val,
  SUM(val) OVER(PARTITION BY custid) AS custtotal,
  SUM(val) OVER() AS grandtotal
FROM Sales.OrderValues;

-- computing percents of detail out of aggregates
SELECT custid, orderid, 
  val,
  CAST(100.0 * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust,
  CAST(100.0 * val / SUM(val) OVER()                    AS NUMERIC(5, 2)) AS pcttotal
FROM Sales.OrderValues;

-- framing

-- computing running total
SELECT custid, orderid, orderdate, val,
  SUM(val) OVER(PARTITION BY custid
                ORDER BY orderdate, orderid
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runningtotal
FROM Sales.OrderValues;

-- filter running totals that are less than 1000.00
WITH RunningTotals AS
(
  SELECT custid, orderid, orderdate, val,
    SUM(val) OVER(PARTITION BY custid
                  ORDER BY orderdate, orderid
                  ROWS BETWEEN UNBOUNDED PRECEDING
                           AND CURRENT ROW) AS runningtotal
  FROM Sales.OrderValues
)
SELECT *
FROM RunningTotals
WHERE runningtotal < 1000.00;

---------------------------------------------------------------------
-- Window Ranking Functions
---------------------------------------------------------------------

SELECT custid, orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  RANK()       OVER(ORDER BY val) AS rnk,
  DENSE_RANK() OVER(ORDER BY val) AS densernk,
  NTILE(100)   OVER(ORDER BY val) AS ntile100
FROM Sales.OrderValues;

---------------------------------------------------------------------
-- Window Offset Functions
---------------------------------------------------------------------

-- LAG and LEAD retrieving values from previous and next rows
SELECT custid, orderid, orderdate, val,
  LAG(val)  OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS prev_val,
  LEAD(val) OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS next_val
FROM Sales.OrderValues;

-- FIRST_VALUE and LAST_VALUE retrieving values from first and last rows in frame
SELECT custid, orderid, orderdate, val,
  FIRST_VALUE(val)  OVER(PARTITION BY custid
                         ORDER BY orderdate, orderid
                         ROWS BETWEEN UNBOUNDED PRECEDING
                                  AND CURRENT ROW) AS first_val,
  LAST_VALUE(val) OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid
                       ROWS BETWEEN CURRENT ROW
                                AND UNBOUNDED FOLLOWING) AS last_val
FROM Sales.OrderValues;


---------------------------------------------------------------------
-- TK 70-461 - Chapter 05 - Grouping and Windowing
-- Exercises
---------------------------------------------------------------------

-- Lesson 01 - Writing Grouped Queries

-- Exercise 1 - Aggregate Information About Customer Orders


-- 2.

-- compute number of orders per customer for customers from Spain

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid;

-- 3.

-- add city to the SELECT list
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid;

-- 4.

-- add city to GROUP BY as well
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid, C.city;

---------------------------------------------------------------------
-- Exercise 2 - Define Multiple Grouping Sets
---------------------------------------------------------------------

-- 1.

-- add total of all orders; present detail first
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY GROUPING SETS ( (C.custid, C.city), () )
ORDER BY GROUPING(C.custid);

---------------------------------------------------------------------
-- Lesson 02 - Pivoting and Unpivoting Data

-- Exercise 1 - Pivot Data Using a Table Expression
---------------------------------------------------------------------

-- 2.

-- attempt to return maximum shipping date for each order year and shipper ID
-- with order years on rows and shipper IDs (1, 2 and 3) on columns
SELECT YEAR(orderdate) AS orderyear, [1], [2], [3]
FROM Sales.Orders
  PIVOT( MAX(shippeddate) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- 3.

-- correct the query from step 2 to return only one row per order year
-- by using a table expression

WITH PivotData AS
(
	SELECT YEAR(orderdate) AS orderyear, shipperid, shippeddate
	FROM Sales.Orders
)
SELECT orderyear, [1], [2], [3]
FROM PivotData
  PIVOT( MAX(shippeddate) FOR shipperid IN ([1],[2],[3]) ) AS P;


---------------------------------------------------------------------
-- Exercise 2 - Pivot Data and Compute Counts
---------------------------------------------------------------------

-- 1.

-- show customer IDs on rows, shipper IDs on columns, count of orders in intersection

-- first attempt to use a query similar to the one in the module, but with COUNT(*)
WITH PivotData AS
(
  SELECT
    custid   ,  -- grouping column
    shipperid   -- spreading column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT( COUNT(*) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- 2.

-- solve the problem by either returning the key or a dummy column
WITH PivotData AS
(
  SELECT
    custid   ,  -- grouping column
    shipperid,  -- spreading column
    1 AS aggcol -- aggregation column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT( COUNT(aggcol) FOR shipperid IN ([1],[2],[3]) ) AS P;

---------------------------------------------------------------------
-- Lesson 03 - Using Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use Window Aggregate Functions
---------------------------------------------------------------------

-- 2.

-- per each customer and order compute moving average value of the customer's last three orders
SELECT custid, orderid, orderdate, val,
  AVG(val) OVER(PARTITION BY custid
                ORDER BY orderdate, orderid
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW) AS movingavg
FROM Sales.OrderValues;

---------------------------------------------------------------------
-- Exercise 2 - Using Window Ranking and Offset Functions
---------------------------------------------------------------------

-- 1.

-- filter for each shipper the three orders with the highest freight
WITH C AS
(
  SELECT shipperid, orderid, freight,
    ROW_NUMBER() OVER(PARTITION BY shipperid
                      ORDER BY freight DESC, orderid) AS rownum
  FROM Sales.Orders
)
SELECT shipperid, orderid, freight
FROM C
WHERE rownum <= 3
ORDER BY shipperid, rownum;

-- 2.

-- compute the difference between the current order value and the value of the customer's previous order,
-- as well as the difference between the current order value and the value of the customer's next order

SELECT custid, orderid, orderdate, val,
  val - LAG(val)  OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid) AS diffprev,
  val - LEAD(val) OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid) AS diffnext
FROM Sales.OrderValues;
