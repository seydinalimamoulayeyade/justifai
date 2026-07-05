import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// `amazon-cognito-identity-js` référence `global`, absent dans le navigateur.
// On le mappe sur `globalThis` pour éviter un "global is not defined" (page blanche).
export default defineConfig({
  plugins: [react()],
  define: {
    global: "globalThis",
  },
});
