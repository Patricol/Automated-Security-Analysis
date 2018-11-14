#!/bin/bash
#Patrick Collins (Patricol)

cd "${0%/*}"
touch ./out.txt

check_invocations () {
    #given filename and line of function
    LINE="$(sed -n ${2},${2}p ${1})"rm
    FUNCTION_NAME="$(echo ${LINE} | grep -Po '(?<= )(\S*?)(?=\))')"
    ESCAPED_FUNCTION_NAME="$(printf "%q" "${FUNCTION_NAME})")"
    TRIMMED_FILENAME="${1:8:${#1}-14}"
    ESCAPED_TRIMMED_FILENAME="$(printf "%q" "${TRIMMED_FILENAME}")"
    grep -rnP "L${ESCAPED_TRIMMED_FILENAME}"'\;->'"${ESCAPED_FUNCTION_NAME}" ./smali/
    grep -rnP "L${ESCAPED_TRIMMED_FILENAME}"'\;-><init>' ./smali/
}

get_context_start () {
    grep -nP "^.${3}" ${1} | awk -v mid_function=${2} -v start=0 '{if($1>start && $1<=mid_function){start=$1}}END{print start} ' FS=":"
}

get_context_end () {
    grep -nP "^.end ${3}$" ${1} | awk -v mid_function=${2} -v end=999999999 '{if($1<end && $1>=mid_function){end=$1}}END{print end} ' FS=":"
}

print_context_around_line () {
    #give it a file and the number of a line that is a part of the function you want to print.
    CONTEXT_START="$(get_context_start ${1} ${2} "method")"
    CONTEXT_END="$(get_context_end ${1} ${2} "method")"
    if [[ ${CONTEXT_START} == 0 || ${CONTEXT_END} == 999999999 ]]; then
        CONTEXT_START="$(get_context_start ${1} ${2} "annotation")"
        CONTEXT_END="$(get_context_end ${1} ${2} "annotation")"
        if [[ ${CONTEXT_START} == 0 || ${CONTEXT_END} == 999999999 ]]; then
            CONTEXT_START="$(get_context_start ${1} ${2} "field")"
            CONTEXT_END="$(get_context_end ${1} ${2} "field")"
            if [[ ${CONTEXT_START} == 0 || ${CONTEXT_END} == 999999999 ]]; then
                CONTEXT_START=$2
                CONTEXT_END=$2
            fi
        fi
    fi
    echo ${1}
    echo "Invocations:"
    check_invocations ${1} ${CONTEXT_START}
    echo "Context Starts: Line: ${CONTEXT_START}"
    echo "Issue:          Line: ${2}"
    echo "Context:"
    CURRENT_LINE=${CONTEXT_START}
    sed -n ${CONTEXT_START},${CONTEXT_END}p ${1} | while read -r line; do
        # TODO: Simplify this later.
        DIFF="$((${2}-${CURRENT_LINE}))"

        if [ ${CURRENT_LINE} -eq ${CONTEXT_START} ]; then # First Line
            echo -e ${CURRENT_LINE}"\t" ${line}
        elif [ ${CURRENT_LINE} -eq ${2} ]; then # Target Line
            echo "*****ISSUE*****"
            echo -e ${CURRENT_LINE}"\t" ${line}
            echo "*****ISSUE*****"
        elif [ ${DIFF#-} -lt 30 ]; then # Within 30
            echo -e ${CURRENT_LINE}"\t" ${line}
        fi
        CURRENT_LINE=$((CURRENT_LINE + 1))
    done
    echo ""
}

check_for_string () {
    grep -nF "${2}" ${1} | awk '{print $1}' FS=":" | while read -r line; do
        echo "Worrisome String: ${2}"
        print_context_around_line ${1} ${line}
    done
}

doesnt_invoke () {
    #given filename and line number of function
    grep -nF 'invoke' ${1} | awk '{print $1}' FS=":" | while read -r line; do
        FUNCTION_START="$(get_context_start ${1} ${line} "method")"
        if [[ ${FUNCTION_START} == ${2} ]]; then echo "found"; fi
    done
}

check_for_deadend_function () {
    #given file and name of function
    grep -nF ".method public ${2}(" ${1} | awk '{print $1}' FS=":" | while read -r line; do
        FOUND="$(doesnt_invoke ${1} ${line})"
        if [[ ${FOUND} == "" ]]; then print_context_around_line ${1} ${line}; fi
    done
}

worrisome_strings=("SslErrorHandler;->proceed()V" "AllowAll" "trustAll" "ALLOW_ALL_HOSTNAME_VERIFIER")
potentially_unimplemented_functions=("checkClientTrusted" "checkServerTrusted" "verify")

check_file () {
    for i in ${worrisome_strings[@]}; do check_for_string ${1} ${i} >> out.txt; done
    for i in ${potentially_unimplemented_functions[@]}; do check_for_deadend_function ${1} ${i} >> out.txt; done
}

#Speeds up runtime; excluding libraries from trustable sources.
assumed_secure_paths=(./smali/android/support ./smali/com/google ./smali/org/apache ./smali/com/github
                      ./smali/com/facebook ./smali/com/crashlytics ./smali/net/sourceforge ./smali/com/nokia)

#some of these files have $1 etc. in their name, need to enclose them in {} when used.
check_ssl () {
    for D in `find ./smali/ -maxdepth 2 -mindepth 2 -type d`; do
        if ! [[ ./smali/${assumed_secure_paths[*]} =~ "$D" ]]; then
            for F in `find ${D} -type f`; do check_file ${F}; done
        fi
    done
}

#afaik, apktool exports manifests in exactly that format; no need to check for different spacing or if split into multiple lines etc.
check_manifest () {
    if grep -qF '<uses-permission android:name="android.permission.INTERNET"/>' ${1}; then
        if grep -qF '<uses-permission android:name="android.permission.RECORD_AUDIO"/>' ${1}; then echo 'Manifest Uses Internet & Microphone'; fi
        if grep -qF '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>' ${1}; then echo 'Manifest Uses Internet & Fine Location'; fi
        if grep -qF '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>' ${1}; then echo 'Manifest Uses Internet & Coarse Location'; fi
        if grep -qF '<uses-permission android:name="android.permission.CAMERA"/>' ${1}; then echo 'Manifest Uses Internet & Camera'; fi
    fi
}
check_manifests () {
    for F in `find ./ -maxdepth 1 -mindepth 1 -type f -name 'AndroidManifest.xml'`; do check_manifest ${F} >> out.txt; done
}



trim_action () {
    if ! [[ ${1} == "<action" ]]; then
        TRIMMED="${1:13:${#1}-15}"
        if ! [[ ${TRIMMED} == "" ]]; then
            if ! [[ ${TRIMMED} == android* ]]; then
                # echo ${1}
                echo ${TRIMMED}
            fi
        fi
    fi
}

get_actions () {
    for LINE in `grep '<action android:name=\S*/>' ${1} | xargs -L 1 | sort -u`; do
    trim_action ${LINE}; done
}


starts_activity_or_broadcast () {
    #given filename and line number of function
    grep -nF '>startActivity(' ${1} | awk '{print $1}' FS=":" | while read -r line; do
        FUNCTION_START="$(get_context_start ${1} ${line} "method")"
        if [[ ${FUNCTION_START} == ${2} ]]; then echo "found"; fi
    done
    grep -nF '>sendBroadcast(' ${1} | awk '{print $1}' FS=":" | while read -r line; do
        FUNCTION_START="$(get_context_start ${1} ${line} "method")"
        if [[ ${FUNCTION_START} == ${2} ]]; then echo "found"; fi
    done
}

check_for_activity_started_with_intent () {
    #given file and intent action
    grep -nF "\"${2}\"" ${1} | awk '{print $1}' FS=":" | while read -r line; do
        FUNCTION_START="$(get_context_start ${1} ${line} "method")"
        FOUND="$(starts_activity_or_broadcast ${1} ${FUNCTION_START})"
        if [[ ${FOUND} != "" ]]; then
            echo "Intent Action String: ${2}"
            print_context_around_line ${1} ${line}
        fi
    done
}



check_intents () {
    for M in `find ./ -maxdepth 1 -mindepth 1 -type f -name 'AndroidManifest.xml'`; do
        ACTIONS=$(get_actions ${M})
        for D in `find ./smali/ -maxdepth 2 -mindepth 2 -type d`; do
            if ! [[ ./smali/${assumed_secure_paths[*]} =~ "$D" ]]; then
                for F in `find ${D} -type f`; do
                    for ACTION in ${ACTIONS}; do
                        check_for_activity_started_with_intent ${F} ${ACTION} >> out.txt
                    done
                done
            fi
        done
    done
}


check_manifests
check_ssl
check_intents
