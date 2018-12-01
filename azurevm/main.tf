provider "azurerm" {
}
resource "azurerm_resource_group" "nicktfrg" {
    name = "NickResourceGroup"
    location = "eastasia"
    tags {
        environment = "My Terraform Demo"
    }
}
resource "azurerm_virtual_network" "nicktfnetwork" {
    name                = "NickVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastasia"
    resource_group_name = "${azurerm_resource_group.nicktfrg.name}"

    tags {
        environment = "My Terraform Demo"
    }
}
resource "azurerm_subnet" "nicktfsubnet" {
    name                 = "NickSubnet"
    resource_group_name  = "${azurerm_resource_group.nicktfrg.name}"
    virtual_network_name = "${azurerm_virtual_network.nicktfnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}
resource "azurerm_public_ip" "nicktfpublicip" {
    name                         = "NickPublicIP"
    location                     = "eastasia"
    resource_group_name          = "${azurerm_resource_group.nicktfrg.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "My Terraform Demo"
    }
}
resource "azurerm_network_security_group" "nicktfnsg" {
    name                = "NickNetworkSecurityGroup"
    location            = "eastasia"
    resource_group_name = "${azurerm_resource_group.nicktfrg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "My Terraform Demo"
    }
}
resource "azurerm_network_interface" "nicktfnic" {
    name                = "NickNIC"
    location            = "eastasia"
    resource_group_name = "${azurerm_resource_group.nicktfrg.name}"
    network_security_group_id = "${azurerm_network_security_group.nicktfnsg.id}"

    ip_configuration {
        name                          = "NickNicConfiguration"
        subnet_id                     = "${azurerm_subnet.nicktfsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.nicktfpublicip.id}"
    }

    tags {
        environment = "My Terraform Demo"
    }
}
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.nicktfrg.name}"
    }

    byte_length = 8
}
resource "azurerm_storage_account" "nicktfstorageaccount" {
    name                = "nicksa${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.nicktfrg.name}"
    location            = "eastasia"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "My Terraform Demo"
    }
}
resource "azurerm_virtual_machine" "nicktfvm" {
    name                  = "NickVM"
    location              = "eastasia"
    resource_group_name   = "${azurerm_resource_group.nicktfrg.name}"
    network_interface_ids = ["${azurerm_network_interface.nicktfnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "NickOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "phoenix"
        admin_username = "nick"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/nick/.ssh/authorized_keys"
            key_data = "xxxxxxxxxx"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.nicktfstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "My Terraform Demo"
    }
}
