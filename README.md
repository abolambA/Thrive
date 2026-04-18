<div align="center">

<br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" />
<img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" />

<br/><br/>

```
████████╗██╗  ██╗██████╗ ██╗██╗   ██╗███████╗
╚══██╔══╝██║  ██║██╔══██╗██║██║   ██║██╔════╝
   ██║   ███████║██████╔╝██║██║   ██║█████╗  
   ██║   ██╔══██║██╔══██╗██║╚██╗ ██╔╝██╔══╝  
   ██║   ██║  ██║██║  ██║██║ ╚████╔╝ ███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝
```

### **Your health. Intelligently.**

*AI-powered burnout detection for university students — built at AUS, for AUS.*

<br/>

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square)](https://flutter.dev)
[![Gemini](https://img.shields.io/badge/Powered%20by-Gemini%202.0-purple?style=flat-square)](https://ai.google.dev)
[![AUS Hackathon](https://img.shields.io/badge/AUS%20Computing%20Competition-2025-orange?style=flat-square)](#)

</div>

---

<br/>

## 🧠 The Problem

University students in the UAE are burning out — silently.

- **70%+** report sleep deprivation during exam periods
- The **UAE climate** accelerates dehydration, yet most apps ignore it  
- Existing health apps (Apple Health, Fitbit) are built for adults with routines  
- Students don't have routines. They have **chaos**

No app treats *"I slept 3 hours, had Red Bull for breakfast, and have a final in 4 hours"* as a pattern to intervene on.

**Thrive does.**

<br/>

## ⚡ What Makes Thrive Different

| Feature | Apple Health | Fitbit | **Thrive** |
|---------|-------------|--------|-----------|
| Built for students | ❌ | ❌ | ✅ |
| Burnout risk detection | ❌ | ❌ | ✅ |
| AI coaching (not just tracking) | ❌ | ❌ | ✅ |
| UAE climate awareness | ❌ | ❌ | ✅ |
| Exam mode | ❌ | ❌ | ✅ |
| 15-second daily check-in | ❌ | ❌ | ✅ |
| Emergency health card | ❌ | ❌ | ✅ |

<br/>

## 🎯 Core Features

<table>
<tr>
<td width="50%">

### 🔴 Burnout Risk Score
An animated 0–100 gauge calculated from 6 weighted health signals. Not a gimmick — a real algorithm tuned for student patterns.

**Signals tracked:**
- 🛏️ Sleep (30% weight)
- 💧 Hydration (20% weight)  
- 🍽️ Nutrition (15% weight)
- 🧠 Stress level (20% weight)
- 📱 Screen time (10% weight)
- ☕ Caffeine intake (5% weight)

</td>
<td width="50%">

### 🤖 AI Health Coach
Powered by **Gemini 2.0 Flash** — not generic tips. Specific, timed, actionable interventions based on *your* actual data.

> *"You have an exam in 4 hours. Drink 500ml water now, eat protein within 30 minutes, and close your screens at 10 PM. You need REM sleep before 9 AM tomorrow."*

That's not a notification. That's a coach.

</td>
</tr>
<tr>
<td width="50%">

### 📊 Weekly Insights
Three trend charts (sleep, hydration, risk score) that visualize your week at a glance. Catch patterns before they become problems.

**Plus:** AI-generated weekly health report — a full narrative summary of your week's patterns.

</td>
<td width="50%">

### 🎓 Exam Mode
Toggle on, set your exam date and subject. The AI coach recalibrates entirely — sleep targets, study break reminders, hydration for cognitive performance.

Also includes a **day countdown** to keep you aware without panicking.

</td>
</tr>
<tr>
<td width="50%">

### 🆘 Emergency Card
Blood type, allergies, emergency contact — visible in one tap. Displayed on a bold red card with quick-share. No unlock needed in a crisis.

</td>
<td width="50%">

### 🔥 Streak Tracking
Consecutive day streaks with fire badges. Because the best health habit is consistency, and consistency needs reinforcement.

</td>
</tr>
</table>

<br/>

## 🏗️ Architecture

```
thrive/lib/
│
├── main.dart                    # App entry + routing + AppShell
│
├── models/
│   ├── daily_checkin.dart       # Check-in data model + SQLite serialization
│   └── ai_advice.dart           # AI advice model + persistence
│
├── services/
│   ├── database_service.dart    # SQLite singleton — all CRUD operations
│   ├── risk_engine.dart         # Burnout score algorithm (weighted, 0–100)
│   └── ai_service.dart          # Gemini 2.0 API integration + smart fallback
│
├── screens/
│   ├── splash_screen.dart       # Animated entry point
│   ├── onboarding_screen.dart   # 4-page swipe onboarding (one-time)
│   ├── home_screen.dart         # Dashboard: gauge, vitals, AI coach
│   ├── checkin_screen.dart      # 15-second daily check-in form
│   ├── insights_screen.dart     # Weekly charts + AI report
│   ├── profile_screen.dart      # Emergency card, exam mode, settings
│   └── history_screen.dart      # Expandable log of all past check-ins
│
└── utils/
    └── app_theme.dart           # Design system: colors, typography, theme
```

<br/>

## 🧮 The Risk Score Algorithm

```dart
score += sleep < 6h   ? 18–30 pts  : 0 pts    // Sleep (30% weight)
score += water < 4cups ? 8–20 pts  : 0 pts    // Hydration (20%)
score += meals < 2     ? 4–15 pts  : 0 pts    // Nutrition (15%)
score += (stressLevel - 1) * 5                // Stress (20%)
score += screenTime > 6h ? 4–10 pts : 0 pts  // Screen (10%)
score += caffeine > 2  ? 1–5 pts   : 0 pts    // Caffeine (5%)
```

| Score | Level | Action |
|-------|-------|--------|
| 0–29 | 🟢 Low | Maintain your rhythm |
| 30–49 | 🟡 Moderate | Small adjustments needed |
| 50–74 | 🟠 High | Take action now |
| 75–100 | 🔴 Critical | Immediate intervention |

<br/>

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.11`
- Dart `^3.11`
- Android Studio / VS Code
- A [Gemini API key](https://aistudio.google.com/apikey) (free)

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/abolambA/Thrive.git
cd "Thrive/Thrive Health app/thrive"

# 2. Install dependencies
flutter pub get

# 3. Add your Gemini API key
# Open lib/services/ai_service.dart and replace:
static const String _key = 'YOUR_GEMINI_API_KEY_HERE';

# 4. Run
flutter run
```

### Android Setup
Make sure `android/app/src/main/AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
*(Already included in this repo)*

<br/>

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database — all data stays on-device |
| `http` | Gemini API calls |
| `fl_chart` | Sleep, hydration, and risk trend charts |
| `google_fonts` | Inter typeface throughout |
| `shared_preferences` | User profile + settings persistence |
| `animate_do` | Staggered entrance animations |
| `smooth_page_indicator` | Onboarding page dots |
| `intl` | Date formatting |
| `percent_indicator` | Progress visualizations |

<br/>

## 🔒 Privacy

**All health data stays on your device.**

- No account required
- No cloud sync (by default)
- SQLite database stored locally
- When the AI advisor is called, only anonymized daily metrics are sent — never personally identifiable information
- API calls are made over HTTPS

<br/>

## 🗺️ Roadmap

- [ ] Smartwatch integration (Apple Watch / Wear OS) for passive data collection
- [ ] Ramadan mode — adapts all targets for fasting schedules
- [ ] AUS campus integration — opt-in anonymous aggregate insights for the wellness center
- [ ] Arabic language support
- [ ] Push notification reminders (hydration, sleep wind-down)
- [ ] Cloud backup (opt-in)

<br/>

## 🏆 Built For

**AUS Computing Competition 2025**  
Track 3: Mobile App Development  
American University of Sharjah, UAE

> *"Other apps track your health. Thrive coaches it."*

<br/>

## 👥 Team

Built in one day by two AUS students who were tired of being tired.

---

<div align="center">

**Made with ❤️ in Sharjah**

*If this helped you, give it a ⭐*

</div>
