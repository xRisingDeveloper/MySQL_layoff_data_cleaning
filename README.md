# 🧹 Layoffs Dataset Cleaning with SQL

This project showcases how I used SQL to clean, deduplicate, and standardize a real-world dataset of company layoffs. The process includes identifying duplicate records, cleaning inconsistent text data, converting date formats, and handling missing values.

---

## 📂 Project Structure

layoffs-data-cleaning/  
├── old_dataset.csv           # Original raw dataset (as exported from the database)  
├── cleaned_dataset.csv       # Final cleaned dataset (exported from cleaned SQL table)  
├── layoffs_cleaning.sql      # SQL script used for all data cleaning steps  
└── README.md                 # Project documentation

---

## 🔧 Tools Used

- SQL (MySQL)
- ROW_NUMBER() window function
- DBeaver / PopSQL (for writing and executing queries)
- GitHub (for version control and publishing)

---

## 🔍 Key Cleaning Steps

✅ **1. Deduplication**  
Used ROW_NUMBER() to find and remove duplicate records based on key columns such as company, industry, stage, date, etc.

✅ **2. Text Standardization**  
- Trimmed whitespace from company and country  
- Standardized variations in industry (e.g., "Crypto / Blockchain" → "Crypto")

✅ **3. Date Formatting**  
- Converted date strings from MM/DD/YYYY to SQL DATE type  
- Handled NULL and invalid entries

✅ **4. Handling NULLs and Missing Values**  
- Replaced 'NULL' strings with real NULL values  
- Filled missing industry fields using self-joins based on the company name  
- Removed rows with no useful layoff data

---

## 📈 Result

The cleaned dataset contains accurate, standardized, and deduplicated data ready for analysis and visualization.

---

## 📘 Example SQL Snippets

-- Deduplication using ROW_NUMBER  
INSERT INTO layoffs_staging2  
SELECT *,  
       ROW_NUMBER() OVER (  
           PARTITION BY company, industry, total_laid_off, percentage_laid_off,  
                        funds_raised_millions, country, stage, date  
       ) AS row_num  
FROM layoffs_staging;

-- Delete duplicates  
DELETE FROM layoffs_staging2  
WHERE row_num > 1;

-- Standardize text fields  
UPDATE layoffs_staging2  
SET company = TRIM(company);

UPDATE layoffs_staging2  
SET industry = 'Crypto'  
WHERE industry LIKE 'Crypto%';

-- Handle invalid date formats  
UPDATE layoffs_staging2  
SET date = STR_TO_DATE(date, '%m/%d/%Y')  
WHERE date IS NOT NULL  
  AND STR_TO_DATE(date, '%m/%d/%Y') IS NOT NULL;

-- Fill NULLs using self-join  
UPDATE layoffs_staging2 ls1  
JOIN layoffs_staging2 ls2  
  ON ls1.company = ls2.company  
SET ls1.industry = ls2.industry  
WHERE ls1.industry IS NULL  
  AND ls2.industry IS NOT NULL;

---

## 👨‍💻 Author

**Yahia Ghanim**  
Junior Data Analyst | SQL & Python Enthusiast  
[LinkedIn](https://www.linkedin.com) • [GitHub](https://github.com/YahiaGhanim)

---

## 📎 License

This project is open-source and available for anyone to learn from or build upon.