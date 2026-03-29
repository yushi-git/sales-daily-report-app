gcloud iam service-accounts add-iam-policy-binding \
    831732763814-compute@developer.gserviceaccount.com \
    --role roles/iam.serviceAccountUser \
    --member "serviceAccount:github-actions-deployer@project-87677895-1a10-4291-8ac.iam.gserviceaccount.com" \
    --project project-87677895-1a10-4291-8ac 