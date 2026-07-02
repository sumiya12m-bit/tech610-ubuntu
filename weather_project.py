import requests
from pprint import pprint

# API KEYS & ENDPOINTS
POSTCODE_ENDPOINT = "https://api.postcodes.io/postcodes/"
WEATHER_ENDPOINT = "https://api.openweathermap.org/data/2.5/weather"
with open("gitignore_api_key") as file:
     API_KEY = file.readline().strip()


# func 1: Get latitude & longitude from postcode : Calls the Postcodes API and returns lat and long"
def get_lat_lon(postcode):
    response = requests.get(POSTCODE_ENDPOINT + postcode)

    if response.status_code == 200:
        result = response.json()["result"]
        latitude = result["latitude"]
        longitude = result["longitude"]
        return latitude, longitude
    else:
        print(f" Could not find postcode: {postcode}")
        return None, None


# func 2: Get weather from lat & long: Calls the OpenWeather API and returns weather data
def get_weather(latitude, longitude):
    response = requests.get(
        WEATHER_ENDPOINT + f"?lat={latitude}&lon={longitude}&appid={API_KEY}&units=metric"
    )

    if response.status_code == 200:
        return response.json()
    else:
        print(f"Could not get weather. Status code: {response.status_code}")
        return None


# func 3: Print weather in a user-friendly/readable format
def print_weather(postcode, weather_data):
    if not weather_data:
        return

    city        = weather_data["name"]
    description = weather_data["weather"][0]["description"]
    temp        = weather_data["main"]["temp"]
    feels_like  = weather_data["main"]["feels_like"]
    humidity    = weather_data["main"]["humidity"]
    wind_speed  = weather_data["wind"]["speed"]

    print(f"\n  Weather for {postcode} ({city})")
    print(f"─────────────────────────────────")
    print(f"   Condition  : {description.capitalize()}")
    print(f"   Temperature: {temp}°C (feels like {feels_like}°C)")
    print(f"   Humidity   : {humidity}%")
    print(f"   Wind Speed : {wind_speed} m/s")
    print(f"─────────────────────────────────\n")


# MAIN: Ties everything together
def main():
    # Ask the user to type a postcode
    postcode = input("Enter a postcode: ").upper()

    print(f"\n Looking up postcode: {postcode}...")

    # Step 1: get lat and long from postcode
    latitude, longitude = get_lat_lon(postcode)

    # Step 2: if lat and long found, get the weather
    if latitude and longitude:
        print(f" Found! Lat: {latitude} | Lon: {longitude}")
        weather_data = get_weather(latitude, longitude)

        # Step 3: print it nicely
        print_weather(postcode, weather_data)


# Run the script
if __name__ == "__main__":
    main()