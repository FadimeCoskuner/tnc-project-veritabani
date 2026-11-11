/* =====================================================================
   NovaStore E-Ticaret Veri Yönetim Sistemi
   Hazırlayan : Fadime Coşkuner Mutlu
   Platform   : Microsoft SQL Server (2014 ve üzeri)

   Dosya baştan sona tek seferde çalıştırılabilir (SSMS'te F5).
   Her çalıştırmada NovaStoreDB silinip yeniden kurulur; böylece
   sonuçlar her seferinde aynı çıkar.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 1: VERİ TABANI TASARIMI (DDL)
   ===================================================================== */

-- 1. Veri tabanını oluşturma
USE master;
GO

-- Daha önce oluşturulduysa önce bağlantıları kapatıp siliyoruz.
IF DB_ID('NovaStoreDB') IS NOT NULL
BEGIN
    ALTER DATABASE NovaStoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NovaStoreDB;
END
GO

-- Turkish_CI_AS: Türkçe karakterler (ç, ğ, ı, İ, ö, ş, ü) varchar alanlarda doğru saklanır
-- ve sıralamalar Türkçe alfabeye göre yapılır.
CREATE DATABASE NovaStoreDB COLLATE Turkish_CI_AS;
GO

USE NovaStoreDB;
GO

-- 2. Tablolar
-- Önce ana tablolar (Categories, Customers), sonra onlara bağlı tablolar oluşturulur.

-- A. Kategoriler
CREATE TABLE Categories (
    CategoryID   INT IDENTITY(1,1) CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL
);

-- C. Müşteriler
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) CONSTRAINT PK_Customers PRIMARY KEY,
    FullName   VARCHAR(50),
    City       VARCHAR(20),
    Email      VARCHAR(100) CONSTRAINT UQ_Customers_Email UNIQUE
);

-- B. Ürünler (Categories tablosuna bağlı)
CREATE TABLE Products (
    ProductID   INT IDENTITY(1,1) CONSTRAINT PK_Products PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price       DECIMAL(10,2),
    Stock       INT CONSTRAINT DF_Products_Stock DEFAULT 0,
    CategoryID  INT CONSTRAINT FK_Products_Categories
                    FOREIGN KEY REFERENCES Categories(CategoryID)
);

-- D. Siparişler (Customers tablosuna bağlı)
CREATE TABLE Orders (
    OrderID     INT IDENTITY(1,1) CONSTRAINT PK_Orders PRIMARY KEY,
    CustomerID  INT CONSTRAINT FK_Orders_Customers
                    FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate   DATETIME CONSTRAINT DF_Orders_OrderDate DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2)
);

-- E. Sipariş Detayları (Orders ile Products arasındaki ara tablo)
CREATE TABLE OrderDetails (
    DetailID  INT IDENTITY(1,1) CONSTRAINT PK_OrderDetails PRIMARY KEY,
    OrderID   INT CONSTRAINT FK_OrderDetails_Orders
                  FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT CONSTRAINT FK_OrderDetails_Products
                  FOREIGN KEY REFERENCES Products(ProductID),
    Quantity  INT
);
GO


/* =====================================================================
   BÖLÜM 2: VERİ GİRİŞİ (DML - INSERT)
   ===================================================================== */

-- Görev 1: 5 kategori
INSERT INTO Categories (CategoryName) VALUES
    ('Elektronik'),     -- 1
    ('Giyim'),          -- 2
    ('Kitap'),          -- 3
    ('Kozmetik'),       -- 4
    ('Ev ve Yaşam');    -- 5

-- Görev 2: Her kategoriden ürün olacak şekilde 13 ürün
INSERT INTO Products (ProductName, Price, Stock, CategoryID) VALUES
    ('Kablosuz Kulaklık',      1299.90, 15, 1),  -- 1
    ('Akıllı Saat',            3499.00,  8, 1),  -- 2
    ('Bluetooth Hoparlör',      899.50, 25, 1),  -- 3
    ('Erkek Mont',             1899.00, 12, 2),  -- 4
    ('Kadın Spor Ayakkabı',    1450.00, 30, 2),  -- 5
    ('Pamuklu Tişört',          249.90, 60, 2),  -- 6
    ('Suç ve Ceza',             145.00, 40, 3),  -- 7
    ('Kürk Mantolu Madonna',     95.00, 18, 3),  -- 8
    ('Simyacı',                 120.00,  5, 3),  -- 9
    ('Nemlendirici Krem',       349.90, 22, 4),  -- 10
    ('Parfüm 50 ml',           1150.00,  9, 4),  -- 11
    ('Filtre Kahve Makinesi',  2199.00,  6, 5),  -- 12
    ('Seramik Kupa Seti',       399.00, 35, 5);  -- 13

-- Görev 3: 6 müşteri (e-posta adresleri benzersiz olmak zorunda)
INSERT INTO Customers (FullName, City, Email) VALUES
    ('Ahmet Yılmaz',  'İstanbul', 'ahmet.yilmaz@example.com'),  -- 1
    ('Ayşe Demir',    'Ankara',   'ayse.demir@example.com'),    -- 2
    ('Mehmet Kaya',   'İzmir',    'mehmet.kaya@example.com'),   -- 3
    ('Zeynep Çelik',  'Bursa',    'zeynep.celik@example.com'),  -- 4
    ('Can Öztürk',    'Antalya',  'can.ozturk@example.com'),    -- 5
    ('Elif Arslan',   'İstanbul', 'elif.arslan@example.com');   -- 6 (henüz sipariş vermedi)

-- Görev 4: Farklı tarihlerde 10 sipariş
-- Tarihler 'YYYY-MM-DDTHH:MM:SS' biçiminde yazıldı; bu biçim SQL Server'ın dil ayarından etkilenmez.
-- TotalAmount şimdilik 0; sipariş detayları girildikten sonra hesaplanacak.
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount) VALUES
    (1, '2026-07-05T14:30:00', 0),  -- 1  Ahmet Yılmaz
    (2, '2026-07-18T10:15:00', 0),  -- 2  Ayşe Demir
    (3, '2026-08-02T19:45:00', 0),  -- 3  Mehmet Kaya
    (1, '2026-08-21T09:05:00', 0),  -- 4  Ahmet Yılmaz
    (4, '2026-09-03T16:20:00', 0),  -- 5  Zeynep Çelik
    (5, '2026-09-15T11:40:00', 0),  -- 6  Can Öztürk
    (2, '2026-10-01T13:00:00', 0),  -- 7  Ayşe Demir
    (3, '2026-10-12T20:10:00', 0),  -- 8  Mehmet Kaya
    (1, '2026-10-28T08:55:00', 0),  -- 9  Ahmet Yılmaz
    (4, '2026-11-06T17:35:00', 0);  -- 10 Zeynep Çelik

-- Siparişlere ait detaylar (hangi siparişte hangi üründen kaç adet alındı)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity) VALUES
    (1, 1, 1), (1, 7, 2),
    (2, 5, 1), (2, 6, 3),
    (3, 2, 1),
    (4, 8, 1), (4, 9, 1),
    (5, 10, 2), (5, 11, 1),
    (6, 12, 1), (6, 6, 2),
    (7, 3, 1), (7, 10, 1),
    (8, 4, 1),
    (9, 1, 1), (9, 11, 1),
    (10, 7, 1), (10, 9, 2);

-- Toplam tutarı elle yazmak yerine detaylardan hesaplıyoruz (adet x birim fiyat).
-- Böylece Orders.TotalAmount ile sipariş detayları her zaman tutarlı olur.
UPDATE o
SET o.TotalAmount = t.Toplam
FROM Orders AS o
INNER JOIN (
    SELECT od.OrderID, SUM(od.Quantity * p.Price) AS Toplam
    FROM OrderDetails AS od
    INNER JOIN Products AS p ON p.ProductID = od.ProductID
    GROUP BY od.OrderID
) AS t ON t.OrderID = o.OrderID;
GO


/* =====================================================================
   BÖLÜM 3: SORGULAMA VE ANALİZ (DQL - SELECT ve JOIN)
   ===================================================================== */

-- Soru 1 - Temel Listeleme:
-- Stok miktarı 20'den az olan ürünler, stok miktarına göre azalan sırada.
SELECT ProductName AS [Ürün Adı],
       Stock       AS [Stok]
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;

-- Soru 2 - Veri Birleştirme (INNER JOIN):
-- Hangi müşteri, hangi tarihte, ne tutarında sipariş vermiş?
SELECT c.FullName     AS [Müşteri Adı],
       c.City         AS [Şehir],
       o.OrderDate    AS [Sipariş Tarihi],
       o.TotalAmount  AS [Toplam Tutar]
FROM Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate;

-- Soru 3 - Çoklu Birleştirme ve Detay Raporu:
-- "Ahmet Yılmaz" isimli müşterinin aldığı ürünlerin adı, fiyatı ve kategorisi.
-- Zincir: Customers -> Orders -> OrderDetails -> Products -> Categories
SELECT c.FullName     AS [Müşteri Adı],
       p.ProductName  AS [Ürün Adı],
       p.Price        AS [Fiyat],
       cat.CategoryName AS [Kategori],
       o.OrderDate    AS [Sipariş Tarihi]
FROM Customers AS c
INNER JOIN Orders       AS o   ON o.CustomerID   = c.CustomerID
INNER JOIN OrderDetails AS od  ON od.OrderID     = o.OrderID
INNER JOIN Products     AS p   ON p.ProductID    = od.ProductID
INNER JOIN Categories   AS cat ON cat.CategoryID = p.CategoryID
WHERE c.FullName = 'Ahmet Yılmaz'
ORDER BY o.OrderDate, p.ProductName;

-- Soru 4 - Gruplama ve Aggregate Fonksiyonlar:
-- Her kategoride kaç ürün var?
-- LEFT JOIN sayesinde hiç ürünü olmayan bir kategori de 0 ile listelenir.
SELECT cat.CategoryName    AS [Kategori],
       COUNT(p.ProductID)  AS [Ürün Sayısı]
FROM Categories AS cat
LEFT JOIN Products AS p ON p.CategoryID = cat.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName
ORDER BY [Ürün Sayısı] DESC, cat.CategoryName;

-- Soru 5 - Ciro Analizi:
-- Her müşterinin şirkete kazandırdığı toplam ciro, en çok harcayandan en aza.
SELECT c.FullName          AS [Müşteri Adı],
       COUNT(o.OrderID)    AS [Sipariş Sayısı],
       SUM(o.TotalAmount)  AS [Toplam Ciro]
FROM Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY [Toplam Ciro] DESC;

-- Soru 6 - Zaman Analizi:
-- Bugünün tarihine göre her siparişin üzerinden kaç gün geçtiği.
SELECT o.OrderID                               AS [Sipariş No],
       c.FullName                              AS [Müşteri Adı],
       o.OrderDate                             AS [Sipariş Tarihi],
       DATEDIFF(DAY, o.OrderDate, GETDATE())   AS [Geçen Gün]
FROM Orders AS o
INNER JOIN Customers AS c ON c.CustomerID = o.CustomerID
ORDER BY [Geçen Gün] DESC;
GO


/* =====================================================================
   BÖLÜM 4: İLERİ SEVİYE VERİ TABANI NESNELERİ
   ===================================================================== */

-- 4.1 View: Müşteri adı, sipariş tarihi, ürün adı ve adet bilgisini
-- tek bir tablodaymış gibi getiren görünüm.
-- (CREATE VIEW, bulunduğu grubun ilk komutu olmak zorunda; bu yüzden öncesinde GO var.)
CREATE VIEW vw_SiparisOzet
AS
SELECT c.FullName    AS MusteriAdi,
       o.OrderDate   AS SiparisTarihi,
       p.ProductName AS UrunAdi,
       od.Quantity   AS Adet
FROM Orders AS o
INNER JOIN Customers    AS c  ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails AS od ON od.OrderID   = o.OrderID
INNER JOIN Products     AS p  ON p.ProductID  = od.ProductID;
GO

-- View'ı normal bir tablo gibi sorgulayabiliriz:
SELECT * FROM vw_SiparisOzet ORDER BY SiparisTarihi, UrunAdi;
GO

-- 4.2 Yedekleme komutu dosyanın en sonundadır; yedek, tüm işlemler bittikten sonra alınır.


/* =====================================================================
   EK ÇALIŞMALAR (Yönergede zorunlu olmayan, ek olarak hazırlanan bölüm)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- EK 1: CHECK kısıtları (veri doğruluğu kuralları)
-- Yanlış veri tabloya hiç giremesin diye kurallar ekliyoruz.
-- ---------------------------------------------------------------------
ALTER TABLE Products     ADD CONSTRAINT CK_Products_Price       CHECK (Price >= 0);
ALTER TABLE Products     ADD CONSTRAINT CK_Products_Stock       CHECK (Stock >= 0);
ALTER TABLE OrderDetails ADD CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0);
ALTER TABLE Orders       ADD CONSTRAINT CK_Orders_TotalAmount   CHECK (TotalAmount >= 0);
GO

-- Deneme: Negatif fiyatlı ürün eklemeye çalışınca kural devreye girer.
BEGIN TRY
    INSERT INTO Products (ProductName, Price, Stock, CategoryID)
    VALUES ('Hatalı Ürün', -10, 5, 1);
END TRY
BEGIN CATCH
    PRINT 'Beklenen hata (CHECK kısıtı): ' + ERROR_MESSAGE();
END CATCH;
GO

-- ---------------------------------------------------------------------
-- EK 2: Alt sorgu (Subquery) raporları
-- ---------------------------------------------------------------------

-- 2a. Hiç satılmamış ürünler (NOT EXISTS ile ilişkili alt sorgu)
SELECT p.ProductName AS [Ürün Adı],
       p.Stock       AS [Stok]
FROM Products AS p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails AS od WHERE od.ProductID = p.ProductID
);

-- 2b. Hiç sipariş vermemiş müşteriler (kampanya e-postası için)
SELECT c.FullName AS [Müşteri Adı],
       c.Email    AS [E-posta]
FROM Customers AS c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders AS o WHERE o.CustomerID = c.CustomerID
);

-- 2c. Toplam harcaması, müşteri başına ortalama harcamanın üzerinde olan müşteriler
SELECT c.FullName         AS [Müşteri Adı],
       SUM(o.TotalAmount) AS [Toplam Harcama]
FROM Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FullName
HAVING SUM(o.TotalAmount) > (
    SELECT AVG(MusteriToplami)
    FROM (SELECT SUM(TotalAmount) AS MusteriToplami
          FROM Orders
          GROUP BY CustomerID) AS t
)
ORDER BY [Toplam Harcama] DESC;
GO

-- ---------------------------------------------------------------------
-- EK 3: Ek analiz raporları
-- ---------------------------------------------------------------------

-- 3a. En çok satan 5 ürün (adet ve ciro)
SELECT TOP 5
       p.ProductName                 AS [Ürün Adı],
       SUM(od.Quantity)              AS [Satılan Adet],
       SUM(od.Quantity * p.Price)    AS [Ürün Cirosu]
FROM OrderDetails AS od
INNER JOIN Products AS p ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY [Satılan Adet] DESC, [Ürün Cirosu] DESC;

-- 3b. Aylık satış özeti (CONVERT 126 biçimi 'YYYY-AA' verir)
SELECT CONVERT(CHAR(7), OrderDate, 126) AS [Ay],
       COUNT(*)                         AS [Sipariş Sayısı],
       SUM(TotalAmount)                 AS [Aylık Ciro]
FROM Orders
GROUP BY CONVERT(CHAR(7), OrderDate, 126)
ORDER BY [Ay];

-- 3c. Şehirlere göre ciro: yalnızca en az 2 siparişin geldiği şehirler (HAVING)
SELECT c.City              AS [Şehir],
       COUNT(o.OrderID)    AS [Sipariş Sayısı],
       SUM(o.TotalAmount)  AS [Toplam Ciro]
FROM Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.City
HAVING COUNT(o.OrderID) >= 2
ORDER BY [Toplam Ciro] DESC;
GO

-- ---------------------------------------------------------------------
-- EK 4: Stored Procedure ile güvenli sipariş
-- Sipariş, sipariş detayı ve stok düşme işlemlerini tek bir TRANSACTION içinde yapar.
-- Stok yetmezse ya da müşteri/ürün yoksa hiçbir değişiklik kaydedilmez.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_SiparisVer
    @CustomerID INT,
    @ProductID  INT,
    @Quantity   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Beklenmeyen bir hatada transaction otomatik geri alınır.

    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 50001, N'Adet en az 1 olmalıdır.', 1;

    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
        THROW 50002, N'Müşteri bulunamadı.', 1;

    BEGIN TRANSACTION;

    DECLARE @Price DECIMAL(10,2), @Stock INT, @OrderID INT;

    -- UPDLOCK: Aynı anda gelen iki sipariş aynı stoğu ikisi birden kullanamasın.
    SELECT @Price = Price, @Stock = ISNULL(Stock, 0)
    FROM Products WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductID = @ProductID;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003, N'Ürün bulunamadı.', 1;
    END

    IF @Price IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50004, N'Ürünün fiyatı tanımlı değil.', 1;
    END

    IF @Stock < @Quantity
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50005, N'Yeterli stok yok.', 1;
    END

    -- OrderDate yazılmadığı için varsayılan değer GETDATE() kullanılır.
    INSERT INTO Orders (CustomerID, TotalAmount)
    VALUES (@CustomerID, @Price * @Quantity);

    SET @OrderID = SCOPE_IDENTITY();

    INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
    VALUES (@OrderID, @ProductID, @Quantity);

    UPDATE Products
    SET Stock = Stock - @Quantity
    WHERE ProductID = @ProductID;

    COMMIT TRANSACTION;

    SELECT @OrderID AS YeniSiparisID;
END
GO

-- Deneme 1: Ahmet Yılmaz 2 adet Bluetooth Hoparlör alıyor (başarılı olmalı).
SELECT ProductName AS [Ürün Adı], Stock AS [Önceki Stok] FROM Products WHERE ProductID = 3;
EXEC sp_SiparisVer @CustomerID = 1, @ProductID = 3, @Quantity = 2;
SELECT ProductName AS [Ürün Adı], Stock AS [Yeni Stok] FROM Products WHERE ProductID = 3;
GO

-- Deneme 2: Stokta 5 adet olan Simyacı'dan 50 adet istenince sipariş reddedilir.
BEGIN TRY
    EXEC sp_SiparisVer @CustomerID = 2, @ProductID = 9, @Quantity = 50;
END TRY
BEGIN CATCH
    PRINT 'Beklenen hata (stok kontrolü): ' + ERROR_MESSAGE();
END CATCH;
SELECT ProductName AS [Ürün Adı], Stock AS [Stok (değişmedi)] FROM Products WHERE ProductID = 9;
GO


/* =====================================================================
   BÖLÜM 4.2: YEDEKLEME (BACKUP)
   Tüm işlemler tamamlandıktan sonra veri tabanının tam yedeği alınır.
   ===================================================================== */

-- SQL Server klasörü kendisi oluşturmaz; C:\Yedek yoksa önce oluşturuyoruz.
EXEC master.dbo.xp_create_subdir N'C:\Yedek';
GO

BACKUP DATABASE NovaStoreDB
TO DISK = N'C:\Yedek\NovaStoreDB.bak'
WITH FORMAT,                        -- Aynı dosyada eski yedek varsa üzerine yazılır.
     INIT,
     NAME = N'NovaStoreDB - Tam Yedek';
GO
