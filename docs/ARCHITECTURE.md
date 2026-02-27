# Architecture Baseline（MVP-0）

本文件定義 `expense-tracker-native` 在 MVP 階段的「基礎分層」。
目標是讓 iOS / Android 兩端都能維持一致的開發邏輯：

- **Network 層**：封裝遠端 API 客戶端（目前先以最小 stub 為主）
- **Data 層**：封裝本機資料儲存與 repository 實作
- **Domain 層**：定義核心模型與 repository contract
- **UI 層**：畫面、ViewModel、導覽與使用者互動

---

## Layer Responsibilities

### 1) Network Layer
- 提供 API 存取入口與未來串接能力。
- 不直接耦合 UI。

**iOS**
- `ios/ExpenseTracker/Network/APIClient.swift`

**Android**
- `android/app/src/main/java/com/bkes994408/expensetracker/network/ApiClient.kt`

### 2) Data Layer
- 管理本機資料存取與資料來源整合。
- 對上層提供 repository implementation。

**iOS**
- `ios/ExpenseTracker/DB/LocalStore.swift`
- `ios/ExpenseTracker/Expense/GRDBExpenseStore.swift`
- `ios/ExpenseTracker/Category/GRDBCategoryStore.swift`

**Android**
- `android/app/src/main/java/com/bkes994408/expensetracker/db/LocalStore.kt`
- `android/app/src/main/java/com/bkes994408/expensetracker/data/ExpenseRepositoryImpl.kt`
- `android/app/src/main/java/com/bkes994408/expensetracker/category/*`

### 3) Domain Layer
- 放置核心業務模型與介面（contract）。
- 不依賴 UI 或平台框架細節。

**iOS**
- `ios/ExpenseTracker/Domain/Expense.swift`
- `ios/ExpenseTracker/Expense/ExpenseStore.swift`
- `ios/ExpenseTracker/Category/CategoryStore.swift`

**Android**
- `android/app/src/main/java/com/bkes994408/expensetracker/domain/Expense.kt`
- `android/app/src/main/java/com/bkes994408/expensetracker/domain/ExpenseRepository.kt`

### 4) UI Layer
- 組成畫面、導覽、狀態管理（ViewModel）。
- 透過 Domain/Data contract 讀寫資料。

**iOS**
- `ios/ExpenseTracker/UI/*`
- `ios/ExpenseTracker/Expense/ExpenseListViewModel.swift`
- `ios/ExpenseTracker/Category/CategoryManagementViewModel.swift`

**Android**
- `android/app/src/main/java/com/bkes994408/expensetracker/ui/*`
- `android/app/src/main/java/com/bkes994408/expensetracker/MainActivity.kt`

---

## Data Flow（MVP）

```text
UI (View / ViewModel)
  -> Domain contracts (models + store/repository interfaces)
    -> Data implementations (LocalStore / GRDB / Room-like DAO wrappers)
      -> Network client (reserved for sync/API expansion)
```

目前 MVP 以離線優先（local-first）為主，Network 層先保留清楚的擴充點，
後續在 MVP-2 的同步階段接上遠端 API。

---

## Why This Baseline

1. **可測試性**：Domain / ViewModel 可在不依賴完整 UI 的情況測試。  
2. **可擴充性**：未來加入同步、認證、匯出時，不需要打掉重做。  
3. **跨平台一致性**：iOS / Android 以相同分層概念前進，降低維護成本。
