resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations-custom"
  display_name = "Allowed locations custom"
  description  = "This policy enables you to restrict the locations that can be specified when creating a resource."

  policy_type = "Custom"
  mode        = "Indexed"

  metadata = <<METADATA
    {
      "version": "1.0.0",
      "category": "General"
    }
  METADATA

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "allOf": [
        {
          "field": "location",
          "notIn": "[parameters('allowedLocations')]"
        },
        {
          "field": "location",
          "notEquals": "global"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
  {
    "allowedLocations": {
      "type": "array",
      "metadata": {
        "displayName": "Allowed locations",
        "description": "The list of allowed locations for resources."
      },
      "defaultValue": [
        "uksouth",
        "ukwest"
      ],
      "minValueLength": 1,
      "maxValueLength": 2,
      "minLength": 1,
      "maxLength": 2
    }
  }
PARAMETERS
}


#######################################################################

# Subscription policy assignment with managed identity
# Identidade gerenciada pelo sistema na política

# Assign the policy with a managed identity
resource "azurerm_subscription_policy_assignment" "allowed-locations-custom-assignment" {
  name                 = "Allowed Locations-Custom-Assignment"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location-uksouth
  enforce              = true
  display_name         = "Allowed locations custom"
  description          = "This policy enables you to restrict the locations that can be specified when creating a resource."
  non_compliance_message {
    content = "This resource is not in the allowed locations. For this subscription it is only allowed to create resources in the UK South and UK West regions."
  }

  not_scopes = [
    //data.azurerm_resource_group.excluded_rg.id,
    data.azurerm_resource_group.network_watcher_rg.id,
    data.azurerm_resource_group.rg-azure-mgt.id
  ]

  parameters = <<PARAMETERS
  {
    "allowedLocations": {
      "value": [
        "uksouth",
        "ukwest"
      ]
    }
  }
PARAMETERS
}

data "azurerm_resource_group" "rg-azure-mgt" {
  name = "rg-azure-mgt"
}