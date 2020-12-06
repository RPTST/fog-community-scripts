resource "aws_instance" "ubuntu16_04" {
  ami                         = data.aws_ami.ubuntu16.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  root_block_device {
    volume_type           = "standard"
    volume_size           = 8
    delete_on_termination = true
  }
  connection {
    type                = "ssh"
    user                = "ubuntu"
    host                = aws_instance.ubuntu16_04.private_ip
    private_key         = file("~/.ssh/fogtesting_private")
    bastion_host        = aws_instance.bastion.public_ip
    bastion_user        = "admin"
    bastion_private_key = file("~/.ssh/fogtesting_private")
  }
  provisioner "remote-exec" {
    #on_failure = continue
    inline = [
      "sudo apt-get -y remove unattended-upgrades",
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config",
      "sudo echo '' >> /etc/ssh/sshd_config",
      "sudo echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",
      "sudo mkdir -p /root/.ssh",
      "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys",
      "sudo apt-get -y install git",
      "sudo mkdir -p /root/git",
      "sudo git clone ${var.fog-project-repo} /root/git/fogproject",
      "(sleep 10 && sudo reboot)&",
    ]
  }
  tags = {
    Name    = "${var.project}-ubuntu16_04"
    Project = var.project
    OS      = "ubuntu16_04"
  }
}

resource "aws_route53_record" "ubuntu16_04-dns-record" {
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "ubuntu16_04.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.ubuntu16_04.private_dns]
}

