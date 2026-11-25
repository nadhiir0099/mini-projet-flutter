# PC Rig & Setup Builder 🖥️

A clean, modern, and beginner-friendly Flutter mobile application for planning, budgeting, and assembling custom PC builds.

Built as a university mini-project demonstrating **Material 3 UI design**, **local SQLite database persistence (CRUD)**, **Named Route navigation**, and **standard Flutter state management** (`setState`, `StatefulWidget`, and `StatelessWidget`) without third-party state complexity.

---

## 🚀 Key Features

1. **My Builds Dashboard (`DashboardScreen` - StatefulWidget)**:
   - **Customizable Target Budget**: Set and edit your target budget with an intuitive pop-up dialog (`AlertDialog`).
   - **Real-Time Total Cost Calculation**: Dynamically sums component prices directly from SQLite.
   - **Budget Health Tracker**: Visual progress bar and status indicator highlighting remaining budget or warning when over budget.
   - **Search & Category Filters**: Real-time search bar (by part name/specs) and horizontal category chips (`All`, `CPU`, `GPU`, `Motherboard`, `RAM`, `Storage`, `Monitor`, `Peripheral`, `Other`).
   - **Component List**: Modern hardware cards with category icons, component names, pricing, specs notes, and a delete action.

2. **Add / Edit Component Form (`PartFormScreen` - StatefulWidget)**:
   - Handles both **creating new parts** and **editing existing parts** via route arguments.
   - Complete form validation (required names, valid positive numbers for price, category selection).
   - **Over-Budget Warning Pop-up**: If adding or updating a part pushes the total build cost past the target budget, a friendly alert dialog notifies the user with exact figures before saving.
   - Robust `try / catch` error handling for database operations.

3. **PC Building Tips & Guide (`BuildTipsScreen` - StatelessWidget)**:
   - A static informational reference screen.
   - Practical hardware compatibility checklist covering CPU socket types (AM5 vs LGA1700), PSU wattage headroom, GPU chassis clearance, RAM DDR4/DDR5 compatibility, and thermal cooling.

4. **Pop-Up Dialogs (`AlertDialog`)**:
   - **Delete Confirmation Dialog**: Prevents accidental component deletion.
   - **Budget Limit Exceeded Warning**: Visual notification with financial breakdown.
   - **Target Budget Edit Dialog**: Quick modal to adjust financial targets.

---

## 📁 Project Architecture & Folder Structure

```text
lib/
├── main.dart                  # App entry point, Material 3 slate theme, Named Routes
├── models/
│   └── pc_part.dart           # PcPart data model with toMap() and fromMap()
├── database/
│   └── db_helper.dart         # SQLite Singleton database helper (CRUD operations)
└── screens/
    ├── dashboard_screen.dart  # Main dashboard (StatefulWidget)
    ├── part_form_screen.dart  # Add & Edit part form (StatefulWidget)
    └── build_tips_screen.dart # PC building tips checklist (StatelessWidget)
```

---

## 🛠️ Tech Stack & Dependencies

- **Framework:** Flutter (Channel stable, Material 3)
- **Language:** Dart 3
- **Local Database:** `sqflite: ^2.3.0` & `path: ^1.9.0`
- **Design System:** Material 3 Dark Slate Palette (`#0F172A` Slate-900, `#1E293B` Slate-800, `#06B6D4` Cyan Accent)

---

## 🏃 Getting Started & How to Run

1. **Clone or Open the Project**:
   Open this folder in VS Code, Android Studio, or your preferred IDE.

2. **Install Dependencies**:
   Open a terminal in the project directory and run:
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   Connect an Android device, iOS simulator, or desktop target and execute:
   ```bash
   flutter run
   ```

---

## 💡 Notes for University Mini-Project Viva & Presentation

- **Why `setState`?**: Kept intentionally simple and transparent so examiners and reviewers can follow state transitions without the boilerplate of Riverpod or Bloc.
- **SQLite Singleton Pattern**: `DbHelper.instance` ensures only a single database connection is opened across the application lifecycle.
- **Named Routes**: Declarative navigation configured cleanly in `MaterialApp.routes` (`'/'`, `'/part-form'`, `'/tips'`).
