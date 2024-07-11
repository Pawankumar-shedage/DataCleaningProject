
---**DATA CLEANING**---------------
USE [PortfolioProject]

SELECT * 
FROM [PortfolioProject].dbo.NashvilleHousing

--[1] Formatting Date---------------------------------------


SELECT SaleDate, CONVERT(Date,SaleDate)
FROM [PortfolioProject].dbo.NashvilleHousing

--BEGIN TRANSACTION
UPDATE  NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateFormatted Date;

UPDATE NashvilleHousing
SET SaleDateFormatted = CONVERT(Date,SaleDate)

--ROLLBACK TRANSACTION

---------------------------------------------------------


--[2]Populate PropertyAddress Data

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT A.ParcelID,A.PropertyAddress,B.ParcelID,B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM [PortfolioProject]..NashvilleHousing A
JOIN [PortfolioProject]..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ] 
WHERE A.PropertyAddress IS NULL


		--Populating PropertyAddress
--BEGIN TRANSACTION 
UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM [PortfolioProject]..NashvilleHousing A
JOIN [PortfolioProject]..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ] 
WHERE A.PropertyAddress IS NULL

--COMMIT TRANSACTION
--ROLLBACK TRANSACTION

-----------------------------------------------------------------

--Breaking out Address into individual columns (Address,City and State)

SELECT PropertyAddress, 
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM NashvilleHousing
ORDER BY ParcelID


ALTER TABLE [PortfolioProject]..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE [PortfolioProject]..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE [PortfolioProject]..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE [PortfolioProject]..NashvilleHousing
SET PropertySplitCity =SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))


SELECT OwnerAddress
FROM NashvilleHousing

SELECT OwnerAddress, PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
					 PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
					 PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL

ALTER TABLE [PortfolioProject]..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE [PortfolioProject]..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

ALTER TABLE [PortfolioProject]..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE [PortfolioProject]..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

ALTER TABLE [PortfolioProject]..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE [PortfolioProject]..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)



---------------------------------------------------------------

--Change Y and N to Yes and No in SoldAsVacant field.

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)
FROM [PortfolioProject].dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
	WHen SoldAsVacant = 'Y' THEN  'Yes'
	WHEN SoldAsVacant = 'N' THEN  'No'
	ELSE SoldAsVacant 
END AS CorrectedCol
FROM [PortfolioProject].dbo.NashvilleHousing


--BEGIN TRANSACTION
UPDATE [PortfolioProject].dbo.NashvilleHousing
SET SoldAsVacant =
	CASE
		WHen SoldAsVacant = 'Y' THEN  'Yes'
		WHEN SoldAsVacant = 'N' THEN  'No'
		ELSE SoldAsVacant 
	END 

--COMMIT TRANSACTION

---------------------------------------------------------------

--Removve Duplicates (duplicate records)

With RowNumCTE AS (
	SELECT *,
	ROW_NUMBER() OVER 
	(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 LegalReference,
				 SalePrice,
				 SaleDate
				 ORDER BY 
					UniqueID
		) RowNum
	FROM [PortfolioProject].dbo.NashvilleHousing
) 
SELECT * 
--DELETE
FROM RowNumCTE
WHERE RowNum > 1

---------------------------------------------------------------

--Delete  Unused Columns

exec sp_getTable 'NashvilleHousing'

ALTER TABLE [PortfolioProject].dbo.NashvilleHousing
DROP COLUMN PropertyAddress,TaxDistrict,OwnerAddress,SaleDate



