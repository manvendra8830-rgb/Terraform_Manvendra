#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# =========================================================
# System Update
# =========================================================

apt-get update -y
apt-get upgrade -y

# =========================================================
# Install Python and Required Packages
# =========================================================

apt-get install -y \
    python3 \
    python3-pip \
    python3-venv

# =========================================================
# Create Flask Backend Directory
# =========================================================

mkdir -p /opt/terraform-part2/backend

# =========================================================
# Create Flask Application
# =========================================================

cat > /opt/terraform-part2/backend/app.py <<'PYTHON'
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

# =========================================================
# Python Virtual Environment
# =========================================================

python3 -m venv /opt/terraform-part2/backend/venv

/opt/terraform-part2/backend/venv/bin/pip install --upgrade pip
/opt/terraform-part2/backend/venv/bin/pip install Flask

# =========================================================
# Systemd Service
# =========================================================

cat > /etc/systemd/system/terraform-part2-flask.service <<'SERVICE'
[Unit]
Description=Terraform Part 2 Flask Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/terraform-part2/backend
ExecStart=/opt/terraform-part2/backend/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# =========================================================
# Enable and Start Flask
# =========================================================

systemctl daemon-reload

systemctl enable terraform-part2-flask.service
systemctl start terraform-part2-flask.service

# =========================================================
# Verify Flask Service
# =========================================================

systemctl is-active --quiet terraform-part2-flask.service

echo "============================================="
echo "Terraform Part 2 Backend Setup Completed"
echo "Flask Backend running on port 5000"
echo "============================================="
