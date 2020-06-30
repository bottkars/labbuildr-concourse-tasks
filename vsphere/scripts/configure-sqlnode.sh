#!/bin/bash
set -eux
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}
export GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
export NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/NODE"
export SCENARIO_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/SQL"
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
checkstep UAC "[Postsection UAC Rebbot]"

break
exit 1

echo "==>Beginning SQL Setup for ${LABBUILDR_VM_NAME}"
GUEST_SCRIPT="$SCENARIO_SCRIPT_DIR}/new-dc.ps1"
GUEST_PARAMETERS="-dcname ${LABBUILDR_VM_NAME} -Domain ${LABBUILDR_FQDN} -AddressFamily IPv4 -IPv4Subnet ${LABBUILDR_SUBNET} -DefaultGateway ${LABBUILDR_GATEWAY}"
govc guest.start -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_IPATH}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""


printf "checking for Step 2 [Network Setup]"
until govc guest.run -l Administrator:Password123! \
    -vm=dcnode $GUEST_SHELL  "-command get-item c:/scripts/2.pass" > /dev/null 2>&1
do
  printf ". "
  sleep 5
done
echo
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
echo "==>Proceeding with Domain Initialization of ${LABBUILDR_DOMAIN}"
LABBUILDR_DOMAIN_SUFFIX=$(echo $LABBUILDR_FQDN | cut -d'.' -f2-)
GUEST_SCRIPT="finish-domain.ps1"
GUEST_PARAMETERS="-domain ${LABBUILDR_DOMAIN} -domainsuffix ${LABBUILDR_DOMAIN_SUFFIX}"
govc guest.start -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""

printf "checking for Step 3 [Domain Setup]"
until govc guest.run -l Administrator:Password123! \
    -vm=dcnode $GUEST_SHELL  "-command get-item c:/scripts/3.pass" > /dev/null 2>&1
do
  printf ". "
  sleep 5
done
echo

### no a little bit hacky before doing functions
GUEST_SCRIPT="${GUEST_SCRIPT_DIR}/dns.ps1"
GUEST_PARAMETERS="-IPv4subnet ${LABBUILDR_SUBNET} -IPv4Prefixlength 24 -AddressFamily IPv4"
vm_run_powershellscript ${GUEST_SCRIPT} ${GUEST_PARAMETERS}

echo "==>Running DCNode Customization for vSphere"
GUEST_SCRIPTS=("add-serviceuser.ps1" "pwpolicy.ps1")
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
    vm_run_powershellscript "${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT}"
done



echo "==>Running Node Customization for vSphere"
NODE_SCRIPT_DIR="D:/labbuildr-scripts"
GUEST_SCRIPT_DIR="D:/labbuildr-scripts/node"
GUEST_SCRIPT="disable-hardening.ps1"
GUEST_PARAMETERS="-UpdateType never"
govc guest.run -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
# might be delivered via "Scripts to Run"
GUEST_SCRIPTS=("enable-ansiblewinrm.ps1" "set-winrm.ps1")
GUEST_PARAMETERS="-ScriptDir ${NODE_SCRIPT_DIR}"
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
echo "==>Running ${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT}"
govc guest.run -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
done

echo "==>finished configuring dcnode"
