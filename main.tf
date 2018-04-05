resource "azurerm_resource_group" "terraform-test" {
name     = "acctestrg"

location = "west US 2"
}

resource "azurerm_virtual_network" "testvn" {
name                = "acctvn"

address_space       = ["10.0.0.0/16"]
location            = "west US 2"

resource_group_name = "${azurerm_resource_group.terraform-test.name}"
}




resource "azurerm_subnet" "testsb" {


name                 = "acctsub"

resource_group_name  = "${azurerm_resource_group.terraform-test.name}"
virtual_network_name = "${azurerm_virtual_network.testvn.name}"

address_prefix       = "10.0.2.0/24"


}
variable "node_count" {default = 4}
# Create public IPs
resource "azurerm_public_ip" "testpip" {

count = "${var.node_count}"
    name = "testpip-${format("%02d", count.index+1)}"
    location                     = "West US 2"
    resource_group_name          = "${azurerm_resource_group.terraform-test.name}"
    public_ip_address_allocation = "dynamic"


}




resource "azurerm_network_interface" "terraform-CnetFace" {

count = "${var.node_count}"
  name = "cacctni-${format("%02d", count.index+1)}"
  location = "west US 2"
  resource_group_name = "${azurerm_resource_group.terraform-test.name}"

  ip_configuration {
      name = "cIpconfig-${format("%02d", count.index+1)}"
      subnet_id = "${azurerm_subnet.testsb.id}"
      private_ip_address_allocation = "dynamic"
      public_ip_address_id          = "${element(azurerm_public_ip.testpip.*.id, count.index)}"

  /*    public_ip_address_id          = "${azurerm_public_ip.testpip-${format("%02d", count.index+1)}.id}"*/

  }

}



variable "confignode_count" {default = 4}

resource "azurerm_virtual_machine" "terraform-test" {

count = "${var.node_count}"
  name   = "confignode-${format("%02d", count.index+1)}"
  location = "west US 2"
  resource_group_name = "${azurerm_resource_group.terraform-test.name}"
 network_interface_ids = ["${element(azurerm_network_interface.terraform-CnetFace.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"



storage_image_reference {

publisher = "MicrosoftWindowsServer"

offer     = "WindowsServer"

sku       = "2012-R2-Datacenter"

version   = "latest"

  }

  storage_os_disk {

name = "configosdisk-${format("%02d", count.index+1)}"
caching           = "ReadWrite"

create_option     = "FromImage"

managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
  name          = "configdatadisk-${format("%02d", count.index+1)}"
    managed_disk_type = "Standard_LRS"

create_option     = "Empty"

lun               = 0

disk_size_gb      = "100"
  }

  os_profile {
      computer_name = "confignode-${format("%02d", count.index+1)}"
      admin_username = "testadmin"
      admin_password = "Password@1234"
  }

  os_profile_windows_config {

  }

  tags {
      environment = "Production"
  }

  #Loop for Count
  count = "${var.confignode_count}"
}
