

SELECT * FROM Stylebook

BEGIN TRAN
ALTER TABLE Stylebook ADD minSize float NULL;
ALTER TABLE Stylebook ADD maxSize float NULL;

ALTER TABLE Stylebook ADD unit varchar(50) NULL;
ALTER TABLE Stylebook ADD unitPrice int NULL;
ALTER TABLE Stylebook ADD readyMadeSize int NULL;

ALTER TABLE Stylebook ADD engrave varchar(1) NULL;

ALTER TABLE Stylebook ADD color varchar(2) NULL;
ALTER TABLE Stylebook ADD readyMadeStone varchar(2) NULL;
ALTER TABLE Stylebook ADD optionYN varchar(1) NULL;

ALTER TABLE Stylebook ADD YG char(1) NULL;
ALTER TABLE Stylebook ADD RG char(1) NULL;
ALTER TABLE Stylebook ADD WG char(1) NULL;
ALTER TABLE Stylebook ADD WGX char(1) NULL;
ALTER TABLE Stylebook ADD CB char(1) NULL;

ALTER TABLE Stylebook ADD engravePrice int NULL;
ALTER TABLE Stylebook ADD engraveOut varchar(1) NULL;
ALTER TABLE Stylebook ADD engraveOutPrice int NULL;


ROLLBACK TRAN