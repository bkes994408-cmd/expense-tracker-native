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

## 下一步

- Data 層加入本機 DB (Room)
- Network 層接入 Retrofit + serialization
- 增加 DI（Hilt/Koin 擇一）
- 為 UseCase 與 Repository 增加單元測試
