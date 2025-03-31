-- Eðer "trg_RandevuDoktorKontrol" adýnda bir tetikleyici varsa, önce bu tetikleyiciyi sil.
IF OBJECT_ID('trg_RandevuDoktorKontrol', 'TR') IS NOT NULL
    DROP TRIGGER trg_RandevuDoktorKontrol;
GO

-- "trg_RandevuDoktorKontrol" tetikleyicisi oluþturuluyor.
-- Bu tetikleyici, tblRandevu tablosuna ekleme veya güncelleme iþlemlerinde,
-- ayný gün içinde ayný doktordan birden fazla randevu alýnmasýný engeller.
CREATE TRIGGER trg_RandevuDoktorKontrol
ON tblRandevu
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- TRANSACTION baþlat
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Ayný gün, ayný doktordan alýnan randevularýn kontrolü
        IF EXISTS (
            SELECT 1
            FROM INSERTED I
            WHERE EXISTS (
                SELECT 1
                FROM tblRandevu R
                WHERE R.DoktorID = I.DoktorID
                  AND CAST(R.Randevu_Tarihi AS DATE) = CAST(I.Randevu_Tarihi AS DATE)
                  AND R.HastaID = I.HastaID
                  AND R.ID <> I.ID -- Farklý randevu ID'lerine bakýlýr
            )
        )
        BEGIN
            -- Ayný doktordan ayný gün içinde birden fazla randevu varsa rollback yap
            RAISERROR ('Ayný gün içinde ayný doktordan birden fazla randevu alýnamaz.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- TRANSACTION tamamla
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

-- tblRandevu tablosundaki tüm kayýtlarý görüntüleyin:
SELECT *
FROM HASTANE.dbo.tblRandevu;

-- Test senaryolarý:

-- Baþarýlý bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', -- Hasta Ahmet Yýlmaz
    @HastaneID = 1,           -- Hastane ID (tblPersonel tablosunda olmalý)
    @RandevuTarihi = '2024-12-28', -- Gelecek bir tarih
    @RandevuSaati = '13:00:00',   -- Uygun bir saat
    @DoktorID = 1,                -- Doktor ID (tblPersonel tablosunda olmalý)
    @RandevuTuruID = 1;           -- Randevu türü ID (tblBolumTuru veya ilgili tabloya göre)

-- Baþarýsýz bir randevu ekleme testi
-- Ayný doktordan ayný gün içinde ikinci bir randevu almayý deneyecek.
-- "Ayný gün içinde ayný doktordan birden fazla randevu alýnamaz." hatasý bekleniyor.
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', -- Hasta Ahmet Yýlmaz
    @HastaneID = 1,           -- Hastane ID (tblPersonel tablosunda olmalý)
    @RandevuTarihi = '2024-12-28', -- Ayný gün
    @RandevuSaati = '11:00:00',   -- Farklý bir saat
    @DoktorID = 1,                -- Ayný doktor
    @RandevuTuruID = 1;           -- Randevu türü ID