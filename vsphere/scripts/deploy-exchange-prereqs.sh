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
PREREQ_DIR="${SOURCE_DIR}\\prereq"
guest_mkdir "${PREREQ_DIR}" 

NETFX_VERSION=$(cat netframework/version)
echo "Uploading NetFX ${NETFX_VERSION}"
guest_upload "./netframework/ndp${NETFX_VERSION}-x86-x64-allos-enu.exe" "${PREREQ_DIR}\\ndp${NETFX_VERSION}-x86-x64-allos-enu.exe"

UCMA_VERSION=$(cat ucmaruntime/version)
echo "Uploading UCMA Runtime ${UCMA_VERSION}"
guest_upload "./ucmaruntime/UcmaRuntimeSetup-${UCMA_VERSION}.exe" "${PREREQ_DIR}\\UcmaRuntimeSetup.exe"

VCREDIST11_VERSION=$(cat vcredist11/version)
echo "Uploading VCRedist 11 ${VCREDIST11_VERSION}"
guest_upload "./vcredist11/vcredist_x64-${VCREDIST11_VERSION}.exe" "${PREREQ_DIR}\\vcredist11.exe"

VCREDIST12_VERSION=$(cat vcredist12/version)
echo "Uploading VCRedist 12 ${VCREDIST12_VERSION}"
guest_upload "./vcredist12/vcredist_x64-${VCREDIST12_VERSION}.exe" "${PREREQ_DIR}\\vcredist12.exe"




echo "Setting Up Exchange prereqs"
GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/install-exchangeprereqs.ps1"
GUEST_PARAMETERS="-Scriptdir ${GUEST_SCRIPT_DIR} -prereq prereq -SourcePath $SOURCE_DIR"
vm_powershell --SCRIPT "${GUEST_SCRIPT}"   \
    --PARAMETERS "${GUEST_PARAMETERS}" --INTERACTIVE 




##
#     		$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script configure-exchange.ps1 -interactive -Parameter "-e14_sp $e14_sp -e14_ur $e14_ur -ex_lang $e14_lang -SourcePath $IN_Guest_UNC_Sourcepath $CommonParameter"

#
#GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/create-dag.ps1"
#GUEST_PARAMETERS="-EX_Version 2019 -ex_cu LABBUILDR_EXCHANGE_CU -DAGIP $DAGIP"
#vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
#    --PARAMETERS "${GUEST_PARAMETERS}"
# $script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy 
#After this, login is with svc_sql
#GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/finish-sql.ps1"
#GUEST_PARAMETERS=" -Scriptdir ${GUEST_SCRIPT_DIR}"
#vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
#    --PARAMETERS "${GUEST_PARAMETERS}" \
#    --INTERACTIVE --NOWAIT
