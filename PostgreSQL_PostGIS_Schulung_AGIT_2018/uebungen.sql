-- 1) Data Definition Language = DDL in PostgreSQL --------------------------------------------

-- Datenbank anlegen
CREATE DATABASE schulung;

-- Tabelle anlegen
CREATE TABLE baum (
	gid serial , 
	baumart varchar
);

-- Tabelle bearbeiten 
-- Spalte hinzufügen, Spalte umbenennen und eindeutigen Schlüssel definieren
ALTER TABLE baum ADD COLUMN nutzung varchar;
ALTER TABLE baum RENAME nutzung TO nutzungstyp;
ALTER TABLE baum ADD CONSTRAINT pk_gid PRIMARY KEY (gid); 

-- Tabelle löschen
DROP TABLE baum;

-- 2) Data Manipulation Language = DML in PostgreSQL -------------------------------------------

-- einzelnen Datensatz in Tabelle einbinden
INSERT INTO baum (baumart , nutzungstyp) 
VALUES (‘Erle‘, ‘Laubwald‘);

-- Mehrere Datensätze einfügen
INSERT INTO baum (baumart , nutzungstyp) 
VALUES (‘Erle‘, ‘Laubwald‘),(‘Tanne‘, ‘Nadelwald‘);

-- Daten ändern/ aktualisieren
UPDATE baum SET baumart = ‘Buche‘ 
WHERE nutzungstyp = ‘Buchenwald‘;

-- Daten löschen
DELETE FROM baum WHERE gid = 1;

-- Daten abfragen 
-- eindeutige Id über 5 und alle Nutzungstypen außer Erlenwald
SELECT gid, baumart FROM baum
WHERE gid > 5 AND nutzungstyp <> ‘Erlenwald‘
ORDER BY gid;

-- Dynamische Sichten erzeugen
CREATE VIEW qry_count AS 
	SELECT count(baumart) as anzahl, baumart
	FROM baum
	GROUP BY baumart
	ORDER by anzahl;

-- Schema in DB anlegen und
-- Tabelle im neuen Schema erzeugen
CREATE SCHEMA geo;
CREATE TABLE geo.bodenarten
(gid serial, area float8, art varchar);

-- 3) Geometriespalten über PostGIS --------------------------------------------------------

-- PostGIS Erweiterung laden
CREATE EXTENSION postgis;

-- Tabelle mit Geometriespalte erstellen
CREATE TABLE baum (
	gid serial PRIMARY KEY, 
	baumart varchar,
	geom geometry (point,31467)
);

-- Geometriespalte nachträglich in Tabelle einbinden
ALTER TABLE baum add column geom geometry (point,31467);  

-- Eintrag von geometrischen Daten
INSERT INTO baum (baumart , geom) VALUES 
('Erle' , ST_GeometryFromText('POINT(3564780.7 5631558.5)', 31467));

-- Aktualisierung einer Geometriespalte
UPDATE baum SET 
geom = ST_GeometryFromText('POINT(3564850.72 5631672.23)', 31467) 
WHERE gid = 1;

-- Anzeige der Geometrie im WKT-Format
SELECT ST_AsEWKT(geom) FROM baum;

-- 4) Datenimport -----------------------------------------------------------------------------

-- Import von Daten aus CSV-Datei
CREATE TABLE mytable 
(gid serial, bezeichnung varchar, x integer, y integer);

COPY mytable FROM '/data/pois.csv' 
	DELIMITER ',' 
	CSV
	HEADER 
	QUOTE as '"' ;

-- Geometriespalte anlegen und mit x/y-Koordinaten füllen
ALTER TABLE mytable ADD COLUMN geom geometry(point,31467);

UPDATE mytable SET geom = 
ST_GeometryFromText ( 'POINT('  ||  x  ||  '  '  ||  y  ||  ')' , 31467);


-- 5) räumliche Funktionen über PostGIS ------------------------------------------------------

-- Umgebungsrechteck der Daten ermitteln
SELECT ST_Extent(the_geom) FROM ne_10m_admin_0_countries;

-- Flächengröße der Daten ermitteln
SELECT ST_Area(ST_Transform(the_geom, 25832)) 
FROM ne_10m_admin_0_countries 
WHERE admin = ‘Austria‘;

-- Angabe der Länge in Metern und Kilometern

SELECT ST_Length( ST_Transform(the_geom, 31466) ) 
FROM ne_10m_rivers_lake_centerlines;

SELECT round( ( ST_Length(ST_Transform(the_geom, 31466) ) /1000 )::numeric , 3) || ' km' 
FROM ne_10m_rivers_lake_centerlines;

-- Puffer um Geometrien erzeugen und in Tabelle eintragen
SELECT ST_Buffer(the_geom, 0.005) as buffer_50 
FROM ne_10m_rivers_lake_centerlines;

CREATE TABLE buffer_line  AS
SELECT ST_Buffer(the_geom,0.005)::geometry(Polygon,4326) AS geom 
FROM ne_10m_rivers_lake_centerlines;

ALTER TABLE buffer ADD COLUMN gid serial;

-- Datenvalidierung der Geometriespalte
SELECT * FROM ne_10m_rivers_lake_centerlines WHERE ST_IsValid(the_geom);
SELECT * FROM ne_10m_rivers_lake_centerlines WHERE ST_IsEmpty(the_geom);
SELECT ST_IsValidReason(the_geom) FROM ne_10m_rivers_lake_centerlines WHERE not ST_IsValid(the_geom);
SELECT * FROM ne_10m_rivers_lake_centerlines WHERE ST_IsValidDetail(the_geom); 

-- Datenbereinigung nach Validierunsgfehler
SELECT ST_MakeValid(geometry) FROM ne_10m_rivers_lake_centerlines WHERE ST_IsValid(the_geom) = false; 

-- Prüfung, ob Linien sich schneiden
SELECT ST_Intersects(
	ST_GeometryFromText('LINESTRING(6 6 ,0 6)',4326) , 
	ST_GeometryFromText('LINESTRING(0 0, 5 5, 10 10)',4326)
);
