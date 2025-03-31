-- E�er "vwHastaDetayRaporu" ad�nda bir g�r�n�m varsa, �nce bu g�r�n�m� sil.
IF OBJECT_ID('vwHastaDetayRaporu', 'V') IS NOT NULL
    DROP VIEW vwHastaDetayRaporu;
GO

-- "vwHastaDetayRaporu" ad�nda bir g�r�n�m olu�turuluyor.
-- Bu g�r�n�m, hastalar�n detayl� bilgilerini raporlama amac�yla kullan�l�r.
CREATE VIEW vwHastaDetayRaporu AS
SELECT
    h.TC_NO AS HastaTC, -- Hastan�n TC kimlik numaras�
    CONCAT(h.Ad, ' ', h.Soyad) AS HastaAdSoyad, -- Hastan�n tam ad�
    i.Il_Ad� AS Il, -- Hastan�n ba�l� oldu�u il
    bt.Bolum_Adi AS Departman, -- Hastan�n ba�vurdu�u b�l�m
    dbo.fnOncekiRandevu(h.TC_NO) AS GecenGun, -- Son randevudan bu yana ge�en g�n say�s�
    dbo.fnKalanGun(h.TC_NO) AS KalanGun, -- Gelecek randevuya kalan g�n say�s�
    dbo.fnRandevuDurumu(h.TC_NO) AS RandevuDurumu, -- Hastan�n en son randevu durum bilgisi
    FORMAT(r.Randevu_Tarihi, 'dd/MM/yyyy') AS SonRandevuTarihi -- Son randevu tarihi
FROM
    tbl_HASTA h
    LEFT JOIN tblRandevu r ON h.TC_NO = r.HastaID -- Hastalar�n randevu bilgileri ile e�le�tirilmesi
    LEFT JOIN tblIL i ON h.ILID = i.Kod -- Hastalar�n ba�l� olduklar� iller ile e�le�tirilmesi
    LEFT JOIN tblBolumTuru bt ON r.TuruID = bt.ID -- Randevu t�r�yle b�l�mler e�le�tirilir
    LEFT JOIN tblPersonel p ON r.DoktorID = p.ID -- Randevular�n doktor bilgileri ile e�le�tirilmesi
    LEFT JOIN tblHastane hs ON p.HastanesiID = hs.ID -- Doktorlar�n �al��t��� hastaneler ile e�le�tirilmesi
WHERE
    EXISTS (
        SELECT 1
        FROM tblRandevu r2
        WHERE r2.HastaID = h.TC_NO
    ); -- Hastan�n ge�mi�te en az bir randevusunun bulunup bulunmad���n� kontrol eder
GO

-- �l baz�nda cezal� hastalar� listeleyen sorgu
-- Bu sorgu, "vwHastaDetayRaporu" g�r�n�m�nden faydalan�r.
SELECT
    vw.Il, -- �l ad�
    COUNT(vw.HastaTC) AS CezaliHastaSayisi -- Cezal� hasta say�s�
FROM
    vwHastaDetayRaporu vw
INNER JOIN tblRandevu r ON vw.HastaTC = r.HastaID -- Hastalar�n randevu bilgileri ile e�le�tirilmesi
INNER JOIN tblIL i ON vw.Il = i.Il_Ad� -- G�r�n�mdeki il bilgisi ile ger�ek il tablolar�n�n e�le�tirilmesi
WHERE
    vw.RandevuDurumu = 'Cezal�' -- Randevu durumu "Cezal�" olan hastalar
GROUP BY
    vw.Il; -- �l baz�nda gruplama

-- Departman baz�nda cezal� hastalar� listeleyen sorgu
-- Bu sorgu da "vwHastaDetayRaporu" g�r�n�m�n� kullan�r.
SELECT
    vw.Departman, -- Departman ad�
    COUNT(vw.HastaTC) AS CezaliHastaSayisi -- Cezal� hasta say�s�
FROM
    vwHastaDetayRaporu vw
INNER JOIN tblRandevu r ON vw.HastaTC = r.HastaID -- Hastalar�n randevu bilgileri ile e�le�tirilmesi
INNER JOIN tblBolumTuru bt ON vw.Departman = bt.Bolum_Adi -- G�r�n�mdeki departman bilgisiyle ger�ek b�l�mlerin e�le�tirilmesi
WHERE
    vw.RandevuDurumu = 'Cezal�' -- Randevu durumu "Cezal�" olan hastalar
GROUP BY
    vw.Departman; -- Departman baz�nda gruplama
GO


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
							--KONTROL ���N KULLANDI�IMIZ KODLAR
SELECT h.TC_NO, h.Ad, h.Soyad, i.Il_Ad�, bt.Bolum_Adi
FROM tbl_HASTA h
INNER JOIN tblRandevu r ON h.TC_NO = r.HastaID
INNER JOIN tblIL i ON h.ILID = i.Kod
INNER JOIN tblBolumTuru bt ON r.TuruID = bt.ID;

SELECT * FROM tbl_HASTA h
INNER JOIN tblRandevu r ON h.TC_NO = r.HastaID;

SELECT *
FROM tblRandevu
WHERE Randevu_Tarihi < GETDATE(); -- Ge�mi� randevular