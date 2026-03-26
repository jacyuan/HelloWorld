# HelloWorld

ASP.NET Core web application deployed to Azure App Service.

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (for infrastructure provisioning)
- [VS Code](https://code.visualstudio.com/) with **C# Dev Kit** extension (`ms-dotnettools.csdevkit`)

## Getting started

### 1. Provision Azure resources

```bash
sh infra/create.sh
```

Choose **ALL** to create the App Service and SQL Server + Database in one go.

### 2. Configure GitHub Actions deployment

1. In the Azure Portal, go to **App Service** > `HelloWorld-Yuan` > **Download publish profile**
2. In your GitHub repo, go to **Settings > Secrets and variables > Actions**
3. Create a secret named `AZURE_WEBAPP_PUBLISH_PROFILE` and paste the publish profile contents

### 3. Configure the SQL connection string

Get the connection string from the Azure Portal (**SQL Database** > `HelloWorldYuanDb` > **Connection strings**), then:

- **Locally** — add to `HelloWorld/appsettings.Development.json`:

  ```json
  {
    "ConnectionStrings": {
      "DefaultConnection": "Server=tcp:<SQL_SERVER>.database.windows.net,1433;Initial Catalog=<DATABASE>;User Id=<USER>;Password=<PASSWORD>;TrustServerCertificate=True;"
    }
  }
  ```

- **Azure App Service** — set via Portal (Settings > Environment variables > Connection strings) or CLI:

  ```bash
  az webapp config connection-string set \
    --name <APP_SERVICE_NAME> \
    --resource-group <RESOURCE_GROUP> \
    --connection-string-type SQLAzure \
    --settings DefaultConnection="Server=tcp:<SQL_SERVER>.database.windows.net,1433;Initial Catalog=<DATABASE>;User ID=<USER>;Password=<PASSWORD>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  ```

## Run locally

```bash
cd HelloWorld
dotnet run
```

The app will be available at `https://localhost:5001` (or the port shown in console output).

## Infrastructure

Azure resources are managed via CLI scripts in the [`infra/`](infra/) folder. See [`infra/README.md`](infra/README.md) for details.

```bash
# Interactive: choose which resource to create (or all in parallel)
sh infra/create.sh

# Or provision individually
sh infra/app-service/create.sh
sh infra/sql/create.sh

# Interactive: choose which resource to tear down (or all in parallel)
sh infra/teardown.sh

# Or tear down individually
sh infra/app-service/teardown.sh
sh infra/sql/teardown.sh
```

## EF Core scaffold

```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.Extensions.Logging.AzureAppServices
dotnet tool install --global dotnet-ef
dotnet ef dbcontext scaffold "Name=ConnectionStrings:DefaultConnection" Microsoft.EntityFrameworkCore.SqlServer -o Models --context QuizDbContext --no-onconfiguring
```

## Logging

- **Locally**: logs print to the console
- **Azure**: follow the steps below to enable and view logs

### Enable App Service Logs

This is done automatically by `infra/app-service/create.sh`. To do it manually:

1. In the Azure Portal, go to **App Service** > `HelloWorld-Yuan`
2. Go to **Monitoring > App Service logs**
3. Set **Application Logging (Filesystem)** to **On**
4. Set **Level** to **Information** (or **Verbose** for more detail)
5. Click **Save**

### View logs in Log Stream

1. Go to **Monitoring > Log Stream**
2. Browse the site to trigger requests
3. Logs appear in real time in the stream

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
    create.sh              # Interactive: create one or all resources
    teardown.sh            # Interactive: tear down one or all resources
    variables.sh           # Shared config (resource names, SKU, region)
    app-service/           # App Service provisioning scripts
    sql/                   # SQL Server + Database provisioning scripts
  .github/workflows/       # CI/CD pipeline
```
