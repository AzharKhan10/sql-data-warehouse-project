/*
======================================================================================
Stores Procedure: Load Silver Layer (Bronze -> silver)
======================================================================================
Scripts Purpose: 
  This Scritps will performk ETL Process to populate the silver 'Schema' tables from 
  'bronze' schema.
----------------------------------------
Acrions perform:
  -Truncate Silver tables.
  - Insert cleanseed and transformed data from bronze to silver tables.
Parameters : No Parameters, Return value
----------------------------------------
Usage Example:
  EXEC silver.load_silver';
=========================================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME,
		@start_process_time DATETIME, @end_process_time DATETIME;
	BEGIN TRY 
		-- ========================================================================================
		--  CRM bronze.crm_cust_info --> silver.crm_cust_info
		-- ========================================================================================
	
		PRINT '==========================================================================';
		PRINT 'Loading silver layer';
		PRINT '==========================================================================';

		PRINT '--------------------------------------------------------------------------';
		PRINT 'loading crm tables';
		PRINT '--------------------------------------------------------------------------';


		PRINT 'Truncating table: silver.crm_cust_info'
		SET @start_process_time = GETDATE();
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_cust_info
		PRINT 'Transforming And INSERTING Data:'
		PRINT '>> bronze.crm_cust_info --> silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
		SELECT 
			  cst_id,
			  cst_key,
			  COALESCE(TRIM(cst_firstname), 'n/a') cst_firstname,
			  COALESCE(TRIM(cst_lastname), 'n/a') cst_lastname,
			  CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				   WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				   ELSE 'n/a' 
			  END AS cst_marital_status,
			  CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				   WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
			  ELSE 'n/a ' 
			  END cst_gndr,
			  cst_create_date
			FROM (SELECT 
			*,
			ROW_NUMBER() OVER(PARTITION BY cst_id order by cst_create_date desc) flag
			FROM bronze.crm_cust_info
		)t WHERE flag = 1

		SET @end_time = GETDATE();
	
		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------'
		-- ========================================================================================
		--  CRM bronze.crm_prd_info --> silver.crm_prd_info
		-- ========================================================================================
		PRINT 'Truncating table: silver.crm_prd_info'

		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_prd_info
		PRINT 'Transforming And Inserting Data:'
		PRINT '>> bronze.crm_prd_info --> silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE  UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'  
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring' 
				ELSE 'n/a'
			 END AS prd_line,
			 CAST(prd_start_dt AS DATE) prd_start_dt,
			 CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();

		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------';
		-- ========================================================================================
		--  CRM bronze.crm_sales_details --> silver.crm_sales_details
		-- ========================================================================================

		SET @start_time = GETDATE();
		PRINT 'Truncate table: silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details
		PRINT 'Transforming And Inserting Data:'
		PRINT 'bronze.crm_sales_details --> silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details (
			sls_ord_num, 
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,  
			sls_sales, 
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN LEN(sls_order_dt) != 8 THEN NULL 
				 ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE) 
			END AS sls_order_dt,

			CASE WHEN LEN(sls_ship_dt) != 8 THEN NULL 
				 ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE) 
			END AS sls_ship_dt,

			CASE WHEN LEN(sls_due_dt) != 8 THEN NULL 
				 ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE) 
			END AS sls_due_dt,

			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price) 
				ELSE  sls_sales 
			END AS sls_sales,

			sls_quantity,

			CASE WHEN sls_price <= 0 OR  sls_sales is null 
				 THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE sls_price
			END AS sls_price

		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------';
		-- ========================================================================================
		--  ERP bronze.erp_cust_az12 --> silver.erp_cust_az12
		-- ========================================================================================

		PRINT '--------------------------------------------------------------------------';
		PRINT 'loading erp tables';
		PRINT '--------------------------------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT 'Transforming And Inserting Data:'
		PRINT '>> bronze.erp_cust_az12 --> silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
			ELSE cid 
		END cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')  THEN 'Male'
			 WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			 WHEN gen IS NULL OR TRIM(gen) = '' THEN 'n/a'
			 ELSE gen
		END AS gen
		FROM bronze.erp_cust_az12
		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------';
		-- ========================================================================================
		--  ERP bronze.erp_loc_a101 --> silver.erp_loc_a101
		-- ========================================================================================

		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT 'Transforming And Inserting Data:"'
		PRINT '>> bronze.erp_loc_a101 --> silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101(cid, cntry)
		SELECT 
		REPLACE(TRIM(cid), '-', '') cid,

		CASE WHEN cntry IN ('USA', 'US') THEN 'United States'
			 WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
			 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 ELSE TRIM(cntry)
		END AS cntry

		FROM bronze.erp_loc_a101

		SET @end_time = GETDATE();
		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------';
		-- ========================================================================================
		--  ERP bronze.erp_px_cat_g1v2 --> silver.erp_px_cat_g1v2
		-- ========================================================================================

		SET @start_time = GETDATE();
		PRINT 'Truncating table: erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT 'Transforming And Inserting Data:'
		PRINT '>> bronze.erp_px_cat_g1v2 --> silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT 'total duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT '----------------------------------';
		PRINT 'Total batch time: ' + CAST(DATEDIFF(SECOND, @start_process_time, @end_process_time) AS NVARCHAR);

	END TRY 
	BEGIN CATCH
		PRINT '====================================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
	END CATCH
END 
