variable "name" {
  type        = string
  default     = "tfsrchstarter"
  description = "A unique name for the service."
}

variable "location" {
  type        = string
  default     = "westus"
  description = "The proper Azure location name for deployed resources."
}

variable "build_id" {
  type        = string
  default     = ""
  description = "The AzDO build ID string, formatted as a non-negative integer string."
}

variable "environment" {
  type        = string
  description = "The AzDO environment name corresponding to this deployment."
}

variable "functions_package_path" {
  type        = string
  description = "The path to the Azure Functions package zip."
}

variable "search_container_name" {
  type        = string
  default     = "search"
  description = "The name of the data source container for Cognitive Search Service."
}
