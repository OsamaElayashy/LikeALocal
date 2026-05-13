# LikeALocal

A Flutter app for discovering local places and experiences in Egyptian cities.

## Setup

### Prerequisites
- Flutter SDK
- Firebase project with Realtime Database, Authentication, Storage, and Firestore enabled
- Google Maps API key

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase:
   - Add `google-services.json` to `android/app/`
   - Configure iOS if needed
4. Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`

### AI Chatbot Setup
The app includes an AI chatbot powered by Google's Gemini API.

1. Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open `lib/config/api_config.dart`
3. Replace `'your_api_key_here'` with your actual API key
4. The chatbot will now be able to answer questions about places in the app

### Features
- Discover places by city and category
- Add and review places
- AI-powered chatbot for recommendations
- Location-based notifications
- Bookmark favorite places
- User profiles with contribution tracking