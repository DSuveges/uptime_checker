#!/usr/bin/env bash

# This script is written to test the accessibility of ENSEMBL REST server by pinging them every hour.
# The reports are sent to cinzia and daniel

version="v.1.0"

# Get current date:
today=$(date +"%Y.%m.%d")

# Default variables:
defaultServer="rest.ensembl.org"
alternativeServer="http://ec2-54-91-140-228.compute-1.amazonaws.com:5000"
emails=""
sleep_sec=300

function display_help(){
    if [[ ! -z "${1}" ]]; then echo "$1"; fi

    echo ""
    echo "Usage:"
    echo "   ./$0 -t <target_email_list> -s <sleep_time_sec>"
    echo ""
    echo "<target_email_list> : comma separated list of email addresses. Required."
    echo "<sleep_time_sec> : time between availability check. Default: 300sec."
    echo ""
    echo "While the script is running, in sleep_time intervals, two of the REST servers"
    echo "of Ensembl is queried. If the response is slower than 5 sec, we consider the "
    echo "service 'Down'"
    exit
}

# Now these variables can be overriden by command line parameters:
OPTIND=1
while getopts ":ht:s:" optname; do
    case "$optname" in
        "t") emails=${OPTARG} ;; # Update the list of recipients.
        "s") sleep_sec=${OPTARG} ;; # Update sleep time. By default it is 30 minutes.
        "h") display_help ;;
        "?") display_help "[Error] Unknown option $OPTARG" ;;
        ":") display_help "[Error] No argument value for option $OPTARG";;
        *) display_help "[Error] Unknown error while processing options";;
    esac
done

# If no recipiends are specified, the script exits:
if [[ -z ${emails} ]]; then display_help "[Error] At least one email address has to be specified. Exiting."; fi

# Print out some report:
echo "List of recipients: $emails"
echo "Sleep time: $sleep_sec"

# now initialize an infinite loop:
while : ; do
    # ping remote:
    curl -s ${defaultServer}/info/rest?content-type=application/json --connect-timeout 5 > /dev/null
    DefaultCode="is up and running."
    if [[ "$?" != 0 ]]; then
        DefaultCode="is currently down."
    fi

    # ping rooter:
    curl -s ${alternativeServer}/info/rest?content-type=application/json --connect-timeout 5 > /dev/null
    alternativeCode="is up and running."
    if [[ "$?" != 0 ]]; then
        alternativeCode="is currently down."
    fi

    # get timestamp:
    timeStamp=$(date +"%Y/%m/%d %H:%M:%S")

    # Compiling mail:
    echo -e "Reporing on the availability of the REST servers of Ensembl

Timestamp: ${timeStamp}
Default server (${defaultServer}): ${DefaultCode}
Alternative server (${alternativeServer}): ${alternativeCode}

See you in a while!
By!

" | mutt -s "[Uptime_report] $timeStamp" $emails

    # Wait for the next ping:
    sleep ${sleep_sec}
done