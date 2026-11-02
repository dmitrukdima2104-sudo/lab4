from flpython -m pip install flask psycopg2-binaryask import Flask, render_template, request, redirect, url_for
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host="127.0.0.1",
        database="car_service",
        user="postgres",
        password="password",
        port=5432
    )
    return conn

@app.route('/')
def index():
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # Используем наше представление (View) для клиентов и машин
    cursor.execute("SELECT * FROM v_client_cars;")
    clients = cursor.fetchall()
    
    # Получаем данные аналитического запроса для отображения статистики на сайте
    cursor.execute("""
        SELECT 
            CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
            e.position,
            COUNT(o.order_id) AS total_orders,
            SUM(o.total_amount) AS total_revenue
        FROM employees e
        LEFT JOIN orders o ON e.employee_id = o.employee_id
        GROUP BY e.employee_id, e.first_name, e.last_name, e.position;
    """)
    stats = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return render_template('index.html', clients=clients, stats=stats)

@app.route('/add', methods=('GET', 'POST'))
def add_client():
    if request.method == 'POST':
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        phone = request.form['phone']
        email = request.form['email']
        
        conn = get_db_connection()
        cursor = conn.cursor()
        # Используем сохраненную процедуру из базы данных (требование Уровня 2)
        cursor.execute("CALL sp_add_client(%s, %s, %s, %s);", (first_name, last_name, phone, email))
        conn.commit()
        cursor.close()
        conn.close()
        return redirect(url_for('index'))
        
    return render_template('add_client.html')

if __name__ == '__main__':
    app.run(debug=True, port=5000)