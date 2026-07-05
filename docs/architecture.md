# Architecture — JustifAI

## Vue d'ensemble

JustifAI est une application **serverless, event-driven**. Aucune ressource
n'est allumée en permanence : chaque composant ne s'exécute (et n'est facturé)
qu'à l'usage.

![Architecture JustifAI](architecture.png)

> Ce diagramme est généré en **diagram-as-code** depuis `architecture.py`
> (lib `diagrams` + Graphviz). Le régénérer : `python docs/architecture.py`.

```
Usager/Admin --(login)--> Cognito (User Pool + groupe admin)
Usager/Admin --(JWT)----> API Gateway (HTTP API, authorizer JWT)
                                     |
              +----------------------+----------------------+
              v                                             v
   Lambda: request-upload                        Lambda: admin-documents
     (POST /uploads)                          (GET/PATCH /documents, groupe admin)
              |                                             |
     URL S3 présignée                              query/update (GSI status)
              v                                             v
        S3 (justificatifs)  --event ObjectCreated-->  DynamoDB (+ GSI status-index)
                                     |                       ^
                              Lambda: process-document ------+
                          +----------+--------------+
                          v          v              v
                     Textract    DynamoDB       SQS (+ DLQ)
                    (OCR/champs)  (statut)          |
                                                     v
                                              Lambda: notify -> SNS (email)

CloudWatch (alarmes: erreurs Lambda + profondeur DLQ) -> SNS alarmes
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
6. **Revue admin** — un membre du groupe Cognito `admin` accède au dashboard :
   `admin-documents` liste les documents en statut `REVIEW` (Query sur le GSI
   `status-index`) et permet de les valider/rejeter (`PATCH /documents/{id}`).

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
| status | PROCESSED / REVIEW / VALIDATED / REJECTED |
| fields | champs extraits par Textract (JSON) |
| createdAt | horodatage ISO |
| reviewedAt | horodatage de la décision admin (si revue) |

> Un **index secondaire global** `status-index` (clé `status`, tri `createdAt`)
> permet au dashboard admin de requêter les documents par statut.

## Améliorations prévues (roadmap)

- [x] Cognito + authorizer JWT sur l'API Gateway
- [x] Modularisation Terraform (modules réutilisables)
- [x] Alarmes CloudWatch (erreurs Lambda, profondeur DLQ)
- [x] Tableau de bord admin (revue des documents en statut REVIEW)
- [ ] CloudFront + Route 53 + ACM devant le front
