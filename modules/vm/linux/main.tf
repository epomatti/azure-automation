locals {
  vm_affix = "linux"
}

resource "azurerm_public_ip" "default" {
  name                = "pip-${var.workload}-${local.vm_affix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "default" {
  name                = "nic-${var.workload}-${local.vm_affix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.default.id
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  username = "sysadmin"
}

resource "azurerm_linux_virtual_machine" "default" {
  name                  = "vm-${var.workload}-${local.vm_affix}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.size
  admin_username        = local.username
  admin_password        = "P@ssw0rd.123"
  network_interface_ids = [azurerm_network_interface.default.id]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = local.username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "osdisk-${var.workload}-${local.vm_affix}"
    caching              = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_virtual_machine_extension" "azure_monitor_linux_agent" {
  name                       = "monitor-agent"
  virtual_machine_id         = azurerm_linux_virtual_machine.default.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}