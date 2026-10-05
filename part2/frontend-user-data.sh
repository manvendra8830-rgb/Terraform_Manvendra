#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# =========================================================
# System Update
# =========================================================

apt-get update -y
apt-get upgrade -y

# =========================================================
# Install Required Packages
# =========================================================

apt-get install -y \
    curl \
    ca-certificates

# =========================================================
# Install Node.js 20
# =========================================================

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# =========================================================
# Create Express Frontend Directory
# =========================================================

mkdir -p /opt/terraform-part2/frontend/public

# =========================================================
# Create package.json
# =========================================================

cat > /opt/terraform-part2/frontend/package.json <<'JSON'
{
  "name": "terraform-part2-frontend",
  "version": "1.0.0",
  "description": "Express frontend for Terraform Part 2",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^5.1.0"
  }
}
JSON

# =========================================================
# Create Express Server
# =========================================================

cat > /opt/terraform-part2/frontend/server.js <<'JAVASCRIPT'
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
        const response = await fetch(`$${BACKEND_URL}/submittodoitem`, {
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
    console.log(`Frontend server running on port $${PORT}`);
});
JAVASCRIPT

# =========================================================
# Create Frontend HTML
# =========================================================

cat > /opt/terraform-part2/frontend/public/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Terraform Part 2 - To-Do App</title>

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

    <h1>Terraform Part 2</h1>

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

# =========================================================
# Install Express Dependencies
# =========================================================

cd /opt/terraform-part2/frontend

npm install

# =========================================================
# Create Systemd Service
# =========================================================

cat > /etc/systemd/system/terraform-part2-express.service <<SERVICE
[Unit]
Description=Terraform Part 2 Express Frontend
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/terraform-part2/frontend
Environment=BACKEND_URL=http://${backend_private_ip}:5000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# =========================================================
# Enable and Start Express
# =========================================================

systemctl daemon-reload

systemctl enable terraform-part2-express.service
systemctl start terraform-part2-express.service

# =========================================================
# Verify Express Service
# =========================================================

systemctl is-active --quiet terraform-part2-express.service

echo "============================================="
echo "Terraform Part 2 Frontend Setup Completed"
echo "Express Frontend running on port 3000"
echo "Backend: http://${backend_private_ip}:5000"
echo "============================================="
