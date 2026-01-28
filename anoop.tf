terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}
provider "azurerm" {
  subscription_id = "b14a3699-29f5-4013-af1a-5ee5bcc0c511"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "anoop-new-rg"
  location = "Korea Central"
}

resource "azurerm_virtual_network" "vnet" {
  depends_on          = [azurerm_resource_group.rg]
  name                = "anoop-network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "subnet" {
  depends_on           = [azurerm_virtual_network.vnet]
  name                 = "anoop-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  depends_on          = [azurerm_subnet.subnet]
  name                = "anoop-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "anoop-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_linux_virtual_machine" "anoop_vm" {
  depends_on          = [azurerm_network_interface.nic]
  name                = "anoop-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D2s_v3"

 admin_username = var.admin_username
admin_password = var.admin_password
  disable_password_authentication = false


  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    name                 = "anoop-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
