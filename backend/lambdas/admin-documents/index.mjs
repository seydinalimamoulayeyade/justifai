import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  QueryCommand,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const TABLE = process.env.TABLE;
const STATUS_INDEX = process.env.STATUS_INDEX ?? "status-index";
const ALLOWED_STATUSES = new Set(["REVIEW", "PROCESSED", "REJECTED", "VALIDATED"]);

/**
 * API admin (protégée JWT + groupe Cognito "admin").
 *   GET   /documents?status=REVIEW      -> liste les documents d'un statut
 *   PATCH /documents/{documentId} {status} -> met à jour le statut d'un document
 */
export const handler = async (event) => {
  if (!isAdmin(event)) {
    return json(403, { message: "Accès réservé aux administrateurs." });
  }

  const method = event.requestContext?.http?.method;

  try {
    if (method === "GET") return await listByStatus(event);
    if (method === "PATCH") return await updateStatus(event);
    return json(405, { message: "Méthode non supportée." });
  } catch (err) {
    console.error("admin-documents error", err);
    return json(500, { message: "Erreur serveur." });
  }
};

async function listByStatus(event) {
  const status = event.queryStringParameters?.status ?? "REVIEW";
  if (!ALLOWED_STATUSES.has(status)) {
    return json(400, { message: `Statut invalide : ${status}` });
  }

  const res = await ddb.send(
    new QueryCommand({
      TableName: TABLE,
      IndexName: STATUS_INDEX,
      KeyConditionExpression: "#s = :status",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: { ":status": status },
      ScanIndexForward: false, // plus récents d'abord
      Limit: 100,
    })
  );

  return json(200, { items: res.Items ?? [], count: res.Count ?? 0 });
}

async function updateStatus(event) {
  const documentId = event.pathParameters?.documentId;
  if (!documentId) return json(400, { message: "documentId manquant." });

  const body = event.body ? JSON.parse(event.body) : {};
  const status = body.status;
  if (!ALLOWED_STATUSES.has(status)) {
    return json(400, { message: `Statut invalide : ${status}` });
  }

  const res = await ddb.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { documentId },
      UpdateExpression: "SET #s = :status, reviewedAt = :now",
      ConditionExpression: "attribute_exists(documentId)",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: {
        ":status": status,
        ":now": new Date().toISOString(),
      },
      ReturnValues: "ALL_NEW",
    })
  );

  return json(200, { item: res.Attributes });
}

/** Vérifie la présence du groupe "admin" dans la claim cognito:groups du JWT. */
function isAdmin(event) {
  const claims = event.requestContext?.authorizer?.jwt?.claims ?? {};
  const groups = claims["cognito:groups"];
  if (!groups) return false;
  // La claim peut être une liste JSON stringifiée ou une chaîne séparée par des espaces/virgules.
  const normalized = Array.isArray(groups)
    ? groups
    : String(groups).replace(/[[\]]/g, "").split(/[\s,]+/);
  return normalized.includes("admin");
}

const json = (statusCode, data) => ({
  statusCode,
  headers: { "content-type": "application/json" },
  body: JSON.stringify(data),
});
