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
    # stip domain and password
    local VM_USERNAME=${LABBUILDR_LOGINUSER#*\\}
    local VM_USERNAME=${VM_USERNAME/:*}
    printf "==>Waiting for vmtoold for user $VM_USERNAME on${LABBUILDR_VM_IPATH} to become ready"
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



function vm_powershell {
    set +u
    local interactive=false
    local govc_command="guest.run"   
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -s|--SCRIPT)
            local SCRIPT=${2}
            echo "Script is ${SCRIPT}"
            shift
            # past value if  arg value
            ;;
            -p|--PARAMETERS)
            local PARAMETERS=${2}
            echo "Parameters is ${PARAMETERS}"
            shift # past value ia arg value
            ;;
            -i|--INTERACTIVE)
            local interactive=true
            echo "interactive is ${interactive}"
            # shift  # past value ia arg value
            ;;
            -n|--NOWAIT)
            local govc_command="guest.start"
            echo "interactive is ${interactive}"
            set +e
            # shift  # past value ia arg value
            ;;            
            *) 
            echo "unknown Parameter $1"
            return 1   # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            #shift # past argument
            ;;
        esac
        shift
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

    local SHELL="C:/Windows/System32/WindowsPowerShell/V1.0/powershell.exe"
    echo "==>Running ${SCRIPT} ${PARAMETERS} -interactive=$interactive"
    govc guest.run -l="${LABBUILDR_LOGINUSER}" \
        -vm.ipath="${LABBUILDR_VM_IPATH}" \
        -i=$interactive \
        "${SHELL}" "-Command \"${SCRIPT} ${PARAMETERS}\""
    set -eu 
}


function vm_windows_postsection {
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/Set-Customlanguage.ps1" \
        --PARAMETERS "-LanguageTag ${LABBUILDR_LANGUAGE_TAG}" 
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/powerconf.ps1" \
        --PARAMETERS "-Scriptdir ${GUEST_SCRIPT_DIR}" 
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/set-uac.ps1" \
        --PARAMETERS"-Scriptdir ${GUEST_SCRIPT_DIR}" 
}

function vm_reboot_step {
    local STEP=${1}
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/set-step.ps1" \
        --PARAMETERS "-Scriptdir ${GUEST_SCRIPT_DIR} -reboot -step ${STEP}" \
        --INTERACTIVE --NOWAIT
}

function create_disk {
    local disk_name=${1}
    local disk_size=${2}
    govc vm.disk.create -vm.ipath "${LABBUILDR_VM_IPATH}" \
-name "$LABBUILDR_VM_NAME/${disk_name}" -size ${disk_size}
}

