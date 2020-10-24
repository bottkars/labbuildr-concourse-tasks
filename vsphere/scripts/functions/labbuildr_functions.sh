#!/bin/bash
function retryop()
{
  retry=0
  max_retries=$2
  interval=$3
  while [ ${retry} -lt ${max_retries} ]; do
    echo "Operation: $1, Retry #${retry}"
    eval $1
    if [ $? -eq 0 ]; then
      echo "Successful"
      break
    else
      let retry=retry+1
      echo "Sleep $interval seconds, then retry..."
      sleep $interval
    fi
  done
  if [ ${retry} -eq ${max_retries} ]; then
    echo "Operation failed: $1"
    exit 1
  fi
}
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
    printf "==>Waiting for vmtoolsd for user $VM_USERNAME on ${LABBUILDR_VM_IPATH} to become ready"
    until (govc guest.ps -vm.ipath $LABBUILDR_VM_IPATH -l $LABBUILDR_LOGINUSER --json | jq -r -e --arg user $VM_USERNAME '.[][] | select(.Name=="vmtoolsd.exe") | select(.Owner | contains($user))' )
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
    # local oldstate="$(shopt -po xtrace noglob errexit)"
    set +u
    local interactive=false
    local govc_command="guest.run" 
    local PID=""  
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -s|--SCRIPT)
            local SCRIPT=${2}
            echo "Script: ${SCRIPT}"
            shift
            # past value if  arg value
            ;;
            -p|--PARAMETERS)
            local PARAMETERS=${2}
            echo "Parameter: ${PARAMETERS}"
            shift # past value ia arg value
            ;;
            -i|--INTERACTIVE)
            local interactive=true
            echo "interactive: ${interactive}"
            # shift  # past value ia arg value
            ;;
            -n|--NOWAIT)
            local govc_command="guest.start"
            echo "govc_command: ${govc_command}"
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
    while [[ -z "$PID" ]]
    do
    PID=$(govc $govc_command -l="${LABBUILDR_LOGINUSER}" \
        -vm.ipath="${LABBUILDR_VM_IPATH}" \
        -i=$interactive \
        "${SHELL}" "-Command \"${SCRIPT} ${PARAMETERS}\"")
    done    
    set -eu 
}


function vm_windows_postsection {
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/Set-Customlanguage.ps1" \
        --PARAMETERS "-LanguageTag ${LABBUILDR_LANGUAGE_TAG}" 
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/powerconf.ps1" \
        --PARAMETERS "-Scriptdir ${GUEST_SCRIPT_DIR}" 
    vm_powershell --SCRIPT "${NODE_SCRIPT_DIR}/set-uac.ps1" \
        --PARAMETERS "-Scriptdir ${GUEST_SCRIPT_DIR}" 
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
function guest_upload {
    local source_file=${1}
    local target_file=${2}
    govc guest.upload -vm.ipath "${LABBUILDR_VM_IPATH}" \
    -l="${LABBUILDR_LOGINUSER}" \
    ${source_file} ${target_file}
}

function guest_mkdir {
    local target_dir=${1}
    govc guest.mkdir -vm.ipath "${LABBUILDR_VM_IPATH}" \
    -l="${LABBUILDR_LOGINUSER}" \
    -p ${target_dir}
}
