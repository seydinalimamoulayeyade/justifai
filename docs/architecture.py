"""Diagramme d'architecture JustifAI (diagram-as-code).

Génère docs/architecture-as-code.png à partir du code, avec les icônes AWS
officielles. (Le visuel principal du README, docs/architecture.png, est le
rendu draw.io — voir docs/architecture.drawio.)

Pré-requis :
    - Graphviz (binaire `dot`) : https://graphviz.org/download/
    - pip install diagrams

Usage :
    python docs/architecture.py
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.integration import SimpleNotificationServiceSns as SNS
from diagrams.aws.integration import SimpleQueueServiceSqs as SQS
from diagrams.aws.management import Cloudwatch
from diagrams.aws.ml import Textract
from diagrams.aws.mobile import APIGateway
from diagrams.aws.security import Cognito
from diagrams.aws.storage import SimpleStorageServiceS3 as S3
from diagrams.onprem.client import User

graph_attr = {
    "fontsize": "18",
    "labelloc": "t",
    "pad": "0.6",
    "splines": "spline",
}

with Diagram(
    "JustifAI — architecture serverless AWS",
    filename="docs/architecture-as-code",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    user = User("Usager / Admin")
    cognito = Cognito("Cognito\n(User Pool + groupe admin)")

    with Cluster("API Gateway (HTTP API) — authorizer JWT"):
        api = APIGateway("API")

    with Cluster("Lambdas"):
        request_upload = Lambda("request-upload\nPOST /uploads")
        admin_docs = Lambda("admin-documents\nGET/PATCH /documents")
        process_doc = Lambda("process-document")
        notify = Lambda("notify")

    bucket = S3("S3 justificatifs\n(privé + chiffré)")
    table = Dynamodb("DynamoDB\n(+ GSI status-index)")
    textract = Textract("Textract\n(OCR / champs)")

    with Cluster("Notification (découplée)"):
        queue = SQS("SQS")
        dlq = SQS("DLQ")
        topic = SNS("SNS (email)")

    with Cluster("Observabilité"):
        cw = Cloudwatch("CloudWatch\nalarmes")
        alarms_topic = SNS("SNS alarmes")

    # Authentification + appels API
    user >> Edge(label="login") >> cognito
    user >> Edge(label="JWT") >> api
    api >> request_upload
    api >> admin_docs

    # Upload présigné puis traitement piloté par événement S3
    request_upload >> Edge(label="URL présignée") >> bucket
    bucket >> Edge(label="ObjectCreated") >> process_doc
    process_doc >> textract
    process_doc >> table
    process_doc >> Edge(label="message") >> queue

    # Notification
    queue >> notify
    queue >> Edge(style="dashed", label="échecs") >> dlq
    notify >> topic

    # Dashboard admin (revue statut REVIEW)
    admin_docs >> Edge(label="query/update") >> table

    # Observabilité
    cw >> alarms_topic
