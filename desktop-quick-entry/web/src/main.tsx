import React from "react";
import { createRoot } from "react-dom/client";
import { QuickEntryApp } from "./QuickEntryApp";

createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <QuickEntryApp />
  </React.StrictMode>
);
