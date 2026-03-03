import axios from 'axios';
import { BASE_URL } from './config/api.js';

const GOOGLE_MAPS_API_KEY = 'AIzaSyAClGQYQDrnLDd8xxq0-9NIZGtaktlsqb4';

export const getCityName = async (lat, lon) => {
  try {
    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${GOOGLE_MAPS_API_KEY}`
    );
    const results = response.data.results;
    if (results.length > 0) {
      const addressComponents = results[0].address_components;
      const cityComponent = addressComponents.find((component) =>
        component.types.includes('locality')
      );
      return cityComponent ? cityComponent.long_name : 'Unknown City';
    }
    return 'Unknown City';
  } catch (error) {
    console.error('Error fetching city name:', error.message);
    return 'Unknown City';
  }
};

const roundForecastValues = (forecast) => {
  return {
    ...forecast,
    temperature: Math.round(forecast.temperature),
    relativeHumidity: Math.round(forecast.relativeHumidity),
    windVector: [
      Math.round(forecast.windVector[0]), // Wind speed
      forecast.windVector[1],            // Wind direction remains unchanged
    ],
    precipitationChance: Math.round(forecast.precipitationChance || 0),
  };
};

export const getCurrentForecast = async (lat, lon) => {
  try {
    console.log(`Fetching forecast for lat: ${lat}, lon: ${lon}`); // Debug log
    const response = await axios.get(`${BASE_URL}/getCurrentForecastFromLatLon`, {
      params: { lat, lon },
    });
    console.log("API Response:", response.data); // Log the API response
    return roundForecastValues(response.data);
  } catch (error) {
    console.error(`Error fetching current forecast: ${error.message}`);
    throw error;
  }
};


export const getFireRisk = async (lat, lon) => {
  try {
    const response = await axios.get(`${BASE_URL}/getFireRisk`, {
      params: { lat: lat, lon: lon },
    });
    return Math.round(response.data);
  } catch (error) {
    console.error(`Error fetching fire risk: ${error.message}`);
    throw error;
  }
};

export const getWeekForecastData = async (lat, lon) => {
  try {
    const response = await axios.get(`${BASE_URL}/getFullForecastFromLatLon`, {
      params: { lat: lat, lon: lon },
    });
    return response.data.map(roundForecastValues);
  } catch (error) {
    console.error(`Error fetching weekly forecast: ${error.message}`);
    throw error;
  }
};
