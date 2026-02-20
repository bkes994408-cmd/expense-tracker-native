# Architecture Baseline (MVP-0)

本專案先採用簡化的 Clean Architecture 分層，方便後續擴充。

## Layers

1. **UI 層** (`ui/...`)
   - Compose 畫面與 ViewModel
   - 只處理畫面狀態與使用者互動

2. **Domain 層** (`domain/...`)
   - `Transaction` 等核心模型
   - `UseCase` + Repository 介面
   - 不依賴 Android framework

3. **Data 層** (`data/...`)
   - Repository 實作
   - 負責串接 network/local data source

4. **Network 層** (`network/...`)
   - API client 抽象
   - 目前先用 stub 實作，後續接真實 API

## 依賴方向

`UI -> Domain <- Data -> Network`

- UI 透過 UseCase 呼叫 Domain
- Data 實作 Domain 的 repository 介面
- Network 作為 Data 的外部依賴

## Dependency Injection（目前做法）

目前先使用「手動 DI」：由 `AppContainer` 集中建立依賴並提供給 UI。

### 1) `AppContainer` 如何初始化

`AppContainer` 在 app 啟動階段建立一次（通常在 `Application` 或最上層入口），內部會把 Repository、UseCase 等依賴組好。

### 2) `AppContainer` 如何往下傳

在畫面入口（例如 `MainActivity`）取得 `AppContainer` 後，透過 `viewModel { ... }` 或工廠建立 `ViewModel`，把需要的 UseCase 傳進去。

### 3) `ViewModel` 如何拿到依賴

`ViewModel` 透過建構子注入（constructor injection）取得 UseCase，例如：

```kotlin
class HomeViewModel(
    private val getTransactionsUseCase: GetTransactionsUseCase,
) : ViewModel()
```

建立時由外部注入：

```kotlin
val vm: HomeViewModel = viewModel {
    HomeViewModel(appContainer.getTransactionsUseCase)
}
```

這樣 `ViewModel` 不需要自己 new repository / use case，方便測試與替換實作。

## 下一步

- Data 層加入本機 DB (Room)
- Network 層接入 Retrofit + serialization
- 增加 DI（Hilt/Koin 擇一）
- 為 UseCase 與 Repository 增加單元測試
