#!/bin/bash
# Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script configure-node.ps1 -Parameter "-nodeip $Nodeip -nodename $Nodename -Domain $BuildDomain -domainsuffix $custom_domainsuffix -IPv4subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix $AddGateway -AddOnfeatures '$AddonFeatures' -TimeZone '$($labdefaults.timezone)' $CommonParameter" -nowait -interactive # $CommonParameter
# Parameters required for PS1
# -nodeip $Nodeip 
# -nodename $Nodename 
# -Domain $BuildDomain 
# -domainsuffix $custom_domainsuffix 
# -IPv4subnet $IPv4subnet 
# -IPV6Subnet $IPv6Prefix
# -AddressFamily $AddressFamily
# -IPv4PrefixLength $IPv4PrefixLength
# -IPv6PrefixLength $IPv6PrefixLength
# -IPv6Prefix $IPv6Prefix
# $AddGateway
# -AddOnfeatures '$AddonFeatures' 
# -TimeZone '$($labdefaults.timezone)'
set -eux
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

MYSELF="$(dirname "${BASH_SOURCE[0]}")"
source "${MYSELF}/functions/labbuildr_functions.sh"


GUEST_SCRIPT_DIR="D:/labbuildr-scripts"
NODE_SCRIPT_DIR="${GUEST_SCRIPT_DIR}/node"
vm_ready

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"
LABBUILDR_DOMAIN=$(echo $LABBUILDR_FQDN | cut -d'.' -f1-1)
LABBUILDR_DOMAIN_SUFFIX=$(echo $LABBUILDR_FQDN | cut -d'.' -f2-)

GUEST_SCRIPT="${NODE_SCRIPT_DIR}/configure-node.ps1"
GUEST_PARAMETERS="-nodename ${LABBUILDR_VM_NAME} \
-nodeip ${LABBUILDR_VM_IP} \
-Domain ${LABBUILDR_DOMAIN} \
-domainsuffix ${LABBUILDR_DOMAIN_SUFFIX} \
-AddressFamily IPv4 \
-IPv4Subnet ${LABBUILDR_SUBNET} \
-DefaultGateway ${LABBUILDR_GATEWAY} \
-Timezone '${LABBUILDR_TIMEZONE}' \
-scriptdir '${GUEST_SCRIPT_DIR}' \
-AddOnfeatures '$ADDON_FEATURES'"
vm_start_powershellscript ${GUEST_SCRIPT} "${GUEST_PARAMETERS}"

checkstep 3 "[Domain Join]"
