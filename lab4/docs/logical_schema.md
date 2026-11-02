# Логічна схема бази даних (Автосервіс)

База даних складається з таких таблиць (3НФ):
1. **clients** (client_id, first_name, last_name, phone, email)
2. **cars** (car_id, client_id, brand, model, year, vin)
3. **employees** (employee_id, first_name, last_name, position, phone)
4. **services** (service_id, service_name, price, description)
5. **orders** (order_id, car_id, employee_id, order_date, status, total_amount)
6. **order_items** (item_id, order_id, service_id, quantity, price)