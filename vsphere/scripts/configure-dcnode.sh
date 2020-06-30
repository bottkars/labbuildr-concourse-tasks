#!/bin/bash
set -eu
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}

DEBIAN_FRONTEND=noninteractive apt-get install -qq genisoimage < /dev/null > /dev/null
echo "==>Creating Script ISO"
genisoimage -quiet -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO to vCenter"
govc datastore.upload -ds $LABBUILDR_DATASTORE ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attaching Script ISO"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_IPATH} \
    -device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect \
        -vm.ipath=${LABBUILDR_VM_IPATH} cdrom-3000

GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/dcnode"
MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"

# we need to put in a wait for vm up and running ?!
vm_ready

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"


GUEST_SCRIPT="${NODE_SCRIPT_DIR}/new-dc.ps1"
GUEST_PARAMETERS="-dcname ${LABBUILDR_VM_NAME} -Domain ${LABBUILDR_FQDN} -AddressFamily IPv4 -IPv4Subnet ${LABBUILDR_SUBNET} -DefaultGateway ${LABBUILDR_GATEWAY}"
vm_start_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"


checkstep 2 "[Network Setup]"

LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
echo "==>Proceeding with Domain Initialization of ${LABBUILDR_DOMAIN}"
LABBUILDR_DOMAIN_SUFFIX=$(echo $LABBUILDR_FQDN | cut -d'.' -f2-)
GUEST_SCRIPT="finish-domain.ps1"
GUEST_PARAMETERS="-domain ${LABBUILDR_DOMAIN} -domainsuffix ${LABBUILDR_DOMAIN_SUFFIX}"
vm_start_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"

checkstep 3 "[Domain Setup]"

### no a little bit hacky before doing functions
GUEST_SCRIPT="${NODE_SCRIPT_DIR}/dns.ps1"
GUEST_PARAMETERS="-IPv4subnet ${LABBUILDR_SUBNET} -IPv4Prefixlength 24 -AddressFamily IPv4"
vm_start_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"

echo "==>Running DCNode Customization for vSphere"
GUEST_SCRIPTS=("${NODE_SCRIPT_DIR}/add-serviceuser.ps1" "${NODE_SCRIPT_DIR}/pwpolicy.ps1")
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
vm_run_powershellscript "${GUEST_SCRIPT}"
done

echo "==>Running Node Customization for vSphere"
NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/node"
GUEST_SCRIPT="${NODE_SCRIPT_DIR}/disable-hardening.ps1"
GUEST_PARAMETERS="-UpdateType never"
vm_run_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"

GUEST_SCRIPTS=("${NODE_SCRIPT_DIR}/enable-ansiblewinrm.ps1" "${NODE_SCRIPT_DIR}/set-winrm.ps1")
GUEST_PARAMETERS="-ScriptDir ${NODE_SCRIPT_DIR}"
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
vm_run_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"
done

vm_ready
vm_windows_postsection
vm_reboot_step postsection

echo "==>finished configuring dcnode"