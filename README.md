# HelloWorld

ASP.NET Core web application deployed to Azure App Service.

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (for infrastructure provisioning)

## Run locally

```bash
cd HelloWorld
dotnet run
```

The app will be available at `https://localhost:5001` (or the port shown in console output).

## Infrastructure

Azure resources are managed via CLI scripts in the [`infra/`](infra/) folder. See [`infra/README.md`](infra/README.md) for details.

```bash
# Provision App Service Plan + App Service
sh infra/create-app-service.sh

# Tear down
sh infra/teardown.sh
```

## Deployment

Deployment is handled by a GitHub Actions workflow (`.github/workflows/deploy.yml`).

- **On push to `develop`**: builds and publishes the artifact
- **Manual trigger**: set `deploy` to `true` to deploy to Azure

The workflow uses a publish profile stored in the `AZURE_WEBAPP_PUBLISH_PROFILE` GitHub secret.

## Project structure

```
HelloWorld/
  HelloWorld/          # ASP.NET Core application
  infra/               # Azure CLI provisioning scripts
  .github/workflows/   # CI/CD pipeline
```
