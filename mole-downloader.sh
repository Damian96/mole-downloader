#!/bin/bash

# Enable Debugging Mode
# set -x;

# Initialize Global Variables
UN="";
PW="";
TEMP="temp_mole-downloader";
COOKIES="$TEMP/cookies.txt";
LOGINDATA="$TEMP/login.txt";
COURSES="$TEMP/course-list.txt";
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php";
LOGINCHECK="My course list";
DOWNLOAD="https://mole.citycollege.sheffield.eu/claroline/document/document.php";
declare -A COURSELIST;
DESKTOP="$TEMP/desktop.html";

_trapCmd() {
    trap 'kill -TERM $PID; exit 130;' TERM
    eval "$1" &
    PID=$!
    wait $PID
}

getLoginData() {

    while [[ true ]]; do

        while [[ true ]]; do
            printf "\n%s" "Please enter your mole.citycollege.sheffield.eu username: ";
            read -r UN;

            if [[ `expr "$UN" : '[a-z]*'` == 0 ]]; then
                printf "\n%s" "Invalid username.";
            else
                break;
            fi
        done

        while [[ true ]]; do
            printf "\n%s" "Please enter your mole.citycollege.sheffield.eu password: ";
            read -r -s PW;

            if [[ -z "${PW// }" ]]; then
                continue;
            elif [[ `expr "$PW" : '[0-9]{3}[a-z]3[0-9]{3}'` != 0 ]]; then
                printf "\n%s" "Invalid password.";
                continue;
            else
                break;
            fi
        done

        # Auth and create cookie jar
        _trapCmd "curl --silent -c \"$COOKIES\" -d \"login=$UN&password=$PW\" -X POST $LOGIN -L --post302 2>&1 | grep -q \"$LOGINCHECK\"";

        if [[ $? == 0 ]]; then #LOGIN SUCCEDED
            printf "\n%s\n%s" "Successfull login." "Stored login data.";
            printf '%s\n' "$UN" "$PW" > "$LOGINDATA";
            break;
        else
            printf "\n%s\n" "Invalid username / password.";
        fi

    done
}

readLoginData() {
    local COUNT=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ "$COUNT" == 0 ]]; then
            UN=$line;
            ((COUNT++));
        elif [[ "$COUNT" == 1 ]]; then
            PW=$line;
        fi
    done < "$LOGINDATA"

    # Auth and create cookie jar
    _trapCmd "curl --silent -c \"$COOKIES\" -d \"login=$UN&password=$PW\" -X POST $LOGIN -L --post302 2>&1 | grep -q \"$LOGINCHECK\"";

    if [[ $? != 0 ]]; then #LOGIN DIDNT SUCCEED
        printf "\n%s" "Incorrect username / password.";
        getLoginData;
    fi
}

getCourseList() {
    printf "\n%s\n" "Retrieving desktop...";
    _trapCmd "curl --silent -c \"$COOKIES\" -d \"login=$UN&password=$PW\" -X POST \"$LOGIN\" -L --post302 -o \"$DESKTOP\"";

    local INDEX=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do
        local CODE_PATT=".*\?cid=(.*)\">.*";
        local TITLE_PATT=".*\?cid=.*\">(.*)<\/a>";

        if [[ $line =~ $CODE_PATT ]]; then
            local CODE=${BASH_REMATCH[1]};
            if [[ $line =~ $TITLE_PATT ]]; then
                local TITLE=${BASH_REMATCH[1]};
                COURSELIST[$CODE]=$TITLE;
            fi
        fi

    done < $DESKTOP

    for C in "${!COURSELIST[@]}"; do
        printf "%s,%s\n" "$C" "${COURSELIST[$C]}";
    done > $COURSES
}

readCourseList() {
    while IFS='' read -r line || [[ -n "$line" ]]; do

        if [[ ! -z "${line// }" ]]; then
            local PARTS;
            IFS=',' read -ra PARTS <<< "$line"
            COURSELIST[${PARTS[0]}]=${PARTS[1]};
            IFS='';
        fi

    done < $COURSES
}

downloadCourse() {
    FILENAME="${COURSELIST[$CID]}.zip";
    FILENAME="${FILENAME/\//-}";
    FILENAME="./${FILENAME}";

    printf "\n%s\n" "Downloading '${COURSELIST[$CID]}' into $FILENAME...";

    _trapCmd "curl --silent --output \"$FILENAME\" -b \"$COOKIES\" -d \"cmd=exDownload&file=&cidReset=true&cidReq=$CID\" -G $DOWNLOAD";

    if [[ $? == 0 ]]; then
        printf "\n%s" "Downloaded @ $FILENAME";
    else
        printf "\n%s" "Something went wrong while downloading course $CID.";
    fi
}

# Initialization
if [[ ! -d "$TEMP" ]]; then # Temp folder does not exist
    printf "%s\n" "Creating data folder..." ;
    printf "%s\n" "Make sure you delete the '$TEMP' folder when you are done!";
    mkdir "$TEMP";
fi

if [[ ! -a "$LOGINDATA" ]]; then # Login Data do not exist
    getLoginData;
else
    printf "\n%s" "Reading login credentials...";
    readLoginData;
fi

if [[ ! -a "$COURSES" ]]; then # Login Data do not exist
    printf "\n%s\n" "Retrieving course list...";
    getCourseList;
else
    printf "\n%s\n" "Reading course list...";
    readCourseList;
fi

while [[ true ]]; do
    printf "\n\n%s" "Mole's Course List:";

    for C in "${!COURSELIST[@]}"; do
        if [[ "${#C}" -ge 7 ]]; then
            printf "\n%s:\t%s" "$C" "${COURSELIST[$C]}";
        else
            printf "\n%s:\t\t%s" "$C" "${COURSELIST[$C]}";
        fi;
    done

    printf "\n\n%s" "If you don't see a course you have enrolled on the list, insert 'r' or 'R' to refresh.";
    printf "\n%s" "Insert 'q' or 'Q' to exit.";
    printf "\n%s" "Insert 'a' or 'A' to download all courses.";
    printf "\n%s" "Download multiple courses by inserting the course codes seperated by spaces."
    printf "\n%s" "Please insert the course code(s): ";
    read -r CID;

    printf "\n%s\n" "Make sure you delete the '$TEMP' folder when you are done!";

    if [[ "$CID" == "q" || "$CID" == "Q" ]]; then
        printf "\n%s\n" "Bye!";
        break;
    elif [[ "$CID" == "a" || "$CID" == "A" ]]; then
        for C in "${!COURSELIST[@]}"; do
            CID=$C;
            downloadCourse;
        done
    elif [[ "$CID" == "r" || "$CID" == "R" ]]; then
        getCourseList;
    elif [[ $CID = *" "* ]]; then
        IFS=' ' read -r -a MCID <<< "$CID"

        for C in  "${MCID[@]}"; do
            if [[ ${COURSELIST[$C]} ]]; then
                CID=$C;
                downloadCourse;
            else
                printf "\n%s" "Invalid course id \"$C\", skipping...";
            fi
        done
    elif [[ ! ${COURSELIST[$CID]} ]]; then
        printf "\n%s" "Invalid course code.";
    else
        downloadCourse;
    fi
done

# Disable Debugging mode
# set +x;

# Unset Global Variables
unset UN;
unset PW;
unset LOGIN;
unset TEMP;
unset COOKIES;
unset LOGINDATA;
unset LOGINCHECK;
unset COURSES;
unset DOWNLOAD;
unset COURSELIST;
unset C;
unset DESKTOP;
unset FILENAME;
unset CID;

unset readLoginData;
unset getLoginData;
unset readCourseList;
unset getCourseList;

exit 0;
