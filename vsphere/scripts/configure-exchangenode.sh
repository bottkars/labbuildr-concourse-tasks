#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about

export LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}



echo "Inserting ${LABBUILDR_EXCHANGE_ISO}"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_IPATH} \
    -device cdrom-3001 "${LABBUILDR_EXCHANGE_ISO}"
echo "connecting ${LABBUILDR_EXCHANGE_ISO}"
govc device.connect \
        -vm.ipath="${LABBUILDR_VM_IPATH}" cdrom-3001

MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"
vm_ready
checktools
vm_windows_postsection
vm_reboot_step UAC
checkstep UAC "[Postsection UAC Reboot]"

echo "Creating Disks"
create_disk data1 500G
create_disk data2 500G
create_disk data3 500G

vm_ready
checktools
echo "Preparing disks in OS"
GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/prepare-disks.ps1"
GUEST_PARAMETERS="-Scriptdir ${GUEST_SCRIPT_DIR}"

vm_powershell --SCRIPT "${GUEST_SCRIPT}" \
    --PARAMETERS "${GUEST_PARAMETERS}" --INTERACTIVE 
    
