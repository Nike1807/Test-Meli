-- Creación de tipo de usuario

CREATE TABLE Tipo_Usuario (
    tipo_usuario_id    INT AUTO_INCREMENT PRIMARY KEY,
    tipo        VARCHAR(50) UNIQUE NOT NULL
);

--Creación de la tabla de clientes

CREATE TABLE Customer (
    customer_id        INT AUTO_INCREMENT PRIMARY KEY,
    email              VARCHAR(255) UNIQUE NOT NULL,
    nombre             VARCHAR(100) NOT NULL,
    apellido           VARCHAR(100) NOT NULL,
    sexo               ENUM('M', 'F', 'Otro') NOT NULL,
    direccion          TEXT,
    fecha_nacimiento   DATE,
    telefono           VARCHAR(20),
    tipo_usuario_id    INT NOT NULL, -- Se decidió definirlo como ID y generar una tabla aparte con los tipos de usuario , ya que esto da flexibilidad para el crecimiento futuro de distintos tipos du usuarios.
     FOREIGN KEY (tipo_usuario_id) REFERENCES Tipo_Usuario(tipo_usuario_id) ON DELETE RESTRICT ON UPDATE CASCADE -- No nos permite eliminar un tipo de usuario si está siendo usado por la tabla Customer, a su vez nos permite actualizar los registros si la PK de la tabla Tipo_Usuario cambia 
);

CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(255) NOT NULL,
    path        VARCHAR(500) NOT NULL
);

CREATE TABLE Item (
    item_id       INT AUTO_INCREMENT PRIMARY KEY,
    item_nombre   VARCHAR(255) NOT NULL,
    descripcion   TEXT,
    precio        DECIMAL(10,2) NOT NULL CHECK (precio >= 0), -- Chequea que el precio no sea 0
    estado        ENUM('Activo', 'Inactivo') NOT NULL DEFAULT 'Activo', -- Utiliza activo como valor por defecto
    fecha_baja    DATE NULL,
    category_id   INT NOT NULL,
    seller_id     INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE SET NULL ON UPDATE CASCADE, -- Nos permite eliminar una category si está siendo usado por la tabla Item pero está será seteada a null, a su vez nos permite actualizar los registros si la PK de la tabla Category cambia. 
    FOREIGN KEY (seller_id) REFERENCES Customer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE -- Elimina los items asociados si se elimina el customerId de la tabla Customer, a su vez nos permite actualizar los registros si la PK de la tabla Customer cambia. Esto es debatible, puede que no se conveniente si queremos mantener un historial de los items de la plataforma.
);

CREATE TABLE `Order` (
    order_id   INT AUTO_INCREMENT PRIMARY KEY,
    fecha      DATETIME DEFAULT CURRENT_TIMESTAMP,
    buyer_id   INT NOT NULL,
    total      DECIMAL(10,2) NOT NULL CHECK (total >= 0), -- Evita valores negativos
    FOREIGN KEY (buyer_id) REFERENCES Customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE -- No nos permite eliminar un customer si tiene siendo usado por la tabla Order, a su vez nos permite actualizar los registros si la PK de la tabla Customer cambia 
);

CREATE TABLE Order_Item (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY, 
    order_id      INT NOT NULL,
    item_id       INT NOT NULL,
    cantidad      INT NOT NULL CHECK (cantidad > 0),
    subtotal      DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `Order`(order_id) ON DELETE CASCADE ON UPDATE CASCADE, -- Si una order_id se elimina/actualiza de la tabla Order, todos los registros relacionados en Order_Item también se eliminan/actualizan automáticamente.
    FOREIGN KEY (item_id) REFERENCES Item(item_id) ON DELETE RESTRICT ON UPDATE CASCADE -- No permite que se elimine un item que si es parte de una order, debatible, se puede usar ON DELETE SET NULL para nullearlo si se requiere eliminarlo.
);
