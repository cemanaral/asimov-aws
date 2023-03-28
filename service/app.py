from flask import Flask, jsonify
from healthcheck import HealthCheck, EnvironmentDump

health = HealthCheck()
app = Flask(__name__)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True
app.add_url_rule("/health", "healthcheck", view_func=lambda: health.run())

asimov_books = {
    "prequel_novels": [
        {"Title": "Prelude to Foundation", "Year": 1988, "ISBN": "0-553-27839-8"},
        {"Title": "Forward to Foundation", "Year": 1993, "ISBN": "0-553-40488-1"}
    ],
    "original_trilogy": [
         {"Title": "Foundation", "Year": 1951, "ISBN": "0-553-29335-4"},
         {"Title": "Foundation and Empire", "Year": 1952, "ISBN": "0-553-29337-0"},
         {"Title": "Second Foundation", "Year": 1953, "ISBN": "0-553-29336-2"}
    ],
    "later_novels": [
        {"Title": "Foundation's Edge", "Year": 1982, "ISBN": "0-553-29338-9"},
        {"Title": "Foundation and Earth", "Year": 1986, "ISBN": "0-553-58757-9"}
    ]
}

@app.route('/')
def index():
    return jsonify(asimov_books, )

app.run(host='0.0.0.0', port=8080)
