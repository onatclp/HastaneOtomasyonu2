	--INDEX 
			--Aktif edilmemesinin sebebi di�er verileri bozmas�d�r.
			--Aktif edip index denenebilir. Ekran g�r�nt�leri iletilmi�tir. 


-- �ok say�da veri eklemek i�in d�ng�yle INSERT i�lemi
DECLARE @i INT = 1;
WHILE @i <= 10000
BEGIN
    INSERT INTO tblRANDEVU (Randevu_Tarihi, Randevu_Saati, TuruID, Calisma_TakvimiID, HastaID, DoktorID)
    VALUES 
    (DATEADD(DAY, @i % 30, '2024-12-01'), 
     CAST((8 + (@i % 10)) AS VARCHAR) + ':00:00', 
     (@i % 3) + 1, 
     (@i % 5) + 1, 
     '1234567890' + CAST(@i % 5 + 1 AS VARCHAR), 
     (@i % 5) + 1);
    SET @i = @i + 1;
 END;

ALTER TABLE tblRANDEVU CHECK CONSTRAINT ALL;


CREATE NONCLUSTERED INDEX IX_Randevu_Tarihi
ON tblRANDEVU (Randevu_Tarihi);
GO

SET STATISTICS IO ON;

-- INDEX olmadan sorgu �al��t�r
SELECT ID, Randevu_Tarihi, Randevu_Saati
FROM tblRANDEVU
WHERE Randevu_Tarihi = '2024-12-31';

SET STATISTICS IO OFF;
