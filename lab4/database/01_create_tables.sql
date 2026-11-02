-- 1. Клієнти автосервісу
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Автомобілі клієнтів
CREATE TABLE cars (
    car_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    production_year INT CHECK (production_year >= 1900 AND production_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    vin VARCHAR(17) UNIQUE NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE
);

-- 3. Співробітники / Майстри
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL, -- Наприклад: Механік, Електрик, Приймальник
    phone VARCHAR(20) NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE
);

-- 4. Каталог послуг (прайс-лист)
CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) CHECK (price >= 0) NOT NULL
);

-- 5. Замовлення на ремонт
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    car_id INT NOT NULL,
    employee_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'В роботі' CHECK (status IN ('В роботі', 'Виконано', 'Скасовано')),
    total_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (total_amount >= 0),
    FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

-- 6. Проміжна таблиця для зв'язку багато-до-багато (Послуги в замовленні)
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    service_id INT NOT NULL,
    quantity INT CHECK (quantity > 0) DEFAULT 1,
    subtotal DECIMAL(10, 2) CHECK (subtotal >= 0) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
);

-- Створення індексів для оптимізації запитів
CREATE INDEX idx_cars_client_id ON cars(client_id);
CREATE INDEX idx_orders_car_id ON orders(car_id);
CREATE INDEX idx_orders_employee_id ON orders(employee_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);