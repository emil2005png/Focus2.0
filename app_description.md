# Focus App - Complete App Description & Architecture

## Overview
The Focus app is a comprehensive Flutter-based mobile application designed to improve user productivity, mental wellness, and habit tracking. It deeply integrates gamification, AI-assisted insights, and emotional support to keep users engaged and motivated. The app is styled with modern aesthetics (glassmorphism, soft gradients) using the `Outfit` font (`GoogleFonts.outfit`) for typography.

## Backend & Core Services
- **Firebase Authentication & Firestore:** Manages user signups/logins, profile data, journal entries, logged distractions, calendar events, habits, and vision board tasks.
- **Gemini API (`gemini_service.dart`):** Powers the app's AI features, including:
  - An emotional support chatbot where users can talk about their stress.
  - Generative insights/advice based on user's logged distractions and daily mood.
- **Gamification Service (`points_service.dart`):** The core engine driving user engagement.
  - Awards points for: Mood check-ins (+5), Journal entries (+15), Habit checks (+10), Vision board tasks (+10 to +25), and Focus sessions.
  - Maintains daily streaks with a 3-day break rule.
  - Monthly "Lives" system (restores missing streak days automatically, similar to Duolingo).
  - Rank system (Seed -> Sprout -> Blossom -> Guardian -> Master) based on total lifetime points.
- **Notification Service:** Handles local notifications via `flutter_local_notifications` for Hydration reminders (every 2 hours) and Focus Resets.
- **Analytics Provider (`analytics_provider.dart`):** Aggregates weekly data for charts (Focus time, mood trends, habit consistency, screen time).

## App Navigation Flow
The primary navigation relies on a `NavigationBar` housed in `home_screen.dart`, linking to 5 main tabs:
1. **Dashboard**
2. **Journal Hub**
3. **Calendar**
4. **Wellness Tools**
5. **Profile**

## Screen Implementations & Current UI Descriptions

### 1. Authentication & Onboarding
- **`splash_screen.dart`**: Animated entrance screen with glowing concentric circles and the brand name. Navigates to Login or Home based on auth state.
- **`login_screen.dart` & `signup_screen.dart`**: Glassmorphism aesthetic with animated background gradients. Floating orbs provide a calm backdrop while the user enters credentials.
- **`email_verification_screen.dart`**: Restricts access to the app until the user verifies their email with Firebase. Shows an animated pulse while waiting for verification.

### 2. Main Container
- **`home_screen.dart`**: Uses a `NavigationBar` to switch between views without destroying their states.

### 3. Dashboard (`dashboard_screen.dart`)
- **Current UI**:
  - **Header**: Greets the user.
  - **Engagement Banner**: Displays current Gamification Rank, Points, Streak, and Hearts (Lives). Tapping redirects to `AchievementsScreen`.
  - **Quick Action Grid**: 
    - *Daily Check-In (`mood_checkin_screen.dart`)*: Simple emoji grid to log today's mood.
    - *Mini Focus Game (`mini_focus_game_screen.dart`)*: Tapping minigame to recalibrate attention when distracted.
    - *Habit tracking (`habit_garden_screen.dart`)*.
    - *Distraction Stats (`distraction_stats_screen.dart`)*.
  - **Daily Snapshot**: A motivational section with inspirational quotes (`quote_screen.dart`) and reflection reminders.

### 4. Journal Hub (`journal_main_screen.dart`)
- **Current UI**:
  - Top area shows a "Your Month" inline mini-calendar (`TableCalendar`).
  - Vertically stacked actionable cards with solid color borders:
    - **New Journal Entry (`journal_entry_screen.dart`)**: Title, large text area, and a horizontal mood emoji selector.
    - **Daily Reflection (`reflection_screen.dart`)**: Provides thought-provoking prompts that users answer below.
    - **Past Entries (`journal_list_screen.dart`)**: StreamBuilder ListView of historical journal documents.
    - **Emotional Support Chat (`emotional_support_chat_screen.dart`)**: Chat interface talking directly to the Gemini model with preset helpful prompts (e.g., "I feel overwhelmed").

### 5. Calendar (`calendar_screen.dart`)
- **Current UI**:
  - Full-screen `TableCalendar` with customized builders.
  - Small colored dot indicators on days representing Exams (Red), Activities (Orange), Habit completions (Green), and text for Moods.
  - Below the calendar: List of events for the selected day.
  - **Add/Edit Alert Dialog**: Allows users to input Title, Details, Time, and Type (Activity/Exam). Exam events display an urgency badge indicating "X days remaining!".

### 6. Wellness Tools (`wellness_tools_screen.dart`)
- **Current UI**: List-based menu of discrete tools.
  - **Focus Timer (`focus_timer_screen.dart`)**: 
    - 25-minute Pomodoro timer with start/pause/reset. 
    - A circular visual timer indicator. 
    - Integrated "I got distracted" button leading to `log_distraction_screen.dart`.
  - **Breathing Exercise (`breathing_screen.dart`)**: 4-phase breathing cycle (Inhale, Hold, Exhale, Hold) guided by an expanding/contracting pulsating blue circle.
  - **App Reminders Toggle**: Switch tiles for Hydration check and Focus Reset notifications.

### 7. Gamification & Growth Extras
- **`achievements_screen.dart`**:
  - Top card displaying total points and current Rank icon.
  - A tabbed view containing: Total Badges (unlocked by exceeding point thresholds or keeping long streaks) and Point History (transaction logs of how points were earned).
- **`habit_garden_screen.dart`**:
  - Group habits. Checking off habits daily feeds a digital "plant" (Lottie animation) that characterizes growth based on completion rate.
- **`vision_board_screen.dart`**:
  - Top block features a large uploaded image for motivation.
  - Bottom block represents actionable checklist items toward user goals. Completing them provides larger one-time point rewards.

### 8. Analytics & Data (`analytics_screen.dart`)
- **Current UI**: Tabbed view using the `fl_chart` package.
  - **Weekly Overview Tab**: High-level text insights (Mood Trend, Habit Consistency, Best Focus Day).
  - **Charts Tab**: 
    - Focus Activity Bar Chart.
    - Mood Trends Line Chart.
    - Habit Progress Pie Chart (Completed vs Remaining).
    - Screen Time Area Line Chart.

### 9. Distraction Logger & Summary (`distraction_stats_screen.dart` & `distraction_summary_screen.dart`)
- **Current UI**:
  - `log_distraction_screen.dart`: Users explicitly log what distracted them ("Social Media", "Thoughts", etc.) and for how long.
  - The Stats Screen displays an AI-generated **Today's Insight** message analyzing the distraction patterns mapped against today's mood using Gemini.
  - The Summary Screen groups the historical data by categories into Pie charts and Bar charts via `fl_chart`.
