 #!/bin/bash
set -eux
govc about

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"
apt install genisoimage -y
genisoimage -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO"
govc datastore.upload -ds $LABBUILDR_DATASTORE
 ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attachin Script ISO"
govc device.cdrom.insert -vm.ipath ${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} \
-device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect -vm.ipath=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} cdrom-3000
exit 1

VM_SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
SCRIPT="D:\\labbuildr-scripts\\dcnode\\new-dc.ps1"
PARAMETERS="-dcname ${LABBUILDR_VM_NAME} -Domain ${LABBUILDR_FQDN} -AddressFamily IPv4"
govc guest.start -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${VM_SHELL} -Command \"${SCRIPT} ${PARAMETERS}\"" \
-i=true
# was: 			$script_invoke = $NodeClone | Invoke-VMXPowershell -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script new-dc.ps1 -Parameter "
#was : -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix  -AddressFamily $AddressFamily -TimeZone '$($labdefaults.timezone)' $AddGateway $CommonParameter
#" -interactive -nowait
exit 1