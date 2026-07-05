# Partage — JustifAI

> Contenu prêt à coller. Visuels conseillés (dans l'ordre) :
>   1. le diagramme d'architecture (`docs/architecture.png`) en image de couverture ;
>   2. capture du dashboard admin avec le tampon « VALIDÉ » ;
>   3. capture console AWS (item DynamoDB + alarmes CloudWatch) — **numéro de compte flouté**.

---

## Description courte du repo (GitHub → About)

> Dépôt intelligent de justificatifs : app 100 % serverless AWS (Lambda, Textract, DynamoDB, SQS/SNS, Cognito) déployée en Terraform modulaire, avec CI GitHub Actions.

## Topics GitHub à ajouter

`aws` · `serverless` · `terraform` · `iac` · `lambda` · `textract` · `dynamodb` · `cognito` · `devops` · `cicd` · `react`

---

## Post principal (version « projet »)

🚀 Nouveau projet Cloud : **JustifAI** — un dépôt intelligent de justificatifs administratifs, 100 % serverless sur AWS.

Le problème : traiter manuellement des justificatifs (pièce d'identité, domicile, attestation…), c'est lent et sujet aux erreurs.

Ma solution : une architecture **event-driven** où le document se traite tout seul.

Comment ça marche 👇
• L'usager s'authentifie via **Cognito** (JWT) et obtient une **URL S3 présignée**
• Il dépose son justificatif directement dans **S3**
• Un événement S3 déclenche une **Lambda** de traitement
• **Amazon Textract** extrait automatiquement le texte
• Le statut est écrit dans **DynamoDB**, l'usager notifié par email (**SNS**)
• Le tout découplé par une file **SQS** (+ Dead Letter Queue pour la résilience)
• Un **dashboard admin** permet de revoir les cas ambigus (statut REVIEW)

La stack ☁️
Lambda · S3 · DynamoDB · Textract · API Gateway · SQS · SNS · Cognito · CloudWatch
Infrastructure 100 % en **Terraform** (modules réutilisables) · CI/CD **GitHub Actions**

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

## Post « retour d'expérience » (angle incident — le plus engageant)

☁️ J'ai déployé **JustifAI**, une app serverless AWS de traitement de justificatifs — et le plus instructif, c'est un **bug rencontré en vrai**.

En testant, j'uploade un **PDF**. Quelques secondes plus tard : 📩 email d'**alarme CloudWatch**.

Diagnostic (via les logs CloudWatch de la Lambda) :
`UnsupportedDocumentException` — l'API **synchrone** de Textract n'accepte pas ce format. La Lambda échouait, réessayait 3 fois, et déclenchait l'alarme.

Le correctif (déployé par Pull Request) : au lieu de **planter**, un format non OCR-isable est désormais classé en **REVIEW** (revue manuelle) — *graceful degradation*. Plus d'échec, plus de fausse alarme.

Ce que ça illustre, et qui compte vraiment en DevOps :
✅ L'**observabilité** a détecté le problème en < 5 min (alarme automatique)
✅ Les **logs centralisés** ont donné la cause immédiatement
✅ Le **workflow Git** (branche → PR → merge) a tracé le correctif proprement
✅ La **résilience** : SQS + DLQ + gestion d'erreur pensées dès le départ

Stack : Lambda · Textract · S3 · DynamoDB · SQS/SNS · Cognito · CloudWatch · **Terraform** (modules) · GitHub Actions.

Projet open source, architecture + code 👇
🔗 github.com/seydinalimamoulayeyade/justifai

#AWS #Serverless #DevOps #Terraform #Observability #CloudWatch

---

## Variante courte

☁️ **JustifAI** : dépôt de justificatifs 100 % serverless sur AWS.

Cognito (JWT) → URL S3 présignée → Textract (OCR) → DynamoDB → notification SNS, découplé par SQS/DLQ. Déployé en Terraform modulaire, dashboard admin, alarmes CloudWatch. Zéro serveur, ~0 $/mois.

Code 👇 github.com/seydinalimamoulayeyade/justifai

#AWS #Serverless #DevOps #Terraform
