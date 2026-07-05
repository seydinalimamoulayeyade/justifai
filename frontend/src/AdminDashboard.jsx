import { useCallback, useEffect, useState } from "react";
import Stamp from "./Stamp";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "";

const today = new Date().toLocaleDateString("fr-FR");

/**
 * Vue admin : liste les documents en statut REVIEW et permet de les valider
 * ou rejeter. Réservée aux membres du groupe Cognito "admin".
 */
export default function AdminDashboard({ token }) {
  const [docs, setDocs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [stamping, setStamping] = useState({}); // documentId -> true pendant l'animation

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/documents?status=REVIEW`, {
        headers: { authorization: `Bearer ${token}` },
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
        headers: {
          authorization: `Bearer ${token}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ status }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const remove = () => setDocs((prev) => prev.filter((d) => d.documentId !== documentId));

      if (status === "VALIDATED") {
        // Appose le tampon, puis retire le dossier de la liste des "à revoir".
        setStamping((s) => ({ ...s, [documentId]: true }));
        setTimeout(remove, 1100);
      } else {
        remove();
      }
    } catch (err) {
      console.error(err);
      setError("La mise à jour a échoué.");
    }
  }

  return (
    <>
      <div className="section-head">
        <p className="section-label">Documents à revoir</p>
        <button className="btn-ghost" onClick={load} disabled={loading}>
          {loading ? "Chargement..." : "Rafraîchir"}
        </button>
      </div>

      {error && <p className="error">{error}</p>}
      {!loading && docs.length === 0 && (
        <div className="empty-state">Aucun document en attente de revue.</div>
      )}

      <div className="dossiers">
        {docs.map((d) => {
          const ref = String(d.documentId).slice(0, 8);
          const created = d.createdAt
            ? new Date(d.createdAt).toLocaleDateString("fr-FR")
            : "—";
          return (
            <div className="dossier" key={d.documentId}>
              <div className="dossier-top">
                <div>
                  <p className="dossier-ref">N° {ref}</p>
                  <p className="dossier-name">{d.type ?? "INCONNU"}</p>
                  <p className="dossier-meta">déposé le {created}</p>
                </div>
                <span className="badge badge-review">À revoir</span>
              </div>
              <div className="dossier-actions">
                <button className="btn-ghost" onClick={() => decide(d.documentId, "VALIDATED")}>
                  Valider
                </button>
                <button className="btn-ghost" onClick={() => decide(d.documentId, "REJECTED")}>
                  Rejeter
                </button>
              </div>
              {stamping[d.documentId] && <Stamp id={d.documentId} date={today} />}
            </div>
          );
        })}
      </div>
    </>
  );
}
