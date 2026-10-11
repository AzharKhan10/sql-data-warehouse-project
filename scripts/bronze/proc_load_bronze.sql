/*
======================================================================================
Stored procedure:- Load Bronze Layer(Source -> Bronze)
======================================================================================
Purpose of the Script:- 
  This stored procedure load the data  from external source  Csv file to bronze schema.
  It will perform 2 actitions:- 
    It will first delete(truncate) all the data from tables before loading the data.
    then It will load they data using BULK INSERT command.

Usage Example.:-
  EXEC bronze.load_bronze;
=====================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze	AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME ;
	BEGIN TRY 
		PRINT '==========================================================================';
		PRINT 'Loading bronze layer';
		PRINT '==========================================================================';

		PRINT '--------------------------------------------------------------------------';
		PRINT 'loading crm tables';
		PRINT '--------------------------------------------------------------------------';

		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> inserting table: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE(); 
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
		PRINT '--------------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> inserting table: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		from 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
		PRINT '--------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> inserting table: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		from 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration:' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
		PRINT '---------------------';
		-- ===============================================================
		-- ERP DATA SOURCE
		-- ===============================================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> inserting table: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> LOAD DURATION:' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
		PRINT '------------------';
		-- ==============================================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT '>> inserting table: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		from 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '----------------------------';
		-- ==============================================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT '>> inserting table: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		from 'D:\SQL\sql_course_data\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '----------------------------';
		SET @batch_end_time = GETDATE();
		PRINT 'batch loading diration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'Seconds';
	END TRY 

	BEGIN CATCH
		PRINT '====================================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
	END CATCH
END
