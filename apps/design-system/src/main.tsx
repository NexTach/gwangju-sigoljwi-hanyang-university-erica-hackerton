import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "@road-dna/design-tokens/tokens.css";
import "@road-dna/ui/styles.css";
import "./catalog.css";
import { Catalog } from "./Catalog";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Catalog />
  </StrictMode>,
);
