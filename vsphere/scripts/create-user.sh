#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about


export LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"


MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

vm_ready
checktools
SOURCE_DIR="c:\\swdist"


echo "Setting Up Exchange 2019 DAG "
GUEST_SCRIPT="."
USER_SCRIPT="$GUEST_SCRIPT_DIR/userps1"
GUEST_PARAMETERS=" 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; . '${SCENARIO_SCRIPT_DIR}/user.ps1' -ex_version E2019 -Scriptdir ${GUEST_SCRIPT_DIR} -SourcePath $SOURCE_DIR"
vm_powershell --SCRIPT "${GUEST_SCRIPT}"   \
    --PARAMETERS "${GUEST_PARAMETERS}" --INTERACTIVE

