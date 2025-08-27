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

FILE_PATH=$(find /var/jenkins_home/workspace/start_jmeter_test -name "${jmx}" | head -n 1)

if [ ! -f "${FILE_PATH}" ]; then
    logit "ERROR" "Test script file was not found in scenario/${jmx_dir}/${jmx}"
    usage
fi

# Recreating each pods
logit "INFO" "Recreating pod set"
kubectl -n "${namespace}" delete -f jmeter_m.yaml -f jmeter_s.yaml 2> /dev/null
ls -laht
kubectl -n "${namespace}" apply -f jmeter_m.yaml
while [[ $(kubectl -n ${namespace} get pods -l jmeter_mode=master -o 'jsonpath={.items[0].status.phase}') != "Running" ]]; do
  echo "Master pod is not ready yet..."
  kubectl -n ${namespace} get pods -l jmeter_mode=master -o wide
  sleep 2
done

echo "✅ Master pod is running:"
kubectl -n ${namespace} get pods -l jmeter_mode=master -o wide
kubectl -n "${namespace}" apply -f jmeter_s.yaml
kubectl -n "${namespace}" patch job jmeter-slaves -p '{"spec":{"parallelism":0}}'
logit "INFO" "Waiting for all slaves pods to be terminated before recreating the pod set"
while [[ $(kubectl -n ${namespace} get pods -l jmeter_mode=slave -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "" ]]; do echo "$(kubectl -n ${namespace} get pods -l jmeter_mode=slave )" && sleep 1; done


# Starting jmeter slave pod 
if [ -z "${nb_injectors}" ]; then
    logit "WARNING" "Keeping number of injector to 1"
    kubectl -n "${namespace}" patch job jmeter-slaves -p '{"spec":{"parallelism":1}}'
else
    logit "INFO" "Scaling the number of pods to ${nb_injectors}. "
    kubectl -n "${namespace}" patch job jmeter-slaves -p '{"spec":{"parallelism":'${nb_injectors}'}}'
    logit "INFO" "Waiting for pods to be ready"

    end=${nb_injectors}
    for ((i=1; i<=end; i++))
    do
        validation_string=${validation_string}"True"
    done

    while [[ $(kubectl -n ${namespace} get pods -l jmeter_mode=slave -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | sed 's/ //g') != "${validation_string}" ]]; do echo "$(kubectl -n ${namespace} get pods -l jmeter_mode=slave )" && sleep 1; done
    logit "INFO" "Finish scaling the number of pods."
fi


master_pod=$(kubectl get pod -n "${namespace}" | grep jmeter-master | awk '{print $1}')
logit "INFO" "master_pod is ${master_pod}"

slave_pods=($(kubectl get pods -n "${namespace}" | grep jmeter-slave | grep Running | awk '{print $1}'))
slave_num=${#slave_pods[@]}
slave_digit="${#slave_num}"

# jmeter directory in pods
JMETER_DIR=$(kubectl exec -n "${namespace}" -c jmmaster "${master_pod}" -- sh -c "find /opt -maxdepth 1 -type d -name 'apache-jmeter*' | head -n1")
logit "INFO" "Copying ${FILE_PATH} into ${master_pod}"

for ((i=0; i<end; i++))
do
    logit "INFO" "Copying scenario/${jmx_dir}/${jmx} to ${slave_pods[$i]}"
    kubectl cp -c jmslave "${FILE_PATH}" -n "${namespace}" "${slave_pods[$i]}:${JMETER_DIR}/bin/" &
done # for i in "${slave_pods[@]}"

kubectl cp -c jmmaster "${FILE_PATH}" -n "${namespace}" "${master_pod}:${JMETER_DIR}/bin/"

{
    echo "cd ${JMETER_DIR}"
    echo "sh PluginsManagerCMD.sh install-for-jmx ${jmx} > plugins-install.out 2> plugins-install.err"
    echo "jmeter-server -Dserver.rmi.localport=50000 -Dserver_port=1099 -Jserver.rmi.ssl.disable=true >> jmeter-injector.out 2>> jmeter-injector.err &"
    echo "trap 'kill -10 1' EXIT INT TERM"
    #echo "java -jar /opt/jmeter/apache-jmeter/lib/jolokia-java-agent.jar start JMeter >> jmeter-injector.out 2>> jmeter-injector.err"
    echo "wait"
} > "jmeter_injector_start.sh"

INJ_PATH=$(find /var/jenkins_home/workspace/start_jmeter_test -name "jmeter_injector_start.sh" | head -n 1)
logit "INFO" "Installing needed plugins on slave pods"

if [ -n "${csv}" ]; then
    logit "INFO" "Splitting and uploading csv to pods"
    dataset_dir="./data"

    for csvfilefull in "${dataset_dir}"/*.csv; do
        csvfile="${csvfilefull##*/}"
        logit "INFO" "Processing file: $csvfile"
        
        lines_total=$(wc -l < "${csvfilefull}")
        lines_per_split=$(( (lines_total + slave_num - 1) / slave_num ))  # округлення вгору
        logit "INFO" "Splitting ${csvfile} into $slave_num parts, $lines_per_split lines each"

        split --suffix-length="${slave_digit}" -d -l "$lines_per_split" "${csvfilefull}" "${csvfilefull}."

        for ((i=0; i<slave_num; i++)); do
            j=$(printf "%0${slave_digit}d" "$i")
            split_file="${csvfilefull}.${j}"
            logit "INFO" "Copying ${split_file} to ${slave_pods[$i]}:${jmeter_directory}/${csvfile}"
            kubectl -n "${namespace}" cp -c jmslave "$split_file" "${slave_pods[$i]}":"${JMETER_DIR}/${csvfile}" &
        done
    done
    wait
    logit "INFO" "Finished uploading CSV files to all slaves"
fi

wait

for ((i=0; i<end; i++))
do
        logit "INFO" "Starting jmeter server on ${slave_pods[$i]} in parallel"
        kubectl cp -c jmslave "${INJ_PATH}" -n "${namespace}" "${slave_pods[$i]}:${JMETER_DIR}"
        kubectl exec -c jmslave -i -n "${namespace}" "${slave_pods[$i]}" -- //bin/bash "${JMETER_DIR}/jmeter_injector_start.sh" &  
done

slave_list=$(kubectl -n ${namespace} get endpoints jmeter-slaves-svc -o jsonpath='{.subsets[*].addresses[*].ip}')
echo $slave_list

if [ -n "${enable_report}" ]; then
    report_command_line="--reportatendofloadtests --reportoutputfolder /report/report-${jmx}-$(date +"%F_%H%M%S")"
fi

echo "slave_array=(${slave_array[@]}); index=${slave_num} && while [ \${index} -gt 0 ]; do for slave in \${slave_array[@]}; do if echo 'test open port' 2>/dev/null > /dev/tcp/\${slave}/1099; then echo \${slave}' ready' && slave_array=(\${slave_array[@]/\${slave}/}); index=\$((index-1)); else echo \${slave}' not ready'; fi; done; echo 'Waiting for slave readiness'; sleep 2; done" > "scenario/${jmx_dir}/load_test.sh"

cat <<EOF >> "load_test.sh"
echo "Installing needed plugins for master"
cd /opt/jmeter/apache-jmeter/bin

jmeter ${param_host} ${param_user} ${report_command_line} \
  --logfile /jmeter/${jmx}_\$(date +"%F_%H%M%S").csv \
  --nongui --testfile ${jmx} \
  -Dserver.rmi.ssl.disable=true --remoteexit --remotestart ${slave_list} \
  >> jmeter-master.out 2>> jmeter-master.err &

trap 'kill -10 1' EXIT INT TERM
wait
EOF

LOAD_TEST_PATH=$(find /var/jenkins_home/workspace/start_jmeter_test -name "load_test.sh" | head -n 1)

logit "INFO" "Copying ${INJ_PATH} into  ${master_pod}:${JMETER_DIR}/load_test.sh"
kubectl cp -c jmmaster "${INJ_PATH}" -n "${namespace}" "${master_pod}:${JMETER_DIR}/load_test.sh"
kubectl exec -c jmmaster -i -n "${namespace}" "${master_pod}" -- //bin/bash "${JMETER_DIR}/load_test.sh" &

logit "INFO" "Starting the performance test"
logit "INFO" "${namespace} ${master_pod}"
