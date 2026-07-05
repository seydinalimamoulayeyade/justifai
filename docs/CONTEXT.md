# Contexte projet — JustifAI

> Fichier de reprise rapide : à lire en premier pour retrouver le contexte du
> projet dans une nouvelle session.

## En une phrase

Application **serverless AWS** de dépôt de justificatifs administratifs :
upload S3 → **Textract** (OCR/champs) → statut en DynamoDB → notification SNS,
découplé par SQS, déployé en **Terraform**, CI via GitHub Actions.

## Objectif

Projet vitrine Cloud & DevOps pour LinkedIn + prépa **AWS CLF-C02**. Doit rester
proche du **free tier** (pas d'EC2/NAT/RDS ; tout est pay-per-use).

## État actuel (squelette réalisé)

- Terraform (racine `terraform/`) : S3 chiffré + privé, DynamoDB (on-demand),
  SQS + DLQ, SNS + abonnement email, 3 rôles IAM least-privilege, 3 Lambdas,
  trigger S3→process-document, mapping SQS→notify, API Gateway HTTP.
- Lambdas Node.js 20 (SDK v3) : `request-upload`, `process-document`, `notify`.
- Frontend React+Vite minimal (upload + suivi).
- CI GitHub Actions : `terraform fmt/validate` + `node --check`.
- README, architecture.md, LINKEDIN_POST.md, .env.example, LICENSE (MIT).

## Décisions clés

- URL S3 **présignée** (pas d'upload via Lambda) : coût + pas de limite payload.
- **SQS** entre traitement et notification : découplage + retry + DLQ.
- **DynamoDB on-demand** : coût nul au repos.
- **IAM least-privilege** : un rôle par Lambda.

## Non fait / à valider

- [ ] `terraform fmt/validate` en local (pas encore exécuté)
- [ ] `node --check` sur les 3 handlers
- [ ] Tester le déploiement (`terraform apply`) sur un compte AWS

## Prochaines étapes (roadmap)

1. **Cognito** : User Pool + authorizer JWT sur l'API Gateway
   (⚠️ l'API est ouverte en l'état — à sécuriser avant toute exposition).
2. **CloudFront + Route 53 + ACM** devant le front S3 (HTTPS + domaine).
3. **Alarmes CloudWatch** : erreurs Lambda, profondeur de la DLQ.
4. **Dashboard admin** : revue des documents en statut `REVIEW`.
5. Modularisation Terraform (modules réutilisables).
6. **Toujours** : `terraform destroy` après démonstration.

## Rappels de méthode (voir steering global)

- Branches + Pull Requests, commits conventionnels, pas de secrets commités.
- README à jour + topics GitHub + post de partage en fin de jalon.
