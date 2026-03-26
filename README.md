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
# Provision App Service
sh infra/app-service/create.sh

# Provision SQL Server + Database
sh infra/sql/create.sh

# Tear down
sh infra/app-service/teardown.sh
sh infra/sql/teardown.sh
```

## Database setup

### 1. Configure connection string

Add to `HelloWorld/appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=sql-quizlab-xx.database.windows.net;Database=AzureQuizLabDB;User Id=dbserveradmin;Password=VOTRE_MOT_DE_PASSE;TrustServerCertificate=True;"
  }
}
```

### 2. Install packages and scaffold

```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet tool install --global dotnet-ef
dotnet ef dbcontext scaffold "Name=ConnectionStrings:DefaultConnection" Microsoft.EntityFrameworkCore.SqlServer -o Models --context QuizDbContext --no-onconfiguring
```

## Deployment

Deployment is handled by a GitHub Actions workflow (`.github/workflows/deploy.yml`).

- **On push to `develop`**: builds and publishes the artifact
- **Manual trigger**: set `deploy` to `true` to deploy to Azure

The workflow uses a publish profile stored in the `AZURE_WEBAPP_PUBLISH_PROFILE` GitHub secret.

## Project structure

```
HelloWorld/
  HelloWorld/              # ASP.NET Core application
  infra/
    variables.sh           # Shared config (resource names, SKU, region)
    app-service/           # App Service provisioning scripts
    sql/                   # SQL Server + Database provisioning scripts
  .github/workflows/       # CI/CD pipeline
```
