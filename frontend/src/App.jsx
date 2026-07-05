import { useEffect, useState } from "react";
import { signIn, signOut, getCurrentToken } from "./auth";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "";

export default function App() {
  const [token, setToken] = useState(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authError, setAuthError] = useState("");

  const [file, setFile] = useState(null);
  const [status, setStatus] = useState("");

  // Restaure une session Cognito existante au chargement
  useEffect(() => {
    getCurrentToken().then((t) => t && setToken(t));
  }, []);

  async function handleLogin(e) {
    e.preventDefault();
    setAuthError("");
    try {
      const jwt = await signIn(email, password);
      setToken(jwt);
    } catch (err) {
      setAuthError(err.message ?? "Échec de la connexion.");
    }
  }

  function handleLogout() {
    signOut();
    setToken(null);
    setStatus("");
  }

  async function handleUpload(e) {
    e.preventDefault();
    if (!file) return;
    setStatus("Demande d'URL...");

    try {
      // 1. Demander une URL présignée (route protégée par JWT)
      const res = await fetch(`${API_BASE}/uploads`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ filename: file.name, contentType: file.type }),
      });

      if (res.status === 401) {
        setStatus("Session expirée, reconnectez-vous.");
        handleLogout();
        return;
      }

      const { uploadUrl, documentId } = await res.json();

      // 2. Uploader directement le fichier dans S3
      setStatus("Envoi du fichier...");
      await fetch(uploadUrl, {
        method: "PUT",
        headers: { "content-type": file.type },
        body: file,
      });

      setStatus(`Justificatif déposé (id: ${documentId}). Traitement en cours...`);
    } catch (err) {
      console.error(err);
      setStatus("Erreur lors de l'envoi.");
    }
  }

  const wrap = { maxWidth: 520, margin: "4rem auto", fontFamily: "system-ui" };

  if (!token) {
    return (
      <main style={wrap}>
        <h1>JustifAI</h1>
        <p>Connectez-vous pour déposer un justificatif.</p>
        <form onSubmit={handleLogin}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            type="password"
            placeholder="Mot de passe"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <button type="submit">Se connecter</button>
        </form>
        {authError && <p style={{ color: "crimson" }}>{authError}</p>}
      </main>
    );
  }

  return (
    <main style={wrap}>
      <header style={{ display: "flex", justifyContent: "space-between" }}>
        <h1>JustifAI</h1>
        <button onClick={handleLogout}>Se déconnecter</button>
      </header>
      <p>Déposez un justificatif administratif — il sera analysé automatiquement.</p>
      <form onSubmit={handleUpload}>
        <input type="file" onChange={(e) => setFile(e.target.files[0])} />
        <button type="submit" disabled={!file}>Déposer</button>
      </form>
      {status && <p>{status}</p>}
    </main>
  );
}
