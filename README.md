# Student Resources App

A comprehensive iOS application designed to help students manage their educational resources, notes, and study materials efficiently. 

## Features

- User Authentication: Secure login and registration system integrated with Firebase.
- Profile Management: Customizable user profiles and application settings.
- Notes Management: Create, edit, and organize personal and shared notes.
- Study Materials: Access and organize question papers and study resources.
- AI Quiz Generator: Automatically generate practice quizzes based on study materials.
- Media Integration: Save and organize educational YouTube links.
- Review Workflows: Submit notes and question papers for peer or admin review.
- Task Management: Built-in to-do list functionality to track assignments and deadlines.
- Admin Dashboard: Dedicated interfaces for administrators to manage content and reviews.

## Architecture & Technologies

- Framework: SwiftUI
- Architecture: MVVM (Model-View-ViewModel)
- Backend Integration: Firebase (Authentication, Firestore, Storage)
- Third-Party Services: Cloudinary (Media management), OpenAI API (AI Quiz generation)

## Project Structure

- Authentication: Contains managers and views for user sessions and security.
- Model: Defines core data structures like Notes, Quizzes, and To-Do items.
- Views: Contains all SwiftUI interface components, organized by feature (Home, Notes, Profile, etc.).
- Firebase: Service classes for interacting with backend databases and external APIs.
- Tests: Includes unit tests and UI tests to ensure application stability.

## Setup Instructions

1. Clone the repository to your local machine.
2. Open `student-res.xcodeproj` in Xcode.
3. Ensure you have an active Apple Developer account configured in Xcode for provisioning.
4. Add the required `GoogleService-Info.plist` to the project root for Firebase configuration.
5. Create a `Secrets.swift` file in the project root containing your specific API keys.
6. Build and run the application on your preferred iOS simulator or physical device.
