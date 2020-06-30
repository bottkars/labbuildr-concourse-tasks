#!/bin/bash
function checkstep {
    local step=${1}
    local message="==>checking for Step ${step} ${2} "
    printf "${message}"
    until govc guest.run -l Administrator:Password123! \
        -vm=dcnode $GUEST_SHELL  "-command get-item c:/scripts/${step}.pass" > /dev/null 2>&1
    do
        printf ". "
        sleep 5
    done
    echo Done
}

function vm_ready {
    local VM_IPATH=$1
    local SHELL=$2
    printf "==>Waiting for ${VM_IPATH} to become ready"
    until govc guest.start -l="Administrator:Password123!" \
        -vm.ipath="${VM_IPATH}" "${SHELL}" > /dev/null 2>&1
    do
        printf ". "
        sleep 5
    done
    echo Done
}

