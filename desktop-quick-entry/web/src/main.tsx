import { useState } from "react";
import ReactDOM from "react-dom/client";
import { invoke } from "@tauri-apps/api/core";

function App() {
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("0");
  const [category, setCategory] = useState("飲食");
  const [status, setStatus] = useState("");

  async function submit() {
    await invoke("quick_add_expense", { payload: { title, amount: Number(amount), category } });
    setStatus("已送出 Quick Entry（待串接 SyncMutation）");
    setTitle("");
    setAmount("0");
  }

  return (
    <main style={{ padding: 12, fontFamily: "sans-serif" }}>
      <h3>Quick Entry</h3>
      <input placeholder="標題" value={title} onChange={(e) => setTitle(e.target.value)} />
      <input placeholder="金額" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
      <input placeholder="分類" value={category} onChange={(e) => setCategory(e.target.value)} />
      <button onClick={submit}>新增</button>
      <p>{status}</p>
    </main>
  );
}

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
