# Déploiement & démo — JustifAI

Runbook pas-à-pas pour déployer sur AWS, faire la démo, puis tout détruire.
Commandes prévues pour **PowerShell** (Windows). Coût visé : **free tier**.

## Pré-requis

- Compte AWS + **AWS CLI v2** configuré : `aws configure` (région `eu-west-1`).
- Terraform ≥ 1.6, Node.js 20+.
- Vérifier l'identité : `aws sts get-caller-identity`.

## 1. Variables Terraform

Créer `terraform/terraform.tfvars` (non versionné) :

```hcl
notification_email = "ton-email@example.com"
alarm_email        = "ton-email@example.com"        # optionnel
allowed_origins    = ["http://localhost:5173"]      # origine du front en dev
```

## 2. Déployer l'infrastructure

```powershell
cd terraform
terraform init
terraform plan
terraform apply        # tape "yes" pour confirmer
```

> `apply` crée de vraies ressources AWS (pay-per-use, proche de 0 $ en démo).

## 3. Confirmer l'abonnement SNS

AWS envoie un email de confirmation à `notification_email`.
**Clique le lien "Confirm subscription"** — sinon aucune notif ne partira.

## 4. Créer un utilisateur admin (Cognito)

```powershell
$POOL  = terraform output -raw cognito_user_pool_id
$EMAIL = "admin@example.com"

aws cognito-idp admin-create-user `
  --user-pool-id $POOL --username $EMAIL `
  --user-attributes Name=email,Value=$EMAIL Name=email_verified,Value=true `
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password `
  --user-pool-id $POOL --username $EMAIL `
  --password "MotDePasse123!" --permanent

aws cognito-idp admin-add-user-to-group `
  --user-pool-id $POOL --username $EMAIL --group-name admin
```

## 5. Configurer et lancer le front

Créer `frontend/.env` à partir des outputs Terraform :

```powershell
"VITE_API_BASE_URL="        + (terraform output -raw api_endpoint)          | Out-File ../frontend/.env -Encoding utf8
"VITE_COGNITO_USER_POOL_ID="+ (terraform output -raw cognito_user_pool_id) | Add-Content ../frontend/.env
"VITE_COGNITO_CLIENT_ID="   + (terraform output -raw cognito_client_id)    | Add-Content ../frontend/.env
```

Puis :

```powershell
cd ../frontend
npm install
npm run dev            # http://localhost:5173
```

## 6. Démo (captures à prendre)

1. Se connecter avec l'utilisateur admin → **écran de connexion**.
2. Déposer un justificatif → message "Traitement en cours".
3. Vérifier l'**email SNS** de notification.
4. Ouvrir le **dashboard admin** → document en statut `REVIEW` → Valider/Rejeter.
5. Console AWS : **DynamoDB** (l'item), **CloudWatch** (logs/alarmes), **S3** (l'objet).

## 7. Nettoyage (important)

```powershell
cd ../terraform
terraform destroy      # supprime toutes les ressources
```

> Vider le bucket S3 d'abord si `destroy` refuse (bucket non vide) :
> `aws s3 rm s3://$(terraform output -raw documents_bucket) --recursive`

## Dépannage

- **Upload bloqué (CORS)** : vérifier que `allowed_origins` inclut bien
  l'origine du front (ex. `http://localhost:5173`) — la CORS S3 en dépend.
- **401 sur l'API** : token expiré → se reconnecter ; vérifier que le `.env`
  pointe le bon `VITE_COGNITO_CLIENT_ID` (= audience de l'authorizer).
- **403 sur le dashboard** : l'utilisateur n'est pas dans le groupe `admin`.
- **Pas d'email** : abonnement SNS non confirmé (étape 3).
