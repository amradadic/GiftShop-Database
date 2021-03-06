--zadatak 3
--1.
SELECT d.naziv,
       p.naziv,
       k.kolicina_proizvoda
FROM drzava d ,proizvod p, skladiste s, grad g, lokacija l, kolicina k
WHERE d.drzava_id = g.drzava_id AND
      g.grad_id = l.grad_id AND
      s.lokacija_id = l.lokacija_id AND
      k.skladiste_id = s.skladiste_id AND
      p.proizvod_id = k.proizvod_id AND
      k.kolicina_proizvoda > 0 ;

--2.
SELECT DISTINCT  p.pravno_lice_id,
                 p.naziv
FROM pravno_lice p, ugovor_za_pravno_lice u
WHERE u.pravno_lice_id = p.pravno_lice_id AND
      u.datum_potpisivanja > To_Date('1.1.2014.', 'dd.mm.yyyy.');

--3.
SELECT DISTINCT p.proizvod_id,
                p.naziv
FROM proizvod p, narudzba_proizvoda n, popust t
WHERE p.proizvod_id = n.proizvod_id AND
      t.popust_id = n.popust_id AND
      t.postotak > 0 AND
      p.broj_mjeseci_garancije = 12 ;

--4.
SELECT (p.postotak-97)
FROM popust p, narudzba_proizvoda n
WHERE p.popust_id = n.popust_id AND
      p.postotak>20;

--5.
SELECT f.ime ||' '|| f.prezime AS "ime i prezime",
       o.naziv
FROM fizicko_lice f, uposlenik u, odjel o, kupac k
WHERE u.uposlenik_id = f.fizicko_lice_id AND
      u.odjel_id = o.odjel_id AND
      k.kupac_id = f.fizicko_lice_id;

--6.
SELECT p.naziv,
       p.cijena,
       Nvl(o.postotak,0)
FROM proizvod p, popust o, narudzba_proizvoda n
WHERE p.proizvod_id = n.proizvod_id AND
      o.popust_id = n.popust_id;

--7.
SELECT Decode(n.kategorija_id,
              1, 'Komp Oprema',
              NULL , 'Nema Kategorije',
              n.naziv) "nadkategorija",
              k.naziv "kategorija"
FROM kategorija k, kategorija n
WHERE k.nadkategorija_id = n.kategorija_id(+);   --outer join

 SELECT * FROM kategorija;
--8.

SELECT Round(( Months_between (SYSDATE, u.datum_zaposlenja))/12) || ' godina ' || Round(( Mod(Months_between (SYSDATE, u.datum_zaposlenja),12) )) || ' mjeseci i ' || Round(( (Months_between (SYSDATE, u.datum_zaposlenja)/30) )) || ' dana'
FROM ugovor_za_uposlenika u;


SELECT round(((SYSDATE-u.datum_zaposlenja)/365)*12*30)
FROM ugovor_za_uposlenika u;
--9.
SELECT f.ime,
       f.prezime,
       Decode(o.naziv,
              'Management','Menadzment',
              'Human Resources','Ljudski resursi',
              'Warehouse department','Skladisni odjel',
              'Marketing','Marketing',
              'Service','Usluge',
              o.naziv) "Odjel na nasem"
FROM fizicko_lice f, odjel o, uposlenik u
WHERE f.fizicko_lice_id = u.uposlenik_id AND o.odjel_id = u.odjel_id
ORDER BY f.ime ASC,
         f.prezime DESC;


              SELECT * FROM odjel;

--10.
SELECT k.naziv,
       Max(p.cijena),
       Min(p.cijena)
FROM kategorija k, proizvod p
WHERE k.kategorija_id = p.kategorija_id
GROUP BY k.naziv
ORDER by Max(p.cijena)+Min(p.cijena) ASC;