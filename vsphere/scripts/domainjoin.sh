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

set -eu
govc about
DEBIAN_FRONTEND=noninteractive apt-get install -qq genisoimage < /dev/null > /dev/null
echo "==>Creating Script ISO"
genisoimage -quiet -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO to vCenter"
govc datastore.upload -ds $LABBUILDR_DATASTORE ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attaching Script ISO"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} \
    -device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect \
        -vm.ipath=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} cdrom-3000
GUEST_SCRIPT_DIR="D:/labbuildr-scripts/node"
GUEST_SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
# we need to put in a wait for vm up and running ?!
printf "==>Waiting for ${LABBUILDR_VM_NAME} to become ready"
until govc guest.start -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" "${GUEST_SHELL}" > /dev/null 2>&1
do
  printf ". "
  sleep 5
done
echo

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"


GUEST_SCRIPT="configure-node.ps1"
GUEST_PARAMETERS="-nodename ${LABBUILDR_VM_NAME} \
-Domain ${LABBUILDR_FQDN} \
-AddressFamily IPv4 \
-IPv4Subnet ${LABBUILDR_SUBNET} \
-DefaultGateway ${LABBUILDR_GATEWAY} \
-Timezone ${LABBUILDR_TIMEZONE}"
govc guest.start -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
