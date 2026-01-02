#!/usr/bin/env bash
set -euo pipefail

# VulnLab all-in-one (Ubuntu Server 22.04 LTS, bare metal)
# WARNING: Intentionally vulnerable services. Run ONLY on isolated lab LAN/VLAN.
#
# Exposed LAN endpoints (default):
#   3000  Juice Shop        http://<LAN_IP>:3000
#   8080  WebGoat           http://<LAN_IP>:8080/WebGoat
#   8888  crAPI             http://<LAN_IP>:8888
#   8025  crAPI MailHog UI  http://<LAN_IP>:8025
#   8081  bWAPP             http://<LAN_IP>:8081
#   8087  Mutillidae II     http://<LAN_IP>:8087
#   8082  WordPress         http://<LAN_IP>:8082
#   8083  Drupal            http://<LAN_IP>:8083
#   8085  NGINX static      http://<LAN_IP>:8085
#   8086  Apache static     http://<LAN_IP>:8086
#   4566  LocalStack        http://<LAN_IP>:4566
#
# Kubernetes Goat:
#   Installs kind+k8s cluster "vulnlab" and runs kubernetes-goat setup script.
#   Their default access is port-forward to 127.0.0.1:1234; LAN exposure requires --address 0.0.0.0.

LAB_ROOT="/opt/vulnlab"
MAIN_COMPOSE="${LAB_ROOT}/docker-compose.yml"
CRAPI_DIR="${LAB_ROOT}/crapi"
K8S_DIR="${LAB_ROOT}/kubernetes-goat"
CRAPI_ZIP="/tmp/crapi.zip"

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: run as root (sudo)."
    exit 1
  fi
}

lan_ip() {
  local ip
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7; exit}' || true)"
  if [[ -z "${ip}" ]]; then
    ip="$(hostname -I | awk '{print $1}' || true)"
  fi
  echo "${ip}"
}

install_prereqs() {
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https unzip git jq
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    # Ensure service enabled
    systemctl enable --now docker >/dev/null 2>&1 || true
    return 0
  fi

  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  local arch codename
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable
EOF

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

write_main_compose() {
  mkdir -p "${LAB_ROOT}"
  mkdir -p "${LAB_ROOT}/nginx-static" "${LAB_ROOT}/apache-static"
  echo "OK (nginx static)" > "${LAB_ROOT}/nginx-static/index.html"
  echo "OK (apache static)" > "${LAB_ROOT}/apache-static/index.html"

  cat >"${MAIN_COMPOSE}" <<'YAML'
services:
  juiceshop:
    image: bkimminich/juice-shop:latest
    container_name: juiceshop
    restart: unless-stopped
    ports:
      - "0.0.0.0:3000:3000"

  webgoat:
    image: webgoat/webgoat:latest
    container_name: webgoat
    restart: unless-stopped
    ports:
      - "0.0.0.0:8080:8080"

  bwapp:
    image: raesene/bwapp:latest
    container_name: bwapp
    restart: unless-stopped
    ports:
      - "0.0.0.0:8081:80"

  mutillidae:
    image: citizenstig/nowasp:latest
    container_name: mutillidae
    restart: unless-stopped
    ports:
      - "0.0.0.0:8087:80"

  wordpress:
    image: wordpress:php8.2-apache
    container_name: wordpress
    restart: unless-stopped
    ports:
      - "0.0.0.0:8082:80"
    environment:
      WORDPRESS_DB_HOST: wpdb
      WORDPRESS_DB_USER: wp
      WORDPRESS_DB_PASSWORD: wp
      WORDPRESS_DB_NAME: wp
    depends_on:
      - wpdb

  wpdb:
    image: mysql:8
    container_name: wpdb
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wp
      MYSQL_USER: wp
      MYSQL_PASSWORD: wp
      MYSQL_ROOT_PASSWORD: root
    command: ["--default-authentication-plugin=mysql_native_password"]

  drupal:
    image: drupal:9-apache
    container_name: drupal
    restart: unless-stopped
    ports:
      - "0.0.0.0:8083:80"
    depends_on:
      - drupaldb

  drupaldb:
    image: postgres:15
    container_name: drupaldb
    restart: unless-stopped
    environment:
      POSTGRES_DB: drupal
      POSTGRES_USER: drupal
      POSTGRES_PASSWORD: drupal

  nginx-static:
    image: nginx:alpine
    container_name: nginx-static
    restart: unless-stopped
    ports:
      - "0.0.0.0:8085:80"
    volumes:
      - ./nginx-static:/usr/share/nginx/html:ro

  apache-static:
    image: httpd:2.4
    container_name: apache-static
    restart: unless-stopped
    ports:
      - "0.0.0.0:8086:80"
    volumes:
      - ./apache-static:/usr/local/apache2/htdocs:ro

  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    restart: unless-stopped
    ports:
      - "0.0.0.0:4566:4566"
    environment:
      - SERVICES=s3,iam,lambda,apigateway,sts
      - DEBUG=0
YAML
}

deploy_main_stack() {
  docker compose -f "${MAIN_COMPOSE}" pull
  docker compose -f "${MAIN_COMPOSE}" up -d
}

deploy_crapi_official() {
  mkdir -p "${CRAPI_DIR}"
  rm -rf "${CRAPI_DIR:?}/"* || true

  # OWASP crAPI docs show deploying from zip and running compose with LISTEN_IP for LAN exposure.  [oai_citation:4â¡OWASP](https://owasp.org/crAPI/docs/setup.html?utm_source=chatgpt.com)
  curl -fsSL -o "${CRAPI_ZIP}" https://github.com/OWASP/crAPI/archive/refs/heads/develop.zip
  unzip -q -o "${CRAPI_ZIP}" -d "${CRAPI_DIR}"

  local deploy_dir="${CRAPI_DIR}/crAPI-develop/deploy/docker"
  if [[ ! -d "${deploy_dir}" ]]; then
    echo "ERROR: Expected crAPI deploy dir not found: ${deploy_dir}"
    exit 1
  fi

  ( cd "${deploy_dir}" && docker compose pull )
  ( cd "${deploy_dir}" && LISTEN_IP="0.0.0.0" docker compose -f docker-compose.yml --compatibility up -d )
}

open_firewall_ports() {
  if command -v ufw >/dev/null 2>&1; then
    ufw allow 3000/tcp || true
    ufw allow 8080/tcp || true
    ufw allow 8888/tcp || true
    ufw allow 8025/tcp || true
    ufw allow 8081/tcp || true
    ufw allow 8087/tcp || true
    ufw allow 8082/tcp || true
    ufw allow 8083/tcp || true
    ufw allow 8085/tcp || true
    ufw allow 8086/tcp || true
    ufw allow 4566/tcp || true
  fi
}

install_k8s_tooling() {
  # kubectl
  if ! command -v kubectl >/dev/null 2>&1; then
    curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
    chmod +x /usr/local/bin/kubectl
  fi

  # kind
  if ! command -v kind >/dev/null 2>&1; then
    curl -fsSL -o /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    chmod +x /usr/local/bin/kind
  fi

  # helm
  if ! command -v helm >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
}

deploy_kubernetes_goat() {
  mkdir -p "${LAB_ROOT}"
  if [[ ! -d "${K8S_DIR}/.git" ]]; then
    rm -rf "${K8S_DIR}" || true
    git clone https://github.com/madhuakula/kubernetes-goat.git "${K8S_DIR}"
  fi

  # Create kind cluster (idempotent-ish)
  if ! kind get clusters | grep -qx "vulnlab"; then
    kind create cluster --name vulnlab
  fi

  # Run the official setup script from the repo.  [oai_citation:5â¡GitHub](https://github.com/madhuakula/kubernetes-goat)
  ( cd "${K8S_DIR}" && chmod +x setup-kubernetes-goat.sh && bash setup-kubernetes-goat.sh )
}

print_status() {
  local ip
  ip="$(lan_ip)"

  echo
  echo "=== MAIN STACK STATUS ==="
  docker compose -f "${MAIN_COMPOSE}" ps

  echo
  echo "=== READY (LAN) ==="
  echo "Juice Shop        : http://${ip}:3000"
  echo "WebGoat           : http://${ip}:8080/WebGoat"
  echo "bWAPP             : http://${ip}:8081"
  echo "Mutillidae II     : http://${ip}:8087"
  echo "WordPress         : http://${ip}:8082"
  echo "Drupal            : http://${ip}:8083"
  echo "NGINX static      : http://${ip}:8085"
  echo "Apache static     : http://${ip}:8086"
  echo "LocalStack        : http://${ip}:4566"
  echo "crAPI             : http://${ip}:8888"
  echo "crAPI MailHog UI  : http://${ip}:8025"
  echo
  echo "=== MANAGEMENT ==="
  echo "Main stack logs   : docker compose -f ${MAIN_COMPOSE} logs -f --tail=200"
  echo "Main stack down   : docker compose -f ${MAIN_COMPOSE} down"
  echo "crAPI dir         : ${CRAPI_DIR}/crAPI-develop/deploy/docker"
  echo "crAPI logs        : (cd ${CRAPI_DIR}/crAPI-develop/deploy/docker && docker compose logs -f --tail=200)"
  echo "crAPI down        : (cd ${CRAPI_DIR}/crAPI-develop/deploy/docker && docker compose down)"
  echo
  echo "=== KUBERNETES GOAT ==="
  echo "Pods              : kubectl get pods -A"
  echo "Access (default)  : (cd ${K8S_DIR} && bash access-kubernetes-goat.sh) then browse http://127.0.0.1:1234"
  echo "LAN port-forward  : kubectl port-forward --address 0.0.0.0 -n kubernetes-goat svc/kubernetes-goat 1234:1234"
}

main() {
  require_root
  install_prereqs
  install_docker

  write_main_compose
  deploy_main_stack

  deploy_crapi_official

  open_firewall_ports

  # Kubernetes (optional but requested)
  install_k8s_tooling
  deploy_kubernetes_goat

  print_status
}

main "$@"
