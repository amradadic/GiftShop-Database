--zadatak 4
--upit 1
SELECT pl.naziv
FROM pravno_lice pl, lokacija l
WHERE pl.lokacija_id = l.lokacija_id AND
      pl.lokacija_id IN (SELECT fl.lokacija_id
                         FROM fizicko_lice fl
                         WHERE fl.lokacija_id = l.lokacija_id);
--upit 2
SELECT To_Date(u.datum_potpisivanja,'dd.MM.YYYY'), pl.naziv
FROM ugovor_za_pravno_lice u, pravno_lice pl
WHERE pl.pravno_lice_id = u.pravno_lice_id AND
      To_Date(u.datum_potpisivanja,'dd.MM.YYYY') >any (SELECT To_Date(f.datum_kupoprodaje,'dd.MM.YYYY')
                              FROM faktura f, narudzba_proizvoda np, proizvod p
                              WHERE np.faktura_id = f.faktura_id AND
                                    p.proizvod_id = np.proizvod_id AND
                                    p.broj_mjeseci_garancije IS NOT NULL);

--upit 3
SELECT p.naziv
FROM proizvod p, kategorija k--, kolicina ko
WHERE p.kategorija_id = k.kategorija_id AND
 --p.proizvod_id = ko.proizvod_id AND
      p.kategorija_id IN (SELECT k.kategorija_id
                          FROM kategorija k, proizvod p, kolicina ko
                          WHERE p.kategorija_id = k.kategorija_id AND
                                p.proizvod_id = ko.proizvod_id AND
                                (SELECT Max(kolicina_proizvoda)
                                 FROM kolicina) IN (SELECT kolicina_proizvoda
                                                   FROM kolicina k1, proizvod p1
                                                   WHERE k1.proizvod_id = p1.proizvod_id AND
                                                         p1.kategorija_id = p.kategorija_id));

--upit 4
SELECT DISTINCT p.naziv AS Proizvod, pr.naziv AS Proizvodjac
FROM proizvod p, proizvodjac pro, pravno_lice pr , proizvod p1
WHERE p.proizvodjac_id = pro.proizvodjac_id AND
      pr.pravno_lice_id = pro.proizvodjac_id AND
      p1.proizvodjac_id = pro.proizvodjac_id AND
      p1.cijena > (SELECT Avg(proi.cijena)
                     FROM proizvod proi);

--upit 5
SELECT fl.ime, fl.prezime, Sum(fa.iznos)
FROM kupac k, uposlenik u, fizicko_lice fl, faktura fa
WHERE k.kupac_id = fl.fizicko_lice_id AND
      fl.fizicko_lice_id = u.uposlenik_id AND
      fa.kupac_id = k.kupac_id
HAVING Sum(fa.iznos) > (SELECT Round(Avg(sume),2)
                       FROM (SELECT Sum(iznos) sume
                             FROM kupac k1, fizicko_lice fl1, faktura fa1
                             WHERE fl1.fizicko_lice_id = k1.kupac_id AND
                                   k1.kupac_id = fa1.kupac_id
                             GROUP BY fl1.ime, fl1.prezime))
GROUP BY fl.ime, fl.prezime;


--upit 6
SELECT pl.naziv AS NAZIV
FROM narudzba_proizvoda nap,kurirska_sluzba ks, pravno_lice pl,isporuka isp,faktura fakt
WHERE fakt.faktura_id=nap.faktura_id AND
      fakt.isporuka_id=isp.isporuka_id AND
      isp.kurirska_sluzba_id=ks.kurirska_sluzba_id AND
      ks.kurirska_sluzba_id=pl.pravno_lice_id and
      nap.popust_id IS NOT NULL
GROUP BY pl.naziv
HAVING  sum(nap.kolicina_jednog_proizvoda) = (SELECT Max(sum(n.kolicina_jednog_proizvoda))
                                              FROM faktura f, narudzba_proizvoda n, isporuka i, kurirska_sluzba k
                                              WHERE f.faktura_id=n.faktura_id
                                                    AND f.isporuka_id=i.isporuka_id
                                                    AND i.kurirska_sluzba_id=k.kurirska_sluzba_id
                                                    AND n.popust_id IS NOT NULL
                                              GROUP BY k.kurirska_sluzba_id );


--upit 7
SELECT f.ime ||' '|| f.prezime AS "KUPAC", Sum(np.kolicina_jednog_proizvoda*p.cijena*pop.postotak/100) AS "USTEDA"
FROM fizicko_lice f, kupac k, faktura fakt, narudzba_proizvoda np, proizvod p , popust pop
WHERE f.fizicko_lice_id=k.kupac_id AND
      fakt.kupac_id=k.kupac_id AND
      np.faktura_id=fakt.faktura_id AND
      np.popust_id=pop.popust_id AND
      p.proizvod_id=np.proizvod_id
GROUP BY f.ime ||' '|| f.prezime;



--upit 8
SELECT (i.isporuka_id) ||','|| i.kurirska_sluzba_id AS "ISPORUKA_ID,KURIRSKA_SLUZBA_ID"
FROM isporuka i, faktura f
WHERE f.isporuka_id=i.isporuka_id AND f.faktura_id IN (SELECT DISTINCT (fakt.faktura_id)
                                                       FROM faktura fakt,narudzba_proizvoda n,proizvod p
                                                       WHERE fakt.faktura_id=n.faktura_id AND
                                                       n.proizvod_id=p.proizvod_id AND
                                                       p.broj_mjeseci_garancije IS NOT NULL AND
                                                       n.popust_id IS NOT NULL)
GROUP BY i.isporuka_id,i.kurirska_sluzba_id
ORDER BY Min(f.datum_kupoprodaje) DESC;



--upit 9
SELECT p.naziv,p.cijena
FROM proizvod p
WHERE p.cijena>(SELECT Round(AVG(Max(pt.cijena)),2)
                FROM proizvod pr
                GROUP BY pr.kategorija_id);

--upit 10
SELECT p.naziv,p.cijena
FROM proizvod p,kategorija k
WHERE p.kategorija_id=k.kategorija_id AND 
      p.cijena <= ( SELECT Round(Min(Avg(pt.cijena)),2)
                    FROM proizvod pt,kategorija kt
                    WHERE pt.kategorija_id=kt.kategorija_id AND 
                   (kt.nadkategorija_id!=k.kategorija_id
                    OR kt.nadkategorija_id IS null)
                    GROUP BY pt.kategorija_id);



