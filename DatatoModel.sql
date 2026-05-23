-- Insert dữ liệu vào DimCustomer
insert into DimCustomer(
	CUSTOMER_ID,
	CUSTOMER_NAME,
	CUSTOMER_EDUCATION_LEVEL,
	MARITAL_STATUS,
	AGE,
	TENURE,
	EMPLOYMENT_STATUS,
	NO_OF_FAMILY_MEMBERS,
	RISK_SEGMENTATION,
	HOUSE_TYPE,
	SOCIAL_CLASS,
	ROUTING_NUMBER,
	ACCT_NUMBER
)
SELECT DISTINCT
    CUSTOMER_ID,
	CUSTOMER_NAME,
	CUSTOMER_EDUCATION_LEVEL,
	MARITAL_STATUS,
	AGE,
	TENURE,
	EMPLOYMENT_STATUS,
	NO_OF_FAMILY_MEMBERS,
	RISK_SEGMENTATION,
	HOUSE_TYPE,
	SOCIAL_CLASS,
	ROUTING_NUMBER,
	ACCT_NUMBER
FROM insurance_data_cleaned


-- Insert dữ liệu vào DimVendor
insert into DimVendor(
	VENDOR_ID,
	VENDOR_NAME
)
select distinct 
	VENDOR_ID,
	VENDOR_NAME
from insurance_data_cleaned

-- Insert dữ liệu vào  DimPolicy
insert into DimPolicy(
	POLICY_NUMBER,
	POLICY_EFF_DT,
	INSURANCE_TYPE
)
select distinct 
	POLICY_NUMBER,
	POLICY_EFF_DT,
	INSURANCE_TYPE
from insurance_data_cleaned
-- Insert dữ liệu vào DimIncident
insert into DimIncident(
	INCIDENT_SEVERITY,
	AUTHORITY_CONTACTED,
	ANY_INJURY,
	POLICE_REPORT_AVAILABLE,
	CLAIM_STATUS,
	INCIDENT_HOUR
)
select distinct  
	INCIDENT_SEVERITY,
	AUTHORITY_CONTACTED,
	ANY_INJURY,
	POLICE_REPORT_AVAILABLE,
	CLAIM_STATUS,
	INCIDENT_HOUR_OF_THE_DAY
from insurance_data_cleaned
-- Insert dữ liệu vào DimLocation
insert into DimLocation(
	ADDRESS_LINE1,
	CITY,
	STATE,
	POSTAL_CODE
)
select distinct 
	ADDRESS_LINE1,
	CITY,
	STATE,
	POSTAL_CODE
from insurance_data_cleaned
-- Insert dữ liệu vào DimAgent
insert into DimAgent(
	AGENT_ID,
	AGENT_NAME,
	DATE_OF_JOINING,
	EMP_ROUTING_NUMBER,
	EMP_ACCT_NUMBER
)
select distinct 
	AGENT_ID,
	AGENT_NAME,
	DATE_OF_JOINING,
	EMP_ROUTING_NUMBER,
	EMP_ACCT_NUMBER
from insurance_data_cleaned
-- Insert dữ liệu vào 
-- Sửa lỗi Insert cho Fact_Premium
INSERT INTO Fact_Premium (
    Customer_key,
    Policy_key,
    Incident_key,
    Vendor_key,
    LOCATION_KEY,
    Agent_key,
    PREMIUM_AMOUNT
)
SELECT 
    dimC.Customer_Key,   -- Lấy Key từ bảng DimCustomer
    dimP.Policy_Key,     -- Lấy Key từ bảng DimPolicy
    dimI.Incident_Key,   -- Lấy Key từ bảng DimIncident
    dimV.Vendor_Key,     -- Lấy Key từ bảng DimVendor
    dimL.LOCATION_KEY,   -- Lấy Key từ bảng DimLocation
    dimA.Agent_Key,      -- Lấy Key từ bảng DimAgent
    src.PREMIUM_AMOUNT   -- Lấy số tiền từ bảng gốc
FROM insurance_data_cleaned src
-- Thực hiện Join để tìm các Key tương ứng
INNER JOIN DimCustomer dimC ON src.CUSTOMER_ID = dimC.CUSTOMER_ID
INNER JOIN DimPolicy dimP   ON src.POLICY_NUMBER = dimP.POLICY_NUMBER
INNER JOIN DimVendor dimV   ON src.VENDOR_ID = dimV.VENDOR_ID
INNER JOIN DimAgent dimA    ON src.AGENT_ID = dimA.AGENT_ID
-- Với DimIncident và DimLocation, bạn join dựa trên các cột thuộc tính
INNER JOIN DimLocation dimL ON src.ADDRESS_LINE1 = dimL.ADDRESS_LINE1 
                           AND src.POSTAL_CODE = dimL.POSTAL_CODE
INNER JOIN DimIncident dimI ON src.INCIDENT_SEVERITY = dimI.INCIDENT_SEVERITY 
                           AND src.CLAIM_STATUS = dimI.CLAIM_STATUS
                           AND src.INCIDENT_HOUR_OF_THE_DAY = dimI.INCIDENT_HOUR;

-- Kiểm tra kết quả
SELECT TOP 10 * FROM Fact_Premium;
-- Insert dữ liệu vào 
-- Sửa lỗi Insert cho Fact_Claim
INSERT INTO Fact_Claim (
    TRANSACTION_ID,
    CUSTOMER_KEY,
    AGENT_KEY,
    VENDOR_KEY,
    POLICY_KEY,
    INCIDENT_KEY,
    TXN_DATE_KEY,
    LOSS_DATE_KEY,
    REPORT_DATE_KEY,
    INCIDENT_LOCATION_KEY,
    CLAIM_AMOUNT
)
SELECT 
    src.TRANSACTION_ID,      -- ID giao dịch từ bảng gốc
    dimC.Customer_Key,       -- Lấy từ DimCustomer
    dimA.Agent_Key,          -- Lấy từ DimAgent
    dimV.Vendor_Key,         -- Lấy từ DimVendor
    dimP.Policy_Key,         -- Lấy từ DimPolicy
    dimI.Incident_Key,       -- Lấy từ DimIncident
    -- Chuyển đổi các cột ngày tháng sang DateKey (YYYYMMDD) để khớp với DimTime
    YEAR(src.TXN_DATE) * 10000 + MONTH(src.TXN_DATE) * 100 + DAY(src.TXN_DATE),
    YEAR(src.LOSS_DATE) * 10000 + MONTH(src.LOSS_DATE) * 100 + DAY(src.LOSS_DATE),
    YEAR(src.REPORT_DATE) * 10000 + MONTH(src.REPORT_DATE) * 100 + DAY(src.REPORT_DATE),
    dimL.LOCATION_KEY,       -- Lấy từ DimLocation
    src.CLAIM_AMOUNT
FROM insurance_data_cleaned src
-- Thực hiện các phép JOIN để lấy Surrogate Key
INNER JOIN DimCustomer dimC ON src.CUSTOMER_ID = dimC.CUSTOMER_ID
INNER JOIN DimAgent dimA    ON src.AGENT_ID = dimA.AGENT_ID
INNER JOIN DimVendor dimV   ON src.VENDOR_ID = dimV.VENDOR_ID
INNER JOIN DimPolicy dimP   ON src.POLICY_NUMBER = dimP.POLICY_NUMBER
INNER JOIN DimLocation dimL ON src.ADDRESS_LINE1 = dimL.ADDRESS_LINE1 
                           AND src.POSTAL_CODE = dimL.POSTAL_CODE
INNER JOIN DimIncident dimI ON src.INCIDENT_SEVERITY = dimI.INCIDENT_SEVERITY 
                           AND src.CLAIM_STATUS = dimI.CLAIM_STATUS
                           AND src.INCIDENT_HOUR_OF_THE_DAY = dimI.INCIDENT_HOUR;

-- Kiểm tra kết quả nạp dữ liệu
SELECT TOP 10 * FROM Fact_Claim;

