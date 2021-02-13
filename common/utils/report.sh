 #!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf '

  Example: 
    $ source report.sh
    $ report_setfile "/tmp/report"
    $ report_append "hello"
    $ report_produce 
    > hello    
    $ report_clear
    $ report_produce 
    > 
'
exit 0
fi

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi

#
#  Reporting helper
#
report_file="/tmp/report.txt"

function report_setfile () {
    local new_report_file="$1"
    printf "Report.into $new_report_file\n"
    report_file="$new_report_file"
}

function report_append () {
    local content="$1"
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    printf "$1" >> "$report_file"
}

function report_produce () {
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    cat "$report_file"
}

function report_clear () {
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    printf "" > "$report_file"
}
