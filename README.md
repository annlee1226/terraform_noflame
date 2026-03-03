# NoFlame

## Table of Contents

  - [Team Members](#team-members)
  - [Deployment](#deployment)
  - [Inspiration](#inspiration)
  - [What it does](#purpose)
  - [Challenges](#challenges)
  - [Accomplishments](#accomplishments)
  - [What's next for NoFlame](#next-up)


## Team Members

Jason Boenjamin, Sneha Gurung, Falak Tulsi, Anna Lee


## Deployment

NoFlame is deployed on **Oracle Cloud Infrastructure (OCI)** using Terraform. The backend (Flask + TensorFlow) runs on a compute instance and the frontend (React/Vite) is served from OCI Object Storage.

### Quick Start

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # Fill in your OCI credentials
terraform init
terraform apply
```

After the instance is provisioned (~10-15 min), deploy the backend:

```bash
scp Backend/app.py opc@BACKEND_IP:/opt/noflame/
scp Backend/wildfire_detection_model.h5 opc@BACKEND_IP:/opt/noflame/
ssh opc@BACKEND_IP 'sudo systemctl start noflame'
```

Set the backend URL in `Frontend/vite-project/.env`:
```bash
VITE_API_URL=http://BACKEND_IP:5001
```

Then run the frontend:
```bash
cd Frontend/vite-project
npm install && npm run dev
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/fireAlarm` | GET | Fire alarm status (true/false) |
| `/getCurrentForecastFromLatLon?lat=X&lon=X` | GET | Current weather for location |
| `/getFullForecastFromLatLon?lat=X&lon=X` | GET | Full hourly forecast |
| `/getFireRisk?lat=X&lon=X` | GET | Fire risk score (0-100) |
| `/upload_image` | POST | Upload camera image for ML analysis |

### Teardown

```bash
cd infra
terraform destroy
```

See `infra/README.md` for detailed setup instructions and troubleshooting.


## Inspiration

The inspiration behind NoFlame was sparked by the Palisade Fires in Los Angeles. When my mom sent pictures of the beautiful mountains, I, and many others, always found solace in absolute flames, and I was heartburned. We thought to ourselves, it's 2025, there should be no reason for a flame that has burned:

- 14,117 acres with only 15% contained
- 39,428 structures threatened
- 972 structures destroyed; 98 structures damaged
- 5 civilian fatalities; and 5 firefighter injuries for just Eaton Canyon alone is ridiculous.

## Purpose

NoFlame is an innovative fire detection and prevention system that uses advanced technology to protect lives and property. Here's how it works and how it's designed to scale:

- **Real-Time Fire Detection**:
  NoFlame leverages machine learning to analyze camera feeds for flames while incorporating weather API data such as geolocation, humidity, wind speed, wind direction, and a Fire Weather Index (FWI). This comprehensive approach ensures rapid and accurate fire detection, enabling first responders and users to act swiftly before the fire spreads.

- **IoT-Powered Alerts for Immediate Response**:
  When a fire is detected, NoFlame sends real-time alerts to connected devices, notifying homeowners, businesses, and emergency responders. These alerts are designed to provide crucial information, enabling swift decision-making.

- **Environmental Risk Analysis**:
  By integrating data from weather APIs, NoFlame calculates fire risk indices using temperature, humidity, and wind speed. This proactive approach identifies potential hazards before fires even start.

- **Seamless First Responder Integration**:
  Using IoT and a centralized server, NoFlame can scale to provide critical fire data directly to first responders. Equipped with accurate, real-time updates on fire locations and conditions, emergency teams can act faster and more effectively to contain fires before they spiral out of control.

- User-Friendly Monitoring:
  A sleek web application allows users to monitor fire risks, view live camera feeds, and receive alerts tailored to their location. On-site alarms, like buzzers, ensure safety measures are deployed immediately.

- Scalable Community Protection:
  Beyond individual users, NoFlame is designed to scale for community-wide deployment. With its server-powered architecture, entire neighborhoods or rural areas can be monitored, creating a network of interconnected safety systems that work together to prevent large-scale disasters.

- Actionable Insights and Education:
  NoFlame educates users and responders with fire risk trends, historical data, and safety tips. This empowers communities to adopt preventive measures and fosters collaboration in fire safety.

By combining IoT, machine learning, and centralized server technology, NoFlame transforms fire detection into a proactive and scalable solution. It empowers individuals and equips first responders with the tools they need to mitigate fires swiftly and effectively, ensuring tragedies like the Palisade Fires become a thing of the past.


## Challenges

- Remembering how to use CNNs to train a classification model.
- Learning how to use an ESP32 and breadboard for the first time
- Learning the Arduino IDE code for electronics like the Buzzer and Button
- Learning how to create a Flask server and run it on an existing Linux Server that isn't physically here with us
- Web scraping data, especially those that had a paywall
- Learning how to use Vite and React
- Creating animations for Flames and using Geolocation for Real-Time Google maps update.

## Accomplishments

- Mastering CNNs:
  We managed to recall and apply our knowledge of Convolutional Neural Networks to build an accurate fire classification model. This felt like reviving dormant skills and putting them to impactful use.

- Diving into New Hardware:
  None of us had worked with an ESP32 or breadboard before, but now, we can confidently wire up components like a button and a buzzer and make them work in harmony.

- Arduino Expertise:
  Writing Arduino IDE code was uncharted territory for some of us, but we pushed through to create working hardware that complemented our software seamlessly.

- Flask and Remote Linux Servers:
  Setting up and running a Flask server on a Linux server that's physically hundreds of miles away was no small feat, but we made it happen and integrated it into the project smoothly.

- Web Scraping Obstacles:
  Breaking through barriers like paywalls and limited access APIs, we scraped and processed the data we needed for weather and geolocation.

- UI/UX Innovations:
  Using Vite and React for the frontend, we built a clean, functional interface, complete with animations and a real-time Google Maps fire visualization.

- Bringing It All Together:
  Despite these challenges, we integrated all the components—frontend, backend, machine learning, and hardware—into one cohesive system that truly embodies our vision for NoFlame.

We didn't just tackle the hard stuff; we turned it into a product we're genuinely proud of.


## Next Up

- Community-Wide Deployment: We aim to expand NoFlame's reach by integrating more IoT devices and creating a network that monitors entire neighborhoods and natural areas in real-time.
- First Responder Collaboration: Partnering with fire departments to provide direct alerts and real-time data, empowering them to act faster and with more precision.
- Improved Fire Risk Analytics: Enhancing our Fire Weather Index (FWI) calculations by incorporating more environmental factors and satellite data for even more accurate predictions.
- Mobile App Integration: Building a mobile app to make NoFlame's alerts, live feeds, and fire risk indices accessible to users wherever they are.
- Machine Learning Optimization: Refining our CNN model with more diverse datasets to improve accuracy and reduce false positives in fire detection.
- Hardware Iteration: Scaling down hardware requirements to make on-site alarms more compact, affordable, and easier to deploy across various environments.
- Hardware Addition: Incorporating Infrared with the cameras to easily detect if a fire is present. For a more in-depth explanation, please come to our booth!

NoFlame isn't just a project, it's the beginning of a vision to turn reactive fire safety into proactive fire prevention, creating safer communities for everyone. Protection of Inaction.
