# Brouillon de post LinkedIn — JustifAI

> À adapter avec tes mots. Visuels conseillés (dans l'ordre) :
>   1. le schéma d'architecture soigné (Cloudcraft / draw.io) en image de couverture ;
>   2. le diagramme généré `docs/architecture.png` (diagram-as-code) ;
>   3. 2-3 captures réelles (console AWS, email de notif, dashboard admin).

---

🚀 Nouveau projet Cloud : **JustifAI** — un dépôt intelligent de justificatifs administratifs, 100 % serverless sur AWS.

Le problème : traiter manuellement des justificatifs (pièce d'identité, domicile…), c'est lent et sujet aux erreurs.

Ma solution : une architecture event-driven où le document se traite tout seul.

Comment ça marche 👇
• L'usager s'authentifie via Cognito (JWT) et obtient une URL S3 présignée
• Il dépose son justificatif directement dans S3
• Un événement S3 déclenche une Lambda de traitement
• Amazon Textract extrait automatiquement le texte et les champs clés
• Le statut est écrit dans DynamoDB, l'usager est notifié par email (SNS)
• Le tout découplé par une file SQS (avec Dead Letter Queue pour la résilience)
• Un dashboard admin permet de revoir les documents ambigus (statut REVIEW)

La stack ☁️
Lambda · S3 · DynamoDB · Textract · API Gateway · SQS · SNS · Cognito · CloudWatch
Infrastructure 100 % en Terraform (IaC, modules réutilisables) · CI/CD GitHub Actions

Ce que j'aime dans cette approche :
✅ Zéro serveur à gérer, ça scale tout seul
✅ Reste dans le free tier AWS (~0 $/mois en démo)
✅ Sécurisé par défaut : Cognito + JWT, IAM least-privilege, S3 privé chiffré
✅ Reproductible en une commande grâce à l'Infrastructure as Code
✅ Observable : alarmes CloudWatch sur les erreurs Lambda et la DLQ

Le code est open source 👇
🔗 github.com/seydinalimamoulayeyade/justifai

#AWS #Serverless #DevOps #Cloud #Terraform #IaC #Lambda #Textract

---

## Variante courte (si tu préfères concis)

☁️ J'ai construit **JustifAI**, un dépôt de justificatifs 100 % serverless sur AWS.

Upload S3 -> Textract (OCR) -> DynamoDB -> notification SNS, le tout découplé par SQS et déployé en Terraform. Zéro serveur, ~0 $/mois.

Retour d'expérience + code 👇
🔗 github.com/seydinalimamoulayeyade/justifai

#AWS #Serverless #DevOps #Terraform
