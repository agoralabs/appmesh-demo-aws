resource "null_resource" "kurl_command" {
  
  triggers = {
    always_run = "${timestamp()}"
    input_config_file = "${var.input_config_file}"
  }

  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/kurl.sh && input_command=CREATE input_config_file=${var.input_config_file} ${path.module}/files/kurl.sh"
  }

  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/kurl.sh && input_command=DELETE input_config_file=${self.triggers.input_config_file} ${path.module}/files/kurl.sh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

