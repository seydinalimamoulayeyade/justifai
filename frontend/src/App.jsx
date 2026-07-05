import { useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "";

export default function App() {
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState("");

  async function handleUpload(e) {
    e.preventDefault();
    if (!file) return;
    setStatus("Demande d'URL...");

    try {
      // 1. Demander une URL présignée
      const res = await fetch(`${API_BASE}/uploads`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ filename: file.name, contentType: file.type }),
      });
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

  return (
    <main style={{ maxWidth: 520, margin: "4rem auto", fontFamily: "system-ui" }}>
      <h1>JustifAI</h1>
      <p>Déposez un justificatif administratif — il sera analysé automatiquement.</p>
      <form onSubmit={handleUpload}>
        <input type="file" onChange={(e) => setFile(e.target.files[0])} />
        <button type="submit" disabled={!file}>Déposer</button>
      </form>
      {status && <p>{status}</p>}
    </main>
  );
}
