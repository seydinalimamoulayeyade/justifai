import { TextractClient, DetectDocumentTextCommand } from "@aws-sdk/client-textract";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const textract = new TextractClient({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const sqs = new SQSClient({});

const TABLE = process.env.TABLE;
const QUEUE_URL = process.env.QUEUE_URL;

/**
 * Déclenché par un événement S3 (ObjectCreated).
 * Extrait le texte via Textract, écrit le statut en DynamoDB, notifie via SQS.
 */
export const handler = async (event) => {
  for (const record of event.Records ?? []) {
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
    // uploads/<documentId>/<filename>
    const documentId = key.split("/")[1] ?? key;

    try {
      const result = await textract.send(
        new DetectDocumentTextCommand({
          Document: { S3Object: { Bucket: bucket, Name: key } },
        })
      );

      const lines = (result.Blocks ?? [])
        .filter((b) => b.BlockType === "LINE")
        .map((b) => b.Text);

      // Classification minimale (à enrichir) : à partir des mots-clés détectés
      const text = lines.join(" ").toLowerCase();
      const type = detectType(text);
      const status = type === "INCONNU" ? "REVIEW" : "PROCESSED";

      await ddb.send(
        new PutCommand({
          TableName: TABLE,
          Item: {
            documentId,
            key,
            type,
            status,
            fields: { lineCount: lines.length },
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

      console.log(`Traité ${documentId} -> ${type} (${status})`);
    } catch (err) {
      console.error(`Echec traitement ${key}`, err);
      throw err; // laisse Lambda relancer / envoyer en échec
    }
  }
};

function detectType(text) {
  if (text.includes("carte") && text.includes("identit")) return "CNI";
  if (text.includes("facture") || text.includes("domicile")) return "JUSTIF_DOMICILE";
  if (text.includes("attestation")) return "ATTESTATION";
  return "INCONNU";
}
