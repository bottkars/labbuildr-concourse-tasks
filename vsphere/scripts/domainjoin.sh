#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}
export GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
export NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/node"


MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

checktools

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
LABBUILDR_DOMAIN_SUFFIX=$(echo $LABBUILDR_FQDN | cut -d'.' -f2-)

GUEST_SCRIPT="${NODE_SCRIPT_DIR}/configure-node.ps1"
GUEST_PARAMETERS="-nodename ${LABBUILDR_VM_NAME} \
-nodeip ${LABBUILDR_VM_IP} \
-Domain ${LABBUILDR_DOMAIN} \
-domainsuffix ${LABBUILDR_DOMAIN_SUFFIX} \
-AddressFamily IPv4 \
-IPv4Subnet ${LABBUILDR_SUBNET} \
-DefaultGateway ${LABBUILDR_GATEWAY} \
-Timezone '${LABBUILDR_TIMEZONE}' \
-scriptdir '${GUEST_SCRIPT_DIR}' \
-AddOnfeatures '$ADDON_FEATURES'"

vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
    --PARAMETERS "${GUEST_PARAMETERS}" \
    --INTERACTIVE --NOWAIT

echo "Proceeding with Checkstep"
checkstep 3 "[Domain Join]"



