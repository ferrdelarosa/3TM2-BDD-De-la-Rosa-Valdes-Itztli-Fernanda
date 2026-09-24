/*===========================================================
        TAREA - DISEÑO DE FRAGMENTACIÓN
        Base de Datos Distribuidas
        Base de datos: AdventureWorks2019

        Ejercicio 3:
        Fragmentación horizontal de Sales.Customer
===========================================================*/

USE AdventureWorks2019;
GO


/*===========================================================
  1. ANALIZAR LA TABLA SALES.CUSTOMER

  Se obtiene:
  - CustomerID mínimo
  - CustomerID máximo
  - Total de clientes
===========================================================*/

SELECT
    MIN(CustomerID) AS MinimoID,
    MAX(CustomerID) AS MaximoID,
    COUNT(*) AS TotalRegistros
FROM Sales.Customer;
GO

/*
Resultado obtenido:

MinimoID = 1
MaximoID = 30118
TotalRegistros = 19820
*/


/*===========================================================
  2. ANALIZAR LOS 5 RANGOS
===========================================================*/

SELECT
    CASE
        WHEN CustomerID BETWEEN 1 AND 6024
            THEN 'Fragmento 1'

        WHEN CustomerID BETWEEN 6025 AND 12048
            THEN 'Fragmento 2'

        WHEN CustomerID BETWEEN 12049 AND 18072
            THEN 'Fragmento 3'

        WHEN CustomerID BETWEEN 18073 AND 24096
            THEN 'Fragmento 4'

        WHEN CustomerID BETWEEN 24097 AND 30118
            THEN 'Fragmento 5'
    END AS Fragmento,

    COUNT(*) AS TotalClientes

FROM Sales.Customer

GROUP BY
    CASE
        WHEN CustomerID BETWEEN 1 AND 6024
            THEN 'Fragmento 1'

        WHEN CustomerID BETWEEN 6025 AND 12048
            THEN 'Fragmento 2'

        WHEN CustomerID BETWEEN 12049 AND 18072
            THEN 'Fragmento 3'

        WHEN CustomerID BETWEEN 18073 AND 24096
            THEN 'Fragmento 4'

        WHEN CustomerID BETWEEN 24097 AND 30118
            THEN 'Fragmento 5'
    END

ORDER BY Fragmento;
GO

/*
Resultados:

Fragmento 1 = 701
Fragmento 2 = 1049
Fragmento 3 = 6024
Fragmento 4 = 6024
Fragmento 5 = 6022

TOTAL = 19820
*/


/*===========================================================
  3. PREDICADOS PARA COM_MIN

  p1: CustomerID < 6025
  p2: CustomerID < 12049
  p3: CustomerID < 18073
  p4: CustomerID < 24097

  Fragmentos resultantes:

  m1: CustomerID < 6025

  m2: CustomerID >= 6025
      AND CustomerID < 12049

  m3: CustomerID >= 12049
      AND CustomerID < 18073

  m4: CustomerID >= 18073
      AND CustomerID < 24097

  m5: CustomerID >= 24097
===========================================================*/


/*===========================================================
  4. ELIMINAR FRAGMENTOS SI YA EXISTEN

  Esto permite ejecutar nuevamente todo el código
  sin errores de tablas existentes.
===========================================================*/

DROP TABLE IF EXISTS dbo.SalesOrderDetail_1;
DROP TABLE IF EXISTS dbo.SalesOrderDetail_2;
DROP TABLE IF EXISTS dbo.SalesOrderDetail_3;
DROP TABLE IF EXISTS dbo.SalesOrderDetail_4;
DROP TABLE IF EXISTS dbo.SalesOrderDetail_5;

DROP TABLE IF EXISTS dbo.SalesOrderHeader_1;
DROP TABLE IF EXISTS dbo.SalesOrderHeader_2;
DROP TABLE IF EXISTS dbo.SalesOrderHeader_3;
DROP TABLE IF EXISTS dbo.SalesOrderHeader_4;
DROP TABLE IF EXISTS dbo.SalesOrderHeader_5;

DROP TABLE IF EXISTS dbo.Customer_1;
DROP TABLE IF EXISTS dbo.Customer_2;
DROP TABLE IF EXISTS dbo.Customer_3;
DROP TABLE IF EXISTS dbo.Customer_4;
DROP TABLE IF EXISTS dbo.Customer_5;
GO


/*===========================================================
  5. FRAGMENTACIÓN HORIZONTAL PRIMARIA
     Tabla propietaria: Sales.Customer
===========================================================*/


/*-------------------------
  FRAGMENTO 1
-------------------------*/

SELECT *
INTO dbo.Customer_1
FROM Sales.Customer
WHERE CustomerID BETWEEN 1 AND 6024;


/*-------------------------
  FRAGMENTO 2
-------------------------*/

SELECT *
INTO dbo.Customer_2
FROM Sales.Customer
WHERE CustomerID BETWEEN 6025 AND 12048;


/*-------------------------
  FRAGMENTO 3
-------------------------*/

SELECT *
INTO dbo.Customer_3
FROM Sales.Customer
WHERE CustomerID BETWEEN 12049 AND 18072;


/*-------------------------
  FRAGMENTO 4
-------------------------*/

SELECT *
INTO dbo.Customer_4
FROM Sales.Customer
WHERE CustomerID BETWEEN 18073 AND 24096;


/*-------------------------
  FRAGMENTO 5
-------------------------*/

SELECT *
INTO dbo.Customer_5
FROM Sales.Customer
WHERE CustomerID BETWEEN 24097 AND 30118;

GO


/*===========================================================
  6. COMPROBAR LOS FRAGMENTOS DE CUSTOMER
===========================================================*/

SELECT
    'Customer_1' AS Fragmento,
    COUNT(*) AS Registros
FROM dbo.Customer_1

UNION ALL

SELECT
    'Customer_2',
    COUNT(*)
FROM dbo.Customer_2

UNION ALL

SELECT
    'Customer_3',
    COUNT(*)
FROM dbo.Customer_3

UNION ALL

SELECT
    'Customer_4',
    COUNT(*)
FROM dbo.Customer_4

UNION ALL

SELECT
    'Customer_5',
    COUNT(*)
FROM dbo.Customer_5;

GO

/*
Resultados:

Customer_1 = 701
Customer_2 = 1049
Customer_3 = 6024
Customer_4 = 6024
Customer_5 = 6022
*/


/*===========================================================
  7. FRAGMENTACIÓN DERIVADA DE SALESORDERHEADER

  Se utiliza SEMI-JOIN con Customer.

  Customer_1 --> SalesOrderHeader_1
  Customer_2 --> SalesOrderHeader_2
  Customer_3 --> SalesOrderHeader_3
  Customer_4 --> SalesOrderHeader_4
  Customer_5 --> SalesOrderHeader_5
===========================================================*/


/* Fragmento derivado 1 */

SELECT SOH.*
INTO dbo.SalesOrderHeader_1
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN dbo.Customer_1 AS C
    ON SOH.CustomerID = C.CustomerID;


/* Fragmento derivado 2 */

SELECT SOH.*
INTO dbo.SalesOrderHeader_2
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN dbo.Customer_2 AS C
    ON SOH.CustomerID = C.CustomerID;


/* Fragmento derivado 3 */

SELECT SOH.*
INTO dbo.SalesOrderHeader_3
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN dbo.Customer_3 AS C
    ON SOH.CustomerID = C.CustomerID;


/* Fragmento derivado 4 */

SELECT SOH.*
INTO dbo.SalesOrderHeader_4
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN dbo.Customer_4 AS C
    ON SOH.CustomerID = C.CustomerID;


/* Fragmento derivado 5 */

SELECT SOH.*
INTO dbo.SalesOrderHeader_5
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN dbo.Customer_5 AS C
    ON SOH.CustomerID = C.CustomerID;

GO


/*===========================================================
  8. COMPROBAR SALESORDERHEADER
===========================================================*/

SELECT
    'SOH_1' AS Fragmento,
    COUNT(*) AS Registros
FROM dbo.SalesOrderHeader_1

UNION ALL

SELECT
    'SOH_2',
    COUNT(*)
FROM dbo.SalesOrderHeader_2

UNION ALL

SELECT
    'SOH_3',
    COUNT(*)
FROM dbo.SalesOrderHeader_3

UNION ALL

SELECT
    'SOH_4',
    COUNT(*)
FROM dbo.SalesOrderHeader_4

UNION ALL

SELECT
    'SOH_5',
    COUNT(*)
FROM dbo.SalesOrderHeader_5;

GO

/*
Resultados:

SOH_1 = 0
SOH_2 = 3084
SOH_3 = 10718
SOH_4 = 7569
SOH_5 = 10094

TOTAL = 31465
*/


/*===========================================================
  9. FRAGMENTACIÓN DERIVADA DE SALESORDERDETAIL

  Ahora se utiliza SalesOrderID.

  SalesOrderHeader_1 --> SalesOrderDetail_1
  SalesOrderHeader_2 --> SalesOrderDetail_2
  SalesOrderHeader_3 --> SalesOrderDetail_3
  SalesOrderHeader_4 --> SalesOrderDetail_4
  SalesOrderHeader_5 --> SalesOrderDetail_5
===========================================================*/


/* Fragmento derivado 1 */

SELECT SOD.*
INTO dbo.SalesOrderDetail_1
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN dbo.SalesOrderHeader_1 AS SOH
    ON SOD.SalesOrderID = SOH.SalesOrderID;


/* Fragmento derivado 2 */

SELECT SOD.*
INTO dbo.SalesOrderDetail_2
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN dbo.SalesOrderHeader_2 AS SOH
    ON SOD.SalesOrderID = SOH.SalesOrderID;


/* Fragmento derivado 3 */

SELECT SOD.*
INTO dbo.SalesOrderDetail_3
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN dbo.SalesOrderHeader_3 AS SOH
    ON SOD.SalesOrderID = SOH.SalesOrderID;


/* Fragmento derivado 4 */

SELECT SOD.*
INTO dbo.SalesOrderDetail_4
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN dbo.SalesOrderHeader_4 AS SOH
    ON SOD.SalesOrderID = SOH.SalesOrderID;


/* Fragmento derivado 5 */

SELECT SOD.*
INTO dbo.SalesOrderDetail_5
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN dbo.SalesOrderHeader_5 AS SOH
    ON SOD.SalesOrderID = SOH.SalesOrderID;

GO


/*===========================================================
  10. COMPROBAR SALESORDERDETAIL
===========================================================*/

SELECT
    'SOD_1' AS Fragmento,
    COUNT(*) AS Registros
FROM dbo.SalesOrderDetail_1

UNION ALL

SELECT
    'SOD_2',
    COUNT(*)
FROM dbo.SalesOrderDetail_2

UNION ALL

SELECT
    'SOD_3',
    COUNT(*)
FROM dbo.SalesOrderDetail_3

UNION ALL

SELECT
    'SOD_4',
    COUNT(*)
FROM dbo.SalesOrderDetail_4

UNION ALL

SELECT
    'SOD_5',
    COUNT(*)
FROM dbo.SalesOrderDetail_5;

GO

/*
Resultados:

SOD_1 = 0
SOD_2 = 6661
SOD_3 = 23313
SOD_4 = 17081
SOD_5 = 74262

TOTAL = 121317
*/


/*===========================================================
  11. REGLA 1: COMPLETITUD

  Comparamos la tabla original contra la suma
  de todos los fragmentos.
===========================================================*/

SELECT
    COUNT(*) AS TotalOriginal
FROM Sales.Customer;


SELECT
      (SELECT COUNT(*) FROM dbo.Customer_1)
    + (SELECT COUNT(*) FROM dbo.Customer_2)
    + (SELECT COUNT(*) FROM dbo.Customer_3)
    + (SELECT COUNT(*) FROM dbo.Customer_4)
    + (SELECT COUNT(*) FROM dbo.Customer_5)
    AS TotalFragmentos;

GO

/*
Resultado:

TotalOriginal    = 19820
TotalFragmentos  = 19820

SE CUMPLE COMPLETITUD
*/


/*===========================================================
  12. REGLA 2: RECONSTRUCCIÓN

  Se vuelven a unir los cinco fragmentos.
===========================================================*/

SELECT
    COUNT(*) AS TotalReconstruido
FROM
(
    SELECT * FROM dbo.Customer_1

    UNION ALL

    SELECT * FROM dbo.Customer_2

    UNION ALL

    SELECT * FROM dbo.Customer_3

    UNION ALL

    SELECT * FROM dbo.Customer_4

    UNION ALL

    SELECT * FROM dbo.Customer_5

) AS Reconstruccion;

GO

/*
Resultado:

TotalReconstruido = 19820

SE CUMPLE RECONSTRUCCIÓN
*/


/*===========================================================
  13. REGLA 3: DISYUNCIÓN

  Se comprueba que un CustomerID no aparezca
  en más de un fragmento.
===========================================================*/

SELECT
    CustomerID,
    COUNT(*) AS Veces
FROM
(
    SELECT CustomerID FROM dbo.Customer_1

    UNION ALL

    SELECT CustomerID FROM dbo.Customer_2

    UNION ALL

    SELECT CustomerID FROM dbo.Customer_3

    UNION ALL

    SELECT CustomerID FROM dbo.Customer_4

    UNION ALL

    SELECT CustomerID FROM dbo.Customer_5

) AS Fragmentos

GROUP BY CustomerID

HAVING COUNT(*) > 1;

GO

/*
Resultado:

0 filas

SE CUMPLE DISYUNCIÓN
*/


/*===========================================================
  14. COMPROBAR FRAGMENTACIÓN DERIVADA
      SALESORDERHEADER
===========================================================*/

SELECT
    (SELECT COUNT(*)
     FROM Sales.SalesOrderHeader)
     AS Original_SOH,

    (SELECT COUNT(*) FROM dbo.SalesOrderHeader_1)
    + (SELECT COUNT(*) FROM dbo.SalesOrderHeader_2)
    + (SELECT COUNT(*) FROM dbo.SalesOrderHeader_3)
    + (SELECT COUNT(*) FROM dbo.SalesOrderHeader_4)
    + (SELECT COUNT(*) FROM dbo.SalesOrderHeader_5)
    AS Fragmentado_SOH;

GO

/*
Resultado esperado y comprobado:

Original_SOH     = 31465
Fragmentado_SOH  = 31465
*/


/*===========================================================
  15. COMPROBAR FRAGMENTACIÓN DERIVADA
      SALESORDERDETAIL
===========================================================*/

SELECT
    (SELECT COUNT(*)
     FROM Sales.SalesOrderDetail)
     AS Original_SOD,

    (SELECT COUNT(*) FROM dbo.SalesOrderDetail_1)
    + (SELECT COUNT(*) FROM dbo.SalesOrderDetail_2)
    + (SELECT COUNT(*) FROM dbo.SalesOrderDetail_3)
    + (SELECT COUNT(*) FROM dbo.SalesOrderDetail_4)
    + (SELECT COUNT(*) FROM dbo.SalesOrderDetail_5)
    AS Fragmentado_SOD;

GO

/*
Resultado esperado y comprobado:

Original_SOD     = 121317
Fragmentado_SOD  = 121317
*/


/*===========================================================
                  RESULTADO FINAL

 CUSTOMER
 Original       = 19820
 Fragmentado    = 19820

 SALESORDERHEADER
 Original       = 31465
 Fragmentado    = 31465

 SALESORDERDETAIL
 Original       = 121317
 Fragmentado    = 121317

 REGLAS:

 COMPLETITUD     = CUMPLE
 RECONSTRUCCIÓN  = CUMPLE
 DISYUNCIÓN      = CUMPLE

===========================================================*/