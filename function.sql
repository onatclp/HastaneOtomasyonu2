-- "fnKalanGun" fonksiyonu, bir hastan�n gelecekteki en yak�n randevusuna ka� g�n kald���n� hesaplar.
-- E�er "fnKalanGun" ad�nda bir fonksiyon varsa, �nce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnKalanGun', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnKalanGun;
GO

-- E�er "fnOncekiRandevu" ad�nda bir fonksiyon varsa, �nce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnOncekiRandevu', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnOncekiRandevu;
GO

-- E�er "fnRandevuDurumu" ad�nda bir fonksiyon varsa, �nce bu fonksiyonu sil.
IF OBJECT_ID('dbo.fnRandevuDurumu', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fnRandevuDurumu;
GO

CREATE FUNCTION fnKalanGun(@HastaID CHAR(11))
RETURNS INT
AS
BEGIN
    DECLARE @KalanGun INT;

    -- En yak�n gelecekteki randevu tarihine g�n cinsinden kalan s�reyi hesapla
    SELECT TOP 1
        @KalanGun = DATEDIFF(DAY, GETDATE(), Randevu_Tarihi)
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi > GETDATE() -- Gelecekteki randevular
    ORDER BY Randevu_Tarihi ASC; -- En yak�n tarih

    RETURN ISNULL(@KalanGun, -1); -- E�er NULL ise -1 d�nd�r (varsay�lan de�er)
END;
GO

-- "fnOncekiRandevu" fonksiyonu, bir hastan�n ge�mi�teki en son randevusundan bu yana ge�en g�n say�s�n� hesaplar.
CREATE FUNCTION fnOncekiRandevu(@HastaID CHAR(11))
RETURNS INT
AS
BEGIN
    DECLARE @GecenGun INT;

    -- Ge�mi�teki en son randevu tarihine g�re g�n cinsinden ge�en s�reyi hesapla
    SELECT TOP 1
        @GecenGun = DATEDIFF(DAY, Randevu_Tarihi, GETDATE())
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi < GETDATE() -- Ge�mi� randevular
    ORDER BY Randevu_Tarihi DESC; -- En son tarih

    RETURN ISNULL(@GecenGun, -1); -- E�er NULL ise -1 d�nd�r (varsay�lan de�er)
END;
GO

-- "fnRandevuDurumu" fonksiyonu, bir hastan�n ge�mi� randevular�na ait en son durumu d�nd�r�r.
CREATE FUNCTION fnRandevuDurumu(@HastaID CHAR(11))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @Durum VARCHAR(50);

    -- Ge�mi� randevular aras�nda en son durumu belirle
    SELECT TOP 1
        @Durum = CASE 
                    WHEN GeldiMi = 1 THEN 'Geldi'                     -- Hasta randevuya geldi
                    WHEN OnlineIptal = 1 THEN '�ptal Edildi'          -- Hasta randevuyu iptal etti
                    WHEN GeldiMi = 0 AND OnlineIptal = 0 THEN 'Cezal�' -- Gelmedi ve iptal etmedi
                    ELSE 'Durum Yok'
                 END
    FROM tblRandevu
    WHERE HastaID = @HastaID
      AND Randevu_Tarihi < GETDATE() -- Ge�mi� randevular� kontrol et
      AND (GeldiMi IS NOT NULL AND OnlineIptal IS NOT NULL) -- NULL de�erleri d��la
    ORDER BY Randevu_Tarihi DESC, Randevu_Saati DESC; -- En son ge�mi� randevuyu kontrol et

    -- E�er durum atanmad�ysa, varsay�lan olarak 'Durum Yok' yap
    IF @Durum IS NULL
        SET @Durum = 'Durum Yok';

    RETURN @Durum;
END;
GO
-- fnKalanGun fonksiyonu ile bir hastan�n en yak�n gelecekteki randevusuna kalan g�n say�s�n� hesapla
SELECT dbo.fnKalanGun('12345678901') AS KalanGun;

-- fnOncekiRandevu fonksiyonu ile bir hastan�n ge�mi� en son randevusundan ge�en g�n say�s�n� hesapla
SELECT dbo.fnOncekiRandevu('12345678984') AS GecenGun;

-- fnRandevuDurumu fonksiyonu ile bir hastan�n ge�mi� randevular�na ait en son durumu belirle
SELECT dbo.fnRandevuDurumu('12345678902') AS Durum;