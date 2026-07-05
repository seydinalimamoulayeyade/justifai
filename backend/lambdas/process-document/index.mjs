import { TextractClient, DetectDocumentTextCommand } from "@aws-sdk/client-textract";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const textract = new TextractClient({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const sqs = new SQSClient({});

const TABLE = process.env.TABLE;
const QUEUE_URL = process.env.QUEUE_URL;

// Formats non pris en charge par l'API Textract synchrone (PDF/TIFF -> API async).
const UNSUPPORTED_FORMAT = "UnsupportedDocumentException";

/**
 * Déclenché par un événement S3 (ObjectCreated).
 * Extrait le texte via Textract, écrit le statut en DynamoDB, notifie via SQS.
 * Un format non supporté par l'OCR n'est pas une erreur : le document est
 * simplement classé en REVIEW pour une revue manuelle.
 */
export const handler = async (event) => {
  for (const record of event.Records ?? []) {
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
    // uploads/<documentId>/<filename>
    const documentId = key.split("/")[1] ?? key;

    let type = "INCONNU";
    let status = "REVIEW";
    let fields = {};

    try {
      const result = await textract.send(
        new DetectDocumentTextCommand({
          Document: { S3Object: { Bucket: bucket, Name: key } },
        })
      );

      const lines = (result.Blocks ?? [])
        .filter((b) => b.BlockType === "LINE")
        .map((b) => b.Text);

      const text = lines.join(" ").toLowerCase();
      type = detectType(text);
      status = type === "INCONNU" ? "REVIEW" : "PROCESSED";
      fields = { lineCount: lines.length };
    } catch (err) {
      if (err.name === UNSUPPORTED_FORMAT) {
        // Format non OCR-isable en synchrone (ex. PDF) : revue manuelle, pas d'échec.
        type = "INCONNU";
        status = "REVIEW";
        fields = { note: "Format non pris en charge par l'OCR — revue manuelle requise" };
        console.warn(`Format non supporté pour ${key}, classé en REVIEW`);
      } else {
        console.error(`Echec traitement ${key}`, err);
        throw err; // vraie erreur -> retry Lambda + alarme
      }
    }

    await persistAndNotify({ documentId, key, type, status, fields });
    console.log(`Traité ${documentId} -> ${type} (${status})`);
  }
};

async function persistAndNotify({ documentId, key, type, status, fields }) {
  await ddb.send(
    new PutCommand({
      TableName: TABLE,
      Item: {
        documentId,
        key,
        type,
        status,
        fields,
        createdAt: new Date().toISOString(),
      },
    })
  );

  await sqs.send(
    new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify({ documentId, type, status }),
    })
  );
}

function detectType(text) {
  if (text.includes("carte") && text.includes("identit")) return "CNI";
  if (text.includes("facture") || text.includes("domicile")) return "JUSTIF_DOMICILE";
  if (text.includes("attestation")) return "ATTESTATION";
  return "INCONNU";
}
