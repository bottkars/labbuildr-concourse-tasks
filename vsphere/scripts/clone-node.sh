#!/bin/bash
set -eu
[[ "${LABBUILDR_DEBUG}" == "TRUE" ]] && set -x
figlet labbuildr 2020
govc about

echo "==>Beginning deployment of ${LABBUILDR_VM_NAME} in ${LABBUILDR_RESOURCE_POOL}"
govc vm.clone -vm ${LABBUILDR_VM_TEMPLATE} \
  -m=${LABBUILDR_VM_MEMORY} \
  -c=${LABBUILDR_VM_CPU} \
  -net=${LABBUILDR_NETWORK} \
  -pool=${LABBUILDR_RESOURCE_POOL} \
  -folder=${LABBUILDR_VM_FOLDER} \
  -ds=${LABBUILDR_DATASTORE} \
  ${LABBUILDR_VM_NAME}
   
echo "==>Resizing OS Disk to 127GB for ${LABBUILDR_VM_NAME}"
govc vm.disk.change -vm  ${LABBUILDR_VM_NAME} \
  -disk.key 2000 \
  -size 127G