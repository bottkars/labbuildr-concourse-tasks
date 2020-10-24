#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about

export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}
export GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
export NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/NODE"
export SCENARIO_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/E2019"
export LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"

echo "Inserting ${LABBUILDR_EXCHANGE_ISO}"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_IPATH} \
    -device cdrom-3001 "${LABBUILDR_EXCHANGE_ISO}"
echo "connecting ${LABBUILDR_EXCHANGE_ISO}"
govc device.connect \
        -vm.ipath="${LABBUILDR_VM_IPATH}" cdrom-3001

MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"
checktools
vm_windows_postsection
vm_reboot_step UAC
checkstep UAC "[Postsection UAC Reboot]"

echo "Creating Disks"
create_disk data1 500G
create_disk data2 500G
create_disk data3 500G

echo "Preparing disks in OS"


GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/prepare-disks.ps1.ps1"
GUEST_PARAMETERS=" -Scriptdir ${GUEST_SCRIPT_DIR}"
vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
    --PARAMETERS "${GUEST_PARAMETERS}" \
    --INTERACTIVE 
    
    
    --NOWAIT



sleep 7000


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
