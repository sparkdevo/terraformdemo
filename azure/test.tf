provider "azurerm" {
}
resource "azurerm_resource_group" "rg" {
        name = "NickResourceGroup"
        location = "eastasia"
}
