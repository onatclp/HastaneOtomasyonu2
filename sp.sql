-- E�er "sp_RandevuEkle" ad�nda bir prosed�r varsa, �nce bu prosed�r� sil.
IF OBJECT_ID('sp_RandevuEkle', 'P') IS NOT NULL
    DROP PROCEDURE sp_RandevuEkle;
GO

-- "sp_RandevuEkle" prosed�r� olu�turuluyor.
-- Bu prosed�r, bir hastaya belirli kurallar �er�evesinde randevu eklemek i�in kullan�l�r.
CREATE PROCEDURE sp_RandevuEkle
    @HastaID CHAR(11), -- Hastan�n TC Kimlik numaras�
    @HastaneID INT, -- Randevu al�nacak hastane ID'si
    @RandevuTarihi DATE, -- Randevu tarihi
    @RandevuSaati TIME, -- Randevu saati
    @DoktorID INT, -- Randevu al�nacak doktor ID'si
    @RandevuTuruID INT -- Randevu t�r� ID'si
AS
BEGIN
    -- ��leme ba�lamak i�in transaction ba�lat�l�r
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Ayn� g�n, ayn� hastaneden al�nan randevu say�s�n� kontrol et
        DECLARE @GunlukRandevuSayisi INT;

        SELECT @GunlukRandevuSayisi = COUNT(*)
        FROM tblRandevu R
        JOIN tblPersonel P ON R.DoktorID = P.ID
        WHERE R.HastaID = @HastaID
          AND CAST(R.Randevu_Tarihi AS DATE) = @RandevuTarihi
          AND P.HastanesiID = @HastaneID;

        -- E�er 2'den fazla randevu varsa hata d�nd�r
        IF @GunlukRandevuSayisi >= 2
        BEGIN
            RAISERROR ('Ayn� g�n i�inde ayn� hastaneden 2''den fazla randevu alamazs�n�z.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Randevu kayd�n� ekle
        INSERT INTO tblRandevu (Randevu_Tarihi, Randevu_Saati, TuruID, HastaID, DoktorID, Calisma_TakvimiID)
        VALUES (
            @RandevuTarihi, 
            @RandevuSaati, 
            @RandevuTuruID, 
            @HastaID, 
            @DoktorID, 
            (SELECT TOP 1 ID FROM tblCalismaTakvimi WHERE Tarih = @RandevuTarihi)
        );

        -- Hasta tablosunu g�ncelle
        UPDATE tbl_HASTA
        SET RandevuSayisi = (SELECT COUNT(*) FROM tblRandevu WHERE HastaID = @HastaID),
            EnYakinRandevuTarihi = (SELECT MIN(Randevu_Tarihi)
                                FROM tblRandevu 
                                WHERE HastaID = @HastaID AND Randevu_Tarihi >= GETDATE())
        WHERE TC_NO = @HastaID;

        -- ��lemi tamamla
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Hata durumunda rollback yap
        ROLLBACK TRANSACTION;

        -- Hata mesaj�n� g�ster
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Test kodlar� ve a��klamalar�:

-- 1. Veritaban�ndaki tablo bilgilerini kontrol edin:
SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblRandevu';

-- 2. tblRandevu tablosundaki t�m kay�tlar� listeleyin:
SELECT *
FROM HASTANE.dbo.tblRandevu;

-- 3. Randevu ekleme prosed�r�n� test edin:

-- Ba�ar�l� bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '10:00', 
    @DoktorID = 1, 
    @RandevuTuruID = 1;

-- Ba�ar�l� bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '11:00', 
    @DoktorID = 2, 
    @RandevuTuruID = 1;

-- Ba�ar�s�z bir randevu ekleme testi
-- Bu i�lem, ayn� g�n ayn� hastaneden 2'den fazla randevu almay� deneyecek.
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '12:00', 
    @DoktorID = 3, 
    @RandevuTuruID = 1;