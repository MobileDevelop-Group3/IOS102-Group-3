# IOS102-Group-3- App Design Project

## CampusSpot 

## Table of Contents
1. [Overview](#overview)
2. [Product Spec](#product-spec)
3. [Wireframes](#wireframes)
4. [Schema](#schema)

---

## Overview

### Description
CampusSpot is a mobile application designed for university students to discover, review, and bookmark the best study spots on campus. Whether you're looking for a quiet corner, a collaborative group room, or a hidden gem on campus; CampusSpot helps you find your ideal productivity environment based on real student ratings and live filters.

### App Evaluation
* **Category:** Education / Productivity / Utility
* **Mobile:** Designed primarily as a mobile application (iOS) for students on the move, with responsive layouts for quick on-campus access.
* **Story:** Tells the story of stressed students navigating campus looking for available, high-quality study spaces, transforming a frustrating search into a seamless experience.
* **Market:** College and university students, study groups, and campus organizations.
* **Habit:** Daily or weekly use app, especially utilized during midterms, finals, or between classes when students need a reliable workspace.
* **Scope:** Focused feature set covering user accounts, location browsing, interactive map/list filtering, user reviews with photo uploads, and bookmarking.

---

## Product Spec

### 1. User Stories (Required & Optional)

**Required Must-have Stories**
- [ ] User can register a new account and log in securely.
- [ ] User can browse a list of campus study locations with key details (noise level, seating capacity, power outlet availability).
- [ ] User can search for study locations by name or keyword.
- [ ] User can filter locations based on specific attributes (e.g., quiet zone, has outlets, open late).
- [ ] User can view detailed information for a specific study spot, including aggregated ratings, reviews, and uploaded photos.
- [ ] User can submit a review and upload a photo for a study location.
- [ ] User can bookmark or save favorite locations to a personal "Saved Spots" list.

**Optional Nice-to-have Stories**
- [ ] User can view locations on an interactive campus map.
- [ ] User can see real-time or crowdsourced busyness/crowd level indicators.
- [ ] User can edit or delete their own reviews and uploaded photos.
- [ ] User profile screen displaying user stats (number of reviews posted, saved spots).

### 2. Screen Archetypes
- [ ] **Login / Registration Screen**
  - Allows users to sign up or log in to their account.
- [ ] **Home / Browse Feed Screen**
  - Displays a scrollable list of popular or nearby study locations with quick tags (noise level, outlets).
- [ ] **Search & Filter Screen**
  - Enables users to filter spots by specific criteria and search by name.
- [ ] **Location Detail Screen**
  - Shows full information about a spot (photos, reviews, descriptions, amenities) with options to bookmark or add a review.
- [ ] **Add Review Screen**
  - Allows users to rate a spot, write a review, and attach a photo.
- [ ] **Profile / Bookmarks Screen**
  - Displays user account details and a list of bookmarked/saved study spots.

### 3. Navigation

**Tab Navigation** (Tab to Screen)
- [Home / Browse Tab] -> Home Feed Screen
- [Search / Filter Tab] -> Search & Filter Screen
- [Bookmarks Tab] -> Saved Spots Screen
- [Profile Tab] -> Profile Screen

**Flow Navigation** (Screen to Screen)
- **Home Feed Screen**
  - Leads to **Location Detail Screen** (upon tapping a spot)
- **Search & Filter Screen**
  - Leads to **Location Detail Screen** (upon selecting a search result)
- **Location Detail Screen**
  - Leads to **Add Review Screen** (upon tapping "Write a Review")
- **Profile Screen**
  - Leads to **Login Screen** (upon logging out)

---

## Wireframes

### Hand-Sketched Wireframes

The following PDF contains the hand-sketched wireframes for CampusSpot, illustrating the app's screens and navigation.

[View Hand-Sketched Wireframes (PDF)](Wireframe/Hand-Sketched%20Wireframe%20Project.pdf)

### Digital Wireframes & Mockups

The following digital wireframes illustrate the 12 CampusSpot screens and their layouts.

![CampusSpot Digital Wireframes](Wireframe/Digital%20Wireframe.png)


### [BONUS] Interactive Prototype

---

## Schema

### Models

#### User
| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | unique id for the user (default field) |
| `username` | String | unique username for login |
| `email` | String | user's email address |
| `password` | String | user's password for login authentication |
| `createdAt` | DateTime | date/time when user account is created |

#### Location
| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | unique id for the study location |
| `name` | String | name of the building/room (e.g., Green Library 2nd Floor) |
| `description` | String | details about the space, seating, and atmosphere |
| `noiseLevel` | String | e.g., "Quiet", "Moderate", "Loud / Collaborative" |
| `hasOutlets` | Boolean | true if power outlets are readily available |
| `image` | File | hero photo of the study location |
| `averageRating` | Number | average rating calculated from reviews |

#### Review
| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | unique id for the review |
| `author` | Pointer (User) | user who wrote the review |
| `location` | Pointer (Location) | study spot being reviewed |
| `rating` | Number | star rating (1-5) |
| `comment` | String | text feedback about the spot |
| `photo` | File | optional photo uploaded by the student |
| `createdAt` | DateTime | date/time when review was posted |

#### Bookmark
| Property | Type | Description |
| --- | --- | --- |
| `objectId` | String | unique id for the bookmark entry |
| `user` | Pointer (User) | user who saved the location |
| `location` | Pointer (Location) | study spot that was bookmarked |

### Networking

- **List of network requests by screen:**
  - **Home Feed Screen**
    - `[GET]` Query all `Location` objects to display in the feed.
  - **Search & Filter Screen**
    - `[GET]` Query `Location` objects matching search query string or filter constraints (e.g., `hasOutlets == true`).
  - **Location Detail Screen**
    - `[GET]` Query `Review` objects where `location` matches the current spot.
    - `[POST]` Create a new `Bookmark` object when the user taps save.
    - `[DELETE]` Delete the `Bookmark` object when the user unsaves.
  - **Add Review Screen**
    - `[POST]` Create a new `Review` object linked to the current user and location.
  - **Profile / Bookmarks Screen**
    - `[GET]` Query `Bookmark` objects where `user` matches the current user to display saved spots.
