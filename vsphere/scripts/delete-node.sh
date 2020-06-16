#!/bin/bash
#set -eu
govc about

echo "==>Beginning node removal of ${LABBUILDR_VM_NAME}"
govc vm.destroy -vm.ipath  ${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}  
echo "Cleaning Datastorre for VM ${LABBUILDR_VM_NAME}"

govc datastore.rm -ds=${LABBUILDR_DATASTORE}  ${LABBUILDR_VM_NAME}
exit 0