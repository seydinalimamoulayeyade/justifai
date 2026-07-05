import { useCallback, useEffect, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "";

/**
 * Vue admin : liste les documents en statut REVIEW et permet de les valider
 * ou rejeter. Réservée aux membres du groupe Cognito "admin".
 */
export default function AdminDashboard({ token }) {
  const [docs, setDocs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const authHeaders = { authorization: `Bearer ${token}` };

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/documents?status=REVIEW`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setDocs(data.items ?? []);
    } catch (err) {
      console.error(err);
      setError("Impossible de charger les documents à revoir.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    load();
  }, [load]);

  async function decide(documentId, status) {
    try {
      const res = await fetch(`${API_BASE}/documents/${documentId}`, {
        method: "PATCH",
        headers: { ...authHeaders, "content-type": "application/json" },
        body: JSON.stringify({ status }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setDocs((prev) => prev.filter((d) => d.documentId !== documentId));
    } catch (err) {
      console.error(err);
      setError("La mise à jour a échoué.");
    }
  }

  return (
    <section style={{ marginTop: "2rem", borderTop: "1px solid #ddd", paddingTop: "1rem" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h2 style={{ margin: 0 }}>Documents à revoir</h2>
        <button onClick={load} disabled={loading}>
          {loading ? "Chargement..." : "Rafraîchir"}
        </button>
      </div>

      {error && <p style={{ color: "crimson" }}>{error}</p>}
      {!loading && docs.length === 0 && <p>Aucun document en attente de revue.</p>}

      <ul style={{ listStyle: "none", padding: 0 }}>
        {docs.map((d) => (
          <li
            key={d.documentId}
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "0.5rem 0",
              borderBottom: "1px solid #eee",
            }}
          >
            <span>
              <strong>{d.type ?? "INCONNU"}</strong>
              <br />
              <small>{d.documentId}</small>
            </span>
            <span>
              <button onClick={() => decide(d.documentId, "VALIDATED")}>Valider</button>{" "}
              <button onClick={() => decide(d.documentId, "REJECTED")}>Rejeter</button>
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}
