#!/bin/sh

# Enable Debugging Mode
# set -x;

# Initialize Global Variables
UN="";
PW="";
TEMP="mole-downloader_temp";
COOKIES="$TEMP/cookies.txt";
LOGINDATA="$TEMP/login.txt";
COURSES="$TEMP/course-list.txt";
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php";
LOGINCHECK="My course list";
DOWNLOAD="https://mole.citycollege.sheffield.eu/claroline/document/document.php";
declare -A COURSELIST;
DESKTOP="$TEMP/desktop.html";

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
            else
                break;
            fi
        done

        # Auth and create cookie jar
        curl --silent -c "$COOKIES" -d "login=$UN&password=$PW" -X POST $LOGIN -L --post302 2>&1 | grep -q "$LOGINCHECK";

        if [[ $? == 0 ]]; then #LOGIN SUCCEDED
            printf '%s\n' "$UN" "$PW" > "$LOGINDATA";
            break;
        else
            printf "\n%s\n" "Invalid username / password.";
        fi;

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
    curl --silent -c "$COOKIES" -d "login=$UN&password=$PW" -X POST $LOGIN -L --post302 2>&1 | grep -q "$LOGINCHECK";

    if [[ $? != 0 ]]; then #LOGIN DIDNT SUCCEED
        printf "\n%s" "Incorrect login data.";
        getLoginData;
    fi;
}

getCourseList() {
    if [[ ! -a "$DESKTOP" ]]; then
        printf "\n%s\n" "Retrieving desktop...";
        curl --silent -c "$COOKIES" -d "login=$UN&password=$PW" -X POST "$LOGIN" -L --post302 -o "$DESKTOP";
    else
        printf "\n%s\n" "Reading desktop...";
    fi

    local INDEX=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do
        local CODE_PATT=".*\?cid=(.*)\">.*";
        local TITLE_PATT=".*\?cid=.*\">(.*)<\/a>";

        if [[ $line =~ $CODE_PATT ]]; then
            local CODE=${BASH_REMATCH[1]};
            if [[ $line =~ $TITLE_PATT ]]; then
                local TITLE=${BASH_REMATCH[1]};
                # printf "\ncode:%s" "$CODE";
                # printf "\ntitle:%s" "$TITLE";
                COURSELIST[$CODE]=$TITLE;
            fi
        fi

    done < $DESKTOP

    for C in "${!COURSELIST[@]}"; do
        printf "%s,%s\n" "$C" "${COURSELIST[$C]}";
    done > $COURSES
}

readCourseList() {
    local KEY;
    local VALUE;
    while IFS='' read -r line || [[ -n "$line" ]]; do

        if [[ ! -z "${line// }" ]]; then
            while IFS='' read -r line || [[ -n "$line" ]]; do

            done <<< "$line"
            COURSELIST[INDEX++]=$line;
        fi

    done < $COURSES
}

# Initialization
if [[ ! -d "$TEMP" ]]; then # Temp folder does not exist
    printf "%s\n" "Creating data folder..." ;
    mkdir "$TEMP";
fi

if [[ ! -a "$LOGINDATA" ]]; then # Login Data do not exist
    getLoginData;
else
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
        printf "\n%s: %s" "$C" "${COURSELIST[$C]}"
    done

    printf "\n\n%s" "Insert 'q' or 'Q' to exit.";
    printf "\n%s" "Please insert the course code: ";
    read -r CID;

    if [[ "$CID" == "q" || "$CID" == "Q" ]]; then
        printf "\n%s" "Make sure you delete the ./moleDownloader folder when you are done!";
        printf "\n%s\n" "Bye!";
        exit 0;
    elif [[ ! ${COURSELIST[$CID]} ]]; then
        printf "\n%s" "Invalid course code.";
    else
        FILENAME="./MOLE.$CID.complete.zip";
        printf "\n%s\n" "Downloading $CID into $FILENAME...";
        curl --silent --output "$FILENAME" -b "$COOKIES" -d "cmd=exDownload&file=&cidReset=true&cidReq=$CID" -G $DOWNLOAD;
        printf "\n%s" "Downloaded @ $FILENAME";
    fi
done

# Disable Debugging mode
# set +x;

# Unset Global Variables
unset UN;
unset PW;
unset COURSES;
unset LOGINDATA;
unset LOGIN;
unset LOGINCHECK;
unset DOWNLOAD;
unset COURSELIST;
unset DESKTOP;
unset FILENAME;
unset CID;

unset readLoginData;
unset getLoginData;
unset readCourseList;
unset getCourseList;

exit 0;