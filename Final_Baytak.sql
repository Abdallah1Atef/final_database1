USE Baytak;
GO


--SELECT * FROM sys.foreign_keys;
-- Should return 0 rows


-- Step 1: Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' +
               QUOTENAME(OBJECT_NAME(parent_object_id)) +
               ' DROP CONSTRAINT ' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.foreign_keys;

EXEC sp_executesql @sql;

-- Step 2: Drop all tables (dynamically)
SET @sql = N'';

SELECT @sql += 'DROP TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' +
               QUOTENAME(name) + ';' + CHAR(13)
FROM sys.tables;

EXEC sp_executesql @sql;




-- Step 3: Create tables with their respective columns, primary keys, and foreign keys
CREATE TABLE LOCATION (
    location_id INT PRIMARY KEY,
    city VARCHAR(255),
    region VARCHAR(255),
    zip_code VARCHAR(255)
);

CREATE TABLE CHANNEL (
    channel_id INT PRIMARY KEY,
    channal_type VARCHAR(255)
);

CREATE TABLE MARKETING (
    campaign_id INT PRIMARY KEY,
    campaign_start_date DATE,
    campaign_end_date DATE,
    campgain_cost INT
);

CREATE TABLE MARKETING_CHANNEL (
    marketing_channel_id INT PRIMARY KEY,
    channel_id INT NOT NULL FOREIGN KEY REFERENCES CHANNEL(channel_id),
    campaign_Id INT NOT NULL FOREIGN KEY REFERENCES MARKETING(campaign_id),
    channel_cost INT
);

CREATE TABLE CUSTOMER (
    customer_id INT PRIMARY KEY,
    location_id INT NOT NULL FOREIGN KEY REFERENCES LOCATION(location_id),
    marketing_channel_id INT FOREIGN KEY REFERENCES MARKETING_CHANNEL(marketing_channel_id),
    age INT,
    gender VARCHAR(255),
    Phone VARCHAR(255),
    register_date DATE
);

CREATE TABLE SUPPLIERS (
    supplier_id INT PRIMARY KEY,
    location_id INT NOT NULL FOREIGN KEY REFERENCES LOCATION(location_id),
    supplier_name VARCHAR(255),
    phone VARCHAR(255)
);

CREATE TABLE PRODUCT (
    product_id INT PRIMARY KEY,
    category VARCHAR(255),
    product_name VARCHAR(255),
    start_date DATE,
    Unit_price DECIMAL(18,2),
    Unit_cost DECIMAL(18,2)
);

CREATE TABLE PRODUCT_SUPPLIER (
    product_supplier_id INT PRIMARY KEY,
    supplier_id INT NOT NULL FOREIGN KEY REFERENCES SUPPLIERS(supplier_id),
    product_id INT NOT NULL FOREIGN KEY REFERENCES PRODUCT(product_id)
);

CREATE TABLE DESIGN (
    design_id INT PRIMARY KEY,
    material VARCHAR(255),
    style VARCHAR(255),
    color VARCHAR(255)
);

CREATE TABLE DISCOUNT (
    discount_id INT PRIMARY KEY,
    product_id INT NOT NULL FOREIGN KEY REFERENCES PRODUCT(product_id),
    discount_start_date DATE,
    discount_end_date DATE,
    discount_precentage DECIMAL(5,2)
);

CREATE TABLE BRANCHES (
    branch_id INT PRIMARY KEY,
    branch_name varchar(255),
    location_id INT NOT NULL FOREIGN KEY REFERENCES LOCATION(location_id),
    opening_date DATE
);

CREATE TABLE [ORDER] ( -- [ORDER] is used as ORDER is a reserved keyword
    order_id INT PRIMARY KEY,
    branch_id INT NOT NULL FOREIGN KEY REFERENCES BRANCHES(branch_id),
    customer_id INT NOT NULL FOREIGN KEY REFERENCES CUSTOMER(customer_id),
    order_date DATETIME,
    payment_method VARCHAR(255)
);

CREATE TABLE ORDER_LINE (
    order_line_id INT PRIMARY KEY,
	order_id INT NOT NULL FOREIGN KEY REFERENCES [ORDER](order_id),
    product_supplier_id INT NOT NULL FOREIGN KEY REFERENCES PRODUCT_SUPPLIER(product_supplier_id),
    design_id INT FOREIGN KEY REFERENCES DESIGN(design_id),
	quantity INT,
	discount_id INT FOREIGN KEY REFERENCES DISCOUNT(discount_id)
);

CREATE TABLE DELIVERY (
    order_id INT PRIMARY KEY FOREIGN KEY REFERENCES [ORDER](order_id),
    sechedul_deliver_date DATE,
    Deliver_Date DATE
);

CREATE TABLE RETURN_REASON (
    reason_id INT PRIMARY KEY,
    reason_detail VARCHAR(255)
);

CREATE TABLE RETURN1 ( -- Using RETURN1 to avoid conflict with reserved keyword RETURN
    return_id INT PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES [ORDER](order_id),
	return_date DATE,
    reason_id INT NOT NULL FOREIGN KEY REFERENCES RETURN_REASON(reason_id)
);

CREATE TABLE REVIEW (
    order_line_id INT PRIMARY KEY FOREIGN KEY REFERENCES ORDER_LINE(order_line_id),
    delivery_rating DECIMAL(3,2),
    branch_rating DECIMAL(3,2),
    product_rating DECIMAL(3,2),
    customer_service_rating DECIMAL(3,2),
    review_date DATE
);

CREATE TABLE LEADS (
    lead_id INT PRIMARY KEY,
    phone VARCHAR(255),
    gender VARCHAR(255),
    date DATE
);

CREATE TABLE BRANCH_VISITS_LOG (
    visit_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES CUSTOMER(customer_id),
    lead_id INT FOREIGN KEY REFERENCES LEADS(lead_id),
    branch_id INT NOT NULL FOREIGN KEY REFERENCES BRANCHES(branch_id),
    visit_date DATE,
    entring_time TIME,
    leaving_time TIME,
    purchased BIT
);
GO


--===================================================================================================
-- Step 4: Bulk insert data directly into main tables
-- The order of inserts is crucial to satisfy foreign key constraints.
-- Assumes all CSV files are located at 'D:\FCDS\semester 6\Jdara\database\'
-- Note: Direct BULK INSERT relies on exact data type matching in CSV.
-- Errors (Msg 4864) will occur if data format doesn't match column type.

-- Temporarily disable all foreign key constraints before data insertion
-- This allows data to be loaded even if some foreign key references are not yet valid.
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL";
GO

-- Level 0: Tables with no foreign key dependencies (User-specified order)
-- ======================================
-- Table: 14_location.csv → LOCATION
-- ======================================
BULK INSERT LOCATION
FROM 'D:\FCDS\semester 6\Jdara\database\14_location.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a', -- Standard Windows-style line ending
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 5_leads.csv → LEADS
-- ======================================
BULK INSERT LEADS
FROM 'D:\FCDS\semester 6\Jdara\database\5_leads.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 13_return_reasons.csv → RETURN_REASON
-- ======================================
BULK INSERT RETURN_REASON
FROM 'D:\FCDS\semester 6\Jdara\database\13_return_reasons.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 15_Marketing_table.csv → MARKETING
-- ======================================
INSERT INTO MARKETING (campaign_id, campaign_start_date, campaign_end_date, campgain_cost)
VALUES
(101, CONVERT(DATE, '1/1/2024', 101), CONVERT(DATE, '4/1/2024', 101), REPLACE('60,000', ',', '')),
(102, CONVERT(DATE, '4/10/2024', 101), CONVERT(DATE, '7/10/2024', 101), REPLACE('90,000', ',', '')),
(103, CONVERT(DATE, '7/20/2024', 101), CONVERT(DATE, '10/20/2024', 101), REPLACE('120,000', ',', '')),
(104, CONVERT(DATE, '10/25/2024', 101), CONVERT(DATE, '1/1/2025', 101), REPLACE('150,000', ',', '')),
(105, CONVERT(DATE, '1/15/2025', 101), CONVERT(DATE, '4/15/2025', 101), REPLACE('180,000', ',', '')),
(106, CONVERT(DATE, '4/25/2025', 101), CONVERT(DATE, '7/25/2025', 101), REPLACE('210,000', ',', '')),
(107, CONVERT(DATE, '7/30/2025', 101), CONVERT(DATE, '8/30/2025', 101), REPLACE('240,000', ',', ''));
GO


-- ======================================
-- Table: 16_Channel_table 2.csv → CHANNEL
-- ======================================
BULK INSERT CHANNEL
FROM 'D:\FCDS\semester 6\Jdara\database\16_Channel_table 2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 06_product_table.csv → PRODUCT
-- ======================================
INSERT INTO PRODUCT (product_id, category, product_name, start_date, Unit_price, Unit_cost)
VALUES
(1, 'Office', 'Office chair', CONVERT(DATE, '16/02/2021', 103), 11900, 7000),
(2, 'Rugs', 'Large rug', CONVERT(DATE, '16/02/2021', 103), 25500, 15000),
(3, 'Bedroom', 'Bed sheets', CONVERT(DATE, '16/02/2021', 103), 39100, 23000),
(4, 'Decor', 'Wall clock', CONVERT(DATE, '16/02/2021', 103), 1360, 800),
(5, 'Lighting', 'Wall lamp', CONVERT(DATE, '16/02/2021', 103), 1700, 1000),
(6, 'Living Room', 'Recliner', CONVERT(DATE, '16/02/2021', 103), 51000, 30000),
(7, 'Outdoor', 'Sun lounger', CONVERT(DATE, '16/02/2021', 103), 17000, 10000),
(8, 'Living Room', 'Sectional sofa', CONVERT(DATE, '16/02/2021', 103), 30600, 18000),
(9, 'Office', 'Desk', CONVERT(DATE, '16/02/2021', 103), 34000, 20000),
(10, 'Dining', 'Dining bench', CONVERT(DATE, '16/02/2021', 103), 68000, 40000),
(11, 'Bedroom', 'Pillow', CONVERT(DATE, '16/02/2021', 103), 629, 370),
(12, 'Rugs', 'Runner rug', CONVERT(DATE, '16/02/2021', 103), 37400, 22000),
(13, 'Living Room', 'Side table', CONVERT(DATE, '16/02/2021', 103), 5100, 3000),
(14, 'Decor', 'Decorative mirror', CONVERT(DATE, '16/02/2021', 103), 7310, 4300),
(15, 'Bedroom', 'Bedroom Sets', CONVERT(DATE, '16/02/2021', 103), 306000, 180000),
(16, 'Lighting', 'Decorative light', CONVERT(DATE, '16/02/2021', 103), 5440, 3200),
(17, 'Storage', 'Shelving unit', CONVERT(DATE, '16/02/2021', 103), 10200, 6000),
(18, 'Lighting', 'Hanging lamp', CONVERT(DATE, '16/02/2021', 103), 1292, 760),
(19, 'Storage', 'Storage cabinet', CONVERT(DATE, '16/02/2021', 103), 102000, 60000),
(20, 'Decor', 'Table clock', CONVERT(DATE, '16/02/2021', 103), 680, 400),
(21, 'Outdoor', 'Patio chair', CONVERT(DATE, '16/02/2021', 103), 6800, 4000),
(22, 'Decor', 'Clock', CONVERT(DATE, '16/02/2021', 103), 612, 360),
(23, 'Decor', 'Accent table', CONVERT(DATE, '16/02/2021', 103), 11900, 7000),
(24, 'Bedroom', 'Quilt', CONVERT(DATE, '16/02/2021', 103), 5100, 3000),
(25, 'Bedroom', 'Kids wardrobe', CONVERT(DATE, '16/02/2021', 103), 13600, 8000),
(26, 'Rugs', 'Medium rug', CONVERT(DATE, '16/02/2021', 103), 17000, 10000),
(27, 'Rugs', 'Small rug', CONVERT(DATE, '16/02/2021', 103), 14620, 8600),
(28, 'Outdoor', 'Garden bench', CONVERT(DATE, '16/02/2021', 103), 5100, 3000),
(29, 'Lighting', 'Table lamp', CONVERT(DATE, '16/02/2021', 103), 595, 350),
(30, 'Dining', 'Crockery unit', CONVERT(DATE, '16/02/2021', 103), 102000, 60000),
(31, 'Outdoor', 'Outdoor sofa', CONVERT(DATE, '16/02/2021', 103), 51000, 30000),
(32, 'Bedroom', 'Kids bed ', CONVERT(DATE, '16/02/2021', 103), 42500, 25000),
(33, 'Dining', 'Dining set (4-seater)', CONVERT(DATE, '16/02/2021', 103), 102000, 60000),
(34, 'Decor', 'Pouf', CONVERT(DATE, '16/02/2021', 103), 6800, 4000),
(35, 'Bedroom', 'King bed', CONVERT(DATE, '16/02/2021', 103), 25500, 15000),
(36, 'Outdoor', 'Patio table', CONVERT(DATE, '16/02/2021', 103), 20400, 12000),
(37, 'Living Room', 'TV stand', CONVERT(DATE, '16/02/2021', 103), 17000, 10000),
(38, 'Bedroom', 'Bedside table', CONVERT(DATE, '16/02/2021', 103), 5950, 3500),
(39, 'Living Room', 'Loveseat', CONVERT(DATE, '16/02/2021', 103), 11900, 7000),
(40, 'Dining', 'Sideboard', CONVERT(DATE, '16/02/2021', 103), 3400, 2000),
(41, 'Decor', 'Accent chair', CONVERT(DATE, '16/02/2021', 103), 5100, 3000),
(42, 'Bedroom', 'Chest of drawers', CONVERT(DATE, '16/02/2021', 103), 8500, 5000),
(43, 'Office', 'File cabinet', CONVERT(DATE, '16/02/2021', 103), 23800, 14000),
(44, 'Living Room', 'Coffee table', CONVERT(DATE, '16/02/2021', 103), 42500, 25000),
(45, 'Dining', 'Dining set (8-seater)', CONVERT(DATE, '16/02/2021', 103), 1700000, 1000000),
(46, 'Bedroom', 'Coverlet', CONVERT(DATE, '16/02/2021', 103), 2550, 1500),
(47, 'Storage', 'Storage Furniture', CONVERT(DATE, '16/02/2021', 103), 34000, 20000),
(48, 'Decor', 'Sand clock', CONVERT(DATE, '16/02/2021', 103), 1020, 600),
(49, 'Bedroom', 'Queen bed', CONVERT(DATE, '16/02/2021', 103), 23800, 14000),
(50, 'Bedroom', 'Twin bed', CONVERT(DATE, '16/02/2021', 103), 17000, 10000),
(51, 'Bedroom', 'Bunk bed', CONVERT(DATE, '16/02/2021', 103), 17000, 10000),
(52, 'Bedroom', 'Storage bed', CONVERT(DATE, '16/02/2021', 103), 13600, 8000),
(53, 'Bedroom', 'Canopy bed', CONVERT(DATE, '16/02/2021', 103), 13600, 8000),
(54, 'Bedroom', 'Dresser', CONVERT(DATE, '16/02/2021', 103), 28900, 17000),
(55, 'Bedroom', 'Nightstand', CONVERT(DATE, '16/02/2021', 103), 8500, 5000),
(56, 'Bedroom', 'Wardrobe', CONVERT(DATE, '16/02/2021', 103), 42500, 25000),
(57, 'Bedroom', 'Armoire', CONVERT(DATE, '16/02/2021', 103), 20400, 12000),
(58, 'Decor', 'Coat rack', CONVERT(DATE, '16/02/2021', 103), 10200, 6000),
(59, 'Bedroom', 'Kids chaire', CONVERT(DATE, '16/02/2021', 103), 8500, 5000),
(60, 'Bedroom', 'Crib', CONVERT(DATE, '16/02/2021', 103), 7650, 4500),
(61, 'Storage', 'Kids Cainet', CONVERT(DATE, '16/02/2021', 103), 10200, 6000),
(62, 'Bedroom', 'Comforter set', CONVERT(DATE, '16/02/2021', 103), 59500, 35000),
(63, 'Bedroom', 'Blanket', CONVERT(DATE, '16/02/2021', 103), 8500, 5000),
(64, 'Bedroom', 'Throw', CONVERT(DATE, '16/02/2021', 103), 5950, 3500),
(65, 'Bedroom', 'Pillowcase', CONVERT(DATE, '16/02/2021', 103), 204, 120),
(66, 'Bedroom', 'Mattress protector', CONVERT(DATE, '16/02/2021', 103), 425, 250),
(67, 'Rugs', 'Round rug', CONVERT(DATE, '16/02/2021', 103), 42500, 25000),
(68, 'Lighting', 'Floor lamp', CONVERT(DATE, '16/02/2021', 103), 1190, 700),
(69, 'Decor', 'Photo frame', CONVERT(DATE, '16/02/2021', 103), 510, 300),
(70, 'Decor', 'Poster', CONVERT(DATE, '16/02/2021', 103), 1360, 800),
(71, 'Decor', 'Wall art', CONVERT(DATE, '16/02/2021', 103), 2550, 1500),
(72, 'Decor', 'Framed artwork', CONVERT(DATE, '16/02/2021', 103), 2890, 1700),
(73, 'Dining', 'Dining chair', CONVERT(DATE, '16/02/2021', 103), 6800, 4000),
(74, 'Dining', 'Buffet', CONVERT(DATE, '16/02/2021', 103), 10200, 6000),
(75, 'Living Room', 'Armchair', CONVERT(DATE, '16/02/2021', 103), 5440, 3200),
(76, 'Office', 'Bookcase', CONVERT(DATE, '16/02/2021', 103), 34000, 20000),
(77, 'Living Room', 'Console table', CONVERT(DATE, '16/02/2021', 103), 22100, 13000);
GO

-- ======================================
-- Table: 09_design_table.csv → DESIGN
-- ======================================
BULK INSERT DESIGN
FROM 'D:\FCDS\semester 6\Jdara\database\09_design_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- Level 1: Tables depending on Level 0 tables (User-specified order)
-- ======================================
-- Table: 01_suppliers.csv → SUPPLIERS
-- Depends on LOCATION
-- ======================================
INSERT INTO SUPPLIERS (supplier_id, location_id, supplier_name, phone)
VALUES
(10, 1, 'NileWood', '1038427654'),
(20, 9, 'DeltaCraft', '1267583941'),
(30, 10, 'al-sharq', '1149832760');
GO
--BULK INSERT SUPPLIERS
--FROM 'D:\FCDS\semester 6\Jdara\database\01_suppliers.csv'
--WITH (
--    FIRSTROW = 2,
--    FIELDTERMINATOR = ',',
--    ROWTERMINATOR = '0x0d0a',
--    CODEPAGE = '65001',
--    DATAFILETYPE = 'char',
--    TABLOCK
--);
--GO

-- ======================================
-- Table: 17_Marketing_channel table 2.csv → MARKETING_CHANNEL
-- Depends on CHANNEL, MARKETING
-- ======================================
BULK INSERT MARKETING_CHANNEL
FROM 'D:\FCDS\semester 6\Jdara\database\17_Marketing_channel table 2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 02_branches.csv → BRANCHES
-- Depends on LOCATION
-- ======================================
INSERT INTO BRANCHES (branch_id, branch_name, location_id, opening_date)
VALUES
(100,'SmouhaCenter', 2, CONVERT(DATE, '15/2/2021', 103)),
(200, 'San StefanoCenter', 5, CONVERT(DATE, '23/6/2022', 103)),
(300, 'LaurentCenter',8, CONVERT(DATE, '3/9/2023', 103));
GO


-- ======================================
-- Table: 001_product_supplier_table.csv → PRODUCT_SUPPLIER
-- Depends on SUPPLIERS, PRODUCT
-- ======================================
BULK INSERT PRODUCT_SUPPLIER
FROM 'D:\FCDS\semester 6\Jdara\database\001_product_supplier_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 10_discount_table.csv → DISCOUNT
-- Depends on PRODUCT
-- ======================================
BULK INSERT DISCOUNT
FROM 'D:\FCDS\semester 6\Jdara\database\10_discount_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO


-- Level 2: Tables depending on Level 0 and 1 tables (User-specified order)
-- ======================================
-- Table: 04_customer_table.csv → CUSTOMER
-- Depends on LOCATION, MARKETING_CHANNEL
-- ======================================
BULK INSERT CUSTOMER
FROM 'D:\FCDS\semester 6\Jdara\database\04_customer_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- Level 3: Tables depending on Level 0, 1, and 2 tables (User-specified order)
-- ======================================
-- Table: 07_order_table.csv → [ORDER]
-- Depends on BRANCHES, CUSTOMER
-- ======================================
BULK INSERT [ORDER]
FROM 'D:\FCDS\semester 6\Jdara\database\07_order_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 03_branch_visit_log.csv → BRANCH_VISITS_LOG
-- Depends on CUSTOMER, LEADS, BRANCHES
-- ======================================

CREATE TABLE BRANCH_VISITS_LOG_Staging (
    visit_id_str VARCHAR(50),
    customer_id_str VARCHAR(50),
    lead_id_str VARCHAR(50),
    branch_id_str VARCHAR(50),
    visit_date_str VARCHAR(50),
    entring_time_str VARCHAR(50), -- Changed to VARCHAR to handle any format
    leaving_time_str VARCHAR(50), -- Changed to VARCHAR to handle any format
    purchased_str VARCHAR(50)
);
TRUNCATE TABLE BRANCH_VISITS_LOG_Staging;
BULK INSERT BRANCH_VISITS_LOG_Staging
FROM 'D:\FCDS\semester 6\Jdara\database\03_branch_visit_log.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK,
    ERRORFILE = 'D:\FCDS\semester 6\Jdara\database\errors\branch_visits_log_bulk_error.csv'
);
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
-- Step 1: Create temp table
CREATE TABLE #BranchVisitsTemp (
    visit_id_str VARCHAR(50),
    customer_id_str VARCHAR(50),
    lead_id_str VARCHAR(50),
    branch_id_str VARCHAR(50),
    visit_date_str VARCHAR(50),
    entring_time_str VARCHAR(50),
    leaving_time_str VARCHAR(50),
    purchased_str VARCHAR(50)
);

-- Step 2: Bulk insert into temp table

BULK INSERT #BranchVisitsTemp
FROM 'D:\FCDS\semester 6\Jdara\database\03_branch_visit_log.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char'
);

-- Step 3: Insert into your main table directly from temp
INSERT INTO BRANCH_VISITS_LOG (
    visit_id, customer_id, lead_id, branch_id,
    visit_date, entring_time, leaving_time, purchased
)
SELECT
    TRY_CONVERT(INT, visit_id_str),
    TRY_CONVERT(INT, customer_id_str),
    TRY_CONVERT(INT, lead_id_str),
    TRY_CONVERT(INT, branch_id_str),
    TRY_CONVERT(DATE, visit_date_str, 101),
    TRY_CONVERT(TIME, entring_time_str),
    TRY_CONVERT(TIME, leaving_time_str),
    CASE
        WHEN purchased_str IN ('1', 'TRUE', 'true', 'yes', 'Yes') THEN 1
        WHEN purchased_str IN ('0', 'FALSE', 'false', 'no', 'No') THEN 0
        ELSE NULL
    END
FROM #BranchVisitsTemp bv
WHERE
    TRY_CONVERT(INT, visit_id_str) IS NOT NULL
    AND TRY_CONVERT(INT, branch_id_str) IS NOT NULL
    AND TRY_CONVERT(DATE, visit_date_str, 101) IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM BRANCHES b
        WHERE b.branch_id = TRY_CONVERT(INT, bv.branch_id_str)
    )
    AND (
        TRY_CONVERT(INT, bv.customer_id_str) IS NULL
        OR EXISTS (
            SELECT 1 FROM CUSTOMER c
            WHERE c.customer_id = TRY_CONVERT(INT, bv.customer_id_str)
        )
    )
    AND (
        TRY_CONVERT(INT, bv.lead_id_str) IS NULL
        OR EXISTS (
            SELECT 1 FROM LEADS l
            WHERE l.lead_id = TRY_CONVERT(INT, bv.lead_id_str)
        )
    );

-- Step 4: Drop temp table
DROP TABLE #BranchVisitsTemp;


-- Level 4: Tables depending on Level 0, 1, 2, and 3 tables (User-specified order)
-- ======================================
-- Table: 18_delivery_table.csv → DELIVERY
-- Depends on [ORDER]
-- ======================================
BULK INSERT DELIVERY
FROM 'D:\FCDS\semester 6\Jdara\database\18_delivery_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- ======================================
-- Table: 12_return_table.csv → RETURN1
-- Depends on [ORDER], RETURN_REASON
-- ======================================

INSERT INTO RETURN1 (return_id, order_id, return_date, reason_id)
VALUES
(1, 6656, CONVERT(DATE, '9/12/2024', 101), 4),
(2, 8704, CONVERT(DATE, '2/8/2025', 101), 4),
(3, 9216, CONVERT(DATE, '4/6/2025', 101), 4),
(4, 6150, CONVERT(DATE, '7/26/2024', 101), 4),
(5, 5640, CONVERT(DATE, '6/13/2024', 101), 4),
(6, 14, CONVERT(DATE, '3/27/2021', 101), 4),
(7, 7185, CONVERT(DATE, '10/16/2024', 101), 4),
(8, 2581, CONVERT(DATE, '1/7/2023', 101), 4),
(9, 5673, CONVERT(DATE, '6/13/2024', 101), 4),
(10, 9258, CONVERT(DATE, '3/31/2025', 101), 4),
(11, 1581, CONVERT(DATE, '8/28/2022', 101), 4),
(12, 2609, CONVERT(DATE, '1/11/2023', 101), 4),
(13, 3122, CONVERT(DATE, '3/30/2023', 101), 4),
(14, 4153, CONVERT(DATE, '2/2/2024', 101), 4),
(15, 4673, CONVERT(DATE, '3/14/2024', 101), 4),
(16, 2116, CONVERT(DATE, '11/5/2022', 101), 4),
(17, 6733, CONVERT(DATE, '9/14/2024', 101), 4),
(18, 1102, CONVERT(DATE, '3/19/2022', 101), 4),
(19, 4692, CONVERT(DATE, '3/12/2024', 101), 4),
(20, 7259, CONVERT(DATE, '10/17/2024', 101), 4),
(21, 1128, CONVERT(DATE, '4/17/2022', 101), 4),
(22, 8810, CONVERT(DATE, '2/16/2025', 101), 4),
(23, 620, CONVERT(DATE, '10/25/2021', 101), 4),
(24, 4210, CONVERT(DATE, '1/31/2024', 101), 4),
(25, 629, CONVERT(DATE, '10/20/2021', 101), 4),
(26, 118, CONVERT(DATE, '4/22/2021', 101), 4),
(27, 3201, CONVERT(DATE, '4/30/2023', 101), 4),
(28, 5253, CONVERT(DATE, '5/20/2024', 101), 4),
(29, 4231, CONVERT(DATE, '2/11/2024', 101), 4),
(30, 5768, CONVERT(DATE, '7/4/2024', 101), 4),
(31, 2704, CONVERT(DATE, '1/27/2023', 101), 4),
(32, 1681, CONVERT(DATE, '9/19/2022', 101), 4),
(33, 1684, CONVERT(DATE, '9/18/2022', 101), 4),
(34, 4756, CONVERT(DATE, '4/22/2024', 101), 4),
(35, 9877, CONVERT(DATE, '8/14/2025', 101), 4),
(36, 671, CONVERT(DATE, '11/9/2021', 101), 4),
(37, 7331, CONVERT(DATE, '11/2/2024', 101), 4),
(38, 2729, CONVERT(DATE, '1/19/2023', 101), 4),
(39, 5809, CONVERT(DATE, '6/17/2024', 101), 4),
(40, 2738, CONVERT(DATE, '1/27/2023', 101), 4),
(41, 2229, CONVERT(DATE, '11/18/2022', 101), 4),
(42, 3765, CONVERT(DATE, '10/25/2023', 101), 4),
(43, 2234, CONVERT(DATE, '11/19/2022', 101), 4),
(44, 4796, CONVERT(DATE, '3/20/2024', 101), 4),
(45, 4806, CONVERT(DATE, '3/30/2024', 101), 4),
(46, 2759, CONVERT(DATE, '2/11/2023', 101), 4),
(47, 9949, CONVERT(DATE, '8/22/2025', 101), 4),
(48, 1246, CONVERT(DATE, '7/27/2022', 101), 4),
(49, 6369, CONVERT(DATE, '8/7/2024', 101), 4),
(50, 739, CONVERT(DATE, '11/27/2021', 101), 4),
(51, 8936, CONVERT(DATE, '3/7/2025', 101), 4),
(52, 4848, CONVERT(DATE, '4/2/2024', 101), 4),
(53, 6390, CONVERT(DATE, '8/11/2024', 101), 4),
(54, 9464, CONVERT(DATE, '4/30/2025', 101), 4),
(55, 763, CONVERT(DATE, '12/4/2021', 101), 4),
(56, 764, CONVERT(DATE, '12/2/2021', 101), 4),
(57, 4349, CONVERT(DATE, '2/18/2024', 101), 4),
(58, 7425, CONVERT(DATE, '11/10/2024', 101), 4),
(59, 2819, CONVERT(DATE, '2/23/2023', 101), 4),
(60, 1806, CONVERT(DATE, '10/21/2022', 101), 4),
(61, 4878, CONVERT(DATE, '4/5/2024', 101), 4),
(62, 4881, CONVERT(DATE, '4/5/2024', 101), 4),
(63, 7953, CONVERT(DATE, '12/14/2024', 101), 4),
(64, 6419, CONVERT(DATE, '8/21/2024', 101), 4),
(65, 7443, CONVERT(DATE, '11/3/2024', 101), 4),
(66, 9494, CONVERT(DATE, '5/11/2025', 101), 4),
(67, 3351, CONVERT(DATE, '7/13/2023', 101), 4),
(68, 8986, CONVERT(DATE, '3/2/2025', 101), 4),
(69, 1832, CONVERT(DATE, '10/2/2022', 101), 4),
(70, 3370, CONVERT(DATE, '7/17/2023', 101), 4),
(71, 5934, CONVERT(DATE, '7/27/2024', 101), 4),
(72, 5425, CONVERT(DATE, '6/3/2024', 101), 4),
(73, 7479, CONVERT(DATE, '11/13/2024', 101), 4),
(74, 4411, CONVERT(DATE, '2/27/2024', 101), 4),
(75, 8512, CONVERT(DATE, '1/20/2025', 101), 4),
(76, 8535, CONVERT(DATE, '1/27/2025', 101), 4),
(77, 6491, CONVERT(DATE, '8/18/2024', 101), 4),
(78, 3934, CONVERT(DATE, '1/2/2024', 101), 4),
(79, 863, CONVERT(DATE, '1/16/2022', 101), 4),
(80, 9567, CONVERT(DATE, '5/28/2025', 101), 4),
(81, 5988, CONVERT(DATE, '7/18/2024', 101), 4),
(82, 3952, CONVERT(DATE, '1/13/2024', 101), 4),
(83, 2929, CONVERT(DATE, '2/26/2023', 101), 4),
(84, 4464, CONVERT(DATE, '3/1/2024', 101), 4),
(85, 6001, CONVERT(DATE, '7/2/2024', 101), 4),
(86, 3448, CONVERT(DATE, '9/3/2023', 101), 4),
(87, 6526, CONVERT(DATE, '8/23/2024', 101), 4),
(88, 1413, CONVERT(DATE, '8/16/2022', 101), 4),
(89, 9098, CONVERT(DATE, '3/17/2025', 101), 4),
(90, 397, CONVERT(DATE, '7/27/2021', 101), 4),
(91, 8590, CONVERT(DATE, '2/5/2025', 101), 4),
(92, 7072, CONVERT(DATE, '9/27/2024', 101), 4),
(93, 417, CONVERT(DATE, '8/5/2021', 101), 4),
(94, 1955, CONVERT(DATE, '10/19/2022', 101), 4),
(95, 3494, CONVERT(DATE, '9/10/2023', 101), 4),
(96, 4021, CONVERT(DATE, '2/5/2024', 101), 4),
(97, 2486, CONVERT(DATE, '12/11/2022', 101), 4),
(98, 7094, CONVERT(DATE, '10/15/2024', 101), 4),
(99, 7096, CONVERT(DATE, '10/7/2024', 101), 4),
(100, 8634, CONVERT(DATE, '2/8/2025', 101), 4),
(101, 958, CONVERT(DATE, '1/25/2022', 101), 4),
(102, 5055, CONVERT(DATE, '4/22/2024', 101), 4),
(103, 5056, CONVERT(DATE, '5/2/2024', 101), 4),
(104, 8127, CONVERT(DATE, '1/9/2025', 101), 4),
(105, 965, CONVERT(DATE, '2/2/2022', 101), 4),
(106, 6597, CONVERT(DATE, '9/1/2024', 101), 4),
(107, 3016, CONVERT(DATE, '3/19/2023', 101), 4),
(108, 4040, CONVERT(DATE, '2/9/2024', 101), 4),
(109, 7624, CONVERT(DATE, '11/20/2024', 101), 4),
(110, 5580, CONVERT(DATE, '6/11/2024', 101), 4),
(111, 5071, CONVERT(DATE, '4/20/2024', 101), 4),
(112, 2527, CONVERT(DATE, '1/4/2023', 101), 4),
(113, 4576, CONVERT(DATE, '3/8/2024', 101), 4),
(114, 2532, CONVERT(DATE, '12/27/2022', 101), 4),
(115, 8165, CONVERT(DATE, '12/22/2024', 101), 4),
(116, 7656, CONVERT(DATE, '11/17/2024', 101), 4),
(117, 2028, CONVERT(DATE, '10/27/2022', 101), 4),
(118, 9708, CONVERT(DATE, '5/26/2025', 101), 4),
(119, 2037, CONVERT(DATE, '11/22/2022', 101), 4),
(120, 9212, CONVERT(DATE, '4/3/2025', 101), 4),
(121, 8965, CONVERT(DATE, '2/28/2025', 101), 3),
(122, 4711, CONVERT(DATE, '3/18/2024', 101), 1),
(123, 6202, CONVERT(DATE, '7/25/2024', 101), 2),
(124, 5255, CONVERT(DATE, '5/9/2024', 101), 1),
(125, 2220, CONVERT(DATE, '11/8/2022', 101), 1),
(126, 8611, CONVERT(DATE, '1/28/2025', 101), 1),
(127, 1852, CONVERT(DATE, '9/30/2022', 101), 3),
(128, 9154, CONVERT(DATE, '4/5/2025', 101), 1),
(129, 3079, CONVERT(DATE, '3/19/2023', 101), 2),
(130, 2677, CONVERT(DATE, '1/29/2023', 101), 2),
(131, 1757, CONVERT(DATE, '9/18/2022', 101), 1),
(132, 6985, CONVERT(DATE, '9/25/2024', 101), 3),
(133, 8537, CONVERT(DATE, '1/26/2025', 101), 3),
(134, 6580, CONVERT(DATE, '8/29/2024', 101), 2),
(135, 364, CONVERT(DATE, '7/15/2021', 101), 1),
(136, 3132, CONVERT(DATE, '3/26/2023', 101), 2),
(137, 6666, CONVERT(DATE, '9/5/2024', 101), 3),
(138, 1620, CONVERT(DATE, '9/7/2022', 101), 1),
(139, 805, CONVERT(DATE, '12/4/2021', 101), 3),
(140, 6765, CONVERT(DATE, '9/8/2024', 101), 1),
(141, 2648, CONVERT(DATE, '1/22/2023', 101), 3),
(142, 5030, CONVERT(DATE, '4/16/2024', 101), 1),
(143, 4598, CONVERT(DATE, '3/12/2024', 101), 1),
(144, 7126, CONVERT(DATE, '10/7/2024', 101), 3),
(145, 9586, CONVERT(DATE, '5/5/2025', 101), 3),
(146, 4959, CONVERT(DATE, '3/31/2024', 101), 2),
(147, 7547, CONVERT(DATE, '11/9/2024', 101), 2),
(148, 926, CONVERT(DATE, '1/27/2022', 101), 2),
(149, 7915, CONVERT(DATE, '11/30/2024', 101), 1),
(150, 2692, CONVERT(DATE, '1/21/2023', 101), 2),
(151, 3867, CONVERT(DATE, '11/22/2023', 101), 1),
(152, 6791, CONVERT(DATE, '10/11/2024', 101), 1),
(153, 442, CONVERT(DATE, '8/9/2021', 101), 1),
(154, 1110, CONVERT(DATE, '3/14/2022', 101), 2),
(155, 719, CONVERT(DATE, '11/18/2021', 101), 1),
(156, 1079, CONVERT(DATE, '2/28/2022', 101), 2),
(157, 4601, CONVERT(DATE, '3/4/2024', 101), 3),
(158, 5606, CONVERT(DATE, '6/10/2024', 101), 1),
(159, 59, CONVERT(DATE, '4/8/2021', 101), 1),
(160, 3274, CONVERT(DATE, '6/4/2023', 101), 3),
(161, 6235, CONVERT(DATE, '7/27/2024', 101), 3),
(162, 7389, CONVERT(DATE, '10/27/2024', 101), 2),
(163, 4840, CONVERT(DATE, '3/28/2024', 101), 2),
(164, 2462, CONVERT(DATE, '12/21/2022', 101), 1),
(165, 758, CONVERT(DATE, '11/27/2021', 101), 2),
(166, 1230, CONVERT(DATE, '7/13/2022', 101), 3),
(167, 9678, CONVERT(DATE, '5/14/2025', 101), 3),
(168, 4742, CONVERT(DATE, '3/14/2024', 101), 2),
(169, 2186, CONVERT(DATE, '11/6/2022', 101), 3),
(170, 2941, CONVERT(DATE, '3/6/2023', 101), 1),
(171, 9312, CONVERT(DATE, '4/4/2025', 101), 2),
(172, 2796, CONVERT(DATE, '2/13/2023', 101), 2),
(173, 3101, CONVERT(DATE, '3/23/2023', 101), 3),
(174, 8830, CONVERT(DATE, '2/11/2025', 101), 2),
(175, 1131, CONVERT(DATE, '4/5/2022', 101), 1),
(176, 2213, CONVERT(DATE, '11/12/2022', 101), 2),
(177, 8116, CONVERT(DATE, '12/16/2024', 101), 2),
(178, 3284, CONVERT(DATE, '6/3/2023', 101), 2),
(179, 7517, CONVERT(DATE, '11/1/2024', 101), 3),
(180, 336, CONVERT(DATE, '7/8/2021', 101), 3),
(181, 6555, CONVERT(DATE, '8/24/2024', 101), 3),
(182, 5967, CONVERT(DATE, '7/1/2024', 101), 3),
(183, 3396, CONVERT(DATE, '8/3/2023', 101), 3),
(184, 2622, CONVERT(DATE, '1/1/2023', 101), 2),
(185, 551, CONVERT(DATE, '9/14/2021', 101), 1),
(186, 8989, CONVERT(DATE, '2/23/2025', 101), 1),
(187, 4652, CONVERT(DATE, '3/3/2024', 101), 3),
(188, 1366, CONVERT(DATE, '8/7/2022', 101), 3),
(189, 8541, CONVERT(DATE, '1/18/2025', 101), 3),
(190, 8428, CONVERT(DATE, '1/18/2025', 101), 1),
(191, 4187, CONVERT(DATE, '2/2/2024', 101), 1),
(192, 8355, CONVERT(DATE, '1/13/2025', 101), 3),
(193, 2971, CONVERT(DATE, '3/9/2023', 101), 1),
(194, 6972, CONVERT(DATE, '9/26/2024', 101), 2),
(195, 7511, CONVERT(DATE, '11/12/2024', 101), 3),
(196, 3748, CONVERT(DATE, '10/11/2023', 101), 1),
(197, 9986, CONVERT(DATE, '9/2/2025', 101), 2),
(198, 5732, CONVERT(DATE, '6/14/2024', 101), 1),
(199, 9989, CONVERT(DATE, '8/24/2025', 101), 3),
(200, 4709, CONVERT(DATE, '3/16/2024', 101), 3);
GO

-- ======================================
-- Table: 08_order_line_table.csv → ORDER_LINE
-- Depends on PRODUCT_SUPPLIER, [ORDER], DISCOUNT, DESIGN
-- ======================================
BULK INSERT ORDER_LINE
FROM 'D:\FCDS\semester 6\Jdara\database\08_order_line_table.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- Level 5: Tables depending on Level 0, 1, 2, 3, and 4 tables (User-specified order)
-- ======================================
-- Table: 11_Reviews.csv → REVIEW
-- Depends on ORDER_LINE
-- ======================================
BULK INSERT REVIEW
FROM 'D:\FCDS\semester 6\Jdara\database\11_Reviews.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    TABLOCK
);
GO

-- Re-enable and check all foreign key constraints after data insertion
-- This step will report any data integrity issues that exist after loading.
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL";
GO
