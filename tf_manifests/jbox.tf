resource "azurerm_resource_group" "jbox-rg" {
  name     = "${var.env}-jbox-rg"
  location = var.location-name
}

module "jbox-vm" {
  source         = "../modules/compute"
  vm-name        = "${var.env}-jbox"
  subnet_id      = module.fe-vnet.vnet_subnets[1]
  rg             = azurerm_resource_group.jbox-rg.name
  location       = azurerm_resource_group.jbox-rg.location
  admin_password = var.admin_password
}

/* 
resource "azurerm_network_interface" "jbox-rg" {
  name                = "jbox-nic"
  location            = azurerm_resource_group.jbox-rg.location
  resource_group_name = azurerm_resource_group.jbox-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.fe-rg-02.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "jbox-rg" {
  name                = "jbox-nsg"
  location            = azurerm_resource_group.jbox-rg.location
  resource_group_name = azurerm_resource_group.jbox-rg.name
}
*/

resource "azurerm_network_security_rule" "jbox-rg" {
  name                        = "rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "${module.jbox-vm.vm_private_ip}/32"
  resource_group_name         = azurerm_resource_group.jbox-rg.name
  network_security_group_name = module.jbox-vm.nsg_name
}

resource "azurerm_network_interface_security_group_association" "jbox-rg" {
  network_interface_id      = module.jbox-vm.nic_id
  network_security_group_id = module.jbox-vm.nsg_id
}

###
/*
resource "azurerm_virtual_machine" "jbox-rg" {
  name                  = "jbox-vm01"
  location              = azurerm_resource_group.jbox-rg.location
  resource_group_name   = azurerm_resource_group.jbox-rg.name
  network_interface_ids = [azurerm_network_interface.jbox-rg.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jbox-osdisk"
    managed_disk_type = "StandardSSD_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "jbox-vm01"
    admin_username = "testadmin"
    admin_password = "Password@123"
  }
  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }
}
*/