/*
====================================================================================
DDL Scripts: create Silver Tables
====================================================================================
Scripts Purpose:
  This scripts creates tables in the 'silver' schema. if the table already exists it will
Drop it first then recreate.
====================================================================================
*/
if OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info 
GO
CREATE TABLE silver.crm_cust_info (
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

Go
if OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info
CREATE TABLE silver.crm_prd_info(
	prd_id INT,
	cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

GO
if OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details
GO
CREATE TABLE silver.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt  DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
if OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_az12
CREATE TABLE silver.erp_cust_az12(
	cid	  NVARCHAR(50),
	bdate DATE,
	gen   NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
if OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE silver.erp_loc_a101
GO
CREATE TABLE silver.erp_loc_a101(
	cid	  NVARCHAR(50),
	cntry NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2
GO
CREATE TABLE silver.erp_px_cat_g1v2(
	id			NVARCHAR(50),
	cat			NVARCHAR(50),
	subcat		NVARCHAR(50),
	maintenance NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);



-- TRANSFORM bronze.crm_sales_details

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
