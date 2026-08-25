locals {
  common_tags = {
    environment = "development"
    managed_by  = "terraform"
    project     = "artizent"
  }
}

resource "azurerm_resource_group" "artizent" {
  name     = "artizent"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "artizent" {
  name                = "artizent-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.artizent.location
  resource_group_name = azurerm_resource_group.artizent.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "artizent" {
  name                 = "artizent-subnet"
  resource_group_name  = azurerm_resource_group.artizent.name
  virtual_network_name = azurerm_virtual_network.artizent.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "artizent" {
  name                = "artizent-public-ip"
  location            = azurerm_resource_group.artizent.location
  resource_group_name = azurerm_resource_group.artizent.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "artizent" {
  name                = "artizent-nsg"
  location            = azurerm_resource_group.artizent.location
  resource_group_name = azurerm_resource_group.artizent.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "artizent" {
  name                = "artizent-nic"
  location            = azurerm_resource_group.artizent.location
  resource_group_name = azurerm_resource_group.artizent.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.artizent.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.artizent.id
  }
}

resource "azurerm_network_interface_security_group_association" "artizent" {
  network_interface_id      = azurerm_network_interface.artizent.id
  network_security_group_id = azurerm_network_security_group.artizent.id
}

resource "tls_private_key" "artizent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.artizent.private_key_openssh
  filename        = "${path.module}/artizent-vm.pem"
  file_permission = "0600"
}

resource "azurerm_linux_virtual_machine" "artizent" {
  name                = "artizent-vm"
  resource_group_name = azurerm_resource_group.artizent.name
  location            = azurerm_resource_group.artizent.location
  size                = "Standard_B2ts_v2"
  admin_username      = var.admin_username
  tags                = local.common_tags

  network_interface_ids = [
    azurerm_network_interface.artizent.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.artizent.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}