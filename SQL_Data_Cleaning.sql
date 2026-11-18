-- Nashville Housing Data Cleaning (SQLite)
-- Data: Nashville housing sales (Jan 2013 – Dec 2016, ~56K rows) | Adapted from Alex the Analyst's tutorial, rewritten for SQLite
-- Skills used: Self Joins, Subquery Updates, CTEs, Window Functions, String Functions, CASE Statements, Altering Tables

Select * 
from NashvilleHousing;


-- Populate Property Address data 
SELECT *
from NashvilleHousing
-- where PropertyAddress is NULL
order by ParcelID;

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, IFNULL(A.PropertyAddress, B.PropertyAddress)
from NashvilleHousing as A
JOIN NashvilleHousing as B
on A.ParcelID = B.ParcelID
and A.UniqueID <> B.UniqueID
where A.PropertyAddress is NULL;

UPDATE NashvilleHousing
SET PropertyAddress = (
SELECT B.PropertyAddress
from NashvilleHousing as B
where B.ParcelID = NashvilleHousing.ParcelID
and B.UniqueID <> NashvilleHousing.UniqueID
and B.PropertyAddress is not NULL
limit 1
)
where PropertyAddress is NULL;

SELECT *
from NashvilleHousing
where PropertyAddress is NULL;


-- Breaking out Property Address into Individual Columns (Address, City)
SELECT PropertyAddress
from NashvilleHousing;
-- where PropertyAddress is NULL
-- order by ParcelID;

SELECT 
substr(PropertyAddress, 1, instr(PropertyAddress, ',') -1) AS Address,
trim( substr( PropertyAddress, instr( PropertyAddress, ',') + 1)) as City
From NashvilleHousing;

ALTER TABLE NashvilleHousing ADD COLUMN PropertySplitAddress TEXT;
ALTER TABLE NashvilleHousing ADD COLUMN PropertySplitCity TEXT;

UPDATE NashvilleHousing
SET PropertySplitAddress = substr(PropertyAddress, 1, instr(PropertyAddress, ',') - 1),
PropertySplitCity = TRIM(substr(PropertyAddress, instr(PropertyAddress, ',') + 1));

SELECT *
FROM NashvilleHousing;


-- Breaking out Owner Address into Individual Columns (Address, City, State)
Select OwnerAddress
from NashvilleHousing;

SELECT OwnerAddress,
substr(OwnerAddress, 1, instr(OwnerAddress, ',') - 1)  AS OwnerSplitAddress,
TRIM(substr(rest, 1, instr(rest, ',') - 1)) AS OwnerSplitCity,
TRIM(substr(rest, instr(rest, ',') + 1)) AS OwnerSplitState
FROM ( SELECT OwnerAddress, substr(OwnerAddress, instr(OwnerAddress, ',') + 1) AS rest
FROM NashvilleHousing
);

ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitAddress TEXT;
ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitCity TEXT;
ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitState TEXT;

UPDATE NashvilleHousing
SET OwnerSplitAddress = substr(OwnerAddress, 1, instr(OwnerAddress, ',') - 1),
OwnerSplitCity = TRIM(substr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), 1,
instr(substr(OwnerAddress, instr(OwnerAddress, ',') + 1), ',') - 1)),
OwnerSplitState = TRIM(substr(OwnerAddress, -2));


-- Change Y and N to Yes and No in 'Sold as Vacant' field
SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
Order by 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END AS SoldAsVacantFixed
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END;


-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID
) AS row_num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

WITH RowNumCTE AS (
SELECT UniqueID, ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID
) AS row_num
FROM NashvilleHousing
)
DELETE FROM NashvilleHousing
WHERE UniqueID IN (SELECT UniqueID FROM RowNumCTE WHERE row_num > 1);


-- Delete Unused Columns
SELECT *
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing DROP COLUMN OwnerAddress;
ALTER TABLE NashvilleHousing DROP COLUMN TaxDistrict;
ALTER TABLE NashvilleHousing DROP COLUMN PropertyAddress;



