-- 1. Вивести всіх клієнтів разом з їхніми автомобілями (INNER JOIN)
SELECT 
    c.first_name AS "Ім'я",
    c.last_name AS "Прізвище",
    c.phone "Телефон",
    car.brand AS "Марка",
    car.model AS "Модель",
    car.production_year AS "Рік",
    car.vin AS "VIN-код"
FROM clients c
JOIN cars car ON c.client_id = car.client_id;

-- 2. Вивести список усіх замовлень із зазначенням клієнта, марки авто та майстра, який виконував роботу
SELECT 
    o.order_id AS "ID Замовлення",
    CONCAT(cl.first_name, ' ', cl.last_name) AS "Клієнт",
    CONCAT(car.brand, ' ', car.model) AS "Автомобіль",
    CONCAT(e.first_name, ' ', e.last_name) AS "Майстер",
    o.status AS "Статус",
    o.total_amount AS "Сума (грн)",
    o.order_date AS "Дата"
FROM orders o
JOIN cars car ON o.car_id = car.car_id
JOIN clients cl ON car.client_id = cl.client_id
LEFT JOIN employees e ON o.employee_id = e.employee_id;

-- 3. Деталі конкретного замовлення (наприклад, замовлення №1): які послуги виконувались та яка їх вартість
SELECT 
    oi.order_id AS "Замовлення №",
    s.service_name AS "Послуга",
    oi.quantity "Кількість",
    oi.subtotal AS "Вартість (грн)"
FROM order_items oi
JOIN services s ON oi.service_id = s.service_id
WHERE oi.order_id = 1;

-- 4. Загальна сума наданих послуг та кількість замовлень по кожному майстру (GROUP BY + агрегатні функції)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS "Майстер",
    e.position AS "Посада",
    COUNT(o.order_id) AS "Кількість замовлень",
    SUM(o.total_amount) AS "Загальна виручка (грн)"
FROM employees e
LEFT JOIN orders o ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.position;

-- 5. Пошук послуг, ціна яких вища за середню по автосервісу (підзапит)
SELECT 
    service_name AS "Послуга",
    price AS "Ціна (грн)"
FROM services
WHERE price > (SELECT AVG(price) FROM services);