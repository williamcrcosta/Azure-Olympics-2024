resource "azurerm_policy_definition" "allowed_size_sku_custom" {
  name         = "Allowed-size-SKU-Custom"
  display_name = "Allowed size SKU custom"
  description  = "This policy enables you to restrict the size SKU that can be specified when creating a resource."

  policy_type = "Custom"
  mode        = "Indexed"

  metadata = <<METADATA
    {
      "version": "1.0.1",
      "category": "Compute"
    }
  METADATA

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
        },
        {
          "not": {
            "field": "Microsoft.Compute/virtualMachines/sku.name",
            "in": "[parameters('listOfAllowedSKUs')]"
          }
        }
      ]
    },
    "then": {
      "effect": "Deny"
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
  {
    "listOfAllowedSKUs": {
      "type": "array",
      "metadata": {
        "displayName": "List of allowed SKUs",
        "description": "List of allowed SKUs"
      }
    }
  }
PARAMETERS
}

#######################################################################

# Subscription policy assignment with managed identity
# Identidade gerenciada pelo sistema na política

# Assign the policy with a managed identity
resource "azurerm_subscription_policy_assignment" "Allowed_size_sku_custom_assignment" {
  name                 = "Allowed-size-SKU-Custom-Assignment"
  policy_definition_id = azurerm_policy_definition.allowed_size_sku_custom.id
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location-uksouth
  enforce              = true
  display_name         = "Allowed size SKU custom"
  description          = "This policy enables you to restrict the size SKU that can be specified when creating a resource."
  non_compliance_message {
    content = "This resource is not in the allowed size SKU. For this subscription it is only allowed to create VMs with SKU Standard_B2s and Standard_B2s_v2."
  }

  not_scopes = [
    //data.azurerm_resource_group.excluded_rg.id,
    data.azurerm_resource_group.network_watcher_rg.id,
  ]

  parameters = <<PARAMETERS
  {
    "listOfAllowedSKUs": {
      "value": [
        "Standard_B2s",
        "Standard_B2s_v2",
        "Standard_B2ms"
        ]
    }
  }
PARAMETERS
}