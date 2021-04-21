---------------------------------------------------------------------
-- TK 70-461 - Chapter 11 - Other Data Modification Aspects
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using the Sequence Object and IDENTITY Column property
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using the IDENTITY Column Property
---------------------------------------------------------------------

-- create table Sales.MyOrders
USE TSQL2012;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
GO

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL IDENTITY(1, 1)
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- insert some rows
INSERT INTO Sales.MyOrders(custid, empid, orderdate) VALUES
  (1, 2, '20120620'),
  (1, 3, '20120620'),
  (2, 2, '20120620');

SELECT * FROM Sales.MyOrders;

-- identity-related functions
SELECT
  SCOPE_IDENTITY()                AS SCOPE_IDENTITY,
  @@IDENTITY                      AS [@@IDENTITY],
  IDENT_CURRENT('Sales.MyOrders') AS IDENT_CURRENT;

-- clear the table
TRUNCATE TABLE Sales.MyOrders;

-- see that identity was reset
SELECT IDENT_CURRENT('Sales.MyOrders') AS [IDENT_CURRENT];

-- reseed
DBCC CHECKIDENT('Sales.MyOrders', RESEED, 4);

INSERT INTO Sales.MyOrders(custid, empid, orderdate) VALUES(2, 2, '20120620');
SELECT * FROM Sales.MyOrders;

-- can have gaps (will fail)
INSERT INTO Sales.MyOrders(custid, empid, orderdate) VALUES(3, -1, '20120620');

INSERT INTO Sales.MyOrders(custid, empid, orderdate) VALUES(3, 1, '20120620');

SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- Using the Sequence Object
---------------------------------------------------------------------

-- create sequence
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

-- request a new value; run 3 times
SELECT NEXT VALUE FOR Sales.SeqOrderIDs;

-- alter sequence properties (all besides type)
ALTER SEQUENCE Sales.SeqOrderIDs
  RESTART WITH 1;

-- recreate Sales.MyOrders table
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
GO

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- use in INSERT VALUES
INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate) VALUES
  (NEXT VALUE FOR Sales.SeqOrderIDs, 1, 2, '20120620'),
  (NEXT VALUE FOR Sales.SeqOrderIDs, 1, 3, '20120620'),
  (NEXT VALUE FOR Sales.SeqOrderIDs, 2, 2, '20120620');

-- use in INSERT SELECT
INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate)
  SELECT
    NEXT VALUE FOR Sales.SeqOrderIDs OVER(ORDER BY orderid),
    custid, empid, orderdate
  FROM Sales.Orders
  WHERE custid = 1;

SELECT * FROM Sales.MyOrders;

-- add as default constraint
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT DFT_MyOrders_orderid
    DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs) FOR orderid;

-- add rows without explicitly specifying orderid
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  SELECT
    custid, empid, orderdate
  FROM Sales.Orders
  WHERE custid = 2;

-- changing the CACHE value
ALTER SEQUENCE Sales.SeqOrderIDs
  CACHE 100;

---------------------------------------------------------------------
-- Lesson 02 - Merging Data
---------------------------------------------------------------------

-- clear table and reset sequence if the already exist
TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;

-- create table and sequence if they don't already exist
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
    CONSTRAINT DFT_MyOrders_orderid
      DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- SELECT without FROM
DECLARE
  @orderid   AS INT  = 1,
  @custid    AS INT  = 1,
  @empid     AS INT  = 2,
  @orderdate AS DATE = '20120620';

SELECT *
FROM (SELECT @orderid, @custid, @empid, @orderdate )
      AS SRC( orderid,  custid,  empid,  orderdate );
GO
      
-- table value constructor
DECLARE
  @orderid   AS INT  = 1,
  @custid    AS INT  = 1,
  @empid     AS INT  = 2,
  @orderdate AS DATE = '20120620';

SELECT *
FROM (VALUES(@orderid, @custid, @empid, @orderdate))
      AS SRC( orderid,  custid,  empid,  orderdate);
GO

-- update where exists, insert where not exists
DECLARE
  @orderid   AS INT  = 1,
  @custid    AS INT  = 1,
  @empid     AS INT  = 2,
  @orderdate AS DATE = '20120620';

MERGE INTO Sales.MyOrders WITH (HOLDLOCK) AS TGT
USING (VALUES(@orderid, @custid, @empid, @orderdate))
       AS SRC( orderid,  custid,  empid,  orderdate)
  ON SRC.orderid = TGT.orderid
WHEN MATCHED THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);
GO

-- update where exists (only if different), insert where not exists
DECLARE
  @orderid   AS INT  = 1,
  @custid    AS INT  = 1,
  @empid     AS INT  = 2,
  @orderdate AS DATE = '20120620';

MERGE INTO Sales.MyOrders WITH (HOLDLOCK) AS TGT
USING (VALUES(@orderid, @custid, @empid, @orderdate))
       AS SRC( orderid,  custid,  empid,  orderdate)
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);
GO

-- table as source
DECLARE @Orders AS TABLE
(
  orderid   INT  NOT NULL PRIMARY KEY,
  custid    INT  NOT NULL,
  empid     INT  NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO @Orders(orderid, custid, empid, orderdate) VALUES
  (2, 1, 3, '20120612'),
  (3, 2, 2, '20120612'),
  (4, 3, 5, '20120612');

-- update where exists (only if different), insert where not exists,
-- delete when exists in target but not in source
MERGE INTO Sales.MyOrders AS TGT
USING @Orders AS SRC
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

-- query table
SELECT *
FROM Sales.MyOrders;

---------------------------------------------------------------------
-- Lesson 03 - Using the OUTPUT Option 
---------------------------------------------------------------------

-- clear table and reset sequence if the already exist
TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;

-- create table and sequence if they don't already exist
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
    CONSTRAINT DFT_MyOrders_orderid
      DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
  custid INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- INSERT with OUTPUT
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  OUTPUT
    inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
  SELECT custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';

-- could use INTO
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  OUTPUT
    inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
    INTO SomeTable(orderid, custid, empid, orderdate)
  SELECT custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';

-- DELETE with OUTPUT
DELETE FROM Sales.MyOrders
  OUTPUT deleted.orderid
WHERE empid = 1;

-- UPDATE with OUTPUT
UPDATE Sales.MyOrders
  SET orderdate = DATEADD(day, 1, orderdate)
  OUTPUT
    inserted.orderid,
    deleted.orderdate AS old_orderdate,
    inserted.orderdate AS neworderdate
WHERE empid = 7;

-- MERGE with OUTPUT
MERGE INTO Sales.MyOrders AS TGT
USING (VALUES(1,        70,      1,      '20061218'),
             (2,        70,      7,      '20070429'),
             (3,        70,      7,      '20070820'),
             (4,        70,      3,      '20080114'),
             (5,        70,      1,      '20080226'),
             (6,        70,      2,      '20080410'))
       AS SRC(orderid,  custid,  empid,  orderdate )
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE
OUTPUT
  $action AS the_action,
  COALESCE(inserted.orderid, deleted.orderid) AS orderid;

-- clear table
TRUNCATE TABLE Sales.MyOrders;

-- compsable DML
DECLARE @InsertedOrders AS TABLE
(
  orderid   INT  NOT NULL PRIMARY KEY,
  custid    INT  NOT NULL,
  empid     INT  NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO @InsertedOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM (MERGE INTO Sales.MyOrders AS TGT
        USING (VALUES(1,        70,      1,      '20061218'),
                     (2,        70,      7,      '20070429'),
                     (3,        70,      7,      '20070820'),
                     (4,        70,      3,      '20080114'),
                     (5,        70,      1,      '20080226'),
                     (6,        70,      2,      '20080410'))
               AS SRC(orderid,  custid,  empid,  orderdate )
          ON SRC.orderid = TGT.orderid
        WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                          OR TGT.empid     <> SRC.empid
                          OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
          SET TGT.custid    = SRC.custid,
              TGT.empid     = SRC.empid,
              TGT.orderdate = SRC.orderdate
        WHEN NOT MATCHED THEN INSERT
          VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
        WHEN NOT MATCHED BY SOURCE THEN
          DELETE
        OUTPUT
          $action AS the_action, inserted.*) AS D
  WHERE the_action = 'INSERT';

SELECT *
FROM @InsertedOrders;

-- cleanup
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL
  DROP SEQUENCE Sales.SeqOrderIDs;



  ---------------------------------------------------------------------
-- TK 70-461 - Chapter 11 - Other Data Modification Aspects
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using the Sequence Object and IDENTITY Column Property
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the Sequence Object
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Create a Sequence with Default Options
---------------------------------------------------------------------

-- 2.

-- create a sequence called dbo.Seq1 with the defaults
USE TSQL2012;

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1;

-- 3.

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

---------------------------------------------------------------------
-- Exercise 2 - Create a Sequence with Non-Default Options
---------------------------------------------------------------------

-- 1.

-- cannot alter type; need to recreate

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1 AS INT
  START WITH 1 CYCLE;

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

-- 2.

ALTER SEQUENCE dbo.Seq1 RESTART WITH 2147483647;

-- run twice
SELECT NEXT VALUE FOR dbo.Seq1;

-- 3.

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1 AS INT
  MINVALUE 1 CYCLE;

-- 4.

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

-- 5.

ALTER SEQUENCE dbo.Seq1 RESTART WITH 2147483647;

-- run twice
SELECT NEXT VALUE FOR dbo.Seq1;

---------------------------------------------------------------------
-- Lesson 02 - Merging Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Merging Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use the MERGE Statement
---------------------------------------------------------------------

-- 2.

-- create the Sales.MyOrders table
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
    CONSTRAINT DFT_MyOrders_orderid
      DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- 3.

-- merge data from Sales.Orders into Sales.MyOrders
MERGE INTO Sales.MyOrders AS TGT
USING Sales.Orders AS SRC
  ON  SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

---------------------------------------------------------------------
-- Exercise 2 - Understand the Role of the ON Clause in a MERGE Statement
---------------------------------------------------------------------

-- 1.

-- populate the Sales.MyOrders table

TRUNCATE TABLE Sales.MyOrders;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry <> N'Norway';

-- 2.

-- try merging Norway customers from Sales.Orders into Sales.MyOrders
MERGE INTO Sales.MyOrders AS TGT
USING Sales.Orders AS SRC
  ON  SRC.orderid = TGT.orderid
  AND shipcountry = N'Norway'
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- 3.

-- try again, but filter the relevant rows in a table expression
WITH SRC AS
(
  SELECT *
  FROM Sales.Orders
  WHERE shipcountry = N'Norway'
)
MERGE INTO Sales.MyOrders AS TGT
USING SRC
  ON  SRC.orderid = TGT.orderid 
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- alternative with derived table
MERGE INTO Sales.MyOrders AS TGT
USING ( SELECT *
        FROM Sales.Orders
        WHERE shipcountry = N'Norway' )
 AS SRC
  ON  SRC.orderid = TGT.orderid 
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

---------------------------------------------------------------------
-- Lesson 03 - Using the OUTPUT Option 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the OUTPUT Option
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use OUTPUT in an UPDATE Statement
---------------------------------------------------------------------

-- 2.

SELECT productid, productname, unitprice
FROM Production.Products
WHERE categoryid = 1
  AND supplierid = 16;

-- 3.

-- increase unitprice by 2.5; return the percent of price increase in the output
UPDATE Production.Products
  SET unitprice += 2.5
  OUTPUT
    inserted.productid,
    inserted.productname,
    deleted.unitprice AS oldprice,
    inserted.unitprice AS newprice,
    CAST(100.0 * (inserted.unitprice - deleted.unitprice)
                 / deleted.unitprice AS NUMERIC(5, 2)) AS pct
WHERE categoryid = 1
  AND supplierid = 16;

-- 4.

-- update back
UPDATE Production.Products
  SET unitprice -= 2.5
  OUTPUT
    inserted.productid,
    inserted.productname,
    deleted.unitprice AS oldprice,
    inserted.unitprice AS newprice,
    CAST(100.0 * (inserted.unitprice - deleted.unitprice)
                 / deleted.unitprice AS NUMERIC(5, 2)) AS pct
WHERE categoryid = 1
  AND supplierid = 16;

---------------------------------------------------------------------
-- Exercise 2 - Use Composable DML
---------------------------------------------------------------------

-- 1.

-- create the Sales.MyOrders and Sales.MyOrdersArchive table
IF OBJECT_ID(N'Sales.MyOrdersArchive', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrdersArchive;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM Sales.Orders;

CREATE TABLE Sales.MyOrdersArchive
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrdersArchive PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
);

-- 2.

-- delete orders placed before 2007
-- archive deleted orders placed by customers 17 and 19
INSERT INTO Sales.MyOrdersArchive(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM (DELETE FROM Sales.MyOrders
          OUTPUT deleted.*
        WHERE orderdate < '20070101') AS D
  WHERE custid IN (17, 19);

-- 3.

-- query Sales.MyOrdersArchive
SELECT *
FROM Sales.MyOrdersArchive;

-- 4.

-- run the following code for cleanup
IF OBJECT_ID(N'Sales.MyOrdersArchive', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrdersArchive;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
