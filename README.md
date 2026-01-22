# 🍽️ Full Stack Restaurant Reservation App

A comprehensive mobile application for discovering restaurants, viewing details, and making real-time reservations. Built with **Flutter** (Frontend), **Node.js** (Backend), and **MSSQL** (Database).

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![MSSQL](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white)

## 📱 Features

* **Authentication:** Secure Login & Registration system.
* **Discovery:** Filter restaurants by categories (Kebab, Burger, Pizza, etc.) or search by name.
* **Optimized Search:** Implemented **Debounce** mechanism for efficient API calls during search.
* **Reservation System:** Real-time checking of available time slots and booking functionality.
* **Favorites:** Users can save their favorite restaurants (Persistent data using **SharedPreferences**).
* **Localization:** Multi-language support (English & Turkish) with dynamic content translation.
* **Theme Support:** Dark and Light mode adaptability.
* **Modern UI:** Custom widgets, smooth animations, and responsive design.

## 🛠️ Tech Stack

### Frontend (Mobile)
* **Framework:** Flutter (Dart)
* **Networking:** Dio
* **State Management:** `setState` (Optimized for performance)
* **Storage:** Shared Preferences (for local data persistence)
* **Utils:** Intl (Date formatting), Localization delegates

### Backend (API)
* **Runtime:** Node.js
* **Framework:** Express.js
* **Database Driver:** mssql

### Database
* **System:** Microsoft SQL Server (SSMS)
* **Structure:** Relational schema including Users, Restaurants, Reservations, and Availability Slots.

## 📸 Screenshots

### ✨ Core Application Flow
Here is the main user journey from login to making a reservation and checking the profile.

| Login Screen | Home & Discovery | Restaurant View |
|:---:|:---:|:---:|
| <img src="screenshots/giris.png" width="250"> | <img src="screenshots/anasayfa.png" width="250"> | <img src="screenshots/rezervasyon.png" width="250"> |
| **Date Selection** | **Favorites** | **User Profile** |
| <img src="screenshots/tarih.png" width="250"> | <img src="screenshots/favoriler.png" width="250"> | <img src="screenshots/profil.png" width="250"> |

<br>

<details>
<summary><b>🔻 Click here to see MORE screenshots (Settings, Dark Mode, etc.)</b></summary>
<br>
These features demonstrate the depth of the application, including filtering, settings, and theming.

| Category Filter | Reservation Details | Settings Menu |
|:---:|:---:|:---:|
| <img src="screenshots/kategori.png" width="250"> | <img src="screenshots/rezervasyon_detay.png" width="250"> | <img src="screenshots/ayarlar.png" width="250"> |
| **Dark Mode** | **Language Selection** | **Change Password** |
| <img src="screenshots/darkmode.png" width="250"> | <img src="screenshots/dil.png" width="250"> | <img src="screenshots/sifredegistirme.png" width="250"> |

</details>

## 🚀 Installation & Setup

This project is organized as a monorepo. Follow the steps below to run it locally.

### 1. Database Setup
1.  Open **SQL Server Management Studio (SSMS)**.
2.  Navigate to the `/database` folder in this repo.
3.  Run the `script.sql` (or `kurulum.sql`) file to generate the schema and populate dummy data.

### 2. Backend Setup
```bash
cd backend
npm install
# Configure your database connection in the server file or .env
node server.js
```
### 2. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```
