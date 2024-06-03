from flask import Flask, render_template, request, redirect, url_for
import pymysql

app = Flask(__name__)

# Database connection
db = pymysql.connect(host="localhost", user="scorpion", password="password", database="scorpion")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/add_domain', methods=['POST'])
def add_domain():
    domain = request.form['domain']
    cursor = db.cursor()
    cursor.execute(f"INSERT INTO domains (name) VALUES ('{domain}')")
    db.commit()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

