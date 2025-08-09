-- Step 1: Create a staging table identical to the original layoffs table
CREATE TABLE layoffs_staging LIKE layoffs;

-- Step 2: Verify the structure of the new staging table
SELECT * FROM layoffs_staging;

-- Step 3: Populate the staging table with data from the original layoffs table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Step 4: Identify duplicate records based on key columns
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, industry, total_laid_off, percentage_laid_off,
                            funds_raised_millions, country, stage, date
           ) AS row_num
    FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Step 5: Create a new staging table to hold deduplicated data and add a row_num column
CREATE TABLE layoffs_staging2 LIKE layoffs_staging;

ALTER TABLE layoffs_staging2
ADD row_num INT;

-- Step 6: Insert data into the second staging table with row numbers to identify duplicates
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, percentage_laid_off,
                        funds_raised_millions, country, stage, date
       ) AS row_num
FROM layoffs_staging;

-- Step 7: Delete duplicate rows (keeping only row_num = 1)
DELETE FROM layoffs_staging2 
WHERE row_num > 1;

-- Step 8: Verify no duplicates remain
SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- Step 9: Standardize company names by removing leading/trailing spaces
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Step 10: Explore distinct industry values to identify inconsistencies
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- Step 11: Standardize similar industry names (e.g., "Crypto / Blockchain" → "Crypto")
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Step 12: Review distinct locations (optional cleaning)
SELECT DISTINCT(location)
FROM layoffs_staging2
ORDER BY 1;

-- Step 13: Review and clean country names
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- Step 14: Remove trailing periods from country names (e.g., "United States.")
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Step 15: Review and parse the `date` column to proper DATE format
SELECT date, STR_TO_DATE(date, '%m/%d/%Y')
FROM layoffs_staging2;

-- Step 16: Replace string 'NULL' with actual NULLs in the `date` column
UPDATE layoffs_staging2
SET date = NULL
WHERE date = 'NULL';

-- Step 17: Convert valid date strings to DATE format
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y')
WHERE date IS NOT NULL
  AND STR_TO_DATE(date, '%m/%d/%Y') IS NOT NULL;

-- Step 18: Review converted date column
SELECT date
FROM layoffs_staging2;

-- Step 19: Alter column type to enforce proper DATE datatype
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- Step 20: Review dataset before handling missing numerical values
SELECT * FROM layoffs_staging2;

-- Step 21: Convert string 'NULL' to actual NULL in numerical columns
UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

-- Step 22: Identify records with missing values in both layoff fields
SELECT total_laid_off, percentage_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Step 23: Set blank or invalid industry values to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = 'NULL' OR industry = '';

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'NULL' OR funds_raised_millions = '';

-- Step 24: Use self-join to fill in missing industries based on company name
SELECT ls1.company, ls1.industry, ls2.industry
FROM layoffs_staging2 ls1
JOIN layoffs_staging2 ls2
  ON ls1.company = ls2.company
WHERE ls1.industry IS NULL
  AND ls2.industry IS NOT NULL;

-- Step 25: Update NULL industry values using non-null values from other rows
UPDATE layoffs_staging2 ls1
JOIN layoffs_staging2 ls2
  ON ls1.company = ls2.company
SET ls1.industry = ls2.industry
WHERE ls1.industry IS NULL
  AND ls2.industry IS NOT NULL;

-- changing datatypes
ALTER TABLE layoffs_staging2
  MODIFY COLUMN funds_raised_millions DECIMAL(15,2),
  MODIFY COLUMN percentage_laid_off DECIMAL(15,2),
  MODIFY COLUMN total_laid_off DECIMAL(15,2);

-- Step 26: Check if any NULL industries remain
SELECT industry
FROM layoffs_staging2
WHERE industry IS NULL;

-- Step 27: Delete rows where both `total_laid_off` and `percentage_laid_off` are NULL
DELETE FROM layoffs_staging2 
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Step 28: Remove the helper column `row_num` after deduplication is complete
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
