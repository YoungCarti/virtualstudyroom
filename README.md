# StudyLink - Virtual Study Room Platform

![StudyLink App Screenshot](assets/images/app_screenshot.png)

A comprehensive, AI-powered student dashboard and collaboration platform built with Flutter. StudyLink combines productivity tools, classroom management, and real-time collaboration into a single, modern interface.

## 🚀 Key Features

### 🎓 Student Dashboard
*   **Personalized Experience**: Dynamic greeting, rotating motivational quotes (updates every minute), and streak tracking.
*   **Assignment Tracker**: View pending assignments with due day urgency indicators (Today, Tomorrow, Overdue).
*   **Quick Actions**: Fast access to key study modules.
*   **Real-time Stats**: Track your completed assignments, classes attended, and study streak.

### 🧠 AI-Powered Learning Tools
*   **Flashcard Generator**: Generate study flashcards instantly from any topic using Gemini AI.
*   **Quiz Maker**: Create custom quizzes to test your knowledge on any subject.
*   **Notes Helper**: AI-assisted note organization and summarization.
*   **Brainwave Station**: Focus music and AI guidance.

### 🍅 Productivity Suite
*   **Forest Timer**: Gamified focus timer. Grow virtual trees by staying focused!
*   **Todo List**: Manage daily tasks and study goals.
*   **Study Rooms**: Join virtual rooms to study with others.

### 🤝 Real-Time Collaboration
*   **Group Chats**: Instant messaging for study groups and classes.
*   **Collaborative Canvas**: Real-time shared whiteboard for brainstorming and problem-solving.
*   **Video & Audio Calls**: Integrated high-quality video and voice conferencing (powered by Agora).

### 🏫 Classroom Management (LMS)
*   **Class & Assignment Management**: Join classes, view curriculum, and track grades.
*   **Role-Based Access**: Dedicated views for Students and Lecturers.
*   **Notifications**: Real-time alerts for new assignments and messages.

## 🛠️ Tech Stack

*   **Frontend**: [Flutter](https://flutter.dev/) (Dart) - Cross-platform (iOS, Android, Web, Desktop).
*   **Backend**: [Firebase](https://firebase.google.com/)
    *   **Auth**: Secure user authentication (Email/Password, Google Sign-In).
    *   **Firestore**: Real-time NoSQL database for data syncing.
    *   **Storage**: Asset and file storage.
    *   **App Check**: Security and abuse prevention.
*   **AI Integration**: Google Gemini AI (via `firebase_ai` / `google_generative_ai`).
*   **Real-Time Media**: [Agora](https://www.agora.io/) (Video/Audio/Live Streaming).
*   **State Management**: `StreamBuilder`, `StatefulWidget`, and reactive patterns.
*   **UI/UX**: Custom "Glassmorphism" influenced dark theme with `flutter_animate` and custom painters.

## 📱 Project Structure

```
lib/
├── auth_page.dart           # Authentication State Handler
├── home_dashboard.dart      # Main Student Dashboard
├── classes_page.dart        # Class Management
├── collaborative_canvas/    # Shared Whiteboard 
├── ai_tools_page.dart       # Hub for AI features
├── services/                # Backend logic (Auth, Notifications, etc.)
├── widgets/                 # Reusable UI components
└── ... (Feature specific pages)
```

## 🏁 Getting Started

### Prerequisites
1.  **Flutter SDK**: Ensure you have Flutter installed (`flutter doctor`).
2.  **Firebase Project**: Create a project in the Firebase Console.
    *   Enable Authentication, Firestore, and Storage.
    *   Enable AI extensions (if using Firebase Extensions for Gemini) or generate a generic API key.
3.  **Agora App ID**: Register on Agora.io for video call functionality.

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/YoungCarti/virtualstudyroom.git
    cd virtualstudyroom
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configuration**:
    *   Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective app folders.
    *   Create a `.env` file in the root directory (add to `.gitignore`) and add necessary keys:
        ```env
        GEMINI_API_KEY=your_api_key_here
        AGORA_APP_ID=your_agora_app_id
        ```

4.  **Run the app**:
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a Pull Request.

## Authors

*   **@YoungCarti** - Frontend & UI/UX
*   **@Breadler** - Backend & Architecture

## Feedback

If you have any feedback or find bugs, please reach out via GitHub Issues or Discord.
