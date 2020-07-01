#!/bin/bash
#set -eu
govc about

export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}

echo "==>Beginning node removal of ${LABBUILDR_VM_NAME}"
govc vm.destroy -vm.ipath  ${LABBUILDR_VM_IPATH}  
echo "==>Cleaning Datastore for VM ${LABBUILDR_VM_NAME}"

govc datastore.rm -ds=${LABBUILDR_DATASTORE}  ${LABBUILDR_VM_NAME}
exit 0