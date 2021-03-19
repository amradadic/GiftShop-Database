--zadatak 5

CREATE TABLE faktura18197 (faktura_id INTEGER PRIMARY KEY,
                           kupac_id INTEGER NOT NULL REFERENCES kupac(kupac_id),
                           iznos INTEGER NOT NULL,
                           datum_kupoprodaje DATE NOT NULL,
                           isporuka_id INTEGER NOT NULL REFERENCES isporuka(isporuka_id));
                         --u suprotnom posto faktura sa idem 2 se ne nalazi u narudzbo proizvoda nece se dodati pa se mora ovako ici sa dodavanjem podataka i alter table

INSERT INTO faktura18197
SELECT faktura.faktura_id, faktura.kupac_id, faktura.iznos, faktura.datum_kupoprodaje, faktura.isporuka_id
FROM faktura ; --10 redova


ALTER TABLE faktura18197
ADD(broj_prodatih_artikala INTEGER);

UPDATE faktura18197 f
SET broj_prodatih_artikala = (SELECT Sum(np.kolicina_jednog_proizvoda)
                              FROM faktura fakt, narudzba_proizvoda np, proizvod p
                              WHERE f.faktura_id = fakt.faktura_id AND
                              fakt.faktura_id = np.faktura_id AND
                              np.proizvod_id = p.proizvod_id);


CREATE TABLE narudzba_proizvoda18197(narudzba_id INTEGER PRIMARY KEY,
                                     proizvod_id INTEGER NOT NULL REFERENCES proizvod(proizvod_id),
                                     kolicina_jednog_proizvoda INTEGER,
                                     faktura_id INTEGER REFERENCES faktura(faktura_id),
                                     iznos_naruzbe INTEGER);

                                    
INSERT INTO narudzba_proizvoda18197
SELECT n.narudzba_id, n.proizvod_id, n.kolicina_jednog_proizvoda, n.faktura_id, n.kolicina_jednog_proizvoda*(p.cijena-(Nvl(po.postotak,0)*p.cijena)/100)
FROM narudzba_proizvoda n, proizvod p, popust po
WHERE n.proizvod_id = p.proizvod_id AND
      n.popust_id = po.popust_id(+)
ORDER BY n.narudzba_id  ;


CREATE TABLE proizvod18197(prozvod_id INTEGER PRIMARY KEY,
                           cijena INTEGER,
                           proizvodjac_id INTEGER REFERENCES proizvodjac(proizvodjac_id),
                           broj_mjeseci_garancije INTEGER,
                           starinaziv VARCHAR(100));

INSERT INTO proizvod18197
SELECT p.proizvod_id, p.cijena, p.proizvodjac_id, p.broj_mjeseci_garancije, Concat(p.naziv,Concat(Concat('(', k.naziv),')'))
FROM proizvod p, kategorija k
WHERE p.kategorija_id = k.kategorija_id;

CREATE TABLE proizvodjac18197(proizvodjac_id INTEGER PRIMARY KEY,
                              email VARCHAR(100),
                              pravno_lice_id INTEGER,
                              naziv VARCHAR(50),
                              lokacija_id INTEGER REFERENCES lokacija(lokacija_id));
INSERT INTO proizvodjac18197
SELECT p.proizvodjac_id, p.email, pl.pravno_lice_id, pl.naziv, pl.lokacija_id
FROM proizvodjac p , pravno_lice pl
WHERE p.proizvodjac_id = pl.pravno_lice_id;


--sekvenca

CREATE SEQUENCE sekvenca_brojac_narudzba
  START WITH 1
  INCREMENT BY 1
  MAXVALUE 100000000
  MINVALUE 0;
/
--triger


CREATE OR REPLACE TRIGGER triger_za_narudzbu
before INSERT ON narudzba_proizvoda
FOR EACH ROW
DECLARE
  fakturaajdi faktura.faktura_id%TYPE     ;
  varijabla NUMBER(38);
  broj NUMBER(38);
  broj_postoji_uproizvodu NUMBER(38);
  broj_postoji_ufakturi NUMBER(38);
  broj_postoji_uproizvodjacu NUMBER(38);

BEGIN
broj := sekvenca_brojac_narudzba.NEXTVAL;

broj_postoji_uproizvodu := 0;
broj_postoji_ufakturi := 0;
broj_postoji_uproizvodjacu :=0;

SELECT Count(*)
INTO broj_postoji_ufakturi
FROM faktura18197
WHERE faktura18197.faktura_id = :new.faktura_id;


      

IF(broj_postoji_ufakturi = 0) then
  INSERT INTO faktura18197 (faktura_id, kupac_id, iznos, datum_kupoprodaje, isporuka_id, broj_prodatih_artikala)
  SELECT f.faktura_id, f.kupac_id,f.iznos, f.datum_kupoprodaje, f.isporuka_id, null
  FROM faktura f
  WHERE f.faktura_id = :new.faktura_id;


  UPDATE faktura18197
  SET broj_prodatih_artikala = (SELECT Sum(np.kolicina_jednog_proizvoda)
                              FROM faktura fakt, narudzba_proizvoda np, proizvod p
                              WHERE
                              fakt.faktura_id = np.faktura_id AND
                              np.proizvod_id = p.proizvod_id AND
                              fakt.faktura_id = :new.faktura_id)
  WHERE faktura_id = :new.faktura_id;

END IF ;

--apdejt narudzbe proizvoda 18197
INSERT INTO narudzba_proizvoda18197 (narudzba_id, proizvod_id, kolicina_jednog_proizvoda, faktura_id, iznos_naruzbe) VALUES
                                    (:new.narudzba_id, :new.proizvod_id, :new.kolicina_jednog_proizvoda, :new.faktura_id, null );

UPDATE narudzba_proizvoda18197
SET iznos_naruzbe =
                    (SELECT n.kolicina_jednog_proizvoda*(p.cijena-(Nvl(po.postotak,0)*p.cijena)/100)
                      FROM narudzba_proizvoda n, proizvod p, popust po
                      WHERE n.proizvod_id = p.proizvod_id AND
                      n.popust_id = po.popust_id(+)
                      AND n.narudzba_id =:new.narudzba_id )
                      --ORDER BY n.narudzba_id)
WHERE narudzba_proizvoda18197.narudzba_id = :new.narudzba_id;


fakturaajdi := :new.faktura_id;



SELECT Count(*)
INTO broj_postoji_uproizvodu
FROM proizvod18197
WHERE proizvod18197.prozvod_id = :new.proizvod_id;
--apdejt proizvoda
IF(broj_postoji_uproizvodu = 0 ) then
  INSERT INTO proizvod18197 (prozvod_id, cijena, proizvodjac_id, broj_mjeseci_garancije, starinaziv)
  SELECT p.proizvod_id, p.cijena, p.proizvodjac_id, p.broj_mjeseci_garancije, Concat(p.naziv,Concat(Concat('(', k.naziv),')'))
  FROM proizvod p, kategorija k, narudzba_proizvoda np
  WHERE p.kategorija_id = k.kategorija_id AND
        np.proizvod_id = p.proizvod_id AND
        np.narudzba_id = :new.narudzba_id;
END IF; 


SELECT Count(*)
INTO broj_postoji_uproizvodjacu
FROM proizvodjac18197 p, proizvod18197 pro
WHERE pro.prozvod_id = :new.proizvod_id and
      p.proizvodjac_id = pro.proizvodjac_id ;


IF(broj_postoji_uproizvodjacu = 0 ) then
INSERT INTO proizvodjac18197(proizvodjac_id, email, pravno_lice_id, naziv, lokacija_id)
SELECT p.proizvodjac_id, p.email, pl.pravno_lice_id, pl.naziv, pl.lokacija_id
FROM proizvodjac p , proizvod pro, pravno_lice pl, narudzba_proizvoda np
WHERE p.proizvodjac_id = pro.proizvodjac_id AND
      np.proizvod_id = pro.proizvod_id and
      pl.pravno_lice_id = p.proizvodjac_id AND
      np.narudzba_id = :new.narudzba_id;

END IF;

       
EXCEPTION
  WHEN Dup_Val_On_Index THEN
    NULL;  
END triger_za_narudzbu;
/


--procedura


CREATE OR REPLACE PROCEDURE procedura_narudzba (narudzbaid IN NUMBER) IS
 
  varijabla NUMBER(38);
  broj NUMBER(38);
  broj_postoji_uproizvodu NUMBER(38);
  broj_postoji_ufakturi NUMBER(38);
  broj_postoji_uproizvodjacu NUMBER(38);
  proizvodid NUMBER(38);
  kolicinajednogproizvoda NUMBER (38);
  fakturaid NUMBER(38);

 

 BEGIN

SELECT np.proizvod_id 
INTO proizvodid
FROM narudzba_proizvoda   np
WHERE np.narudzba_id = narudzbaid;

SELECT np.kolicina_jednog_proizvoda 
INTO kolicinajednogproizvoda
FROM narudzba_proizvoda np
WHERE np.narudzba_id = narudzbaid;


SELECT np.faktura_id 
INTO fakturaid
FROM narudzba_proizvoda np
WHERE np.narudzba_id = narudzbaid;

            --DROP PROCEDURE procedura_narudzba
                
broj_postoji_uproizvodu := 0;
broj_postoji_ufakturi := 0;
broj_postoji_uproizvodjacu :=0;

  

SELECT Count(*)
INTO broj_postoji_ufakturi
FROM faktura18197 , narudzba_proizvoda np
WHERE faktura18197.faktura_id = np.faktura_id AND
      np.narudzba_id = narudzba_id;


      

IF(broj_postoji_ufakturi = 0) then
  INSERT INTO faktura18197 (faktura_id, kupac_id, iznos, datum_kupoprodaje, isporuka_id, broj_prodatih_artikala)
  SELECT f.faktura_id, f.kupac_id,f.iznos, f.datum_kupoprodaje, f.isporuka_id, null
  FROM faktura f   ,narudzba_proizvoda np
  WHERE f.faktura_id = np.faktura_id AND
      np.narudzba_id = narudzbaid;


  UPDATE faktura18197
  SET broj_prodatih_artikala = (SELECT Sum(np.kolicina_jednog_proizvoda)
                              FROM faktura fakt, narudzba_proizvoda np, proizvod p
                              WHERE
                              fakt.faktura_id = np.faktura_id AND
                              np.proizvod_id = p.proizvod_id AND
                              fakt.faktura_id =np.faktura_id AND
                              np.narudzba_id = narudzba_id ) 
  WHERE faktura_id = fakturaid;

END IF ;

--apdejt narudzbe proizvoda 18197
INSERT INTO narudzba_proizvoda18197 (narudzba_id, proizvod_id, kolicina_jednog_proizvoda, faktura_id, iznos_naruzbe) VALUES
                                    (narudzbaid, proizvodid, kolicinajednogproizvoda, fakturaid, null );

UPDATE narudzba_proizvoda18197
SET iznos_naruzbe =
                    (SELECT n.kolicina_jednog_proizvoda*(p.cijena-(Nvl(po.postotak,0)*p.cijena)/100)
                      FROM narudzba_proizvoda n, proizvod p, popust po
                      WHERE n.proizvod_id = p.proizvod_id AND
                      n.popust_id = po.popust_id(+)
                      AND n.narudzba_id =narudzbaid )
                      --ORDER BY n.narudzba_id)
WHERE narudzba_proizvoda18197.narudzba_id = narudzbaid;


--fakturaajdi := :new.faktura_id;



SELECT Count(*)
INTO broj_postoji_uproizvodu
FROM proizvod18197
WHERE proizvod18197.prozvod_id = proizvodid;
--apdejt proizvoda
IF(broj_postoji_uproizvodu = 0 ) then
  INSERT INTO proizvod18197 (prozvod_id, cijena, proizvodjac_id, broj_mjeseci_garancije, starinaziv)
  SELECT p.proizvod_id, p.cijena, p.proizvodjac_id, p.broj_mjeseci_garancije, Concat(p.naziv,Concat(Concat('(', k.naziv),')'))
  FROM proizvod p, kategorija k, narudzba_proizvoda np
  WHERE p.kategorija_id = k.kategorija_id AND
        np.proizvod_id = p.proizvod_id AND
        np.narudzba_id = narudzbaid;
END IF; 


SELECT Count(*)
INTO broj_postoji_uproizvodjacu
FROM proizvodjac18197 p, proizvod18197 pro
WHERE pro.prozvod_id = proizvodid and
      p.proizvodjac_id = pro.proizvodjac_id ;


IF(broj_postoji_uproizvodjacu = 0 ) then
INSERT INTO proizvodjac18197(proizvodjac_id, email, pravno_lice_id, naziv, lokacija_id)
SELECT p.proizvodjac_id, p.email, pl.pravno_lice_id, pl.naziv, pl.lokacija_id
FROM proizvodjac p , proizvod pro, pravno_lice pl, narudzba_proizvoda np
WHERE p.proizvodjac_id = pro.proizvodjac_id AND
      np.proizvod_id = pro.proizvod_id and
      pl.pravno_lice_id = p.proizvodjac_id AND
      np.narudzba_id = narudzbaid;

END IF;

       
EXCEPTION
  WHEN Dup_Val_On_Index THEN
    NULL;  
  
 END procedura_narudzba;
/
