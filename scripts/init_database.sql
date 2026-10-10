/*

=============================================
Create Database and schemas
=============================================

Script purpose:
	This script will create new database 'DataWarehouse' After checking if it already exists.
	if the database already exists, then it will be dropped and recreated. 
	Additionally the script sets up three schemas within the database: 'Bronze', 'Silver' and  'Gold'.

WARNING:
	Running the script will drop the entire 'DataWarehouse' database if it exists.	
	All data in database will be permanently deleted. Proceed with caution 
	and ensure you have proper backups before running the scripts.

*/
USE master;
go

-- Drop and recreate the 'DataWarehouse' database
if Exists (SELECT 1 FROM  sys.databases WHERE name = 'DataWarehouse')
BEGIN 
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

-- Create 'DataWarehouse' database
CREATE DATABASE DataWarehouse;

use DataWarehouse;
go

-- Create Schemas
CREATE SCHEMA bronze;
go
CREATE SCHEMA silver;
go
CREATE SCHEMA gold;
go
