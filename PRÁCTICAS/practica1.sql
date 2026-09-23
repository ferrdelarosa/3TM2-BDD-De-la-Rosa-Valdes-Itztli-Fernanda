use AdventureWorks2022;


-- Eje 1: Encuentra los 10 productos más vendidos en 2014, mostrando nombre del producto, cantidad total vendida y nombre del cliente.
SELECT TOP 10 
    P.Name AS [Nombre del Producto], 
    SUM(SOD.OrderQty) AS [Cantidad Total Vendida],
    PER.FirstName + ' ' + PER.LastName AS [Nombre del Cliente]
FROM Production.Product P
JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
JOIN Person.Person PER ON C.PersonID = PER.BusinessEntityID
WHERE YEAR(SOH.OrderDate) = 2014
GROUP BY P.Name, PER.FirstName, PER.LastName
ORDER BY [Cantidad Total Vendida] DESC;


--Una vez resuelta la consulta: agrega el precio unitario promedio (AVG(UnitPrice)) y filtra solo 
--productos con ListPrice > 1000. 

SELECT TOP 10 
    P.Name AS [Nombre del Producto], 
    SUM(SOD.OrderQty) AS [Cantidad Total Vendida],
    AVG(SOD.UnitPrice) AS [Precio Unitario Promedio], -- AVG(UnitPrice)
    PER.FirstName + ' ' + PER.LastName AS [Nombre del Cliente]
FROM Production.Product P
JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
JOIN Person.Person PER ON C.PersonID = PER.BusinessEntityID
WHERE YEAR(SOH.OrderDate) = 2014 
  AND P.ListPrice > 1000 --ListPrice > 1000
GROUP BY P.Name, PER.FirstName, PER.LastName
ORDER BY [Cantidad Total Vendida] DESC;
 



--2.   Lista los empleados que han vendido más que el promedio de ventas por empleado en 
--el territorio 'Northwest'. 

SELECT 
    BusinessEntityID, 
    SalesYTD
FROM Sales.SalesPerson
WHERE TerritoryID = (SELECT TerritoryID FROM Sales.SalesTerritory WHERE Name = 'Northwest')
AND SalesYTD > (
    SELECT AVG(SalesYTD) 
    FROM Sales.SalesPerson 
    WHERE TerritoryID = (SELECT TerritoryID FROM Sales.SalesTerritory WHERE Name = 'Northwest')
);

-- Una vez resuelta la consulta convierte la subconsulta en un CTE (Common Table Expresión). 
WITH PromedioNorthwest AS (
    --  (CTE)
    SELECT AVG(SalesYTD) AS PromedioVentas
    FROM Sales.SalesPerson
    WHERE TerritoryID = (SELECT TerritoryID FROM Sales.SalesTerritory WHERE Name = 'Northwest')
)
SELECT 
    sp.BusinessEntityID, 
    sp.SalesYTD
FROM Sales.SalesPerson sp
CROSS JOIN PromedioNorthwest pnw
WHERE sp.TerritoryID = (SELECT TerritoryID FROM Sales.SalesTerritory WHERE Name = 'Northwest')
AND sp.SalesYTD > pnw.PromedioVentas;


--3.  Calcula ventas totales por territorio y año, mostrando solo aquellos con más de 5 órdenes 
--y ventas > $1,000,000, ordenado por ventas descendente. 


SELECT 
    ST.Name AS Territorio,
    YEAR(SOH.OrderDate) AS Anio,
    SUM(SOH.TotalDue) AS VentasTotales,
    COUNT(SOH.SalesOrderID) AS NumeroOrdenes
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.Name, YEAR(SOH.OrderDate)
HAVING COUNT(SOH.SalesOrderID) > 5 
   AND SUM(SOH.TotalDue) > 1000000
ORDER BY VentasTotales DESC;


--1. Una vez resuelta la consulta agrega desviación estándar de ventas 
SELECT 
    ST.Name AS Territorio,
    YEAR(SOH.OrderDate) AS Anio,
    SUM(SOH.TotalDue) AS VentasTotales,
    COUNT(SOH.SalesOrderID) AS NumeroOrdenes,
    STDEV(SOH.TotalDue) AS DesviacionVentas --Desviación
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.Name, YEAR(SOH.OrderDate)
HAVING COUNT(SOH.SalesOrderID) > 5 
   AND SUM(SOH.TotalDue) > 1000000
ORDER BY VentasTotales DESC;


--4. Encuentra vendedores que han vendido TODOS los productos de la categoría "Bikes".

SELECT 
    SOH.SalesPersonID,
    COUNT(DISTINCT P.ProductID) AS ProductosDistintosVendidos
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE PC.Name = 'Bikes' AND SOH.SalesPersonID IS NOT NULL
GROUP BY SOH.SalesPersonID
HAVING COUNT(DISTINCT P.ProductID) = (
    SELECT COUNT(P2.ProductID)
    FROM Production.Product P2
    JOIN Production.ProductSubcategory PSC2 ON P2.ProductSubcategoryID = PSC2.ProductSubcategoryID
    JOIN Production.ProductCategory PC2 ON PSC2.ProductCategoryID = PC2.ProductCategoryID
    WHERE PC2.Name = 'Bikes'
);

--Cambia a categoría "Clothing" (ID=4). 
SELECT 
    SOH.SalesPersonID,
    PC.Name AS Categoria
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE PC.ProductCategoryID = 4 --Clothing 
AND SOH.SalesPersonID IS NOT NULL
GROUP BY SOH.SalesPersonID, PC.Name;

--Cuenta cuántos productos por categoría maneja cada vendedor. 


SELECT 
    SOH.SalesPersonID,
    PC.Name AS Categoria,
    COUNT(DISTINCT P.ProductID) AS CantidadProductosManejados 
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE PC.ProductCategoryID = 4
AND SOH.SalesPersonID IS NOT NULL
GROUP BY SOH.SalesPersonID, PC.Name
ORDER BY CantidadProductosManejados DESC;


--Ejercicio 5: Determinar el producto más vendido de cada categoría de producto, considerando el 
--escenario de que el esquema SALES se encuentra en una instancia (servidor) A y el esquema 
--PRODUCTION en otra instancia (servidor) B. 

SELECT Categoria, Producto, TotalVendido
FROM (
    SELECT 
        PC.Name AS Categoria, 
        P.Name AS Producto, 
        SUM(SOD.OrderQty) AS TotalVendido,
        ROW_NUMBER() OVER(PARTITION BY PC.Name ORDER BY SUM(SOD.OrderQty) DESC) as Ranking
    FROM Sales.SalesOrderDetail SOD -- LOCAL
 
    JOIN [26.7.159.60].[AdventureWorks2022].[Production].[Product] P 
        ON SOD.ProductID = P.ProductID
    JOIN [26.7.159.60].[AdventureWorks2022].[Production].[ProductSubcategory] PS 
        ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN [26.7.159.60].[AdventureWorks2022].[Production].[ProductCategory] PC 
        ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY PC.Name, P.Name
) AS Resultados
WHERE Ranking = 1; 
