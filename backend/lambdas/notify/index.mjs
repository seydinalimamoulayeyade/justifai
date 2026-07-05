import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const sns = new SNSClient({});
const TOPIC_ARN = process.env.TOPIC_ARN;

/**
 * Déclenché par la file SQS. Publie une notification SNS (email) par message.
 */
export const handler = async (event) => {
  for (const record of event.Records ?? []) {
    const { documentId, type, status } = JSON.parse(record.body);

    const subject = `JustifAI — justificatif ${status.toLowerCase()}`;
    const message =
      `Votre justificatif ${documentId} a été traité.\n` +
      `Type détecté : ${type}\n` +
      `Statut : ${status}\n`;

    await sns.send(
      new PublishCommand({ TopicArn: TOPIC_ARN, Subject: subject, Message: message })
    );

    console.log(`Notification envoyée pour ${documentId}`);
  }
};
