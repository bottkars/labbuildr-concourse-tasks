#!/bin/bash

set -eux
govc about
export LABBUILDR_VM_IPATH=${LABBUILDR_VM_FOLDER}/${LABBUILDR_VM_NAME}

DEBIAN_FRONTEND=noninteractive apt-get install -qq genisoimage < /dev/null > /dev/null
echo "==>Creating Script ISO"
genisoimage -quiet -o labbuildr-scripts.iso -R -J -D labbuildr-scripts 
echo "==>Uploading Script ISO to vCenter"
govc datastore.upload -ds $LABBUILDR_DATASTORE ./labbuildr-scripts.iso ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 
echo "==>Attaching Script ISO"
govc device.cdrom.insert \
    -vm.ipath ${LABBUILDR_VM_IPATH} \
    -device cdrom-3000 ${LABBUILDR_VM_NAME}/labbuildr-scripts.iso 

govc device.connect \
        -vm.ipath=${LABBUILDR_VM_IPATH} ${LABBUILDR_DEVICE}




