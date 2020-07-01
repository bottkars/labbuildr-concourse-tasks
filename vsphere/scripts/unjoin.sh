#!/bin/bash
set -eux
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_DCNODE}
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"

MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

checktools

echo "Removing${LABBUILDR_VM_NAME} from ${LABBUILDR_DOMAIN}"

GUEST_SCRIPT="Remove-ADComputer"
GUEST_PARAMETERS="-Identity ${LABBUILDR_VM_NAME}"
vm_run_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"




