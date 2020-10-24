#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_DCNODE}
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)


MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

checktools
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"
echo "Removing${LABBUILDR_VM_NAME} from ${LABBUILDR_DOMAIN}"

GUEST_SCRIPT="Remove-ADComputer"
GUEST_PARAMETERS="-Identity ${LABBUILDR_VM_NAME} -Confirm:\$false"
vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
    --PARAMETERS "${GUEST_PARAMETERS}" 




