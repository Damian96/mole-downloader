#!/bin/bash

# Enable Debugging Mode
# set -x

moledUnset() {
    unset UN
    unset PW
    unset LOGIN
    unset TEMP
    unset COOKIES
    unset LOGINCHECK
    unset COURSES
    unset DOWNLOAD
    unset COURSELIST
    unset C
    unset DESKTOP
    unset FILENAME
    unset CID

    unset readLoginData
    unset readCourseList
    unset getCourseList
}

printf "%s\n" "  ___ _  _ _____ ___ ___ _  _   _ _____ ___ ___  _  _   _   _    
 |_ _| \| |_   _| __| _ \ \| | /_\_   _|_ _/ _ \| \| | /_\ | |   
  | || .\` | | | | _||   / .\` |/ _ \| |  | | (_) | .\` |/ _ \| |__ 
 |___|_|\_|_|_| |___|_|_\_|\_/_/ \_\_| |___\___/|_|\_/_/ \_\____|
 | __/_\ / __| | | | ||_   _\ \ / /                              
 | _/ _ \ (__| |_| | |__| |  \ V /                               
 |_/_/_\_\___|\___/|____|_|   |_|                                
 |  \/  |/ _ \| |  | __|                                         
 | |\/| | (_) | |__| _|                                          
 |_|  |_|\___/|____|___|                                         "

# Initialize Global Variables
UN=""
PW=""
TEMP="temp_mole-downloader"
COOKIES="$TEMP/cookies.txt"
COURSES="$TEMP/course-list.txt"
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php"
LOGINCHECK="My course list"
DOWNLOAD="https://mole.citycollege.sheffield.eu/claroline/document/document.php"
declare -A COURSELIST
DESKTOP="$TEMP/desktop.html"

_trapCmd() {
    trap 'kill -TERM $PID; moledUnset; exit 130;' TERM
    eval "$1" &
    PID=$!
    wait $PID
}

getLoginData() {
    while [[ true ]]; do
        while [[ true ]]; do
            printf "\n%s" "Please enter your mole.citycollege.sheffield.eu username: "
            read -r UN

            if [[ `expr "$UN" : '[a-z]*'` == 0 ]]; then
                printf "\n%s" "Invalid username."
            else
                break
            fi
        done

        while [[ true ]]; do
            printf "\n%s\n%s" "Please enter your mole.citycollege.sheffield.eu password:" "(will not be echoed):"
            read -r -s PW

            REGEX="^[[:digit:]]{3}[[:lower:]]{3}[[:digit:]]{3}$"
            PW="${PW//[[:space:]]/}"
            if ([[ ! -z "$PW" ]] && [[ $PW =~ $REGEX ]]); then
                break
            else
                printf "\n%s" "Invalid password."
                continue
            fi
        done

        # Auth and create cookie jar
        _trapCmd "curl --silent -c \"$COOKIES\" -d \"login=$UN&password=$PW\" -X POST $LOGIN -L --post302 2>&1 | grep -q \"$LOGINCHECK\""

        if [[ $? == 0 ]]; then #LOGIN SUCCEDED
            printf "\n%s\n%s" "Successfull login." "Stored login data."
            break
        else
            printf "\n\n%s\n" "Could not authenticate."
            printf "%s\n" "Invalid username / password"
        fi
    done
}

getCourseList() {
    printf "\n%s\n" "Retrieving course list..."
    _trapCmd "curl --silent -c \"$COOKIES\" -d \"login=$UN&password=$PW\" -X POST \"$LOGIN\" -L --post302 -o \"$DESKTOP\""

    local INDEX=0
    while IFS='' read -r line || [[ -n "$line" ]]; do
        local CODE_PATT=".*\?cid=(.*)\">.*"
        local TITLE_PATT=".*\?cid=.*\">(.*)<\/a>"

        if [[ $line =~ $CODE_PATT ]]; then
            local CODE=${BASH_REMATCH[1]}
            if [[ $line =~ $TITLE_PATT ]]; then
                local TITLE=${BASH_REMATCH[1]}
                COURSELIST[$CODE]=$TITLE
            fi
        fi
    done < $DESKTOP

    for C in "${!COURSELIST[@]}"; do
        printf "%s,%s\n" "$C" "${COURSELIST[$C]}"
    done > $COURSES
}

readCourseList() {
    printf "\n%s\n" "Reading course list..."
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ ! -z "${line// }" ]]; then
            local PARTS
            IFS=',' read -ra PARTS <<< "$line"
            COURSELIST[${PARTS[0]}]=${PARTS[1]}
            IFS=''
        fi
    done < $COURSES
}

downloadCourse() {
    FILENAME="./${COURSELIST[$CID]/\//-}.zip"

    printf "\n%s\n" "Downloading '${COURSELIST[$CID]}' into $FILENAME..."

    _trapCmd "curl --silent --output \"$FILENAME\" -b \"$COOKIES\" -d \"cmd=exDownload&file=&cidReset=true&cidReq=$CID\" -G $DOWNLOAD"

    if [[ $? == 0 ]]; then
        printf "\n%s\n" "Downloaded @ $FILENAME"
    else
        printf "\n%s\n" "Something went wrong while downloading course $CID."
    fi
}

# Initialization
if ! [ -x "$(command -v curl)" ]; then
    printf "\n%s" "Error: Package \"curl\" doesn't exist"
    moledUnset
    exit 126
fi

if [[ ! -d "$TEMP" ]]; then # Temp folder does not exist
    printf "%s\n" "Creating data folder..." 
    printf "%s\n" "Make sure you delete the '$TEMP' folder when you are done!"
    mkdir "$TEMP"
fi

getLoginData # GET LOGIN DATA

if [[ ! -a "$COURSES" ]]; then # COURSE DATA do not exist
    getCourseList
else
    readCourseList
fi

while [[ true ]]; do
    printf "\n%s" "Mole's Course List:"

    for C in "${!COURSELIST[@]}"; do
        if [[ "${#C}" -gt 7 ]]; then
            printf "\n\e[94m%s\e[0m\t%s" "$C" "${COURSELIST[$C]}"
        else
            printf "\n\e[94m%s\e[0m\t\t%s" "$C" "${COURSELIST[$C]}"
        fi
    done

    printf "\n%s" "[A/a]ll"
    printf "\n%s" "Multiple: CCPA, CCPB, ..., CCPZ"
    printf "\n\n%s" "[R/r]efresh"
    printf "\n%s" "[Q/q]uit"
    printf "\n%s" "Please insert the command / code(s):"
    read -r CID

    printf "\n%s\n" "Make sure you delete the '$TEMP' folder when you are done!"

    if [[ "$CID" == "q" || "$CID" == "Q" ]]; then
        printf "\n%s\n" "Bye!"
        break
    elif [[ "$CID" == "a" || "$CID" == "A" ]]; then
        for C in "${!COURSELIST[@]}"; do
            CID=$C
            downloadCourse
        done
    elif [[ "$CID" == "r" || "$CID" == "R" ]]; then
        getCourseList
    elif [[ $CID = *" "* ]]; then
        IFS=' ' read -r -a MCID <<< "$CID"

        for C in  "${MCID[@]}"; do
            if [[ ${COURSELIST[$C]} ]]; then
                CID=$C
                downloadCourse
            else
                printf "\n%s" "Invalid course id \"$C\", skipping..."
            fi
        done
    elif [[ ! ${COURSELIST[$CID]} ]]; then
        printf "\n%s" "Invalid course code."
    else
        downloadCourse
    fi
done

# Disable Debugging mode
# set +x

# Unset Global Variables
moledUnset
exit 0
