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

 -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version -SourcePath $IN_Guest_UNC_Sourcepath $CommonParameter"
				} # end if $DAG

echo "Setting Up Exchange 2019 DAG "
GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/create-dag.ps1.ps1"
GUEST_PARAMETERS="-ex_version E2019 -Scriptdir ${GUEST_SCRIPT_DIR} -SourcePath $SOURCE_DIR"
vm_powershell --SCRIPT "${GUEST_SCRIPT}"   \
    --PARAMETERS "${GUEST_PARAMETERS}" --INTERACTIVE

