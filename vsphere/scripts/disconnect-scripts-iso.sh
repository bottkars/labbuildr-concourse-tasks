#!/bin/bash
set -u # we don´t use e for vmware´s eject bug
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
labbuildr 2020
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}

echo "==>Beginning removal of ${LABBUILDR_DEVICE}"
govc device.cdrom.eject -vm.ipath "${LABBUILDR_VM_IPATH}" -device "${LABBUILDR_DEVICE}"
echo "==>Removing ISO ${LABBUILDR_DATASTORE}/labbuildr-scripts.iso"
govc datastore.rm -f -ds="${LABBUILDR_DATASTORE}" "${LABBUILDR_VM_NAME}/labbuildr-scripts.iso"
exit 0