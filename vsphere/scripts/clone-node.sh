#!/bin/bash
set -eu
govc about

echo "==>Beginning deployment of ${LABBUILDR_VM_NAME} in ${LABBUILDR_RESOURCE_POOL}"
govc vm.clone -vm 2019_template \
 -m=${LABBUILDR_VM_MEMORY} \
 -c=${LABBUILDR_VM_CPU} \
 -net=${LABBUILDR_NETWORK} \
 -pool=${LABBUILDR_RESOURCE_POOL} \
 -folder=${LABBUILDR_VM_FOLDER} \
 -ds=${LABBUILDR_DATASTORE} \
 ${LABBUILDR_VM_NAME} 