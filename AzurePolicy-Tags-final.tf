
# Variáveis para tags
# Define the name of the tag to be added
variable "tagName" {
  description = "The name of the tag to be added"
  default     = "Organization"
}

# Define the value of the tag to be added
variable "tagValue" {
  description = "The value of the tag to be added"
  default     = "ClouStoreTFTEC" # Replace with the name of your company
  //default     = "ClouStoreTFTEC" ### Substitua pelo nome da sua empresa
}

# Definition of the Policy
# Adds the specified tag and value when any resource missing this tag is created or updated.
# Existing resources can be remediated by triggering a remediation task.
# If the tag exists with a different value it will not be changed.
# Does not modify tags on resource groups.
# Definição da Política
resource "azurerm_policy_definition" "add_tag_to_resources" {
  name         = "add-tag-to-resources-custom"
  display_name = "Add a tag to resources-custom"
  description  = "Adds the specified tag and value when any resource missing this tag is created or updated. Existing resources can be remediated by triggering a remediation task. If the tag exists with a different value it will not be changed. Does not modify tags on resource groups."

  policy_type = "Custom"
  mode        = "Indexed"

  metadata = <<METADATA
    {
      "version": "1.0.0",
      "category": "Tags"
    }
  METADATA

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "field": "[concat('tags[', parameters('tagName'), ']')]",
      "exists": "false"
    },
    "then": {
      "effect": "modify",
      "details": {
        "roleDefinitionIds": [
          "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "operations": [
          {
            "operation": "add",
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "value": "[parameters('tagValue')]"
          }
        ]
      }
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
  {
    "tagName": {
      "type": "string",
      "metadata": {
        "displayName": "Tag Name",
        "description": "Name of the tag to be added"
      }
    },
    "tagValue": {
      "type": "string",
      "metadata": {
        "displayName": "Tag Value",
        "description": "Value of the tag to be added"
      }
    }
  }
PARAMETERS
}

# Get the current subscription data
# Dados da assinatura atual
data "azurerm_subscription" "current" {}

# Excluded resource groups
# Grupos de Recursos a serem excluídos
data "azurerm_resource_group" "excluded_rg" {
  name = "rg-local"
}

data "azurerm_resource_group" "network_watcher_rg" {
  name = "NetworkWatcherRG"
}


#######################################################################

# Subscription policy assignment with managed identity
# Identidade gerenciada pelo sistema na política

# Assign the policy with a managed identity
resource "azurerm_subscription_policy_assignment" "assign_add_tag_policy" {
  name                 = "assign-add-tag-policy"
  policy_definition_id = azurerm_policy_definition.add_tag_to_resources.id
  subscription_id      = data.azurerm_subscription.current.id
  location = var.location-uksouth
  enforce = true
  display_name = "assign-add-tag-policy"

  identity {
    type = "SystemAssigned"
  }

  not_scopes = [
    data.azurerm_resource_group.excluded_rg.id,
    data.azurerm_resource_group.network_watcher_rg.id,
  ]

  parameters = <<PARAMETERS
  {
    "tagName": {
      "value": "${var.tagName}"
    },
    "tagValue": {
      "value": "${var.tagValue}"
    }
  }
PARAMETERS
}


# Define the role to be assigned to the managed identity
# Definindo a Role que será atribuída à identidade gerenciada
data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

# Assign the role to the managed identity
# Atribuindo a Role à identidade gerenciada
resource "azurerm_role_assignment" "assign_role_to_policy_identity" {
  principal_id   = azurerm_subscription_policy_assignment.assign_add_tag_policy.identity.0.principal_id
  role_definition_name = data.azurerm_role_definition.contributor.name
  scope          = data.azurerm_subscription.current.id
}
