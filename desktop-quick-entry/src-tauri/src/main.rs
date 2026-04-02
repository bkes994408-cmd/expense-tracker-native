#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::Deserialize;
use tauri::{menu::{Menu, MenuItem}, tray::TrayIconBuilder, Manager};

#[derive(Debug, Deserialize)]
struct QuickExpensePayload {
    title: String,
    amount: f64,
    category: String,
}

#[tauri::command]
fn quick_add_expense(payload: QuickExpensePayload) -> Result<(), String> {
    println!(
        "[quick-entry] title={}, amount={}, category={}",
        payload.title, payload.amount, payload.category
    );
    Ok(())
}

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let show = MenuItem::with_id(app, "show", "顯示視窗", true, None::<&str>)?;
            let quit = MenuItem::with_id(app, "quit", "離開", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &quit])?;

            let _tray = TrayIconBuilder::new()
                .menu(&menu)
                .on_menu_event(|app, event| {
                    match event.id.as_ref() {
                        "show" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                        "quit" => app.exit(0),
                        _ => {}
                    }
                })
                .build(app)?;

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![quick_add_expense])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
