#!/bin/bash
set -eux
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}
export GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
export NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/NODE"
export SCENARIO_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/SQL"
export LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
export LABBUILDR_LOGINUSER="${LABBUILDR_DOMAIN}\\${LABBUILDR_LOGINUSER}"

echo "Inserting ${LABBUILDR_SQL_ISO}"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_IPATH} \
    -device cdrom-3001 "${LABBUILDR_SQL_ISO}"
echo "connecting ${LABBUILDR_SQL_ISO}"
govc device.connect \
        -vm.ipath="${LABBUILDR_VM_IPATH}" cdrom-3001

MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"
vm_ready
vm_windows_postsection
vm_reboot_step UAC
checkstep UAC "[Postsection UAC Reboot]"

echo "Creating Disks"
create_disk data 200G
create_disk log 20G
create_disk tmpdb 200G
create_disk tmplog 20G


GUEST_SCRIPT="${SCENARIO_SCRIPT_DIR}/install-sql.ps1"
GUEST_PARAMETERS="-SQLVER SQL2019_ISO"
vm_start_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}" interactive


