# CLAUDE.md

Project context for Claude Code.

## Project overview

ASP.NET Core MVC web application (quiz platform) deployed to Azure App Service with Azure SQL Database backend.

## Tech stack

- **.NET 10** / ASP.NET Core MVC
- **Entity Framework Core** (SQL Server provider, database-first via scaffold)
- **Azure App Service** (F1 tier, `HelloWorld-Yuan`)
- **Azure SQL Database** (Basic tier, `HelloWorldYuanDb` on `helloworld-yuan-sqlserver`)
- **Bootstrap 5** for frontend styling
- **GitHub Actions** for CI/CD

## Project structure

```
HelloWorld/                  # Solution root
  HelloWorld/                # ASP.NET Core application
    Controllers/             # MVC controllers
    Models/                  # EF Core models (scaffolded, do not edit manually)
    Views/                   # Razor views
    wwwroot/                 # Static assets
    Program.cs               # App entry point + DI config
    appsettings.*.json       # Configuration per environment
  infra/                     # Azure CLI provisioning scripts
    variables.sh             # Shared config (resource names, SKU, region)
    create.sh                # Interactive: create one or all resources
    teardown.sh              # Interactive: tear down one or all resources
    app-service/             # App Service create/teardown
    sql/                     # SQL Server + Database create/teardown
  .github/workflows/
    deploy.yml               # Build + deploy on push to develop
```

## Key commands

```bash
# Run locally
cd HelloWorld
dotnet run

# Build
dotnet build

# Provision Azure resources (interactive menu)
sh infra/create.sh

# Tear down Azure resources (interactive menu)
sh infra/teardown.sh

# Re-scaffold models from database
dotnet ef dbcontext scaffold "Name=ConnectionStrings:DefaultConnection" Microsoft.EntityFrameworkCore.SqlServer -o Models --context QuizDbContext --no-onconfiguring --force
```

## Database

- Models are scaffolded from Azure SQL — do not edit `Models/*.cs` or `QuizDbContext.cs` manually
- Tables: Quiz, Question, Answer, QuizAttempt, QuizAttemptAnswer, Logs
- Connection string key: `ConnectionStrings:DefaultConnection`
- On Azure, the connection string is set via App Service connection strings config

## Azure resources

- Resource group: `RG-Student-04` (shared, never deleted by scripts)
- App Service: `HelloWorld-Yuan` (plan: `HelloWorld-BelieveIt-Plan`, F1)
- SQL Server: `helloworld-yuan-sqlserver` (francecentral)
- SQL Database: `HelloWorldYuanDb` (Basic, Local backup redundancy)
- Entra admin: `yuan.lin@believeit.fr`

## Deployment

- Push to `develop` triggers build + deploy via GitHub Actions
- Uses publish profile stored in `AZURE_WEBAPP_PUBLISH_PROFILE` secret
- App runs with `WEBSITE_RUN_FROM_PACKAGE=1`

## Logging

- Console logging locally
- `AddAzureWebAppDiagnostics()` for Azure App Service Log Stream
- Enable file system logging in Azure Portal to see logs in Log Stream

## Conventions

- Azure CLI path on Windows: `C:\Tools\azure-cli\bin\az.cmd` (set in `infra/variables.sh`)
- Infra scripts are idempotent — safe to re-run
- Main branch is `develop`
