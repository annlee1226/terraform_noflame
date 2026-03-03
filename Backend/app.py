from flask import Flask
from flask import request
from flask import Response
from flask import jsonify
from flask_cors import CORS
from datetime import datetime
from zoneinfo import ZoneInfo
from timezonefinder import TimezoneFinder
from tensorflow.keras.preprocessing.image import img_to_array
from PIL import Image, ImageOps
import numpy as np 
from tensorflow.keras.models import load_model

import json
import requests
import os
from threading import Lock

app = Flask(__name__)
CORS(app)
model = load_model('wildfire_detection_model.h5')

isFire = False
fire_lock = Lock()



def getForecastFromLatLon(lat, lon):
    lat = float(request.args.get('lat'))
    lon= float(request.args.get('lon'))
    tz = TimezoneFinder()
    timezone = tz.timezone_at(lat=lat, lng=lon)
    gridForecastData = requests.get(f"https://api.weather.gov/points/{lat},{lon}")
    forecastLink = gridForecastData.json()["properties"]["forecastHourly"]
    forecastResponse = requests.get(forecastLink)
    forecastData = forecastResponse.json()["properties"]["periods"]
    filtered_forecast_data = [{"startTime": datetime.fromisoformat(item["startTime"]).astimezone(ZoneInfo(timezone)).strftime("%Y-%m-%d %H:%M:%S %Z").split(" ")[:2], "endTime": datetime.fromisoformat(item["endTime"]).astimezone(ZoneInfo(timezone)).strftime("%Y-%m-%d %H:%M:%S %Z").split(" ")[:2], "temperature": item["temperature"], "relativeHumidity": item["relativeHumidity"]["value"], "windVector": [item["windSpeed"][:-4], item["windDirection"]], "precipitationChance": item["probabilityOfPrecipitation"]["value"]} for item in forecastData]   

    return filtered_forecast_data

def getFWI(temperature, humidity, wind_speed):
    ffmc = (temperature - 10) * (100 - humidity) / 100 
    isi = wind_speed * (temperature / 10)  
    fwi = ffmc * isi / 100
    print("Pre FWI: ", fwi)
    return fwi

def normalize_fwi(score, min_fwi=0, max_fwi=50):
    if score < min_fwi:
        return 0.0
    elif score > max_fwi:
        return 1.0
    return (score - min_fwi) / (max_fwi - min_fwi)

def getModelConfidence(file):
    img = Image.open(file)
    img = ImageOps.pad(img, size=(128, 128), color=(0, 0, 0)) 
    img_array = img_to_array(img)
    img_array = img_array / 255.0 
    img_array = np.expand_dims(img_array, axis=0)  

    prediction = model.predict(img_array)
    confidence = (1 - float(prediction[0][0])) *100
    return confidence

@app.route('/getFullForecastFromLatLon', methods=['GET'])
def getFullForecastFromLatLon():
    lat = float(request.args.get('lat'))
    lon= float(request.args.get('lon'))
    return Response(
        json.dumps(getForecastFromLatLon(lat, lon)).encode('utf-8')
    )


@app.route('/getCurrentForecastFromLatLon', methods=['GET'])
def getCurrentForecastFromLatLon():
    lat = float(request.args.get('lat'))
    lon= float(request.args.get('lon'))
    return Response(
        json.dumps(getForecastFromLatLon(lat, lon)[0]).encode('utf-8')
    )

@app.route('/fireAlarm', methods=["GET"])
def fireAlarm():
    return Response(
        json.dumps(isFire).encode('utf-8')
    )

@app.route('/getFireRisk', methods=['GET'])
def getFireRisk():
    global isFire
    file = "./unchecked_camera_image/image.jpeg"
    if not os.path.exists(file):
        return jsonify({'error': 'No file saved'}), 400
    
    lat = float(request.args.get('lat'))
    lon= float(request.args.get('lon'))
    forecastData = getForecastFromLatLon(lat, lon)[0]
    temperature = float(forecastData["temperature"])
    humidity = float(forecastData["relativeHumidity"])
    wind_speed = float(forecastData["windVector"][0])
    fwi = normalize_fwi(getFWI(temperature, humidity, wind_speed)) * 100

    confidence = getModelConfidence(file)

    result = float(f"{(fwi + confidence)/2:.2f}")
    with fire_lock:
        isFire = result > 30

        
    print(f"FWI: {fwi} \n Confidence: {confidence} \n Result: {result}")

    return Response(
        json.dumps(result).encode('utf-8')
    )


@app.route('/upload_image', methods=['POST'])
def upload_image():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    folder = "./unchecked_camera_image"
    if os.path.exists(folder):
        for item in os.listdir(folder):
            item_path = os.path.join(folder, item)
            if os.path.isfile(item_path) or os.path.islink(item_path):
                os.unlink(item_path) 

    file_path = os.path.join(folder, "image.jpeg")
    file.save(file_path)

    return jsonify({'message': f'File saved to {file_path}'}), 200

    


if __name__ == '__main__':
    import os
    # Use SSL only if certificates exist (production), otherwise run without SSL (local dev)
    cert_path = '/etc/ssl/certs/myserver/myserver.crt'
    key_path = '/etc/ssl/certs/myserver/myserver.key'

    if os.path.exists(cert_path) and os.path.exists(key_path):
        # Production: HTTPS on port 443
        app.run(debug=True, host='0.0.0.0', port=443, ssl_context=(cert_path, key_path))
    else:
        # Local development: HTTP on port 5001 (5000 is used by AirPlay on macOS)
        app.run(debug=True, host='0.0.0.0', port=5001)

