#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Create application directories
mkdir -p /opt/terraform-part1/backend
mkdir -p /opt/terraform-part1/frontend/public

# =========================================================
# Flask Backend
# =========================================================

cat > /opt/terraform-part1/backend/app.py <<'PYTHON'
from flask import Flask, jsonify, request
import uuid

app = Flask(__name__)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "Backend is running successfully."
    })


@app.route("/submittodoitem", methods=["POST"])
def submit_todo_item():
    try:
        data = request.get_json(silent=True) or {}

        item_name = str(data.get("itemName", "")).strip()
        item_description = str(
            data.get("itemDescription", "")
        ).strip()

        if not item_name or not item_description:
            return jsonify({
                "error": "Item Name and Item Description are required."
            }), 400

        item_id = str(uuid.uuid4())

        return jsonify({
            "message": "To-Do item processed successfully.",
            "itemId": item_id,
            "itemName": item_name,
            "itemDescription": item_description
        }), 201

    except Exception as error:
        return jsonify({
            "error": "An error occurred while processing the request.",
            "details": str(error)
        }), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYTHON

# Create Python virtual environment
python3 -m venv /opt/terraform-part1/backend/venv

# Install Flask
/opt/terraform-part1/backend/venv/bin/pip install --upgrade pip
/opt/terraform-part1/backend/venv/bin/pip install Flask

# =========================================================
# Express Frontend
# =========================================================

cat > /opt/terraform-part1/frontend/package.json <<'JSON'
{
  "name": "terraform-part1-frontend",
  "version": "1.0.0",
  "description": "Express frontend for Terraform Part 1",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^5.1.0"
  }
}
JSON

cat > /opt/terraform-part1/frontend/server.js <<'JAVASCRIPT'
const express = require("express");
const path = require("path");

const app = express();
const PORT = 3000;

const BACKEND_URL =
    process.env.BACKEND_URL || "http://127.0.0.1:5000";

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "public")));

app.post("/submit", async (req, res) => {
    try {
        const response = await fetch(`${BACKEND_URL}/submittodoitem`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                itemName: req.body.itemName,
                itemDescription: req.body.itemDescription
            })
        });

        const data = await response.json();

        if (!response.ok) {
            return res.status(response.status).json(data);
        }

        res.status(201).json(data);

    } catch (error) {
        res.status(500).json({
            error: "Unable to connect to Flask backend.",
            details: error.message
        });
    }
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`Frontend server running on port ${PORT}`);
});
JAVASCRIPT

cat > /opt/terraform-part1/frontend/public/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Part 1 - To-Do App</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f7fb;
            margin: 0;
            padding: 40px;
        }

        .container {
            max-width: 600px;
            margin: auto;
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
        }

        h1 {
            text-align: center;
            margin-bottom: 25px;
        }

        label {
            display: block;
            margin-top: 15px;
            margin-bottom: 6px;
            font-weight: bold;
        }

        input,
        textarea {
            width: 100%;
            box-sizing: border-box;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
        }

        textarea {
            min-height: 120px;
            resize: vertical;
        }

        button {
            width: 100%;
            margin-top: 20px;
            padding: 12px;
            border: none;
            border-radius: 6px;
            background: #222;
            color: white;
            font-size: 16px;
            cursor: pointer;
        }

        button:hover {
            background: #444;
        }

        #result {
            margin-top: 20px;
            padding: 15px;
            border-radius: 6px;
            background: #f0f0f0;
            white-space: pre-wrap;
            word-break: break-word;
        }
    </style>
</head>

<body>

<div class="container">

    <h1>Terraform Part 1</h1>

    <form id="todoForm">

        <label for="itemName">Item Name</label>
        <input
            type="text"
            id="itemName"
            name="itemName"
            placeholder="Enter item name"
            required
        >

        <label for="itemDescription">Item Description</label>
        <textarea
            id="itemDescription"
            name="itemDescription"
            placeholder="Enter item description"
            required
        ></textarea>

        <button type="submit">
            Submit To-Do Item
        </button>

    </form>

    <div id="result"></div>

</div>

<script>
    const form = document.getElementById("todoForm");
    const result = document.getElementById("result");

    form.addEventListener("submit", async (event) => {
        event.preventDefault();

        result.textContent = "Submitting...";

        const formData = new FormData(form);

        const data = {
            itemName: formData.get("itemName"),
            itemDescription: formData.get("itemDescription")
        };

        try {
            const response = await fetch("/submit", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(data)
            });

            const responseData = await response.json();

            result.textContent = JSON.stringify(
                responseData,
                null,
                2
            );

        } catch (error) {
            result.textContent =
                "Error: " + error.message;
        }
    });
</script>

</body>
</html>
HTML

# Install Express dependencies
cd /opt/terraform-part1/frontend
npm install

# =========================================================
# Systemd Service - Flask Backend
# =========================================================

cat > /etc/systemd/system/terraform-flask.service <<'SERVICE'
[Unit]
Description=Terraform Part 1 Flask Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/terraform-part1/backend
ExecStart=/opt/terraform-part1/backend/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# =========================================================
# Systemd Service - Express Frontend
# =========================================================

cat > /etc/systemd/system/terraform-express.service <<'SERVICE'
[Unit]
Description=Terraform Part 1 Express Frontend
After=network.target terraform-flask.service
Requires=terraform-flask.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/terraform-part1/frontend
Environment=BACKEND_URL=http://127.0.0.1:5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# Reload systemd configuration
systemctl daemon-reload

# Enable services at boot
systemctl enable terraform-flask.service
systemctl enable terraform-express.service

# Start Flask
systemctl start terraform-flask.service

# Wait for Flask to start
sleep 5

# Start Express
systemctl start terraform-express.service

# =========================================================
# Verification
# =========================================================

systemctl is-active --quiet terraform-flask.service
systemctl is-active --quiet terraform-express.service

echo "============================================="
echo "Terraform Part 1 setup completed successfully"
echo "Flask Backend : http://0.0.0.0:5000"
echo "Express Frontend: http://0.0.0.0:3000"
echo "============================================="
