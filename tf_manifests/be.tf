resource "azurerm_resource_group" "be-rg" {
  name     = "${var.env}-be-rg"
  location = var.location-name
}

module "be-vnet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = "${var.env}-web-vnet"
  resource_group_name = azurerm_resource_group.be-rg.name
  address_space       = ["10.0.2.0/23"]
  subnet_prefixes     = ["10.0.2.0/24"]
  subnet_names        = ["${var.env}-web-subnet"]
  tags                = null

  # subnet_service_endpoints = {
  #   subnet2 = ["Microsoft.Storage", "Microsoft.Sql"],
  #   subnet3 = ["Microsoft.AzureActiveDirectory"]
  # }

  # tags = {
  #   environment = "dev"
  #   costcenter  = "it"
  # }

  depends_on = [azurerm_resource_group.be-rg]
}

/*
resource "azurerm_virtual_network" "be-rg" {
  name                = var.web-vnet-name
  location            = azurerm_resource_group.be-rg.location
  resource_group_name = azurerm_resource_group.be-rg.name
  address_space       = ["10.0.2.0/23"]
}

resource "azurerm_subnet" "be-rg" {
  name                 = var.web-sub-name
  resource_group_name  = azurerm_resource_group.be-rg.name
  virtual_network_name = azurerm_virtual_network.be-rg.name
  address_prefixes     = ["10.0.2.0/24"]
}
*/

module "web-vm" {
  source         = "../modules/compute"
  vm-name        = "${var.env}-web"
  subnet_id      = module.be-vnet.vnet_subnets[0]
  rg             = azurerm_resource_group.be-rg.name
  location       = azurerm_resource_group.be-rg.location
  admin_password = var.admin_password
}

/*
resource "azurerm_network_interface" "be-rg" {
  name                = "${var.web-sub-name}-nic"
  location            = azurerm_resource_group.be-rg.location
  resource_group_name = azurerm_resource_group.be-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.be-rg.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "be-rg" {
  name                = "${var.web-vm-name}-nsg"
  location            = azurerm_resource_group.be-rg.location
  resource_group_name = azurerm_resource_group.be-rg.name
}
*/

resource "azurerm_network_security_rule" "be-rg" {
  name                        = "web"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "${module.web-vm.vm_private_ip}/32"
  resource_group_name         = azurerm_resource_group.be-rg.name
  network_security_group_name = module.web-vm.nsg_name
}

resource "azurerm_network_interface_security_group_association" "be-rg" {
  network_interface_id      = module.web-vm.nic_id
  network_security_group_id = module.web-vm.nsg_id
}

###
/*
resource "azurerm_virtual_machine" "be-rg" {
  name                  = "${var.web-vm-name}-vm01"
  location              = azurerm_resource_group.be-rg.location
  resource_group_name   = azurerm_resource_group.be-rg.name
  network_interface_ids = [azurerm_network_interface.be-rg.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web-vm-name}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.web-vm-name}-vm01"
    admin_username = "testadmin"
    admin_password = "Password@123"
  }
  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }
}
*/

resource "azurerm_virtual_machine_extension" "be-rg" {
  name                 = "iis-extension"
  virtual_machine_id   = module.web-vm.vm_id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
    {
        "commandToExecute": "powershell Install-WindowsFeature -name Web-Server -IncludeManagementTools;"
    }
SETTINGS
}


