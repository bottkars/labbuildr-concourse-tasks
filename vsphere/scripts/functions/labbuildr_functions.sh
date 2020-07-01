#!/bin/bash
function checkstep {
    local step=${1}
    local message="==>checking for Step ${step} ${2} "
    local SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"

    printf "${message}"
    until govc guest.run -l ${LABBUILDR_LOGINUSER} \
        -vm.ipath="${LABBUILDR_VM_IPATH}" "${SHELL}"  "-command get-item c:/scripts/${step}.pass" > /dev/null 2>&1
    do
        printf ". "
        sleep 5
    done
    echo Done
}

function vm_ready {
    local SHELL=C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe
    printf "==>Waiting for ${LABBUILDR_VM_IPATH} to become ready"
    until govc guest.start -l="${LABBUILDR_LOGINUSER}" \
        -vm.ipath="${LABBUILDR_VM_IPATH}" "${SHELL}" > /dev/null 2>&1
    do
        printf ". "
        sleep 5
    done
    echo Done
}
function checktools {
    local VM_USERNAME=${LABBUILDR_LOGINUSER/:*}
    printf "==>Waiting for ${LABBUILDR_VM_IPATH} to become ready"
    until  echo $(govc guest.ps -vm.ipath $LABBUILDR_VM_IPATH  -l $LABBUILDR_LOGINUSER  --json ) | jp.py "ProcessInfo[?contains(Name,'vmtoolsd.exe')].Owner" 2>/dev/null | grep ${VM_USERNAME}
    do
    printf ". " 
    sleep 5
    done
}

function checkuser {
    local VM_USER=${1}
    printf "==>Waiting for ${VM_USER} "
    until govc guest.ps -vm.ipath $LABBUILDR_VM_IPATH -l $LABBUILDR_LOGINUSER | grep $VM_USER  > /dev/null 2>&1
        do
        printf ". "
        sleep 5
    done
    echo Done
}

function vm_start_powershellscript {
    local SCRIPT=${1}
    local PARAMETERS=${2}
    set +u
    if [[ ! -z "${3}" ]]
        then local interactive="true"
        else local interactive="false"
    fi
    set -u 
    local SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
    echo "==>Starting ${SCRIPT} ${PARAMETERS}"
    govc guest.start -i=${interactive} -l="${LABBUILDR_LOGINUSER}" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
"${SHELL}" "-Command \"${SCRIPT} ${PARAMETERS}\""
}


function vm_run_powershellscript {
    local SCRIPT=${1}
    local PARAMETERS=${2}
    set +u
    if [[ ! -z "${3}" ]]
        then local interactive="true"
        else local interactive="false"
    fi
    set -u 
    local SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
    echo "==>Running ${SCRIPT} ${PARAMETERS}"
    govc guest.run -i=${interactive} -l="${LABBUILDR_LOGINUSER}" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
    "${SHELL}" "-Command \"${SCRIPT} ${PARAMETERS}\""
}

function vm_run_powershellcommand {
    local SCRIPT=${1}
    local PARAMETERS=${2}
    set +u
    if [[ ! -z "${3}" ]]
        then local interactive="true"
        else local interactive="false"
    fi
    set -u  
    local SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
    echo "==>Running ${SCRIPT} ${PARAMETERS}"
    govc guest.run -i=false -l="${LABBUILDR_LOGINUSER}" \
    -vm.ipath="${LABBUILDR_VM_IPATH}" \
    "${SHELL}" "-Command ${COMMAND} \"${PARAMETERS}\""
}


function vm_windows_postsection {
    vm_run_powershellscript "${NODE_SCRIPT_DIR}/Set-Customlanguage.ps1" "-LanguageTag ${LABBUILDR_LANGUAGE_TAG}" 
    vm_run_powershellscript "${NODE_SCRIPT_DIR}/powerconf.ps1" "-Scriptdir ${GUEST_SCRIPT_DIR}"
    vm_run_powershellscript "${NODE_SCRIPT_DIR}/set-uac.ps1" "-Scriptdir ${GUEST_SCRIPT_DIR}"
}

function vm_reboot_step {
    local STEP=${1}
    vm_start_powershellscript "${NODE_SCRIPT_DIR}/set-step.ps1" "-Scriptdir ${GUEST_SCRIPT_DIR} -reboot -step ${STEP}"
}

function create_disk {
    local disk_name=${1}
    local disk_size=${2}
    govc vm.disk.create -vm.ipath "${LABBUILDR_VM_IPATH}" \
-name "$LABBUILDR_VM_NAME/${disk_name}" -size ${disk_size}
}
