USE covidHistorico2;
GO

select year(FECHA_INGRESO), count(*)
from datoscovid
group by year(FECHA_INGRESO)

 /*

BULK INSERT covid_staging
FROM 'C:\Temp\COVID19MEXICO2024.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
*/
 
/**
   Crea función de particionamiento.
   Regla en SQL Server: particiones = numero de límites + 1,
   en este caso se generan 4 particiones, la primera permite 
   representar datos anteriores a 2020. Como no hay, esa partición
   está vacía. 
   */
CREATE PARTITION FUNCTION pf_anio (DATE)
AS RANGE RIGHT FOR VALUES 
('2020-01-01', '2021-01-01', '2022-01-01');

-- crea esquema basado en función de particionamiento
CREATE PARTITION SCHEME ps_anio
AS PARTITION pf_anio
ALL TO ([PRIMARY]);

-- crea tabla con esquema y función de particionamiento
CREATE TABLE covid_particionado (
    FECHA_INGRESO DATE,
    ENTIDAD_RES VARCHAR(50),
    EDAD INT
)
ON ps_anio(FECHA_INGRESO);

CREATE CLUSTERED INDEX idx_fecha
ON covid_particionado(FECHA_INGRESO)
ON ps_anio(FECHA_INGRESO);

-- Inserción de datos en la tabla particionada
INSERT 
INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT 
    TRY_CONVERT(DATE, REPLACE(Fecha_ingreso,'"','')),
    REPLACE(ENTIDAD_RES,'"',''),
    TRY_CONVERT(INT, REPLACE(EDAD,'"',''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"',''))
IS NOT NULL;
 

 -- rangos por partición
SELECT pf.name, prv.value
FROM sys.partition_functions pf
JOIN sys.partition_range_values prv 
    ON pf.function_id = prv.function_id
WHERE pf.name = 'pf_anio';

-- Filas por particiones 
 SELECT 
    p.partition_number,
    p.rows
FROM sys.partitions p
WHERE p.object_id = OBJECT_ID('covid_particionado')
AND p.index_id IN (0,1);

-- detalles partición
SELECT 
    t.name AS Tabla,
    i.name AS Indice,
    p.partition_number,
    p.rows
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE t.name = 'covid_particionado';

SET STATISTICS IO ON;
SELECT *
FROM covid_particionado
WHERE FECHA_INGRESO >= '2020-01-01' 
and FECHA_INGRESO <= '2020-12-31';

/******************************************************************
  EJEMPLO CON FILE GROUP DISTINTOS AL PRIMARY
******************************************************************/
ALTER DATABASE Covidhistorico2 ADD FILEGROUP FG_ANTES_202;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2020;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2021;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2022_MAS;

ALTER DATABASE CovidHistorico2 
ADD FILE (NAME = FG_ANTES_2020_dat, FILENAME = 'C:\Data\FG_ANTES_2020.ndf')
TO FILEGROUP FG_ANTES_2020;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2020_dat, FILENAME = 'C:\Data\FG_2020.ndf')
TO FILEGROUP FG_2020;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2021_dat, FILENAME = 'C:\Data\FG_2021.ndf')
TO FILEGROUP FG_2021;

ALTER DATABASE CovidHistorico2
ADD FILE (NAME = FG_2022_MAS_dat, FILENAME = 'C:\Data\FG_2022_MAS.ndf')
TO FILEGROUP FG_2022_MAS;

CREATE PARTITION SCHEME ps_anio
AS PARTITION pf_anio
TO (
    FG_ANTES_2020,  -- < 2020-01-01
    FG_2020,        -- >= 2020-01-01 y < 2021-01-01
    FG_2021,        -- >= 2021-01-01 y < 2022-01-01
    FG_2022_MAS     -- >= 2022-01-01
);

CREATE TABLE cc_particionado (
    Id INT NOT NULL,
    Fecha DATE NOT NULL,
    edad DECIMAL(10,2),
    CONSTRAINT PK_cc_particionado
        PRIMARY KEY CLUSTERED (Fecha, Id) -- 👈 clave alineada
)
ON ps_anio (Fecha);


/* Por si se almacenan datos 2023 
ALTER PARTITION SCHEME ps_anio NEXT USED FG_2023;
ALTER PARTITION FUNCTION pf_anio()
SPLIT RANGE ('2023-01-01');

*/