#[tauri::command]
fn save_quick_entry(title: String, amount: f64, category: String) -> Result<String, String> {
    if title.trim().is_empty() {
        return Err("title is required".into());
    }
    if amount <= 0.0 {
        return Err("amount must be > 0".into());
    }
    if category.trim().is_empty() {
        return Err("category is required".into());
    }

    Ok(format!("saved:{}:{}:{}", title, amount, category))
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![save_quick_entry])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
