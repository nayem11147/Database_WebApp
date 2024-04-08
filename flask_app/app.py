from flask import Flask, render_template, request, redirect, url_for
import MySQLdb

app = Flask(__name__)

# Database configuration
DB_HOST = "localhost"
DB_USER = "uXX"
DB_NAME = "uXX"
DB_PASSWORD = "YourPWD"

# App config
PORT = 11147  # provide a unique integer value instead of XXXX, e.g., PORT = 15657


def get_db_connection():
    conn = MySQLdb.connect(host=DB_HOST, user=DB_USER, passwd=DB_PASSWORD, db=DB_NAME)
    return conn


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/table", methods=["POST"])
def show_table():
    name = request.form.get("table_name")

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = %s",
            (name,),
        )
        headers = (h[0] for h in cur.fetchall())
        cur.execute(f"SELECT * FROM %s", (name,))
        data = cur.fetchall()
    except MySQLdb.Error as e:
        cur.close()
        conn.close()
        return render_template("error.html", err=e)

    cur.close()
    conn.close()
    return render_template(
        "table.html", table_name=name, table_headers=headers, table_data=data
    )


@app.route("/supplier", methods=["POST"])
def add_supplier():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        details = request.form
        cur.execute(
            "INSERT INTO suppliers(supplier_id, name, email) VALUES (%s, %s, %s)",
            (details["sup_id"], details["sup_name"], details["sup_email"]),
        )
        for num in details["sup_tel"].split(","):
            cur.execute(
                "INSERT INTO suppliers_telephone(supplier_id, number) VALUES (%s, %s)",
                (details["sup_id"], num.strip()),
            )
    except MySQLdb.Error as e:
        conn.commit()
        cur.close()
        conn.close()
        return render_template("error.html", err=e)

    conn.commit()
    cur.close()
    conn.close()
    return redirect("/")


@app.route("/expenses", methods=["POST"])
def annual_expenses():
    start_year = int(request.form.get("start_year"))
    end_year = int(request.form.get("end_year"))

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT YEAR(orders.order_date), SUM(order_parts.quantity * parts.price)
            FROM order_parts, orders, parts
            WHERE orders.order_id = order_parts.order_id
            AND order_parts.part_id = parts._id
            AND YEAR(orders.order_date) BETWEEN %s AND %s
            GROUP BY YEAR(orders.order_date)
            ORDER BY YEAR(orders.order_date) DESC;
            """,
            (start_year, end_year),
        )
        data = cur.fetchall()
    except MySQLdb.Error as e:
        cur.close()
        conn.close()
        return render_template("error.html", err=e)

    cur.close()
    conn.close()
    return render_template(
        "expenses.html",
        start_year=start_year,
        end_year=end_year,
        table_data=data,
    )


@app.route("/budget", methods=["POST"])
def budget_projection():
    years = int(request.form.get("years"))
    rate = float(request.form.get("rate"))

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT YEAR(orders.order_date), SUM(order_parts.quantity * parts.price)
            FROM order_parts, orders, parts
            WHERE orders.order_id = order_parts.order_id
            AND order_parts.part_id = parts._id
            GROUP BY YEAR(orders.order_date)
            ORDER BY YEAR(orders.order_date) DESC
            LIMIT 1;
            """
        )
        data = cur.fetchone()
        last_yr = int(data[0])
        total_expenses = float(data[1])
        tdata = [
            [last_yr + i, round(total_expenses * (1 + rate / 100) ** i, 2)]
            for i in range(1, years + 1)
        ]
    except MySQLdb.Error as e:
        cur.close()
        conn.close()
        return render_template("error.html", err=e)

    cur.close()
    conn.close()
    return render_template("budget.html", years=years, rate=rate, table_data=tdata)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=PORT)
