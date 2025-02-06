 --1) Listar los usuarios que cumplan años el día de hoy cuya cantidad de ventas realizadas en enero 2020 sea superior a 1500.

SELECT C.customer_id,
       COUNT(OI.order_item_id) AS total_vendidos -- Si se quisiera excluir total_vendidos del select, podriamos utilizar una CTE para calcularlo y solo devolver el customer_id.
FROM Customer C
JOIN Item I ON C.customer_id = I.seller_id
JOIN Order_Item OI ON I.item_id = OI.item_id
JOIN `Order` O ON OI.order_id = O.order_id
WHERE -- Clientes que cumplen años hoy
 DATE_FORMAT(C.fecha_nacimiento, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d')
  AND O.fecha BETWEEN '2020-01-01' AND '2020-01-31'
GROUP BY C.customer_id HAVING total_vendidos > 1500;

 --2)Por cada mes del 2020, se solicita el top 5 de usuarios que más vendieron($) en la categoría Celulares. Se requiere el mes y año de análisis, nombre y apellido del vendedor, cantidad de ventas realizadas, cantidad de productos vendidos y el monto total transaccionado.
 WITH Ranking AS  -- Definimos una CTE para hacer calculos y crear el ranking
  ( SELECT MONTH(O.fecha) AS mes,
           YEAR(O.fecha) AS año,
           C.customer_id,
           C.nombre,
           C.apellido,
           COUNT(DISTINCT O.order_id) AS cantidad_ventas,
           SUM(OI.cantidad) AS cantidad_productos_vendidos,
           SUM(OI.subtotal) AS monto_total,
           RANK() OVER (PARTITION BY YEAR(O.fecha), MONTH(O.fecha)
                        ORDER BY SUM(O.total) DESC) AS ranking
   FROM Order_Item OI
   JOIN Item I ON OI.item_id = I.item_id
   JOIN Order O ON OI.order_id = O.order_id
   JOIN Customer C ON I.seller_id = C.customer_id
   WHERE YEAR(O.fecha) = 2020
     AND I.category_id = 20 -- Asumimos que la category ID 20 = Celulares
   GROUP BY mes,
            año,
            C.customer_id)
SELECT *
FROM Ranking
WHERE ranking <= 5;


--3) Se solicita poblar una nueva tabla con el precio y estado de los Ítems a fin del día. Tener en cuenta que debe ser reprocesable. Vale resaltar que en la tabla Item, vamos a tener únicamente el último estado informado por la PK definida. (Se puede resolver a través de StoredProcedure) 

--Creamos la tabla que almacenará los datos de los día por día
CREATE TABLE Item_Historico (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    item_id         INT NOT NULL,
    precio          DECIMAL(10,2) NOT NULL,
    estado          ENUM('Activo', 'Inactivo') NOT NULL,
    fecha_registro  DATE NOT NULL,  -- El proceso correrá una vez por dia, por lo cual vemos mejor usar DATE a DATETIME
    FOREIGN KEY (item_id) REFERENCES Item(item_id) ON DELETE CASCADE ON UPDATE CASCADE
);

--Creamos el Stored procedure para insertar los datos a la tabla

DELIMITER //

CREATE PROCEDURE RegistrarEstadoItems()
BEGIN
    INSERT INTO Item_Historico (item_id, precio, estado, fecha_registro)
    SELECT 
        i.item_id, 
        i.precio, 
        i.estado, 
        CURDATE()
    FROM 
        Item i
    WHERE  -- Evitar duplicados para el mismo día, nos garantiza que solo se añada una vez por día cada actualización de item a la tabla
        NOT EXISTS (
            SELECT 1 
            FROM Item_Historico ih 
            WHERE ih.item_id = i.item_id 
              AND ih.fecha_registro = CURDATE() 
        );
END //

DELIMITER ;

--Activar el event_scheduler (solo si está desactivado)
SET GLOBAL event_scheduler = ON;

-- Creamos el Evento para ejecutar el procedimiento una vez al día y automatizarlo

DELIMITER //

CREATE EVENT IF NOT EXISTS EstadoItemsDiario
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURDATE() + INTERVAL 1 DAY, '23:59:59')  -- Se ejecuta al finalizar el día
DO 
BEGIN
    CALL RegistrarEstadoItems();
END //

DELIMITER ;