#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about


export LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}


MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

vm_ready
checktools
SOURCE_DIR="c:\\swdist"



echo "Setting Up Exchange 2019 $LABBUILDR_EXCHANGE_CU"
GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/install-exchange.ps1"
GUEST_PARAMETERS="-ex_cu $LABBUILDR_EXCHANGE_CU -install_from ISO -Scriptdir ${GUEST_SCRIPT_DIR} -SourcePath $SOURCE_DIR"
vm_powershell --SCRIPT "${GUEST_SCRIPT}"   \
    --PARAMETERS "${GUEST_PARAMETERS}" --INTERACTIVE --NOWAIT

checkstep exchange "[Postsection Exchange Reboot]"