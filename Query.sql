--create database insurance
--use insurance
--select * from insurance_data

-- truy vấn các giá trị null 
--select ADDRESS_LINE1 from insurance_data


--select * from INFORMATION_SCHEMA.COLUMNS


-- kiểm tra nulll trong bảng
--DECLARE @sql NVARCHAR(MAX) = '';

--SELECT @sql += 
--    QUOTENAME(COLUMN_NAME) + ' IS NULL OR '
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'insurance_data';

-- Xóa OR cuối
--SET @sql = LEFT(@sql, LEN(@sql) - 3);

--SET @sql = '
--SELECT count(*)
--FROM insurance_data
--WHERE ' + @sql  ;


--EXEC sp_executesql @sql;


-- Tổng doanh thu phí bảo hiểm (Premium) theo từng loại hình bảo hiểm (Insurance_Type) là bao nhiêu?
select distinct sum(Premium_Amount) over(partition by p.Insurance_type), p.INSURANCE_TYPE from Fact_Premium as pr
join DimPolicy as p
on pr.Policy_Key = p.Policy_Key

select * from DimPolicy

--Câu hỏi 2: Top 5 đại lý (Agent_Name) có doanh số phí bảo hiểm cao nhất trong năm 2024?
select distinct top 5 AGENT_NAME, sum(p.Premium_Amount) over(partition by a.AGENT_NAME) as doanhso
from DimAgent a
join Fact_Premium p
on p.Agent_Key = a.Agent_Key
order by doanhso
--Câu hỏi 3: Tỷ lệ đóng góp phí bảo hiểm theo phân khúc rủi ro khách hàng (Risk_Segmentation)?
SELECT distinct
    c.RISK_SEGMENTATION,
    -- 1. Tính tổng phí bảo hiểm của từng phân khúc
    SUM(p.Premium_Amount) AS Total_Premium_By_Segment,
    
    -- 2. Tính tỷ lệ % đóng góp
    -- Công thức: (Tổng từng nhóm / Tổng tất cả) * 100
    CAST(
        SUM(p.Premium_Amount) * 100.0 / SUM(SUM(p.Premium_Amount)) OVER() 
    AS DECIMAL(10, 2)) AS Contribution_Percentage
FROM Fact_Premium p
JOIN DimCustomer c ON p.Customer_Key = c.Customer_Key
GROUP BY c.RISK_SEGMENTATION
ORDER BY Contribution_Percentage DESC;


--Câu hỏi 4: Tổng số tiền bồi thường (Claim_Amount) theo từng mức độ nghiêm trọng của sự cố (Incident_Severity)?
Select sum(Claim_Amount) as total_claim_amount, INCIDENT_SEVERITY
from Fact_Claim c
join DimIncident i
on c.INCIDENT_KEY = i.Incident_Key 
group by i.INCIDENT_SEVERITY

--Câu hỏi 5: Loss Ratio (Tỷ lệ tổn thất): Tính tỷ lệ giữa Tổng tiền bồi thường / Tổng phí bảo hiểm thu về theo từng tiểu bang (State).
select Sum(p.Premium_Amount) *100 / sum(c.CLAIM_AMOUNT) , l.STATE as ratio
from DimLocation l
join Fact_Claim c
on c.INCIDENT_LOCATION_KEY = l.Location_Key
join Fact_Premium p
on p.Location_Key = l.Location_Key
group by l.STATE

--Câu hỏi 6: Khung giờ nào trong ngày thường xảy ra các vụ tai nạn có mức độ nghiêm trọng cao nhất?
select top 1 Count(*), INCIDENT_HOUR
from DimIncident
group by INCIDENT_HOUR
order by INCIDENT_HOUR desc

--Câu hỏi 7: Độ tuổi trung bình (Age) và trình độ học vấn (Education_Level) của những khách hàng có mức bồi thường trên 50,000 là gì?
with cte1 as (select avg(AGE) as age, CUSTOMER_EDUCATION_LEVEL
from Fact_Claim c
join DimCustomer cus
on c.CUSTOMER_KEY = cus.Customer_Key
group by CLAIM_AMOUNT, AGE , CUSTOMER_EDUCATION_LEVEL
having sum(CLAIM_AMOUNT) > 50000)
select avg(age), CUSTOMER_EDUCATION_LEVEL
from cte1
group by CUSTOMER_EDUCATION_LEVEL
--Câu hỏi 8: Tình trạng hôn nhân (Marital_Status) và số lượng thành viên gia đình có ảnh hưởng đến giá trị hợp đồng bảo hiểm không?
select  c.MARITAL_STATUS, c.NO_OF_FAMILY_MEMBERS, p.Premium_Amount
from Fact_Premium p
join DimCustomer c
on p.Customer_Key = c.Customer_Key
order by p.Premium_Amount desc


--Câu hỏi 9: Những khách hàng thuộc tầng lớp xã hội nào (Social_Class) có tỷ lệ yêu cầu bồi thường cao nhất?
WITH Class_Stats AS (
    -- Bước 1: Tính tổng phí bảo hiểm thu được từ mỗi tầng lớp xã hội
    SELECT 
        c.SOCIAL_CLASS,
        COUNT(DISTINCT c.Customer_Key) AS Total_Customers,
        SUM(p.Premium_Amount) AS Total_Premium
    FROM DimCustomer c
    LEFT JOIN Fact_Premium p ON c.Customer_Key = p.Customer_Key
    GROUP BY c.SOCIAL_CLASS
),
Claim_Stats AS (
    -- Bước 2: Tính tổng số vụ và số tiền bồi thường từ mỗi tầng lớp xã hội
    SELECT 
        c.SOCIAL_CLASS,
        COUNT(f.Fact_Claim_Key) AS Total_Claims,
        SUM(f.CLAIM_AMOUNT) AS Total_Claim_Amount
    FROM DimCustomer c
    LEFT JOIN Fact_Claim f ON c.Customer_Key = f.CUSTOMER_KEY
    GROUP BY c.SOCIAL_CLASS
)
-- Bước 3: Kết hợp và tính tỷ lệ
SELECT 
    ps.SOCIAL_CLASS,
    ps.Total_Customers,
    ISNULL(cs.Total_Claims, 0) AS Total_Claims,
    -- Tỷ lệ số vụ bồi thường trên mỗi khách hàng
    CAST(ISNULL(cs.Total_Claims, 0) * 1.0 / ps.Total_Customers AS DECIMAL(10, 2)) AS Claims_Per_Customer,
    -- Tỷ lệ bồi thường trên doanh thu (Loss Ratio)
    CAST(ISNULL(cs.Total_Claim_Amount, 0) * 100.0 / NULLIF(ps.Total_Premium, 0) AS DECIMAL(10, 2)) AS Loss_Ratio_Percentage
FROM Class_Stats ps
LEFT JOIN Claim_Stats cs ON ps.SOCIAL_CLASS = cs.SOCIAL_CLASS
ORDER BY Loss_Ratio_Percentage DESC;

--Câu hỏi 10: Thành phố (City) nào đang có số lượng yêu cầu bồi thường (Claims) bất thường so với mức phí thu về?
SELECT 
    l.CITY,
    COUNT(DISTINCT p.Fact_Premium_Key) AS Total_Policies,
    SUM(p.Premium_Amount) AS Total_Premium,
    COUNT(f.Fact_Claim_Key) AS Total_Claims,
    SUM(f.CLAIM_AMOUNT) AS Total_Claim_Value,
    -- Tính Loss Ratio
    CAST(SUM(f.CLAIM_AMOUNT) * 100.0 / NULLIF(SUM(p.Premium_Amount), 0) AS DECIMAL(10, 2)) AS Loss_Ratio_Percent,
    -- Tính giá trị bồi thường trung bình mỗi vụ
    CAST(SUM(f.CLAIM_AMOUNT) / NULLIF(COUNT(f.Fact_Claim_Key), 0) AS DECIMAL(10, 2)) AS Avg_Claim_Severity
FROM DimLocation l
LEFT JOIN Fact_Premium p ON l.Location_Key = p.Location_Key
LEFT JOIN Fact_Claim f ON l.Location_Key = f.INCIDENT_LOCATION_KEY
GROUP BY l.CITY
HAVING SUM(p.Premium_Amount) > 0 -- Chỉ xét các thành phố có phát sinh doanh thu
   AND SUM(f.CLAIM_AMOUNT) > SUM(p.Premium_Amount) -- Lọc ra các thành phố "bất thường" (lỗ)
ORDER BY Loss_Ratio_Percent DESC;
--Câu hỏi 11: Top 3 đối tác (Vendor_Name) xử lý nhiều vụ bồi thường nhất cho công ty?
SELECT TOP 3
    v.VENDOR_NAME,
    COUNT(f.Fact_Claim_Key) AS Total_Claims_Handled,
    SUM(f.CLAIM_AMOUNT) AS Total_Claim_Value_Processed,
    CAST(AVG(f.CLAIM_AMOUNT) AS DECIMAL(10,2)) AS Avg_Claim_Value
FROM Fact_Claim f
JOIN DimVendor v ON f.VENDOR_KEY = v.Vendor_Key
GROUP BY v.VENDOR_NAME
ORDER BY Total_Claims_Handled DESC;