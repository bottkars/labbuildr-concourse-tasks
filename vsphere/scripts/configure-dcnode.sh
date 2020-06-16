 #!/bin/bash
set -eux
govc about

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"
DEBIAN_FRONTEND=noninteractive apt-get install -qq genisoimage < /dev/null > /dev/null
genisoimage -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO"
govc datastore.upload -ds $LABBUILDR_DATASTORE ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attaching Script ISO"
govc device.cdrom.insert -vm.ipath ${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} \
-device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect -vm.ipath=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} cdrom-3000

GUEST_SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
GUEST_SCRIPT="D:/labbuildr-scripts/dcnode/new-dc.ps1"
GUEST_PARAMETERS="-dcname ${LABBUILDR_VM_NAME} -Domain ${LABBUILDR_FQDN} -AddressFamily IPv4 -IPv4Subnet ${LABBUILDR_SUBNET}"
govc guest.start -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
# was: 			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script new-dc.ps1 -Parameter "
#was : -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix  -AddressFamily $AddressFamily -TimeZone '$($labdefaults.timezone)' $AddGateway $CommonParameter
#" -interactive -nowait
exit 1