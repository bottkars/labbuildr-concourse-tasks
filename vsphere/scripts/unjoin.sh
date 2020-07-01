#!/bin/bash
set -eux
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_DCNODE}
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)


MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

checktools
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"
echo "Removing${LABBUILDR_VM_NAME} from ${LABBUILDR_DOMAIN}"

GUEST_SCRIPT="Remove-ADComputer"
GUEST_PARAMETERS="-Identity ${LABBUILDR_VM_NAME} -Confirm:\$True"
vm_run_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"




