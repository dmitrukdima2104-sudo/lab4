# Звіт з лабораторної роботи №4
**Тема:** Розробка реляційної бази даних з простою інтеграцією  
**Предметна область:** Система обліку автосервісу

---

## 1. Загальна інформація
- **ПІБ студента:** [Ваше ПІБ]
- **Група:** [Ваша група]
- **Варіант (предметна область):** Система обліку автосервісу
- **Рівень виконання:** Рівень 2 (Додаткова функціональність: представлення, тригери, збережені процедури та вебзастосунок на Flask)

---

## 2. Опис предметної області
Розроблена інформаційна система призначена для автоматизації бізнес-процесів станції технічного обслуговування (автосервісу). Основне призначення системи — ведення єдиної бази даних клієнтів, їхніх транспортних засобів, обліку співробітників, каталогу послуг та оформлення замовлень на ремонт.

Основні сутності предметної області:
1. **Клієнти (`clients`)** — зберігають контактну інформацію про замовників (ім'я, прізвище, телефон, email).
2. **Автомобілі (`cars`)** — містять дані про транспортні засоби клієнтів (марка, модель, рік випуску, VIN-код) із прив'язкою до конкретного власника.
3. **Співробітники (`employees`)** — персонал автосервісу (майстри-приймальники, автоелектрики, механіки) із зазначенням посади та контактів.
4. **Послуги (`services`)** — перелік робіт, що надаються автосервісом, з їхньою базовою вартістю.
5. **Замовлення (`orders`)** — фіксують факт звернення клієнта, дату, статус замовлення, прив'язку до автомобіля, майстра та підсумкову вартість.
6. **Позиції замовлення (`order_items`)** — деталізація замовлення (які саме послуги та в якій кількості були виконані в межах конкретного замовлення).

---

## 3. Концептуальна модель (ER-діаграма)
Концептуальна модель побудована на основі реляційних зв'язків:
- Між `clients` та `cars` встановлено зв'язок **1 до багатьох** (один клієнт може мати кілька автомобілів).
- Між `cars` та `orders` — зв'язок **1 до багатьох** (один автомобіль може обслуговуватися кілька разів).
- Між `employees` та `orders` — зв'язок **1 до багатьох** (майстер може виконувати кілька замовлень).
- Між `orders` та `services` реалізовано зв'язок **багато до багатьох** через проміжну таблицю `order_items`.

---

## 4. Логічна схема
Схема проєкту спроєктована відповідно до вимог **третьої нормальної форми (3НФ)**:
- Усі атрибути атомарні (1НФ).
- Відсутні часткові залежності неключових атрибутів від складених ключів (2НФ).
- Усунуто транзитивні залежності між неключовими полями (3НФ), що гарантує відсутність аномалій оновлення та видалення.

---

## 5. Реалізація в PostgreSQL (Рівень 1 та 2)

### А. Представлення (Views)
Для спрощення складних вибірок створено два представлення:
```sql
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
```

### Б. Тригери та функції (Triggers)
Реалізовано автоматизацію перевірки та призначення значень:
```sql
-- Тригер 1: Запобігання від'ємній сумі замовлення
CREATE OR REPLACE FUNCTION check_order_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_amount < 0 THEN
        NEW.total_amount := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_order_amount
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION check_order_amount();

-- Тригер 2: Автоматичне призначення статусу "Новий" за замовчуванням
CREATE OR REPLACE FUNCTION set_default_order_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS NULL OR NEW.status = '' THEN
        NEW.status := 'Новий';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_default_order_status
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_default_order_status();
```

### В. Збережені процедури (Stored Procedures)
```sql
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

-- Процедура 3: Видалення клієнта
CREATE OR REPLACE PROCEDURE sp_delete_client(p_client_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM clients WHERE client_id = p_client_id;
END;
$$;
```

---

## 6. Налаштування Docker
Для ізольованого та швидкого розгортання СУБД використано Docker Compose (`docker-compose.yml`):
```yaml
services:
  postgres:
    image: postgres:17-alpine
    container_name: car_service_db
    environment:
      POSTGRES_DB: car_service
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database:/docker-entrypoint-initdb.d
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## 7. Вебзастосунок на Flask (Рівень 2)
Для взаємодії з базою даних розроблено вебзастосунок на основі мікрофреймворку **Flask**:
- **Маршрут `/` (Головна сторінка):** Відображає списки клієнтів із машин через представлення `v_client_cars` та зведену аналітику по виручці майстрів.
- **Маршрут `/add`:** Надає HTML-форму для додавання нових клієнтів, яка на сервері викликає збережену процедуру `sp_add_client`.

---

## 8. Висновки
У ході виконання лабораторної роботи було успішно спроєктовано та реалізовано реляційну базу даних «Система обліку автосервісу». Продемонстровано навички роботи з Docker, написання складних SQL-скриптів (представлення, процедури, тригери, агрегатні запити) та створення сучасного вебзастосунку на Python/Flask. Усі вимоги **Рівня 2** виконано в повному обсязі.