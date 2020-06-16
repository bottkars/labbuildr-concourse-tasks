#!/bin/bash
set -eu
govc about
# we need to put in a wait for vm up and running ?!

echo "==>Beginning Configuration of ${LABBUILDR_VM_NAME} for ${LABBUILDR_FQDN}"
DEBIAN_FRONTEND=noninteractive apt-get install -qq genisoimage < /dev/null > /dev/null
genisoimage -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO"
govc datastore.upload -ds $LABBUILDR_DATASTORE ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attaching Script ISO"
govc device.cdrom.insert -vm.ipath ${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} \
-device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect -vm.ipath=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME} cdrom-3000
GUEST_SCRIPT_DIR="D:/labbuildr-scripts/dcnode"
GUEST_SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
GUEST_SCRIPT="new-dc.ps1"
GUEST_PARAMETERS="-dcname ${LABBUILDR_VM_NAME} -Domain ${LABBUILDR_FQDN} -AddressFamily IPv4 -IPv4Subnet ${LABBUILDR_SUBNET}"
govc guest.start -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""


printf "checking for Step 2 "
until govc guest.run -l Administrator:Password123! -vm=dcnode $GUEST_SHELL  "-command get-item c:/scripts/2.pass" > /dev/null 2>&1
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
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""

printf "checking for Step 3 "
until govc guest.run -l Administrator:Password123! -vm=dcnode $GUEST_SHELL  "-command get-item c:/scripts/3.pass" > /dev/null 2>&1
do
  printf ". "
  sleep 5
done
echo

### no a little bit hacky before doing functions
GUEST_SCRIPT="dns.ps1"
GUEST_PARAMETERS="-IPv4subnet ${LABBUILDR_SUBNET} -IPv4Prefixlength 24 -AddressFamily IPv4"
govc guest.run -l="Administrator:Password123!" \
-vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
"${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""

echo "==>Running DCNode Customization for vSphere"
GUEST_SCRIPTS=("add-serviceuser.ps1" "pwpolicy.ps1")
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
echo "==>Running ${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT}"
govc guest.run -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT}\""
done



echo "==>Running Node Customization for vSphere"
NODE_SCRIPT_DIR="D:/labbuildr-scripts"
GUEST_SCRIPT_DIR="D:/labbuildr-scripts/node"
GUEST_SCRIPT="disable-hardening.ps1"
GUEST_PARAMETERS="-UpdateType never"
govc guest.run -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
# might be delivered via "Scripts to Run"
GUEST_SCRIPTS=("enable-ansiblewinrm.ps1" "set-winrm.ps1")
GUEST_PARAMETERS="-ScriptDir ${NODE_SCRIPT_DIR}"
for GUEST_SCRIPT in "${GUEST_SCRIPTS[@]}"
do
echo "==>Running ${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT}"
govc guest.run -l="Administrator:Password123!" \
    -vm.ipath="${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}" \
    "${GUEST_SHELL}" "-Command \"${GUEST_SCRIPT_DIR}/${GUEST_SCRIPT} ${GUEST_PARAMETERS}\""
done

echo "==>finished configuring dcnode"
