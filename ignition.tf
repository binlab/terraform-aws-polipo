data "ignition_user" "core" {
  name = "core"
  uid  = 500
  ssh_authorized_keys = [
    var.root_ssh_public_key
  ]
}

data "ignition_user" "admin" {
  name = "admin"
  uid  = 1000
}

data "ignition_file" "sshd_config" {
  filesystem = "root"
  path       = "/etc/ssh/sshd_config"
  mode       = 384 ### 0600
  uid        = 0
  gid        = 0
  content {
    mime    = "text/plain"
    content = <<-EOT
      UsePrivilegeSeparation sandbox
      ClientAliveInterval 180
      UseDNS no
      UsePAM yes
      PermitRootLogin no
      AllowUsers core admin
      AuthenticationMethods publickey
      TrustedUserCAKeys /etc/ssh/ssh_ca_rsa_key.pub
      AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u
    EOT
  }
}

data "ignition_file" "auth_principals_core" {
  filesystem = "root"
  path       = "/etc/ssh/auth_principals/core"
  mode       = 420 ### 0644
  uid        = 0
  gid        = 0
  content {
    mime    = "text/plain"
    content = <<-EOT
      sudo
    EOT
  }
}

data "ignition_file" "auth_principals_admin" {
  filesystem = "root"
  path       = "/etc/ssh/auth_principals/admin"
  mode       = 420 ### 0644
  uid        = 0
  gid        = 0
  content {
    mime    = "text/plain"
    content = <<-EOT
      proxy
      polipo
    EOT
  }
}

data "ignition_file" "ca_ssh_public_key" {
  filesystem = "root"
  path       = "/etc/ssh/ssh_ca_rsa_key.pub"
  mode       = 420 ### 0644
  uid        = 0
  gid        = 0
  content {
    mime    = "text/plain"
    content = var.ca_ssh_public_key
  }
}

data "ignition_file" "ca_tls_public_key" {
  count = var.ca_tls_public_key == "false" ? 0 : 1

  filesystem = "root"
  path       = "/etc/ssl/certs/ca_cert_int_chain.cert" # path       = "/etc/ssl/certs/ca-root.pem"
  mode       = 420                                     ### 0644
  uid        = 0
  gid        = 0
  content {
    mime    = "text/plain"
    content = var.ca_tls_public_key
  }
}

data "ignition_systemd_unit" "service" {
  name    = "polipo.service"
  content = <<-EOT
    [Unit]
    Description="Polipo Proxy Service"
    [Service]
    ExecStartPre=-/usr/bin/rkt rm --uuid-file="/var/cache/polipo-service.uuid"
    ExecStart=/usr/bin/rkt run \
      --insecure-options=image \
      --volume polipo-cache,kind=empty,readOnly=false \
      --mount volume=polipo-cache,target=/var/cache/polipo \
      --volume polipo-www,kind=empty,readOnly=true \
      --mount volume=polipo-www,target=/usr/share/polipo/www \
      docker://${var.docker_image} \
      --name=polipo \
      --net=host \
      --dns=host \
      --exec=/usr/local/bin/polipo -- \
        proxyName="HTTP/HTTPS-Proxy" \
        displayName="HTTP/HTTPS-Proxy" \
        diskCacheRoot="" \
        localDocumentRoot="" \
        proxyAddress="0.0.0.0" \
        proxyPort="${var.proxy_port}" \
        tunnelAllowedPorts=22,80,109-110,143,443,873,993,995,2401,5222-5223,6443,9418 \
        allowedClients=${join(",", var.allowed_cidr)} \
        authCredentials="${var.proxy_user}:${var.proxy_pass}"
    ExecStop=-/usr/bin/rkt stop --uuid-file="/var/cache/polipo-service.uuid"
    Restart=always
    RestartSec=5
    [Install]
    WantedBy=multi-user.target
  EOT
}

data "ignition_config" "polipo" {
  users = [
    data.ignition_user.core.rendered,
    data.ignition_user.admin.rendered,
  ]
  files = [
    data.ignition_file.sshd_config.rendered,
    data.ignition_file.auth_principals_core.rendered,
    data.ignition_file.auth_principals_admin.rendered,
    data.ignition_file.ca_ssh_public_key.rendered,
    data.ignition_file.ca_tls_public_key.rendered,
  ]
  systemd = [
    data.ignition_systemd_unit.service.rendered,
  ]
}
