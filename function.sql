-- "fnKalanGun" fonksiyonu, bir hastanýn gelecekteki en yakýn randevusuna kaç gün kaldýðýný hesaplar.
-- Eðer "fnKalanGun" adýnda bir fonksiyon varsa, önce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnKalanGun', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnKalanGun;
GO

-- Eðer "fnOncekiRandevu" adýnda bir fonksiyon varsa, önce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnOncekiRandevu', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnOncekiRandevu;
GO

-- Eðer "fnRandevuDurumu" adýnda bir fonksiyon varsa, önce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnRandevuDurumu', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnRandevuDurumu;
GO

CREATE FUNCTION fnKalanGun(@HastaID CHAR(11))
RETURNS INT
AS
BEGIN
    DECLARE @KalanGun INT;

    -- En yakýn gelecekteki randevu tarihine gün cinsinden kalan süreyi hesapla
    SELECT TOP 1
        @KalanGun = DATEDIFF(DAY, GETDATE(), Randevu_Tarihi)
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi > GETDATE() -- Gelecekteki randevular
    ORDER BY Randevu_Tarihi ASC; -- En yakýn tarih

    RETURN ISNULL(@KalanGun, -1); -- Eðer NULL ise -1 döndür (varsayýlan deðer)
END;
GO

-- "fnOncekiRandevu" fonksiyonu, bir hastanýn geçmiþteki en son randevusundan bu yana geçen gün sayýsýný hesaplar.
CREATE FUNCTION fnOncekiRandevu(@HastaID CHAR(11))
RETURNS INT
AS
BEGIN
    DECLARE @GecenGun INT;

    -- Geçmiþteki en son randevu tarihine göre gün cinsinden geçen süreyi hesapla
    SELECT TOP 1
        @GecenGun = DATEDIFF(DAY, Randevu_Tarihi, GETDATE())
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi < GETDATE() -- Geçmiþ randevular
    ORDER BY Randevu_Tarihi DESC; -- En son tarih

    RETURN ISNULL(@GecenGun, -1); -- Eðer NULL ise -1 döndür (varsayýlan deðer)
END;
GO

-- "fnRandevuDurumu" fonksiyonu, bir hastanýn geçmiþ randevularýna ait en son durumu döndürür.
CREATE FUNCTION fnRandevuDurumu(@HastaID CHAR(11))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @Durum VARCHAR(50);

    -- Geçmiþ randevular arasýnda en son durumu belirle
    SELECT TOP 1
        @Durum = CASE 
                    WHEN GeldiMi = 1 THEN 'Geldi'                     -- Hasta randevuya geldi
                    WHEN OnlineIptal = 1 THEN 'Ýptal Edildi'          -- Hasta randevuyu iptal etti
                    WHEN GeldiMi = 0 AND OnlineIptal = 0 THEN 'Cezalý' -- Gelmedi ve iptal etmedi
                    ELSE 'Durum Yok'
                 END
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi < GETDATE() -- Geçmiþ randevularý kontrol et
      AND (GeldiMi IS NOT NULL AND OnlineIptal IS NOT NULL) -- NULL deðerleri dýþla
    ORDER BY Randevu_Tarihi DESC, Randevu_Saati DESC; -- En son geçmiþ randevuyu kontrol et

    -- Eðer durum atanmadýysa, varsayýlan olarak 'Durum Yok' yap
    IF @Durum IS NULL
        SET @Durum = 'Durum Yok';

    RETURN @Durum;
END;
GO
-- fnKalanGun fonksiyonu ile bir hastanýn en yakýn gelecekteki randevusuna kalan gün sayýsýný hesapla
SELECT dbo.fnKalanGun('12345678901') AS KalanGun;

-- fnOncekiRandevu fonksiyonu ile bir hastanýn geçmiþ en son randevusundan geçen gün sayýsýný hesapla
SELECT dbo.fnOncekiRandevu('12345678984') AS GecenGun;

-- fnRandevuDurumu fonksiyonu ile bir hastanýn geçmiþ randevularýna ait en son durumu belirle
SELECT dbo.fnRandevuDurumu('12345678902') AS Durum;