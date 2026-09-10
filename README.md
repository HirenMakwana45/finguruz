# FinGuruz - Personal Finance Management Application

FinGuruz is a Flutter-based personal finance management application designed to help users log expenses, plan budgets, monitor financial health, and track multi-currency transactions.

---

## 🌟 Key Features

### 📊 1. Dashboard
- **Financial Summary**: Real-time display of total balance, income, and expenses converted into your chosen base currency.
- **Dynamic Currency Switcher**: Seamlessly switch base currency (USD, EUR, GBP, INR, JPY, CAD, AUD, CHF) with automatic rate updates.
- **Budget Alert Banner**: Instant notifications when category budgets near 80% or exceed 100% limit.
- **Recent Transactions List**: Quick view of recent transactions with category icons and visual status indicators (+ for income, - for expenses).

### 💳 2. Expense Tracker
- **Log Transactions**: Categorize income & expenses with custom note and original currency.
- **Recurring Expenses**: Automatically log recurring transactions (Daily, Weekly, Monthly, Yearly).
- **Search & Filter**: Real-time search with type filters (All, Expenses, Income) and category filtering.
- **Swipe to Delete**: Dismissible items with confirmation modal.

### 🎯 3. Budget Planning
- **Category Budgets**: Set monthly spending limits per category.
- **Progress Tracking**: Color-coded progress indicators:
  - 🟢 **Green**: Under 80% used (Normal)
  - 🟠 **Orange**: 80% - 99% used (Nearing Limit Warning)
  - 🔴 **Red**: 100%+ used (Limit Exceeded)
- **Month Selector**: Easily view past or upcoming monthly budgets.

### 📈 4. Reports & Visual Insights
- **Category Spending Pie Chart**: Interactive `fl_chart` breakdown of spending per category.
- **Income vs Expense Bar Chart**: Visual comparison of income vs expenses.
- **Savings Rate Metric**: Real-time calculation of net savings and savings percentage.

### 🌐 5. Multi-Currency Exchange API & Caching
- **API Integration**: Powered by open-source ExchangeRate API (`open.er-api.com`).
- **Optimization Strategy**: API calls are made **at most once per calendar day**. Rate data is persisted locally in SQLite (`cached_exchange_rates` table). Data reloads read directly from cache without redundant network calls.

---

## 🏗️ Architecture & Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: `provider` (Clean separation of Business Logic & UI)
- **Local Database**: `sqflite` (SQLite)
- **Charts**: `fl_chart`
- **Formatting**: `intl`
- **Theme**: Material 3 (Light & Dark mode support)

---

## 🚀 Getting Started

```bash
# Get dependencies
flutter pub get

# Run unit and widget tests
flutter test

# Run application
flutter run
```
