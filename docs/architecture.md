# Architecture — JustifAI

## Vue d'ensemble

JustifAI est une application **serverless, event-driven**. Aucune ressource
n'est allumée en permanence : chaque composant ne s'exécute (et n'est facturé)
qu'à l'usage.

```
Route53 + ACM  ->  CloudFront  ->  S3 (front React statique)
                                     |
                            API Gateway (HTTP API) + Cognito
                                     |
                     Lambda: request-upload / list / status
                                     |
                          S3 (bucket justificatifs)
                                     |  event: ObjectCreated
                              Lambda: process-document
                          +----------+--------------+
                          v          v              v
                     Textract    DynamoDB       SQS (+ DLQ)
                    (OCR/champs)  (statut)          |
                                                     v
                                              Lambda: notify -> SNS (email)
                                     |
                              CloudWatch (logs / métriques / alarmes)
```

## Flux détaillé

1. **Authentification** — l'usager se connecte via Amazon Cognito (User Pool).
   Le front récupère un JWT et l'envoie à l'API Gateway.
2. **Demande d'upload** — `request-upload` génère une **URL S3 présignée**
   (PUT), ce qui évite de faire transiter le fichier par la Lambda.
3. **Dépôt** — le front upload directement le fichier dans le bucket S3.
4. **Traitement** — l'événement `s3:ObjectCreated:*` déclenche
   `process-document` :
   - appel à **Amazon Textract** pour extraire texte + champs ;
   - classification simple (type de document, présence des champs attendus) ;
   - écriture du statut dans **DynamoDB** (`PENDING` -> `PROCESSED` / `REVIEW`) ;
   - envoi d'un message dans **SQS**.
5. **Notification** — `notify` consomme la file SQS et publie sur **SNS**
   (email à l'usager). Les échecs partent en **Dead Letter Queue** (DLQ).
6. **Suivi** — le front interroge l'API (`list` / `status`) pour afficher l'état
   des justificatifs.

## Décisions d'architecture

- **URL présignée** plutôt qu'upload via Lambda : moins cher, pas de limite de
  taille de payload API Gateway (6 Mo), et découplage.
- **SQS entre traitement et notification** : découplage + résilience (retry,
  DLQ) — un échec d'email ne bloque pas le traitement.
- **DynamoDB on-demand** : pas de capacité à provisionner, coût nul au repos.
- **Textract** : service IA managé, pas d'infra ML à gérer, 1000 pages/mois
  gratuites la première année.
- **IAM least-privilege** : chaque Lambda a un rôle limité à ses actions.

## Sécurité

- Buckets S3 privés (accès uniquement via URL présignée et rôles Lambda).
- Chiffrement au repos (S3 SSE, DynamoDB) activé par défaut.
- Authentification Cognito sur l'API ; autorisation par JWT.
- Secrets et identifiants jamais commités (variables Terraform / SSM).

## Modèle de données (DynamoDB)

Table `documents` (clé de partition `documentId`) :

| Attribut | Description |
| --- | --- |
| documentId | UUID du justificatif |
| userId | identifiant Cognito de l'usager |
| type | type détecté (CNI, domicile, ...) |
| status | PENDING / PROCESSED / REVIEW / REJECTED |
| fields | champs extraits par Textract (JSON) |
| createdAt | horodatage ISO |

## Améliorations prévues (roadmap)

- [ ] Cognito + autorizer JWT sur l'API Gateway
- [ ] CloudFront + Route 53 + ACM devant le front
- [ ] Modularisation Terraform (modules réutilisables)
- [ ] Alarmes CloudWatch (erreurs Lambda, profondeur DLQ)
- [ ] Tableau de bord admin (revue des documents en statut REVIEW)
