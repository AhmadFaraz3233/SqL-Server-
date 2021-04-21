-- Querying Foundations
-- Chapter 01 
-- Lession 1

USE TSQL2012;

SELECT country
FROM HR.Employees;

SELECT DISTINCT country
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees
ORDER BY empid;

SELECT empid, lastname
FROM HR.Employees
ORDER BY 1;

SELECT empid, firstname + ' ' + lastname
FROM HR.Employees;

SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

-- Lesson 02


SELECT shipperid, phone, companyname
FROM Sales.Shippers;


SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20030101'
GROUP BY country, YEAR(hiredate)
HAVING COUNT(*) > 1
ORDER BY country, yearhired DESC;

-- fails
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2003;

-- fails
SELECT empid, country, YEAR(hiredate) AS yearhired, yearhired - 1 AS prevyear
FROM HR.Employees;

-- Exercise 1: 


SELECT custid, YEAR(orderdate)
FROM Sales.Orders
ORDER BY 1, 2;


-- Exercise 2:

-- 1.

SELECT DISTINCT custid, YEAR(orderdate) AS orderyear
FROM Sales.Orders;

-- 2.

-- fails
SELECT custid, orderid
FROM Sales.Orders
GROUP BY custid;

-- 3.

SELECT custid, MAX(orderid) AS maxorderid
FROM Sales.Orders
GROUP BY custid;


-- 4.

SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
WHERE freight > 20000.00
GROUP BY shipperid;

-- 5.

-- fails
SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING totalfreight > 20000.00;

-- 6.

SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING SUM(freight) > 20000.00;