import json
from flask import Flask, request, render_template
from weather_project import get_lat_lon, get_weather

app = Flask(__name__)


# --- HOME: serves the HTML page ---
@app.route('/')
def home():
    return render_template('index.html')


# --- GET: single postcode from URL ---
# --- POST: multiple postcodes from request body ---
@app.route('/weather_api/<postcode>', methods=["GET", "POST"])
def weather_api(postcode):

    if request.method == "GET":
        latitude, longitude = get_lat_lon(postcode)
        weather_data = get_weather(latitude, longitude)
        return json.dumps(weather_data)

    elif request.method == "POST":
        postcodes = request.get_json()

        if not postcodes:
            return json.dumps({"error": "No postcodes provided"}), 400

        results = {}
        for postcode in postcodes:
            latitude, longitude = get_lat_lon(postcode)
            weather_data = get_weather(latitude, longitude)
            results[postcode] = weather_data

        return json.dumps(results)


# --- frontend POST: handles the HTML form submission ---
@app.route('/weather', methods=["POST"])
def weather_from_form():
    postcode = request.form.get("postcode").replace(" ", "")
    latitude, longitude = get_lat_lon(postcode)
    weather_data = get_weather(latitude, longitude)

    return render_template('index.html', weather=weather_data, postcode=postcode)


if __name__ == "__main__":
    app.run(debug=True)