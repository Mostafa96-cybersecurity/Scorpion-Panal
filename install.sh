#!/bin/bash

# Execute install-panel.sh
echo "Installing panel..."
./install-panel.sh

# Print completion message
echo "Installation completed successfully!"

# Update and install necessary packages
sudo apt update
sudo apt install -y nginx mysql-server python3-pip exim4

# Install Python packages
pip3 install Flask PyMySQL

# Setup MySQL
sudo mysql -e "CREATE DATABASE scorpion;"
sudo mysql -e "CREATE USER 'scorpion'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON scorpion.* TO 'scorpion'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Setup Nginx
sudo tee /etc/nginx/sites-available/scorpion-panal <<EOF
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/scorpion-panal /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Setup Exim
sudo dpkg-reconfigure exim4-config

# Create project structure
mkdir -p /var/www/scorpion-panal/app/templates

# Create Flask application
cat << 'EOF' > /var/www/scorpion-panal/app/app.py
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
EOF

# Create HTML template
cat << 'EOF' > /var/www/scorpion-panal/app/templates/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Scorpion Panel</title>
</head>
<body>
    <h1>Web Hosting Control Panel</h1>
    <form action="/add_domain" method="post">
        <label for="domain">Add Domain:</label>
        <input type="text" id="domain" name="domain">
        <input type="submit" value="Add">
    </form>
</body>
</html>
EOF

# Create requirements.txt
cat << 'EOF' > /var/www/scorpion-panal/requirements.txt
Flask
PyMySQL
EOF

# Create README.md
cat << 'EOF' > /var/www/scorpion-panal/README.md
# Scorpion-Panal

A custom web hosting and mail server control panel.

## Installation

Run the setup script to install and configure necessary components:
\`\`\`bash
bash install.sh
\`\`\`

Start the Flask application:
\`\`\`bash
python3 /var/www/scorpion-panal/app/app.py
\`\`\`

## Features

- Web Hosting Management
- Mail Server Management
- User Management
- Security
- Analytics & Monitoring
EOF

echo "Setup Complete. Please start the Flask app by running 'python3 /var/www/scorpion-panal/app/app.py'"

