# ✨ TEST RAPIDE - Vérifier la Météo + Ressenti

## 🚀 En 2 minutes

### 1️⃣ **Lancer l'app**
```bash
cd frontend
flutter run -v
```

### 2️⃣ **Ouvrir DevTools**
```bash
# Dans un autre terminal
dart devtools
# Ou dans VS Code: Run → Flutter DevTools
```

### 3️⃣ **Chercher les logs**
```
Rechercher: "RÉPONSE MÉTÉO COMPLÈTE"
```

### 4️⃣ **Vérifier le JSON**
Vous devriez voir:

```json
{
  "latitude": 14.6667,
  "longitude": -17.0382,
  "timezone": "Africa/Dakar",
  "current": {
    "temperature_2m": 28.5,
    "apparent_temperature": 31.2,   // ⭐ NOUVEAU!
    "weather_code": 0,
    "is_day": 1
  },
  "daily": {
    "temperature_2m_max": [29.5],
    "temperature_2m_min": [22.1],
    "apparent_temperature_max": [32.8],  // ⭐ NOUVEAU!
    "apparent_temperature_min": [20.5],  // ⭐ NOUVEAU!
    "weather_code": [0]
  }
}
```

### 5️⃣ **Vérifier les champs affichés en CONSOLE**
```
📊 CHAMPS AFFICHÉS:
  Location: Dakar
  GPS: (14.6667, -17.0382)
  Temp actuelle: 28.5°C
  Ressenti actuel: 31.2°C
  Max jour: 29.5°C (ressenti: 32.8°C)
  Min jour: 22.1°C (ressenti: 20.5°C)
```

### 6️⃣ **Sur le Dashboard**
Vous devriez voir:
```
MÉTÉO DU JOUR
  28°C
  Ressenti: 31°C
  
  ↓22° ↑29°
  (Ressenti: ↓20° ↑32°)
```

---

## ❌ Dépannage

### Problème: JSON log ne s'affiche pas
**Solution**: 
1. Rebuildez: `flutter clean && flutter pub get && flutter run`
2. Cherchez "Weather API Request" au lieu de "RÉPONSE"

### Problème: Ressenti affiche null
**Solution**:
Vérifiez que le JSON a bien les champs `apparent_temperature*`

### Problème: Température affiche 22.0°C (valeur par défaut)
**Solution**:
1. Vérifiez que Open-Meteo API répond (check URL log)
2. Vérifiez votre connexion Internet
3. Optionnel: Testez l'API directement:
   ```bash
   curl "https://api.open-meteo.com/v1/forecast?latitude=14.6667&longitude=-17.0382&current=temperature_2m,apparent_temperature,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weather_code&timezone=Africa/Dakar"
   ```

---

## 🌍 **Option: Activer GPS**

Dans `dashboard_tab.dart` ligne 311, changez:

```dart
// AVANT (Dakar toujours)
Future<Map<String, dynamic>> _loadWeather() => WeatherService.getWeather();

// APRÈS (GPS + fallback Dakar)
Future<Map<String, dynamic>> _loadWeather() => WeatherService.getWeather(useGPS: true);
```

**Attention**: Pour que GPS marche, il faut ajouter les permissions:

### Android
Ajouter à `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS  
Ajouter à `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>L'app a besoin de votre localisation pour afficher la météo précise</string>
```

Puis rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📸 Screenshot esperado

```
┌─────────────────────────────────────────┐
│       🏠 TABLEAU DE BORD                 │
├─────────────────────────────────────────┤
│                                         │
│   ┌──────────────────────────────────┐ │
│   │ MÉTÉO DU JOUR        │ CONSEILS  │ │
│   │  28°C                │ Arrosez  │ │
│   │  Ressenti: 31°C      │ avant 8h │ │
│   │                      │          │ │
│   │  ↓22° ↑29°          │          │ │
│   │  (Ressenti: ↓20° ↑32°)│        │ │
│   │                      │          │ │
│   └──────────────────────────────────┘ │
│                                         │
│   [Stats] [News] [Tips]                 │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 Checklist

- [ ] API Log montre `apparent_temperature`?
- [ ] Dashboard affiche "Ressenti: 31°C"?
- [ ] Min/max jour + ressenti affichés?
- [ ] Location affiche "Dakar"?
- [ ] Si GPS: Affiche location détectée?

✅ **Once all green → Ready to ship! 🚀**
