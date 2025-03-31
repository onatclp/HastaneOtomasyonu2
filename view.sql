-- Eðer "vwHastaDetayRaporu" adýnda bir görünüm varsa, önce bu görünümü sil.
IF OBJECT_ID('vwHastaDetayRaporu', 'V') IS NOT NULL
    DROP VIEW vwHastaDetayRaporu;
GO

-- "vwHastaDetayRaporu" adýnda bir görünüm oluþturuluyor.
-- Bu görünüm, hastalarýn detaylý bilgilerini raporlama amacýyla kullanýlýr.
CREATE VIEW vwHastaDetayRaporu AS
SELECT
    h.TC_NO AS HastaTC, -- Hastanýn TC kimlik numarasý
    CONCAT(h.Ad, ' ', h.Soyad) AS HastaAdSoyad, -- Hastanýn tam adý
    i.Il_Adý AS Il, -- Hastanýn baðlý olduðu il
    bt.Bolum_Adi AS Departman, -- Hastanýn baþvurduðu bölüm
    dbo.fnOncekiRandevu(h.TC_NO) AS GecenGun, -- Son randevudan bu yana geçen gün sayýsý
    dbo.fnKalanGun(h.TC_NO) AS KalanGun, -- Gelecek randevuya kalan gün sayýsý
    dbo.fnRandevuDurumu(h.TC_NO) AS RandevuDurumu, -- Hastanýn en son randevu durum bilgisi
    FORMAT(r.Randevu_Tarihi, 'dd/MM/yyyy') AS SonRandevuTarihi -- Son randevu tarihi
FROM
    tbl_HASTA h
    LEFT JOIN tblRandevu r ON h.TC_NO = r.HastaID -- Hastalarýn randevu bilgileri ile eþleþtirilmesi
    LEFT JOIN tblIL i ON h.ILID = i.Kod -- Hastalarýn baðlý olduklarý iller ile eþleþtirilmesi
    LEFT JOIN tblBolumTuru bt ON r.TuruID = bt.ID -- Randevu türüyle bölümler eþleþtirilir
    LEFT JOIN tblPersonel p ON r.DoktorID = p.ID -- Randevularýn doktor bilgileri ile eþleþtirilmesi
    LEFT JOIN tblHastane hs ON p.HastanesiID = hs.ID -- Doktorlarýn çalýþtýðý hastaneler ile eþleþtirilmesi
WHERE
    EXISTS (
        SELECT 1
        FROM tblRandevu r2
        WHERE r2.HastaID = h.TC_NO
    ); -- Hastanýn geçmiþte en az bir randevusunun bulunup bulunmadýðýný kontrol eder
GO

-- Ýl bazýnda cezalý hastalarý listeleyen sorgu
-- Bu sorgu, "vwHastaDetayRaporu" görünümünden faydalanýr.
SELECT
    vw.Il, -- Ýl adý
    COUNT(vw.HastaTC) AS CezaliHastaSayisi -- Cezalý hasta sayýsý
FROM
    vwHastaDetayRaporu vw
INNER JOIN tblRandevu r ON vw.HastaTC = r.HastaID -- Hastalarýn randevu bilgileri ile eþleþtirilmesi
INNER JOIN tblIL i ON vw.Il = i.Il_Adý -- Görünümdeki il bilgisi ile gerçek il tablolarýnýn eþleþtirilmesi
WHERE
    vw.RandevuDurumu = 'Cezalý' -- Randevu durumu "Cezalý" olan hastalar
GROUP BY
    vw.Il; -- Ýl bazýnda gruplama

-- Departman bazýnda cezalý hastalarý listeleyen sorgu
-- Bu sorgu da "vwHastaDetayRaporu" görünümünü kullanýr.
SELECT
    vw.Departman, -- Departman adý
    COUNT(vw.HastaTC) AS CezaliHastaSayisi -- Cezalý hasta sayýsý
FROM
    vwHastaDetayRaporu vw
INNER JOIN tblRandevu r ON vw.HastaTC = r.HastaID -- Hastalarýn randevu bilgileri ile eþleþtirilmesi
INNER JOIN tblBolumTuru bt ON vw.Departman = bt.Bolum_Adi -- Görünümdeki departman bilgisiyle gerçek bölümlerin eþleþtirilmesi
WHERE
    vw.RandevuDurumu = 'Cezalý' -- Randevu durumu "Cezalý" olan hastalar
GROUP BY
    vw.Departman; -- Departman bazýnda gruplama
GO


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
							--KONTROL ÝÇÝN KULLANDIÐIMIZ KODLAR
SELECT h.TC_NO, h.Ad, h.Soyad, i.Il_Adý, bt.Bolum_Adi
FROM tbl_HASTA h
INNER JOIN tblRandevu r ON h.TC_NO = r.HastaID
INNER JOIN tblIL i ON h.ILID = i.Kod
INNER JOIN tblBolumTuru bt ON r.TuruID = bt.ID;

SELECT * FROM tbl_HASTA h
INNER JOIN tblRandevu r ON h.TC_NO = r.HastaID;

SELECT *
FROM tblRandevu
WHERE Randevu_Tarihi < GETDATE(); -- Geçmiþ randevular