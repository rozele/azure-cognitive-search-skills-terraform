---
page_type: sample
languages:
- csharp
- terraform
products:
- azure-cognitive-search
- azure-functions
description: A quickstart project for deploying Azure Cognitive Search, custom Web API skills, and enrichment pipelines in Terraform.
url-fragment: azure-cognitive-search-skills-terraform
---

# Deploy Azure Cognitive Search Enrichment Pipelines via Terraform

A starter project for deploying Azure Cognitive Search and [enrichment pipelines](https://docs.microsoft.com/en-us/azure/search/cognitive-search-concept-intro) in Terraform. This project compiles a few learnings to simplify the deployment of Cognitive Search, enrichment pipelines, and custom Web API skills in a single Terraform execution plan.

## Features

This project provides the following features:
* Azure Cognitive Search and Function App resource deployment
* Function App deployment [via blob](https://docs.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package)
* Cognitive Search enrichment pipeline
  * Data source connection [via system-assigned managed identity](https://docs.microsoft.com/en-us/azure/search/search-howto-managed-identities-storage)
  * [Native soft-deletion detection policy](https://docs.microsoft.com/en-us/azure/search/search-howto-indexing-azure-blob-storage#native-blob-soft-delete-preview)
  * Example [custom Web API skill](https://docs.microsoft.com/en-us/azure/search/cognitive-search-custom-skill-web-api) deployed to Azure Functions
* Single Terraform execution plan for all of the above

## Getting Started

Terraform deploys the end-to-end solution, including all Azure resources, Cognitive Search enrichment pipelines, and Azure Functions for custom Web API skills.

### Dependencies
* [Terraform](https://www.terraform.io/downloads.html)
* [.NET Core](https://dotnet.microsoft.com/download)*

\* This project uses .NET Core to compile the Azure Function, but the solution can also be used for any other language supported by Azure Functions (Node.js, Python, etc.).

### Required Azure Subscription Roles

Whether you are deploying locally or using a service principal, you will need the following roles on the Azure Subscription:
* **Contributor** - for creating Azure resources
* **User Access Administrator** - for configuring roles on the Cognitive Search managed identity
* **Storage Blob Data Contributor** - for deleting blobs from Storage

### Building the Azure Functions

The Azure Functions deploy via an Azure Blob Storage using the [`WEBSITE_RUN_FROM_PACKAGE` configuration setting](https://docs.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package#enabling-functions-to-run-from-a-package).

Before deploying with Terraform, build a zip archive containing the Azure Functions package:
```bash
dotnet publish src/CognitiveSkills.Functions -o dist/
pushd dist; zip -r -X ../dist.zip *; popd
```

### Deploying with Terraform

Terraform will create all Azure resources, send PUT requests to Cognitive Search to create the enrichment pipeline, and deploy the custom Web API skill Azure Functions via a block blob in Azure Storage. Run terraform with the following:
```bash
terraform init deploy/terraform
terraform apply deploy/terraform
```

Terraform will ask you for 2 variables:
- **environment**: The name of the environment you are deploying. For testing purposes, use something unique like your alias.
- **functions_package_path**: The path to the Azure Functions package zip. If you used the step above, it's likely `dist.zip`.
