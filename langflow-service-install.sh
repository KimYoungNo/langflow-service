#!/bin/bash

# AUTO-GENERATED FILE — DO NOT EDIT
#
# This script is produced by the build/generation process.  
# Any manual modifications will be overwritten when the file is
# regenerated and will NOT be reflected in the original source.
#
# To change this script, edit the corresponding source
# and regenerate it instead.

# Author: KimYoungNo
# License: MIT

# Header ───────────────────────────────────────────────────────────────
clear
cat <<"EOF"

    __                  ______                                         _         
   / /___ _____  ____ _/ __/ /___ _      __      ________  ______   __(_)_______ 
  / / __ `/ __ \/ __ `/ /_/ / __ \ | /| / /_____/ ___/ _ \/ ___/ | / / / ___/ _ \
 / / /_/ / / / / /_/ / __/ / /_/ / |/ |/ /_____(__  )  __/ /   | |/ / / /__/  __/
/_/\__,_/_/ /_/\__, /_/ /_/\____/|__/|__/     /____/\___/_/    |___/_/\___/\___/ 
              /____/                                                             


EOF
# stdout Helpers ───────────────────────────────────────────────────────────────
RESET=$(  printf '\033[0m')
BOLD=$(   printf '\033[1m')
BLACK=$(  printf '\033[30m')
RED=$(    printf '\033[31m')
GREEN=$(  printf '\033[32m')
YELLOW=$( printf '\033[33m')
BLUE=$(   printf '\033[34m')
MAGENTA=$(printf '\033[35m')
CYAN=$(   printf '\033[36m')
WHITE=$(  printf '\033[37m')

INFO_HEADER="${BOLD}${CYAN}[i]"
WARN_HEADER="${BOLD}${YELLOW}⚠"
DONE_HEADER="${BOLD}${GREEN}✔"
ERROR_HEADER="${BOLD}${RED}✖"

function msg_info() { echo -e "${INFO_HEADER} $@ ${RESET}"; }
function msg_warn() { echo -e "${WARN_HEADER} $@ ${RESET}"; }
function msg_done() { echo -e "${DONE_HEADER} $@ ${RESET}"; }
function msg_error(){ echo -e "${ERROR_HEADER} $@ ${RESET}"; }

# Fallback Routine ───────────────────────────────────────────────────────────────
errlog=$(mktemp)
trap 'rm -f "$errlog"' EXIT

#exec 3>&2
#exec 2> >(tee -a "$errlog" >&1)

function fallback() {
  local rc=$1
  local cmd=${BASH_COMMAND}
  local file=${BASH_SOURCE[1]}
  local lineno=${BASH_LINENO[0]}
  {
    msg_error "${file}: ${lineno}: \"${cmd}\" exited with ${rc}"
#    echo -e   "└── traceback:"
#    sed  's/^/    /' "${errlog}"
#    echo -e   ""
  }
  exit "$rc"
}
set -Eeu
set -Eeuo errexit
set -Eeuo pipefail
trap 'fallback $?' ERR

# OS Detection ───────────────────────────────────────────────────────────────
if [[ -f "/etc/debian_version" ]]; then
  OS="DEBIAN"
fi

# System Path ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  SERVICE_DIR="/etc/systemd/system"
  CONFIG_DIR="/usr/local/share"
fi
mkdir -p "${CONFIG_DIR}" >/dev/null 2>&1
# Dependencies Installation ───────────────────────────────────────────────────────────────
msg_info "Installing Dependencies..."
if [[ ${OS} == "DEBIAN" ]]; then
  apt update
  apt upgrade -y
  apt install -y python3-full curl

  if ! $(command -v uv 1>/dev/null 2>&1); then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
fi
msg_done "Dependency Installation Complete"
echo -e  ""

# Langflow Installation ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  VENV_PATH="/root/.langflow-venv"
  UV="${HOME}/.local/bin/uv"
fi
if ! $(command -v langflow 1>/dev/null 2>&1); then
  msg_info "Installing Langflow..."

  ${UV} venv ${VENV_PATH}
  source ${VENV_PATH}/bin/activate
  ${UV} pip install langflow

  echo -e  ""
  msg_done "Langflow Installation Complete"
  echo -e  ""
fi

# Service Name ───────────────────────────────────────────────────────────────
DEFAULT_NAME="langflow-service"
SERVICE_NAME=""
while systemctl list-unit-files --type=service --all \
      | grep "^${SERVICE_NAME}.service" 1>/dev/null 2>&1 || [[ -z "${SERVICE_NAME}" ]]; do
  if [[ -n "${SERVICE_NAME}" ]]; then
    overwrite=$( \
    whiptail \
	--title "Service Name Conflict" \
	--yesno "Service name is already in use. Will you overwrite current service?\n\
If you choose 'yes', the service will be removed in an instant and cannot be recovered." 10 70 \
3>&1 1>&2 2>&3)
    if $overwrite; then
      revoke_path=$(systemctl cat "${SERVICE_NAME}" | grep "^#")
      rm -f "/${revoke_path#*/}" 1>/dev/null 2>&1
      systemctl kill "${SERVICE_NAME}" 1>/dev/null 2>&1
      systemctl daemon-reload 1>/dev/null 2>&1
      break
    else
      whiptail  --nocancel \
	--title "Service Name Conflict" \
	--msgbox "Service name is already in use. Please change your service name." 10 60 \
3>&1 1>&2 2>&3
    fi
  fi
  SERVICE_NAME=$( \
  whiptail  \
  --title "Service Name" \
  --inputbox "Enter your service name." 10 60 "${SERVICE_NAME:-$DEFAULT_NAME}" \
3>&1 1>&2 2>&3)
  if [[ -z "${SERVICE_NAME}" ]]; then
    whiptail  --nocancel \
	--title "Service Name Resolve" \
	--msgbox "Service name is blank. Default name is applied: ${DEFAULT_NAME}" 10 60 \
3>&1 1>&2 2>&3
    SERVICE_NAME="${DEFAULT_NAME}"
  fi
done

# Service Port ───────────────────────────────────────────────────────────────
DEFAULT_PORT=7860
SERVICE_PORT=""
while ss -l | grep ":${SERVICE_PORT}" 1>/dev/null 2>&1 || \
      [[ -z "${SERVICE_PORT}" ]]; do
  if [[ -n "${SERVICE_PORT}" ]]; then
    whiptail  --nocancel \
	--title "Service Port Conflict" \
	--msgbox "Port is busy. Please change your port." 10 60 \
3>&1 1>&2 2>&3
  fi
  SERVICE_PORT=$( \
  whiptail  \
	--title "Port Number" \
	--inputbox "Enter your port number." 10 60 "${SERVICE_PORT:-$DEFAULT_PORT}" \
3>&1 1>&2 2>&3)
  if [[ -z "${SERVICE_PORT}" ]]; then
    whiptail --nocancel \
	--title "Service Port Resolve" \
	--msgbox "Service port is blank. Default port is applied: ${DEFAULT_PORT}" 10 60 \
3>&1 1>&2 2>&3
    SERVICE_PORT="${DEFAULT_PORT}"
  fi
done

# Execute File ───────────────────────────────────────────────────────────────
START_PATH="${VENV_PATH}/langflow-start.sh"
  cat <<EOF >"${START_PATH}"
cd $VENV_PATH
$UV run langflow run --host 0.0.0.0 --port $SERVICE_PORT
EOF
chmod +x "${START_PATH}"
SERVICE_EXEC="/bin/bash ${START_PATH}"

# Service Path ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  SERVICE_PATH="${SERVICE_DIR}/${SERVICE_NAME}.service"
  CONFIG_PATH="${CONFIG_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.cfg"
else
  fallback "Unsupported OS (${OS}). Installation Aborted."
fi

# Configurations Enumeration ───────────────────────────────────────────────────────────────
msg_info "langflow-service configurations"
echo -e  "  - service name: ${BOLD}${SERVICE_NAME}${RESET}"
echo -e  "  - service file path: ${BOLD}${SERVICE_PATH}${RESET}"
echo -e  "  - service config path: ${BOLD}${CONFIG_PATH}${RESET}"
echo -e  ""

# Configuration File ───────────────────────────────────────────────────────────────
msg_info "Saving Configurations..."
if [[ ${OS} == "DEBIAN" ]]; then
  mkdir -p "${CONFIG_DIR}/${SERVICE_NAME}"
  cat <<EOF >"${CONFIG_PATH}"
SERVICE_NAME=$SERVICE_NAME
SERVICE_PATH=$SERVICE_PATH
SERVICE_EXEC=$SERVICE_EXEC
EOF
fi

msg_done "Configuration saved at: ${CONFIG_PATH}"
echo -e  ""

# Service Creation ───────────────────────────────────────────────────────────────
msg_info "Creating Service..."

if [[ ${OS} == "DEBIAN" ]]; then
  cat <<EOF >"${SERVICE_PATH}"
[Unit]
Description=$SERVICE_NAME
After=network.target

[Service]
User=root
ExecStart=$SERVICE_EXEC
WorkingDirectory=/root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload 1>/dev/null 2>&1
  systemctl enable --now "${SERVICE_NAME}.service" 1>/dev/null 2>&1
fi

msg_done "Service Created"
echo -e  ""

# Primary IP ───────────────────────────────────────────────────────────────
IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

echo -e "${SERVICE_NAME} is reachable at: ${BOLD}${MAGENTA}http://${IP}:${SERVICE_PORT}${RESET}"
echo -e ""
