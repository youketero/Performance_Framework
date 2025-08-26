#!/usr/bin/env bash

#=== FUNCTION ================================================================
#        NAME: logit
# DESCRIPTION: Log into file and screen.
# PARAMETER - 1 : Level (ERROR, INFO)
#           - 2 : Message
#
#===============================================================================
logit() {
    local level="$1"
    local msg="$2"
    local color=""

    case "$level" in
        INFO)  color="\e[94m" ;;
        WARN)  color="\e[93m" ;;
        ERROR) color="\e[91m" ;;
        *)     color="\e[0m" ;; # default
    esac
	
    echo -e " [${color}${level}\e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ] ${color}${msg}\e[0m"
    [ "$level" = "WARN" ] && sleep 2
}

#=== FUNCTION ================================================================
#        NAME: usage
# DESCRIPTION: Helper of the function
# PARAMETER - None
#
#===============================================================================
usage() {
    local messages=(
        "-j <filename.jmx>"
        "-n <namespace>"
        "-c flag to split and copy csv if you use csv in your test"
        "-m flag to copy fragmented jmx present in scenario/project/module if you use include controller and external test fragment"
        "-i <injectorNumber> to scale slaves pods to the desired number of JMeter injectors"
        "-r flag to enable report generation at the end of the test"
    )

    for msg in "${messages[@]}"; do
        logit "INFO" "$msg"
    done

    exit 1
}

declare -A args_with_value=(
    [n]=namespace
    [j]=jmx
    [i]=nb_injectors
)

# Масив прапорців без аргументу
flags=(c m r h)

while getopts 'i:mj:hcrn:' option; do
    if [[ " ${!args_with_value[@]} " =~ " ${option} " ]]; then
        # Параметри з аргументом
        var_name=${args_with_value[$option]}
        declare "$var_name"="${OPTARG}"
    elif [[ " ${flags[@]} " =~ " ${option} " ]]; then
        # Прапорці
        case $option in
            c) csv=1 ;;
            m) module=1 ;;
            r) enable_report=1 ;;
            h) usage ;;
        esac
    else
        usage
    fi
done

# Якщо жодного аргументу не передано
[ "$#" -eq 0 ] && usage

declare -A required_vars=(
    [namespace]="Namespace not provided!"
    [jmx]="JMX jmeter project not provided!"
)

for var in "${!required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        logit "ERROR" "${required_vars[$var]}"
        usage
        # Специфічна дія для namespace
        if [ "$var" == "namespace" ] && [ -f "${PWD}/namespace_export" ]; then
            namespace=$(awk '{print $NF}' "${PWD}/namespace_export")
            logit "INFO" "Namespace set from namespace_export: ${namespace}"
        fi
    fi
done

FILE_PATH=$(find /var/jenkins_home/workspace/start_jmeter_test -name "Google_basic.jmx" | head -n 1)
jmx_dir="${jmx%%.*}"

echo "${FILE_PATH}"
echo "${jmx}"
if [ ! -f "${FILE_PATH}/${jmx}" ]; then
    logit "ERROR" "Test script file was not found in scenario/${jmx_dir}/${jmx}"
    usage
fi

# Recreating each pods
logit "INFO" "Recreating pod set"
kubectl -n "${namespace}" delete -f jmeter_m.yaml -f jmeter_s.yaml 2> /dev/null
ls -laht
kubectl -n "${namespace}" apply -f jmeter_m.yaml
kubectl -n "${namespace}" apply -f jmeter_s.yaml
# kubectl -n "${namespace}" patch job jmeter-slaves -p '{"spec":{"parallelism":0}}'
# logit "INFO" "Waiting for all slaves pods to be terminated before recreating the pod set"
# while [[ $(kubectl -n ${namespace} get pods -l jmeter_mode=slave -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "" ]]; do echo "$(kubectl -n ${namespace} get pods -l jmeter_mode=slave )" && sleep 1; done