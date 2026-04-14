from flask import Flask, jsonify, request
from datetime import datetime

app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    # Get client IP
    if request.headers.get('X-Forwarded-For'):
        ip = request.headers.get('X-Forwarded-For').split(',')[0]
    else:
        ip = request.remote_addr

    # Current timestamp
    current_time = datetime.utcnow().isoformat()

    return jsonify({
        "timestamp": current_time,
        "ip": ip
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
