CREATE TABLE "Pasageri"
(
  "id_pasager"  INT     NOT NULL,
  "id_document" INT     NOT NULL,
  "nume"        VARCHAR NOT NULL,
  "prenume"     VARCHAR NOT NULL,
  "contact"     VARCHAR NOT NULL,
  "telefon"     INT     NOT NULL,
  CONSTRAINT "pk_Pasageri" PRIMARY KEY ("id_pasager")
);

CREATE TABLE "Documente"
(
  "id_document"   INT     NOT NULL,
  "cnp"           INT     NOT NULL,
  "tara"          VARCHAR NOT NULL,
  "adresa"        VARCHAR NOT NULL,
  "zi_de_nastere" VARCHAR NOT NULL,
  "sex"           CHAR    NOT NULL,
  "an_validare"   data    NOT NULL,
  "an_expirare"   data    NOT NULL,
  CONSTRAINT "pk_Documente" PRIMARY KEY ("id_document"),
  CONSTRAINT "uc_Documente_cnp" UNIQUE ("cnp")
);

CREATE TABLE "Bagaje"
(
  "id_bagaj"   INT     NOT NULL,
  "id_pasager" INT     NOT NULL,
  "tip"        VARCHAR NOT NULL,
  "inaltime"   INT     NOT NULL,
  "lungime"    INT     NOT NULL,
  "greutate"   INT     NOT NULL,
  CONSTRAINT "pk_Bagaje" PRIMARY KEY ("id_bagaj")
);

CREATE TABLE "Aeroporturi"
(
  "id_aeroport" INT     NOT NULL,
  "nume"        VARCHAR NOT NULL,
  "tara"        VARCHAR NOT NULL,
  "regiune"     VARCHAR NOT NULL,
  "oras"        VARCHAR NOT NULL,
  CONSTRAINT "pk_Aeroporturi" PRIMARY KEY ("id_aeroport")
);

CREATE TABLE "Companii_Aeriene"
(
  "id_companie" INT     NOT NULL,
  "denumire"    VARCHAR NOT NULL,
  "tara"        VARCHAR NOT NULL,
  "contact"     VARCHAR NOT NULL,
  CONSTRAINT "pk_Companii_Aeriene" PRIMARY KEY ("id_companie")
);

CREATE TABLE "Angajati"
(
  "id_angajat"         INT     NOT NULL,
  "id_companie"        INT     NOT NULL,
  "nume"               VARCHAR NOT NULL,
  "prenume"            VARCHAR NOT NULL,
  "contact"            VARCHAR NOT NULL,
  "telefon"            INT     NOT NULL,
  "salariu"            INT     NOT NULL,
  "incepere_contract"  data    NOT NULL,
  "incheiere_contract" data    NOT NULL,
  CONSTRAINT "pk_Angajati" PRIMARY KEY ("id_angajat")
);

CREATE TABLE "Avioane"
(
  "id_avion"    INT         NOT NULL,
  "id_companie" INT         NOT NULL,
  "model"       VARCHAR(20) NOT NULL,
  "nr_locuri"   INT         NOT NULL,
  "cap_stocare" INT         NOT NULL,
  "rezervor"    INT         NOT NULL,
  "max_viteza"  INT         NOT NULL,
  CONSTRAINT "pk_Avioane" PRIMARY KEY ("id_avion")
);

CREATE TABLE "Echipaje"
(
  "id_avion"     INT     NOT NULL,
  "id_angajat"   INT     NOT NULL,
  "rol"          VARCHAR NOT NULL,
  "timp_program" DATE    NOT NULL
);

CREATE TABLE "Zboruri"
(
  "id_zboruri"    INT     NOT NULL,
  "id_avion"      INT     NOT NULL,
  "id_companie"   INT     NOT NULL,
  "id_plecare"    INT     NOT NULL,
  "id_sosire"     INT     NOT NULL,
  "timp_decolare" DATE    NOT NULL,
  "timp_sosire"   DATE    NOT NULL,
  "status"        VARCHAR NOT NULL,
  CONSTRAINT "pk_Zboruri" PRIMARY KEY ("id_zboruri")
);

CREATE TABLE "Calatorii"
(
  "id_pasager"     INT  NOT NULL,
  "id_zbor"        INT  NOT NULL,
  "numar_loc"      INT  NOT NULL,
  "data_rezervare" DATE NOT NULL
);

ALTER TABLE "Pasageri"
  ADD CONSTRAINT "fk_Pasageri_id_document" FOREIGN KEY ("id_document")
    REFERENCES "Documente" ("id_document");

ALTER TABLE "Bagaje"
  ADD CONSTRAINT "fk_Bagaje_id_pasager" FOREIGN KEY ("id_pasager")
    REFERENCES "Pasageri" ("id_pasager");

ALTER TABLE "Angajati"
  ADD CONSTRAINT "fk_Angajati_id_companie" FOREIGN KEY ("id_companie")
    REFERENCES "Companii_Aeriene" ("id_companie");

ALTER TABLE "Avioane"
  ADD CONSTRAINT "fk_Avioane_id_companie" FOREIGN KEY ("id_companie")
    REFERENCES "Companii_Aeriene" ("id_companie");

ALTER TABLE "Echipaje"
  ADD CONSTRAINT "fk_Echipaje_id_avion" FOREIGN KEY ("id_avion")
    REFERENCES "Avioane" ("id_avion");

ALTER TABLE "Echipaje"
  ADD CONSTRAINT "fk_Echipaje_id_angajat" FOREIGN KEY ("id_angajat")
    REFERENCES "Angajati" ("id_angajat");

ALTER TABLE "Zboruri"
  ADD CONSTRAINT "fk_Zboruri_id_avion" FOREIGN KEY ("id_avion")
    REFERENCES "Avioane" ("id_avion");

ALTER TABLE "Zboruri"
  ADD CONSTRAINT "fk_Zboruri_id_companie" FOREIGN KEY ("id_companie")
    REFERENCES "Companii_Aeriene" ("id_companie");

ALTER TABLE "Zboruri"
  ADD CONSTRAINT "fk_Zboruri_id_plecare" FOREIGN KEY ("id_plecare")
    REFERENCES "Aeroporturi" ("id_aeroport");

ALTER TABLE "Zboruri"
  ADD CONSTRAINT "fk_Zboruri_id_sosire" FOREIGN KEY ("id_sosire")
    REFERENCES "Aeroporturi" ("id_aeroport");

ALTER TABLE "Calatorii"
  ADD CONSTRAINT "fk_Calatorii_id_pasager" FOREIGN KEY ("id_pasager")
    REFERENCES "Pasageri" ("id_pasager");

ALTER TABLE "Calatorii"
  ADD CONSTRAINT "fk_Calatorii_id_zbor" FOREIGN KEY ("id_zbor")
    REFERENCES "Zboruri" ("id_zboruri");