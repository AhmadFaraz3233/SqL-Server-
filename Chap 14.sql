---------------------------------------------------------------------
-- TK 70-461 - Chapter 04 - Using Tools to Analyze Query Performance
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Getting Started with Query Optimization
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Pseudo-code in this lesson
---------------------------------------------------------------------
/*
SELECT A.col5, SUM(C.col6) AS col6sum
FROM TableA AS A
 INNER JOIN TableB AS B
   ON A.col1 = B.col1
 INNER JOIN TableC AS C
   ON B.col2 = c.col2
WHERE A.col3 = constant1
  AND B.col4 = constant2
GROUP BY A.col5;

SELECT col1 FROM TableA WHERE col2 = 3;

SELECT col1 FROM TableA WHERE col2 = 5;

SELECT col1 FROM TableA WHERE col2 = ?;
*/


---------------------------------------------------------------------
-- Lesson 02 - Using SET Session Options and Analyzing Query Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- SET Session Options
---------------------------------------------------------------------

USE TSQL2012;
SET NOCOUNT ON;
GO

-- Get number of pages for Customers and Orders
DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SELECT * FROM Sales.Customers;
SELECT * FROM Sales.Orders;
GO

-- Example of overestimated logical reads
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid;
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid
WHERE O.custid < 5;
GO

-- Turn off statistics IO
SET STATISTICS IO OFF;
GO

-- Use statistics time for the same two queries
-- Also drop clean buffers
DBCC DROPCLEANBUFFERS;
SET STATISTICS TIME ON;
GO
-- Execute a query
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid;
-- Drop clean buffers
DBCC DROPCLEANBUFFERS;
GO
-- Execute a query
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE O.custid < 5;
-- Set statistics time off
SET STATISTICS TIME OFF;
GO


---------------------------------------------------------------------
-- Execution plans
---------------------------------------------------------------------

-- Turn Actual Execution Plan on
SELECT C.custid, MIN(C.companyname) AS companyname, 
 COUNT(*) AS numorders
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE O.custid < 5
GROUP BY C.custid
HAVING COUNT(*) > 6;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Dynamic Management Objects
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Most Important DMOs for Query Tuning
---------------------------------------------------------------------

-- Base info - sys.dm_os_sys_info
SELECT cpu_count AS logical_cpu_count,
 cpu_count / hyperthread_ratio AS physical_cpu_count,
 CAST(physical_memory_kb / 1024. AS int) AS physical_memory__mb, 
 sqlserver_start_time
FROM sys.dm_os_sys_info;

-- Waiting sessions - sys.dm_os_waiting_tasks, sys.dm_exec_sessions
SELECT S.login_name, S.host_name, S.program_name,
 WT.session_id, WT.wait_duration_ms, WT.wait_type, 
 WT.blocking_session_id, WT.resource_description
FROM sys.dm_os_waiting_tasks AS WT
 INNER JOIN sys.dm_exec_sessions AS S
  ON WT.session_id = S.session_id
WHERE s.is_user_process = 1;

-- Currently executing batches, with text and wait info
SELECT S.login_name, S.host_name, S.program_name,
 R.command, T.text,
 R.wait_type, R.wait_time, R.blocking_session_id
FROM sys.dm_exec_requests AS R
 INNER JOIN sys.dm_exec_sessions AS S
  ON R.session_id = S.session_id		
 OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
WHERE S.is_user_process = 1;

-- Top five queries by total logical IO
SELECT TOP (5)
 (total_logical_reads + total_logical_writes) AS total_logical_IO,
 execution_count, 
 (total_logical_reads/execution_count) AS avg_logical_reads,
 (total_logical_writes/execution_count) AS avg_logical_writes,
 (SELECT SUBSTRING(text, statement_start_offset/2 + 1,
    (CASE WHEN statement_end_offset = -1
          THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
          ELSE statement_end_offset
     END - statement_start_offset)/2)
   FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY (total_logical_reads + total_logical_writes) DESC;
GO


---------------------------------------------------------------------
-- TK 70-461 - Chapter 14 - Using Tools to Analyze Query Performance
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Getting Started with Query Optimization
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Extended Events
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid
ORDER BY C.custid, O.orderid;
GO


---------------------------------------------------------------------
-- Lesson 02 - Using SET Session Options and Analyzing Query Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - SET Session Options and Execution Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Analyzing a Query
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
SELECT N1.n * 100000 + O.orderid AS norderid,
       O.*
INTO dbo.NewOrders
FROM Sales.Orders AS O
 CROSS JOIN (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),
                   (10),(11),(12),(13),(14),(15),(16),
				   (17),(18),(19),(20),(21),(22),(23),
				   (24),(25),(26),(27),(28),(29),(30)) AS N1(n);
GO

-- 5.
CREATE NONCLUSTERED INDEX idx_nc_orderid
 ON dbo.NewOrders(orderid);
GO

-- 6.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 7.
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 8.
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- 9. Turn on the actual execution plan
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 12.
CREATE NONCLUSTERED INDEX idx_nc_norderid
 ON dbo.NewOrders(norderid);
GO

-- 13.
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 14. Turn off execution plan

-- 15. Clean up
DROP TABLE dbo.NewOrders;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Dynamic Management Objects
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Index Related DMOs
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Finding Not Used and Missing Indexes
---------------------------------------------------------------------

-- 1. Restart SQL Server

-- 3.
USE TSQL2012;

-- 4. Not used nonclustered indexes
SELECT OBJECT_NAME(I.object_id) AS objectname,
 I.name AS indexname,
 I.index_id AS indexid
FROM sys.indexes AS I
 INNER JOIN sys.objects AS O
  ON O.object_id = I.object_id
WHERE I.object_id > 100
  AND I.type_desc = 'NONCLUSTERED'
  AND I.index_id NOT IN 
       (SELECT S.index_id 
        FROM sys.dm_db_index_usage_stats AS S
        WHERE S.object_id=I.object_id
          AND I.index_id=S.index_id
          AND database_id = DB_ID('TSQL2012'))
ORDER BY objectname, indexname;

-- 6. Recreation of the table from previous practice 
--    and reproducing the missing index problem
SELECT N1.n * 100000 + O.orderid AS norderid,
       O.*
INTO dbo.NewOrders
FROM Sales.Orders AS O
 CROSS JOIN (VALUES(1),(2),(3)) AS N1(n);
GO
CREATE NONCLUSTERED INDEX idx_nc_orderid
 ON dbo.NewOrders(orderid);
GO
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 7. Missing indexes
SELECT MID.statement AS [Database.Schema.Table],
 MIC.column_id AS ColumnId,
 MIC.column_name AS ColumnName,
 MIC.column_usage AS ColumnUsage, 
 MIGS.user_seeks AS UserSeeks,
 MIGS.user_scans AS UserScans,
 MIGS.last_user_seek AS LastUserSeek,
 MIGS.avg_total_user_cost AS AvgQueryCostReduction,
 MIGS.avg_user_impact AS AvgPctBenefit
FROM sys.dm_db_missing_index_details AS MID
 CROSS APPLY sys.dm_db_missing_index_columns (MID.index_handle) AS MIC
 INNER JOIN sys.dm_db_missing_index_groups AS MIG 
	ON MIG.index_handle = MIG.index_handle
 INNER JOIN sys.dm_db_missing_index_group_stats AS MIGS 
	ON MIG.index_group_handle=MIGS.group_handle
ORDER BY MIGS.avg_user_impact DESC;
GO																																																												

-- 14. Clean up
DROP TABLE dbo.NewOrders;
GO
