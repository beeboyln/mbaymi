# 🔄 Architecture de l'API Météo

## Vue Globale

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER DASHBOARD                                 │
│                        (dashboard_tab.dart)                              │
│                                                                          │
│              Affiche: 28°C | Ressenti: 31°C | ↓22° ↑29°                │
└────────────────────┬────────────────────────────────────────────────────┘
                     │
                     │ FutureBuilder
                     │ _weatherFuture
                     │
┌────────────────────▼────────────────────────────────────────────────────┐
│                  WeatherService.getWeather()                            │
│                                                                          │
│  1. Check useGPS parameter (false by default)                          │
│                                                                          │
│  ┌─┬─────────────────────────────────────────────────────────────────┐ │
│  │2│ if (useGPS):                                                    │ │
│  │ │   GPS Location → _getGPSLocation()                              │ │
│  │ │                    ↓                                             │ │
│  │ │   Coordinates → _reverseGeocode()                               │ │
│  │ │                    ↓                                             │ │
│  │ │                 City Name                                        │ │
│  │ │ else:                                                           │ │
│  │ │   Use Dakar (14.6667, -17.0382)                                │ │
│  └─┴─────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  3. Build API URL with coordinates                                     │
│     Format: ?latitude=X&longitude=Y&current=temperature_2m,             │
│            apparent_temperature,weather_code,is_day&daily=...          │
└────────────────────┬────────────────────────────────────────────────────┘
                     │
                     │ HTTP.GET
                     │
┌────────────────────▼────────────────────────────────────────────────────┐
│            🌐 OPEN-METEO API (FREE)                                    │
│     https://api.open-meteo.com/v1/forecast                             │
│                                                                          │
│  Input:  latitude=14.6667, longitude=-17.0382                          │
│          current=temperature_2m,apparent_temperature,...                │
│          daily=temperature_2m_max/min,apparent_temperature_max/min,...  │
│          timezone=Africa/Dakar                                          │
│                                                                          │
│  Output: Full JSON response                                            │
└────────────────────┬────────────────────────────────────────────────────┘
                     │
                     │ JSON Response
                     │
┌────────────────────▼────────────────────────────────────────────────────┐
│                   📝 LOGGING BLOCK                                       │
│                                                                          │
│  debugPrint('═══════════════════════════════════════════════════════')  │
│  debugPrint('✅ RÉPONSE MÉTÉO COMPLÈTE (JSON):')                        │
│  debugPrint(json.encode(data))     ← FULL JSON with apparent_temp    │
│  debugPrint('═════════════════════════════════════════════════════')    │
│                                                                          │
│  Also logs:                                                             │
│    - Current temp & ressenti                                           │
│    - Max/min temp & ressenti                                           │
│    - Location & GPS coordinates                                        │
│    - Weather codes                                                      │
└────────────────────┬────────────────────────────────────────────────────┘
                     │
                     │ Extract Fields
                     │
┌────────────────────▼────────────────────────────────────────────────────┐
│                   ✅ RETURN MAP                                          │
│                                                                          │
│  {                                                                      │
│    'location': 'Dakar',                                                │
│    'latitude': 14.6667,                                               │
│    'longitude': -17.0382,                                             │
│    'current_temp': 28.5,          ← Température réelle                │
│    'apparent_temp': 31.2,          ← ⭐ RESSENTI ACTUEL              │
│    'weather_code': 0,                                                │
│    'max_temp': 29.5,               ← Max du jour                     │
│    'min_temp': 22.1,               ← Min du jour                     │
│    'apparent_temp_max': 32.8,      ← ⭐ RESSENTI MAX                 │
│    'apparent_temp_min': 20.5,      ← ⭐ RESSENTI MIN                 │
│    'daily_weather_code': 0,                                          │
│  }                                                                      │
└────────────────────┬────────────────────────────────────────────────────┘
                     │
                     │ Return to Dashboard
                     │
┌────────────────────▼────────────────────────────────────────────────────┐
│                  🎨 DISPLAY WIDGET                                      │
│                                                                          │
│  Widget builds and shows:                                              │
│  ┌────────────────────────────────┐                                   │
│  │ MÉTÉO DU JOUR                  │                                   │
│  │  28°C                          │ ← maxT                            │
│  │  Ressenti: 31°C                │ ← ⭐ apparentMaxT               │
│  │                                │                                   │
│  │  ↓22° ↑29°                     │ ← minT, maxT                    │
│  │  (Ressenti: ↓20° ↑32°)        │ ← ⭐ apparent mins/maxs         │
│  └────────────────────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Flux avec GPS Activé

```
User Opens App
       ↓
Dashboard initState()
       ↓
WeatherService.getWeather(useGPS: true)
       ↓
   useGPS = true?
   YES ↓
   
   ┌─ Geolocator.getCurrentPosition()
   │         ↓
   │    Permission Check
   │     /    |    \
   │  Denied  OK  DeniedForever
   │   |      |      |
   │   └──────┬──────┘
   │          ↓
   │    Position(lat, lon) or null
   │          ↓
   │    _reverseGeocode(lat, lon)
   │          ↓
   │    Nominatim API
   │    "city": "Dakar"
   │          ↓
   │    location = "Dakar"
   │    lat = 14.7xxx (detected)
   │    lon = -17.0xxx (detected)
   │
   └─→ Build API URL with GPS coords
           ↓
       Open-Meteo API
           ↓
       Full JSON
           ↓
       Extract Fields
           ↓
       Return + Log
           ↓
       Dashboard Display
```

---

## Comparaison: Avant vs Après

### AVANT ❌
```
Dashboard
  │
  └─→ WeatherService.getWeather()
        │
        └─→ Hardcoded Dakar coords
              │
              └─→ API call
                    │
                    └─→ JSON (NO apparent_temp)
                          │
                          └─→ Extract fields
                                │
                                └─→ Return {
                                     'max_temp': 29,
                                     'min_temp': 22
                                   }
                          
Display: 29°C (that's it!)
```

### APRÈS ✅
```
Dashboard
  │
  └─→ WeatherService.getWeather(useGPS: false/true)
        │
        ├─ If useGPS:
        │   ├─→ GPS Location (Geolocator)
        │   └─→ Reverse Geocoding (Nominatim)
        │
        ├─ Build API with coords
        │
        └─→ API call with apparent_temp params
              │
              ├─→ 📝 Log complete JSON
              │
              └─→ Extract fields
                    │
                    └─→ Return {
                         'location': 'Dakar',
                         'latitude': 14.6667,
                         'longitude': -17.0382,
                         'current_temp': 28.5,
                         'apparent_temp': 31.2,     ← ⭐ NEW
                         'max_temp': 29.5,
                         'apparent_temp_max': 32.8, ← ⭐ NEW
                         ...
                       }
                    
Display: 
  28°C
  Ressenti: 31°C     ← ⭐ NEW
  ↓22° ↑29°
  (Ressenti: ↓20° ↑32°)  ← ⭐ NEW
```

---

## **Logging Console Flow**

```
🌐 Weather API Request: https://api.open-meteo.com/v1/forecast?latitude=14.6667&longitude=-17.0382&current=...
    ↓
📍 GPS Location: Dakar (14.6667, -17.0382)  [only if useGPS=true]
    ↓
═══════════════════════════════════════════════════════════════
✅ RÉPONSE MÉTÉO COMPLÈTE (JSON):
{
  "latitude": 14.6667,
  "longitude": -17.0382,
  "timezone": "Africa/Dakar",
  "current": {
    "temperature_2m": 28.5,
    "apparent_temperature": 31.2,        ← What field to display
    "weather_code": 0,
    ...
  },
  "daily": {
    "temperature_2m_max": [29.5],
    "temperature_2m_min": [22.1],
    "apparent_temperature_max": [32.8],  ← What field to display
    "apparent_temperature_min": [20.5],  ← What field to display
    ...
  }
}
═══════════════════════════════════════════════════════════════
    ↓
📊 CHAMPS AFFICHÉS:
  Location: Dakar
  GPS: (14.6667, -17.0382)
  Temp actuelle: 28.5°C
  Ressenti actuel: 31.2°C
  Max jour: 29.5°C (ressenti: 32.8°C)
  Min jour: 22.1°C (ressenti: 20.5°C)
    ↓
✅ Data ready for display
```

---

## Data Structure Hierarchy

```
WeatherService.getWeather()
    ↓
    ├─ 📍 Location Info
    │  ├─ location: "Dakar"
    │  ├─ latitude: 14.6667
    │  └─ longitude: -17.0382
    │
    ├─ 🌡️ Current Weather
    │  ├─ current_temp: 28.5
    │  ├─ apparent_temp: 31.2      ← ⭐ RESSENTI ACTUEL
    │  └─ weather_code: 0
    │
    ├─ 📅 Daily Weather
    │  ├─ max_temp: 29.5
    │  ├─ min_temp: 22.1
    │  ├─ apparent_temp_max: 32.8  ← ⭐ RESSENTI MAX
    │  ├─ apparent_temp_min: 20.5  ← ⭐ RESSENTI MIN
    │  └─ daily_weather_code: 0
    │
    └─ 📊 Display Ready
       └─ Dashboard Widget renders all fields
```

---

## API Parameters Explained

```
🔗 Complete URL Built:

https://api.open-meteo.com/v1/forecast
  ?latitude=14.6667                          ← GPS latitude
  &longitude=-17.0382                        ← GPS longitude
  &current=
    temperature_2m,                          ← Current real temp
    apparent_temperature,                    ← ⭐ Current feels-like
    weather_code,                            ← Current weather code
    is_day                                   ← Is daytime? (1/0)
  &daily=
    temperature_2m_max,                      ← Daily max temp
    temperature_2m_min,                      ← Daily min temp
    apparent_temperature_max,                ← ⭐ Daily feels-like max
    apparent_temperature_min,                ← ⭐ Daily feels-like min
    weather_code                             ← Daily weather code
  &timezone=Africa/Dakar                     ← Timezone for times
```

---

## Summary

**Old Flow**: 
User → Hardcoded Dakar → API → Extract max_temp → Display 29°C ❌

**New Flow**: 
User → GPS or Dakar → API with apparent_temp → Log JSON → Extract all fields → Display 28°C + Ressenti: 31°C + Min/Max with ressenti ✅

**Differences**:
- ✅ Complete JSON logging
- ✅ Apparent temperature (feels-like) included
- ✅ GPS optional support
- ✅ Better UX with multiple temperature values
- ✅ No breaking changes
