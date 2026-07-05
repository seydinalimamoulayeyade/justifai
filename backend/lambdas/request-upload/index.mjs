import { randomUUID } from "node:crypto";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET;

/**
 * POST /uploads
 * Body: { filename, contentType }
 * Retourne une URL S3 présignée (PUT) + l'identifiant du document.
 */
export const handler = async (event) => {
  try {
    const body = event.body ? JSON.parse(event.body) : {};
    const { filename = "document", contentType = "application/octet-stream" } = body;

    const documentId = randomUUID();
    const key = `uploads/${documentId}/${filename}`;

    const url = await getSignedUrl(
      s3,
      new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType }),
      { expiresIn: 300 } // 5 minutes
    );

    return json(200, { documentId, key, uploadUrl: url });
  } catch (err) {
    console.error("request-upload error", err);
    return json(500, { message: "Erreur lors de la génération de l'URL" });
  }
};

const json = (statusCode, data) => ({
  statusCode,
  headers: { "content-type": "application/json" },
  body: JSON.stringify(data),
});
