-- E�er "trg_RandevuDoktorKontrol" ad�nda bir tetikleyici varsa, �nce bu tetikleyiciyi sil.
IF OBJECT_ID('trg_RandevuDoktorKontrol', 'TR') IS NOT NULL
    DROP TRIGGER trg_RandevuDoktorKontrol;
GO

-- "trg_RandevuDoktorKontrol" tetikleyicisi olu�turuluyor.
-- Bu tetikleyici, tblRandevu tablosuna ekleme veya g�ncelleme i�lemlerinde,
-- ayn� g�n i�inde ayn� doktordan birden fazla randevu al�nmas�n� engeller.
CREATE TRIGGER trg_RandevuDoktorKontrol
ON tblRandevu
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- TRANSACTION ba�lat
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Ayn� g�n, ayn� doktordan al�nan randevular�n kontrol�
        IF EXISTS (
            SELECT 1
            FROM INSERTED I
            WHERE EXISTS (
                SELECT 1
                FROM tblRandevu R
                WHERE R.DoktorID = I.DoktorID
                  AND CAST(R.Randevu_Tarihi AS DATE) = CAST(I.Randevu_Tarihi AS DATE)
                  AND R.HastaID = I.HastaID
                  AND R.ID <> I.ID -- Farkl� randevu ID'lerine bak�l�r
            )
        )
        BEGIN
            -- Ayn� doktordan ayn� g�n i�inde birden fazla randevu varsa rollback yap
            RAISERROR ('Ayn� g�n i�inde ayn� doktordan birden fazla randevu al�namaz.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- TRANSACTION tamamla
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

-- tblRandevu tablosundaki t�m kay�tlar� g�r�nt�leyin:
SELECT *
FROM HASTANE.dbo.tblRandevu;

-- Test senaryolar�:

-- Ba�ar�l� bir randevu ekleme testi
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', -- Hasta Ahmet Y�lmaz
    @HastaneID = 1,           -- Hastane ID (tblPersonel tablosunda olmal�)
    @RandevuTarihi = '2024-12-28', -- Gelecek bir tarih
    @RandevuSaati = '13:00:00',   -- Uygun bir saat
    @DoktorID = 1,                -- Doktor ID (tblPersonel tablosunda olmal�)
    @RandevuTuruID = 1;           -- Randevu t�r� ID (tblBolumTuru veya ilgili tabloya g�re)

-- Ba�ar�s�z bir randevu ekleme testi
-- Ayn� doktordan ayn� g�n i�inde ikinci bir randevu almay� deneyecek.
-- "Ayn� g�n i�inde ayn� doktordan birden fazla randevu al�namaz." hatas� bekleniyor.
EXEC sp_RandevuEkle 
    @HastaID = '12345678918', -- Hasta Ahmet Y�lmaz
    @HastaneID = 1,           -- Hastane ID (tblPersonel tablosunda olmal�)
    @RandevuTarihi = '2024-12-28', -- Ayn� g�n
    @RandevuSaati = '11:00:00',   -- Farkl� bir saat
    @DoktorID = 1,                -- Ayn� doktor
    @RandevuTuruID = 1;           -- Randevu t�r� ID