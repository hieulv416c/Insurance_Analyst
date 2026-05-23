-- tạo bảng 
-- Dim Customer
DROP TABLE IF EXISTS DimCustomer;
CREATE TABLE DimCustomer (
    Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(50),
    CUSTOMER_NAME NVARCHAR(255),	
    CUSTOMER_EDUCATION_LEVEL VARCHAR(50),
    MARITAL_STATUS VARCHAR(20),
    AGE INT,
    TENURE INT,
    EMPLOYMENT_STATUS VARCHAR(50),
    NO_OF_FAMILY_MEMBERS INT,
    RISK_SEGMENTATION VARCHAR(50),
    HOUSE_TYPE VARCHAR(50),
    SOCIAL_CLASS VARCHAR(50),
    ROUTING_NUMBER BIGINT,
    ACCT_NUMBER VARCHAR(50),
    Start_Date DATE DEFAULT GETDATE(),
    End_Date DATE Null,
    Is_Current BIT DEFAULT 1 
);

--
DROP TABLE IF EXISTS DimVendor;
CREATE TABLE DimVendor (
    Vendor_Key INT IDENTITY(1,1) PRIMARY KEY,
    VENDOR_ID VARCHAR(50),
    VENDOR_NAME NVARCHAR(255),
    -- SCD Type 2 Columns
    Start_Date DATE DEFAULT GETDATE(),
    End_Date DATE NULL,
    Is_Current BIT DEFAULT 1
);
DROP TABLE IF EXISTS DimPolicy;
CREATE TABLE DimPolicy (
    Policy_Key INT IDENTITY(1,1) PRIMARY KEY,
    POLICY_NUMBER VARCHAR(50),
    POLICY_EFF_DT DATE,
    INSURANCE_TYPE VARCHAR(50),
    -- SCD Type 2
    Start_Date DATE DEFAULT GETDATE(),
    End_Date DATE NULL,
    Is_Current BIT DEFAULT 1
);
DROP TABLE IF EXISTS DimIncident;
CREATE TABLE DimIncident (
    Incident_Key INT IDENTITY(1,1) PRIMARY KEY,
    INCIDENT_SEVERITY VARCHAR(50),
    AUTHORITY_CONTACTED VARCHAR(100),
    ANY_INJURY BIT,
    POLICE_REPORT_AVAILABLE BIT,
    CLAIM_STATUS VARCHAR(50),
    INCIDENT_HOUR TINYINT
);
DROP TABLE IF EXISTS DimLocation;
CREATE TABLE DimLocation (
    Location_Key INT IDENTITY(1,1) PRIMARY KEY,
    ADDRESS_LINE1 NVARCHAR(255),
    CITY NVARCHAR(100),
    STATE VARCHAR(50),
    POSTAL_CODE VARCHAR(20)
);
DROP TABLE IF EXISTS DimAgent;
CREATE TABLE DimAgent (
    Agent_Key INT IDENTITY(1,1) PRIMARY KEY,
    AGENT_ID VARCHAR(50),
    AGENT_NAME NVARCHAR(255),
    DATE_OF_JOINING DATE,
    EMP_ROUTING_NUMBER BIGINT,
    EMP_ACCT_NUMBER VARCHAR(50),
    -- SCD Type 2
    Start_Date DATE DEFAULT GETDATE(),
    End_Date DATE NULL,
    Is_Current BIT DEFAULT 1
);


-- =========================================
-- GENERATE DATE DATA
-- =========================================
-- =========================================
-- DIM TIME
-- =========================================

-- Cố định cài đặt để dữ liệu luôn đồng nhất
/* K22416C_Group4 - HRM Data Warehouse Project 
   Script: Khởi tạo và nạp dữ liệu cho bảng DimTime
*/

-- =====================================
-- DROP & CREATE DIMTIME
-- =====================================

/* PROJECT: HRM DATA WAREHOUSE
   SCRIPT: INITIALIZE DimTime TABLE
   GROUP: 4
*/

-- 1. Thiết lập môi trường chuẩn (Tiếng Anh, Chủ Nhật là đầu tuần)
SET LANGUAGE English;
SET DATEFIRST 7;
GO

-- 2. Xóa bảng cũ nếu tồn tại
IF OBJECT_ID('DimTime', 'U') IS NOT NULL
    DROP TABLE DimTime;
GO

-- 3. Tạo cấu trúc bảng DimTime (Khai báo cột CalendarDate rõ ràng)
CREATE TABLE DimTime (
    DateKey INT NOT NULL PRIMARY KEY,
    CalendarDate DATE NOT NULL,
    TheDay TINYINT,
    TheDayName VARCHAR(20),
    TheWeek TINYINT,
    TheISOWeek TINYINT,
    TheDayOfWeek TINYINT,
    TheMonth TINYINT,
    TheMonthName VARCHAR(20),
    TheQuarter TINYINT,
    TheYear SMALLINT,
    TheFirstOfMonth DATE,
    TheLastOfYear DATE,
    TheDayOfYear SMALLINT
);
GO -- Bắt buộc phải có GO ở đây để SQL Server xác nhận đã tạo xong các cột

-- 4. Khai báo biến thời gian
DECLARE @StartDate DATE = '1990-01-01'; 
DECLARE @TotalYears INT = 40; -- Tạo dữ liệu trong 40 năm
DECLARE @CutoffDate DATE = DATEADD(DAY, -1, DATEADD(YEAR, @TotalYears, @StartDate));

-- 5. Sử dụng CTE để tạo dãy ngày tháng tự động
WITH seq(n) AS
(
    SELECT 0
    UNION ALL
    SELECT n + 1
    FROM seq
    WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
DateSeries AS
(
    SELECT DATEADD(DAY, n, @StartDate) AS DateValue
    FROM seq
)

-- 6. Nạp dữ liệu vào bảng (Liệt kê đầy đủ 14 cột để tránh lỗi Msg 213)
INSERT INTO DimTime (
    DateKey,
    CalendarDate,
    TheDay,
    TheDayName,
    TheWeek,
    TheISOWeek,
    TheDayOfWeek,
    TheMonth,
    TheMonthName,
    TheQuarter,
    TheYear,
    TheFirstOfMonth,
    TheLastOfYear,
    TheDayOfYear
)
SELECT
    -- Tạo DateKey dạng số YYYYMMDD
    YEAR(DateValue) * 10000 + MONTH(DateValue) * 100 + DAY(DateValue),
    DateValue,
    DAY(DateValue),
    DATENAME(WEEKDAY, DateValue),
    DATEPART(WEEK, DateValue),
    DATEPART(ISO_WEEK, DateValue),
    DATEPART(WEEKDAY, DateValue),
    MONTH(DateValue),
    DATENAME(MONTH, DateValue),
    DATEPART(QUARTER, DateValue),
    YEAR(DateValue),
    DATEFROMPARTS(YEAR(DateValue), MONTH(DateValue), 1),
    DATEFROMPARTS(YEAR(DateValue), 12, 31),
    DATEPART(DAYOFYEAR, DateValue)
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

-- 7. Kiểm tra kết quả
--SELECT TOP 100 * FROM DimTime ORDER BY DateKey;
-- Create Fact_Premium
DROP TABLE IF EXISTS Fact_Premium
CREATE TABLE Fact_Premium (
    Fact_Premium_Key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_Key INT NOT NULL,
    Policy_Key INT NOT NULL,
    Incident_Key INT NOT NULL,
    Vendor_Key INT NOT NULL,
    Location_Key INT NOT NULL,
    Agent_Key INT NOT NULL,
    Premium_Amount DECIMAL(18,2) NOT NULL,


    -- Foreign Key
    CONSTRAINT FK_FactPremium_Customer
        FOREIGN KEY (Customer_Key)
        REFERENCES DimCustomer(Customer_Key),

    CONSTRAINT FK_FactPremium_Policy
        FOREIGN KEY (Policy_Key)
        REFERENCES DimPolicy(Policy_Key),

    CONSTRAINT FK_FactPremium_Incident
        FOREIGN KEY (Incident_Key)
        REFERENCES DimIncident(Incident_Key),

    CONSTRAINT FK_FactPremium_Vendor
        FOREIGN KEY (Vendor_Key)
        REFERENCES DimVendor(Vendor_Key),

    CONSTRAINT FK_FactPremium_Location
        FOREIGN KEY (Location_Key)
        REFERENCES DimLocation(Location_Key),

    CONSTRAINT FK_FactPremium_Agent
        FOREIGN KEY (Agent_Key)
        REFERENCES DimAgent(Agent_Key)
);
-- Create Fact_Claim
DROP TABLE IF EXISTS Fact_Claim
CREATE TABLE Fact_Claim (
    Fact_Claim_Key INT IDENTITY(1,1) PRIMARY KEY,
    TRANSACTION_ID VARCHAR(50) NOT NULL,
    CUSTOMER_KEY INT NOT NULL,
    AGENT_KEY INT NOT NULL,
    VENDOR_KEY INT NOT NULL,
    POLICY_KEY INT NOT NULL,
    INCIDENT_KEY INT NOT NULL,
    TXN_DATE_KEY INT NOT NULL,
    LOSS_DATE_KEY INT NOT NULL,
    REPORT_DATE_KEY INT NOT NULL,
    INCIDENT_LOCATION_KEY INT NOT NULL,
    CLAIM_AMOUNT DECIMAL(18,2) NOT NULL,

	CONSTRAINT  FK_FactClaim_Customer
		Foreign key (CUSTOMER_KEY)
		References DimCustomer(Customer_Key),
	Constraint Fk_FactClaim_Agent
		Foreign key (AGENT_KEY)
		References DimAgent(Agent_Key),
	CONSTRAINT  FK_FactClaim_VENDOR
		Foreign key (VENDOR_KEY)
		References DimVendor(Vendor_Key),
	CONSTRAINT FK_FactClaim_Policy
		Foreign key (POLICY_KEY)
		References DimPolicy(Policy_Key),
	CONSTRAINT  FK_FactClaim_INCIDENT
		Foreign key (INCIDENT_KEY)
		References DimIncident(Incident_Key),
	CONSTRAINT FK_FactClaim_TXNDate
		Foreign key (TXN_DATE_KEY)
		References DimTime(DateKey),
	CONSTRAINT FK_FactClaim_LossDate
        FOREIGN KEY (LOSS_DATE_KEY)
        REFERENCES DimTime(DateKey),
    CONSTRAINT FK_FactClaim_ReportDate
        FOREIGN KEY (REPORT_DATE_KEY)
        REFERENCES DimTime(DateKey),
	constraint FK_FactClaim_Location
		foreign key (INCIDENT_LOCATION_KEY)
		references DimLocation(Location_Key))


--DECLARE @sql NVARCHAR(MAX) = '';

--SELECT @sql += 
--    'ALTER TABLE ' 
--    + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))
--    + '.'
--    + QUOTENAME(OBJECT_NAME(parent_object_id))
--    + ' DROP CONSTRAINT '
--    + QUOTENAME(name)
--    + ';' + CHAR(10)
--FROM sys.foreign_keys;

--PRINT @sql;
--EXEC sp_executesql @sql;

--ALTER TABLE Fact_Claim DROP CONSTRAINT FK_FactClaim_TXNDate;
--ALTER TABLE Fact_Claim DROP CONSTRAINT FK_FactClaim_LossDate;
--ALTER TABLE Fact_Claim DROP CONSTRAINT FK_FactClaim_ReportDate;

