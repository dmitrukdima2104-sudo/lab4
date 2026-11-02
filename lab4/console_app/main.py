import psycopg2
from psycopg2 import Error

def get_connection():
    """Створення підключення до бази даних PostgreSQL у Docker"""
    try:
        connection = psycopg2.connect(
            user="postgres",
            password="password",
            host="127.0.0.1",
            port="5432",
            database="car_service"
        )
        return connection
    except (Exception, Error) as error:
        print("❌ Помилка підключення до бази даних:", error)
        return None

def show_clients():
    """Виведення списку всіх клієнтів"""
    conn = get_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT client_id, first_name, last_name, phone, email FROM clients ORDER BY client_id;")
        rows = cursor.fetchall()
        
        print("\n--- СПИСОК КЛІЄНТІВ АВТОСЕРВІСУ ---")
        print(f"{'ID':<5} | {'Ім’я':<12} | {'Прізвище':<15} | {'Телефон':<15} | {'Email':<25}")
        print("-" * 80)
        for row in rows:
            print(f"{row[0]:<5} | {row[1]:<12} | {row[2]:<15} | {row[3]:<15} | {row[4]:<25}")
        cursor.close()
    except Exception as e:
        print("❌ Помилка виконання запиту:", e)
    finally:
        conn.close()

def show_services():
    """Виведення прайс-листа послуг"""
    conn = get_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT service_id, service_name, price FROM services;")
        rows = cursor.fetchall()
        
        print("\n--- ПРАЙС-ЛИСТ ПОСЛУГ ---")
        print(f"{'ID':<5} | {'Назва послуги':<35} | {'Ціна (грн)':<10}")
        print("-" * 55)
        for row in rows:
            print(f"{row[0]:<5} | {row[1]:<35} | {row[2]:<10}")
        cursor.close()
    except Exception as e:
        print("❌ Помилка виконання запиту:", e)
    finally:
        conn.close()

def add_client():
    """Додавання нового клієнта через консоль"""
    conn = get_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        print("\n--- ДОДАВАННЯ НОВОГО КЛІЄНТА ---")
        first_name = input("Введіть ім'я: ")
        last_name = input("Введіть прізвище: ")
        phone = input("Введіть телефон (+380...): ")
        email = input("Введіть email (необов'язково): ")

        query = "INSERT INTO clients (first_name, last_name, phone, email) VALUES (%s, %s, %s, %s);"
        cursor.execute(query, (first_name, last_name, phone, email if email else None))
        conn.commit()
        print("✅ Клієнта успішно додано до бази даних!")
        cursor.close()
    except Exception as e:
        print("❌ Помилка при додаванні клієнта:", e)
        conn.rollback()
    finally:
        conn.close()

def delete_client():
    """Видалення клієнта за ID з обробкою помилок"""
    conn = get_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        
        # Показуємо список клієнтів, щоб користувач бачив ID
        cursor.execute("SELECT client_id, first_name, last_name, phone FROM clients ORDER BY client_id;")
        rows = cursor.fetchall()
        
        print("\n--- ВИДАЛЕННЯ КЛІЄНТА ---")
        print(f"{'ID':<5} | {'Ім’я':<12} | {'Прізвище':<15} | {'Телефон':<15}")
        print("-" * 55)
        for row in rows:
            print(f"{row[0]:<5} | {row[1]:<12} | {row[2]:<15} | {row[3]:<15}")
            
        client_id_input = input("\nВведіть ID клієнта, якого потрібно видалити (або '0' для скасування): ")
        
        if client_id_input == '0':
            return
            
        if not client_id_input.isdigit():
            print("❌ Помилка: ID має складатися тільки з цифр!")
            return

        query = "DELETE FROM clients WHERE client_id = %s;"
        cursor.execute(query, (int(client_id_input),))
        
        if cursor.rowcount == 0:
            print("⚠️ Клієнт з таким ID не знайдений.")
        else:
            conn.commit()
            print("✅ Клієнта успішно видалено з бази даних!")
            
        cursor.close()
    except Exception as e:
        print("❌ Помилка при видаленні клієнта (можливо, до нього прив'язані дані):", e)
        conn.rollback()
    finally:
        conn.close()

def main():
    while True:
        print("\n=== ГОЛОВНЕ МЕНЮ АВТОСЕРВІСУ ===")
        print("1. Переглянути список клієнтів")
        print("2. Переглянути прайс-лист послуг")
        print("3. Додати нового клієнта")
        print("4. Видалити клієнта")
        print("5. Вихід")
        
        choice = input("Оберіть опцію (1-5): ")
        
        if choice == '1':
            show_clients()
        elif choice == '2':
            show_services()
        elif choice == '3':
            add_client()
        elif choice == '4':
            delete_client()
        elif choice == '5':
            print("Вихід з програми. До побачення!")
            break
        else:
            print("❌ Невірний вибір. Спробуйте ще раз.")

if __name__ == "__main__":
    main()