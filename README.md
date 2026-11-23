# IOS102-Group-3 - App Design Project

# CampusSpot

## Table of Contents
1. [Overview](#overview)
2. [Product Spec](#product-spec)
3. [Wireframes](#wireframes)
4. [Schema](#schema)
5. [Current Implementation](#current-implementation)

---

## Overview

### Description

CampusSpot is a mobile application designed for university students to discover, review, and bookmark the best study spots on campus. Whether you're looking for a quiet corner, a collaborative group room, or a hidden gem on campus, CampusSpot helps you find your ideal productivity environment based on student information and location details.

### App Evaluation

* **Category:** Education / Productivity / Utility
* **Mobile:** Designed primarily as a mobile application (iOS) for students on the move, with responsive layouts for quick on-campus access.
* **Story:** Helps students find available study spaces on campus, making it easier to choose an environment that fits their needs.
* **Market:** College and university students, study groups, and campus organizations.
* **Habit:** Daily or weekly use app, especially during midterms, finals, or between classes.
* **Scope:** Focused feature set covering user accounts, location browsing, search, reviews, and bookmarking.

---

## Product Spec

### 1. User Stories (Required & Optional)

**Required Must-have Stories**

- [x] User can log in using demo credentials.
- [x] User can register a new account and log in securely.
- [x] User can browse a list of campus study locations with descriptions and study environments.
- [x] User can search for study locations by name or keyword.
- [x] User can filter locations based on specific attributes (e.g., quiet zone, has outlets, open late).
- [x] User can view details and descriptions for a specific study spot.
- [ ] User can submit a review for a study location.
- [ ] User can bookmark or save favorite locations to a personal "Saved Spots" list.

**Optional Nice-to-have Stories**

- [ ] User can view locations on an interactive campus map.
- [ ] User can see real-time or crowdsourced busyness/crowd level indicators.
- [ ] User profile screen displaying user stats (number of reviews posted, saved spots).

### 2. Screen Archetypes

- [x] **Welcome Screen**
  - Introduces CampusSpot and provides access to the login flow.
- [x] **Login Screen**
  - Allows users to log in using the demo credentials.
- [x] **Registration Screen**
  - Registration interface is available; actual account creation is not implemented yet.
- [x] **Home / Browse Feed Screen**
  - Displays a featured study spot and campus browsing options.
- [x] **Search Screen**
  - Enables users to search study spots by name, description, or campus.
- [x] **Location Detail Screen**
  - Displays the study spot's description, campus, and study environment.
- [ ] **Add Review Screen**
  - Review submission and photo uploads are not implemented yet.
- [x] **Bookmarks Screen**
  - Bookmarks tab is available; saving and displaying bookmarks are not implemented yet.
- [x] **Profile Screen**
  - Profile tab is available with logout functionality. User profile information is not implemented yet.

### 3. Navigation

**Tab Navigation** (Tab to Screen)

- Home Tab -> Home Feed Screen
- Search Tab -> Search Screen
- Bookmarks Tab -> Saved Spots Screen
- Profile Tab -> Profile Screen

**Flow Navigation** (Screen to Screen)

- **Welcome Screen**
  - Leads to Login Screen.
- **Login Screen**
  - Leads to Sign Up Screen.
  - Successful demo login leads to Home Feed Screen.
- **Sign Up Screen**
  - Allows users to return to Login Screen.
- **Home Feed Screen**
  - Leads to Location Detail Screen when selecting a study spot.
  - Allows users to browse locations by campus.
- **Search Screen**
  - Leads to Location Detail Screen when selecting a search result.
- **Profile Screen**
  - Allows users to log out and return to the Login Screen.

---

## Wireframes

### Hand-Sketched Wireframes

The following PDF contains the hand-sketched wireframes for CampusSpot, illustrating the app's screens and navigation.

[View Hand-Sketched Wireframes (PDF)](Wireframe/Hand-Sketched%20Wireframe%20Project.pdf)

### Digital Wireframes & Mockups

The following digital wireframes illustrate the planned CampusSpot screens and their layouts.

![CampusSpot Digital Wireframes](Wireframe/Digital%20Wireframe.png)

### [BONUS] Interactive Prototype

---

## Schema

### Models

The following models describe the planned backend data structure.

#### User

| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | Unique ID for the user (default field) |
| `username` | String | Unique username for login |
| `email` | String | User's email address |
| `password` | String | User's password for login authentication |
| `createdAt` | DateTime | Date/time when user account is created |

#### Location

| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | Unique ID for the study location |
| `name` | String | Name of the building/room |
| `description` | String | Details about the space, seating, and atmosphere |
| `noiseLevel` | String | Example: Quiet, Moderate, or Loud / Collaborative |
| `hasOutlets` | Boolean | True if power outlets are readily available |
| `image` | File | Hero photo of the study location |
| `averageRating` | Number | Average rating calculated from reviews |

#### Review

| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | Unique ID for the review |
| `author` | Pointer (User) | User who wrote the review |
| `location` | Pointer (Location) | Study spot being reviewed |
| `rating` | Number | Star rating (1-5) |
| `comment` | String | Text feedback about the spot |
| `photo` | File | Optional photo uploaded by the student |
| `createdAt` | DateTime | Date/time when review was posted |

#### Bookmark

| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | Unique ID for the bookmark entry |
| `user` | Pointer (User) | User who saved the location |
| `location` | Pointer (Location) | Study spot that was bookmarked |

### Networking

The following network requests describe the planned backend functionality.

- **Home Feed Screen**
  - `[GET]` Query all `Location` objects to display in the feed.
- **Search Screen**
  - `[GET]` Query `Location` objects matching a search query or filter constraints.
- **Location Detail Screen**
  - `[GET]` Query `Review` objects where `location` matches the current spot.
  - `[POST]` Create a new `Bookmark` object when the user taps save.
  - `[DELETE]` Delete the `Bookmark` object when the user unsaves.
- **Add Review Screen**
  - `[POST]` Create a new `Review` object linked to the current user and location.
- **Profile / Bookmarks Screen**
  - `[GET]` Query `Bookmark` objects where `user` matches the current user to display saved spots.

---

## Current Implementation

CampusSpot is currently implemented using SwiftUI.

---

## App Demo

The following GIF demonstrates the CampusSpot application, including its login flow and navigation.

![CampusSpot Demo](Current%20Status%20(1).gif)

### Completed Functionality

- Welcome, Login, and Sign Up interfaces.
- Demo login authentication using hardcoded credentials.
- Persistent login session using local app storage.
- Automatic navigation to Home when reopening the app with an active session.
- Logout functionality that clears the saved login session.
- Main tab navigation with Home, Search, Bookmarks, and Profile.
- Home feed featuring a study spot and campus browsing.
- Study spot listings for MMC, BBC, and the Engineering Center.
- Search functionality across study spot names, descriptions, and campus names.
- Study spot detail pages with descriptions and study environments.

### Demo Login Credentials

- **Email:** `demo@campusspot.com`
- **Password:** `Campus123!`

### Current Development Notes

- Study spot information is currently stored locally in the Swift code.
- Login uses demo credentials and does not yet connect to a backend authentication service.
- Account registration, reviews, photo uploads, bookmarks, and backend networking are planned for future implementation.
