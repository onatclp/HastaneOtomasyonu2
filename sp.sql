-- Eðer "sp_RandevuEkle" adýnda bir prosedür varsa, önce bu prosedürü sil.
IF OBJECT_ID('sp_RandevuEkle', 'P') IS NOT NULL
    DROP PROCEDURE sp_RandevuEkle;
GO

-- "sp_RandevuEkle" prosedürü oluþturuluyor.
-- Bu prosedür, bir hastaya belirli kurallar çerçevesinde randevu eklemek için kullanýlýr.
CREATE PROCEDURE sp_RandevuEkle
    @HastaID CHAR(11), -- Hastanýn TC Kimlik numarasý
    @HastaneID INT, -- Randevu alýnacak hastane ID'si
    @RandevuTarihi DATE, -- Randevu tarihi
    @RandevuSaati TIME, -- Randevu saati
    @DoktorID INT, -- Randevu alýnacak doktor ID'si
    @RandevuTuruID INT -- Randevu türü ID'si
AS
BEGIN
    -- Ýþleme baþlamak için transaction baþlatýlýr
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Ayný gün, ayný hastaneden alýnan randevu sayýsýný kontrol et
        DECLARE @GunlukRandevuSayisi INT;

        SELECT @GunlukRandevuSayisi = COUNT(*)
        FROM tblRandevu R
        JOIN tblPersonel P ON R.DoktorID = P.ID
        WHERE R.HastaID = @HastaID
          AND CAST(R.Randevu_Tarihi AS DATE) = @RandevuTarihi
          AND P.HastanesiID = @HastaneID;

        -- Eðer 2'den fazla randevu varsa hata döndür
        IF @GunlukRandevuSayisi >= 2
        BEGIN
            RAISERROR ('Ayný gün içinde ayný hastaneden 2''den fazla randevu alamazsýnýz.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Randevu kaydýný ekle
        INSERT INTO tblRandevu (Randevu_Tarihi, Randevu_Saati, TuruID, HastaID, DoktorID, Calisma_TakvimiID)
        VALUES (
            @RandevuTarihi, 
            @RandevuSaati, 
            @RandevuTuruID, 
            @HastaID, 
            @DoktorID, 
            (SELECT TOP 1 ID FROM tblCalismaTakvimi WHERE Tarih = @RandevuTarihi)
        );

        -- Hasta tablosunu güncelle
        UPDATE tbl_HASTA
        SET RandevuSayisi = (SELECT COUNT(*) FROM tblRandevu WHERE HastaID = @HastaID),
            EnYakinRandevuTarihi = (SELECT MIN(Randevu_Tarihi)
                                FROM tblRandevu 
                                WHERE HastaID = @HastaID AND Randevu_Tarihi >= GETDATE())
        WHERE TC_NO = @HastaID;

        -- Ýþlemi tamamla
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Hata durumunda rollback yap
        ROLLBACK TRANSACTION;

        -- Hata mesajýný göster
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Test kodlarý ve açýklamalarý:

-- 1. Veritabanýndaki tablo bilgilerini kontrol edin:
SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblRandevu';

-- 2. tblRandevu tablosundaki tüm kayýtlarý listeleyin:
SELECT *
FROM HASTANE.dbo.tblRandevu;

-- 3. Randevu ekleme prosedürünü test edin:

-- Baþarýlý bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '10:00', 
    @DoktorID = 1, 
    @RandevuTuruID = 1;

-- Baþarýlý bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '11:00', 
    @DoktorID = 2, 
    @RandevuTuruID = 1;

-- Baþarýsýz bir randevu ekleme testi
-- Bu iþlem, ayný gün ayný hastaneden 2'den fazla randevu almayý deneyecek.
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', 
    @HastaneID = 1, 
    @RandevuTarihi = '2025-01-31', 
    @RandevuSaati = '12:00', 
    @DoktorID = 3, 
    @RandevuTuruID = 1;