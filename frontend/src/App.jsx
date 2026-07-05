import { useEffect, useState } from "react";
import { signIn, signOut, getCurrentToken, isAdmin } from "./auth";
import AdminDashboard from "./AdminDashboard";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "";

function Letterhead() {
  return (
    <header className="letterhead">
      <p className="wordmark">
        Justif<span>AI</span>
      </p>
      <p className="tagline">
        Dépôt et traitement automatique de justificatifs administratifs
      </p>
      <div className="double-rule" />
    </header>
  );
}

export default function App() {
  const [token, setToken] = useState(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authError, setAuthError] = useState("");

  const [file, setFile] = useState(null);
  const [status, setStatus] = useState("");

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

      setStatus("Envoi du fichier...");
      await fetch(uploadUrl, {
        method: "PUT",
        headers: { "content-type": file.type },
        body: file,
      });

      setStatus(`Dossier déposé (réf. ${documentId.slice(0, 8)}). Traitement en cours...`);
      setFile(null);
    } catch (err) {
      console.error(err);
      setStatus("Erreur lors de l'envoi.");
    }
  }

  // --- Écran de connexion ---
  if (!token) {
    return (
      <div className="page">
        <Letterhead />
        <form className="folder login-card" onSubmit={handleLogin}>
          <p className="section-label">Connexion</p>
          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              placeholder="vous@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="password">Mot de passe</label>
            <input
              id="password"
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className="btn-primary">
            Se connecter
          </button>
          {authError && <p className="error">{authError}</p>}
        </form>
      </div>
    );
  }

  // --- Espace connecté ---
  const admin = isAdmin(token);

  return (
    <div className="page">
      <Letterhead />

      <div className="topbar">
        <span className="user-chip">{admin ? "ADMIN" : "USAGER"}</span>
        <button className="btn-ghost" onClick={handleLogout}>
          Se déconnecter
        </button>
      </div>

      <div className={admin ? "layout" : "layout single"}>
        <section>
          <p className="section-label">Déposer un justificatif</p>
          <form className="folder" onSubmit={handleUpload}>
            <label className="dropzone">
              <input
                type="file"
                style={{ display: "none" }}
                onChange={(e) => setFile(e.target.files[0])}
              />
              {file ? (
                <strong>{file.name}</strong>
              ) : (
                "Glisser un PDF ou une image ici, ou cliquer pour choisir"
              )}
            </label>
            <button type="submit" className="btn-primary" disabled={!file}>
              Déposer le dossier
            </button>
            {status && <p className="status-line">{status}</p>}
          </form>
        </section>

        {admin && (
          <section>
            <AdminDashboard token={token} />
          </section>
        )}
      </div>
    </div>
  );
}
