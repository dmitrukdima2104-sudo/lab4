-- ==========================================
-- 1. ПРЕДСТАВЛЕННЯ (Views) [Вимога: мінімум 2]
-- ==========================================

-- Представлення 1: Повна інформація про автомобілі та їх власників
CREATE OR REPLACE VIEW v_client_cars AS
SELECT 
    c.client_id,
    CONCAT(c.first_name, ' ', c.last_name) AS client_name,
    c.phone,
    car.car_id,
    car.brand,
    car.model,
    car.production_year,
    car.vin
FROM clients c
JOIN cars car ON c.client_id = car.client_id;

-- Представлення 2: Зведена інформація про замовлення та їх статус
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    o.status,
    CONCAT(cl.first_name, ' ', cl.last_name) AS client_name,
    CONCAT(car.brand, ' ', car.model) AS car_model,
    o.total_amount
FROM orders o
JOIN cars car ON o.car_id = car.car_id
JOIN clients cl ON car.client_id = cl.client_id;


-- ==========================================
-- 2. ТРИГЕРИ ТА ФУНКЦІЇ [Вимога: мінімум 2 тригери]
-- ==========================================

-- Тригер 1: Перевірка, щоб сума замовлення не була від'ємною
CREATE OR REPLACE FUNCTION check_order_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_amount < 0 THEN
        NEW.total_amount := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_order_amount ON orders;
CREATE TRIGGER trg_check_order_amount
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION check_order_amount();

-- Тригер 2: Автоматичне встановлення статусу "Новий", якщо статус не вказано
CREATE OR REPLACE FUNCTION set_default_order_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS NULL OR NEW.status = '' THEN
        NEW.status := 'Новий';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_default_order_status ON orders;
CREATE TRIGGER trg_set_default_order_status
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_default_order_status();


-- ==========================================
-- 3. ЗБЕРЕЖЕНІ ПРОЦЕДУРИ [Вимога: мінімум 3]
-- ==========================================

-- Процедура 1: Додавання нового клієнта
CREATE OR REPLACE PROCEDURE sp_add_client(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_phone VARCHAR,
    p_email VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO clients (first_name, last_name, phone, email)
    VALUES (p_first_name, p_last_name, p_phone, p_email);
END;
$$;

-- Процедура 2: Оновлення ціни послуги
CREATE OR REPLACE PROCEDURE sp_update_service_price(
    p_service_id INT,
    p_new_price NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE services 
    SET price = p_new_price 
    WHERE service_id = p_service_id;
END;
$$;

-- Процедура 3: Видалення клієнта за ID
CREATE OR REPLACE PROCEDURE sp_delete_client(
    p_client_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM clients WHERE client_id = p_client_id;
END;
$$;


-- ==========================================
-- 4. АНАЛИТИЧНІ ЗАПИТИ З АГРЕГАЦІЄЮ [Вимога: мінімум 3]
-- ==========================================

-- Аналітичний запит 1: Загальна виручка та кількість замовлень по кожному майстру
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.position,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_revenue
FROM employees e
LEFT JOIN orders o ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.position;

-- Аналітичний запит 2: Середній чек та максимальна вартість замовлення по статусах
SELECT 
    status,
    COUNT(order_id) AS orders_count,
    ROUND(AVG(total_amount), 2) AS avg_amount,
    MAX(total_amount) AS max_amount
FROM orders
GROUP BY status;

-- Аналітичний запит 3: Топ послуг за загальною кількістю їх використання в замовленнях
SELECT 
    s.service_name,
    SUM(oi.quantity) AS total_booked,
    SUM(oi.subtotal) AS total_earned
FROM order_items oi
JOIN services s ON oi.service_id = s.service_id
GROUP BY s.service_id, s.service_name
ORDER BY total_earned DESC;