#!/bin/bash
set -u
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}

echo "==>Beginning removal of ${LABBUILDR_DEVICE}"
govc device.cdrom.eject -vm.ipath "${LABBUILDR_VM_IPATH}" -device "${LABBUILDR_DEVICE}"
echo "==>Removing ISO ${LABBUILDR_DATASTORE}/labbuildr-scripts.iso"
govc datastore.rm -f -ds="${LABBUILDR_DATASTORE}" "${LABBUILDR_VM_NAME}/labbuildr-scripts.iso"
exit 0