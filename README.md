# Numi – Personal Finance Tracker

Numi is a cross-platform personal finance application built using Flutter and the MVVM architecture. The application allows users to track income and expenses, store financial records using Firebase, scan receipts using the device camera, and view spending insights through visual analytics. The project was developed as a collaborative software assignment with a focus on scalable architecture, mobile UI design, and practical device integration.

---

## 1. Project Goals

### Functional Goals
- Allow users to manually add income and expense transactions.
- Support receipt-based data entry through camera scanning and text extraction.
- Display spending summaries, total income, total expenses, and net values.
- Provide visual analytics showing category-level spending.
- Store data using Firebase for persistent access.

### Architectural Goals
- Use the MVVM design pattern to separate UI, business logic, and data access.
- Keep UI free of business and database logic.
- Use ViewModels to manage state, compute financial totals, and communicate with Firebase.
- Use Services to handle camera access, database operations, and external resources.
- Make each component independently testable.

### User Experience Goals
- Apply gesture-based interactions such as swipe deletion and pull-to-refresh.
- Use responsive animations to make information easier to read.
- Provide a consistent interface across multiple screens using shared widgets.

---

## 2. Technology Overview

| Component | Tools |
|-----------|-------|
| Framework | Flutter (Dart) |
| Architecture | MVVM |
| Storage | Firebase |
| Device Feature | Camera-based receipt scanning |
| UI Layer | Flutter Material 3 |
| Analytics | Custom bar chart animations |
| Testing | Unit and widget tests |

---

## 3. MVVM Architecture

Numi follows the Model–View–ViewModel structure to maintain clear separation between interface, logic, and data:

- **Models** define the structure of financial data (e.g., transaction, budget).
- **ViewModels** contain application logic, including data validation, calculations, and calls to services.
- **Views (Screens)** are responsible only for layout and user interaction.
- **Services** handle Firebase operations, camera usage, and external tasks.

This structure prevents UI code from depending directly on Firebase or camera logic, making the application easier to maintain and test.

---

## 4. Project Structure


---

## 5. Screen Descriptions

### HomeScreen
This screen provides an overview of the user's current financial situation. It displays summary cards for income, expenses, and net balance. Each card uses a custom widget and applies animations to draw attention to total values. Quick navigation buttons allow the user to jump to transactions or analytics. Tapping the net value also leads to analytics.

### TransactionsScreen
This screen lists all recorded transactions using a scrollable view. Each item is shown using a reusable component (`TransactionTile`). The screen supports swipe-to-delete, which removes a transaction and confirms the action using a snackbar. Pull-to-refresh allows the user to manually refresh the list. If no data is available, a placeholder widget (`EmptyState`) explains that no transactions exist yet.

### AddTransactionScreen
This screen provides a form for entering a new income or expense. It validates user input and ensures a valid amount is entered. A date picker is provided for accuracy, and categories are selected through a dropdown menu. Optional notes can be entered, and a button completes the submission. In the current version, the submission triggers a confirmation snackbar, but the logic is prepared for ViewModel integration.

### AnalyticsScreen
This screen shows how spending is distributed across categories. A bar chart is drawn using animated widgets, gradually increasing bar heights to make the visualization easier to follow. Actual numerical values are shown above each bar, and a list summarizes category totals below the graph.

---

## 6. Custom Widgets

- **SummaryCard:** Displays key statistics such as income, expenses, or net values. Can also act as a navigation button through an optional callback.
- **TransactionTile:** Shows the details of a single transaction, including category, date, and the amount formatted and color-coded.
- **SectionHeader:** Standard title format used across multiple screens for consistency.
- **EmptyState:** Shown when there is no data to display, providing explanatory text and an icon.

Using reusable widgets reduces code duplication and keeps the UI consistent.

---

## 7. Animations and Gestures

| Feature | Purpose | Implementation |
|--------|---------|----------------|
| Fade and scale on summary cards | Draw attention to important information | AnimatedOpacity, AnimatedScale |
| Animated bar graph | Gradual data visualization | TweenAnimationBuilder |
| Swipe to delete | Efficient list modification | Dismissible |
| Pull to refresh | Familiar mobile behavior and manual refresh | RefreshIndicator |
| Snackbar confirmation | Text feedback for user actions | ScaffoldMessenger |

The goal of these features is to improve clarity and interaction, not simply aesthetic appeal.

---

## 8. Firebase and Data Handling

Firebase is responsible for storing transaction data. ViewModels call Firebase service functions to retrieve, add, update, and delete transaction records. This ensures that UI files do not directly use Firebase libraries, making future changes easier.

Typical ViewModel responsibilities include:
- Fetching all transactions from Firebase
- Deleting transactions based on user gestures
- Calculating totals such as net income and category totals

---

## 9. Camera and Receipt Scanning

The camera service enables users to take a picture of a receipt. Once captured, the image can be processed by an OCR parser to identify total amounts and other details. The resulting data is passed to the ViewModel to create a new financial entry. Keeping these features in services allows camera logic to change without modifying the UI.

---

## 10. Testing

Testing focuses on validating data logic and ensuring UI components render correctly:

- **Unit tests** verify calculations in the ViewModels (income, expenses, net calculations).
- **Widget tests** confirm that custom components render correctly and respond to gestures.
- **Basic integration tests** ensure the main navigation routes launch without errors.

---

## 11. Installation and Setup

### Clone the Repository



