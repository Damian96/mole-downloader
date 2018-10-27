#!/bin/sh

# Enable Debugging Mode
# set -x;

# Initialize Global Variables
UN="";
PW="";
TEMP="moleDownloader";
COOKIES="$TEMP/cookies.txt";
LOGINDATA="$TEMP/login.txt";
COURSES="$TEMP/course-list.txt";
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php";
LOGINCHECK="My course list";
DOWNLOAD="https://mole.citycollege.sheffield.eu/claroline/document/document.php";
COURSELIST=("${@}");
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
    curl --silent -c "$COOKIES" -d "login=$UN&password=$PW" -X POST "$LOGIN" -L --post302 -o "$DESKTOP";

    local INDEX=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do
        local TEMP=`echo $line | grep -Po "(?<=\?cid\=)(CCP[0-9]{4})"`;

        if [[ ! -z "${TEMP// }" ]]; then
            COURSELIST[INDEX++]=$TEMP;
        fi;

    done < $DESKTOP

    for i in "${COURSELIST[@]}"; do
        printf "%s\n" "$i" ;
    done > $COURSES
}

readCourseList() {
    local INDEX=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do

        if [[ ! -z "${line// }" ]]; then
            COURSELIST[INDEX++]=$line;
        fi;

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
    printf "%s" "Retrieving course list...";
    getCourseList;
else
    printf "%s" "Reading course list...";
    readCourseList;
fi

while [[ true ]]; do
    printf "\n\n%s" "Mole's Course List:";
    for i in "${COURSELIST[@]}"; do
        printf "\n%s" "$i";
    done

    printf "\n\n%s" "Insert 'q' or 'Q' to exit.";
    printf "\n%s" "Please insert the course code: ";
    read -r CID;

    if [[ "$CID" == "q" || "$CID" == "Q" ]]; then
        printf "\n%s\n" "Bye!";
        return 0;
    elif [[ `expr "$CID" : 'CCP[0-9]\{4\}'` == 0 ]]; then
        printf "\n%s" "Invalid course code.";
    else
        FILENAME="./MOLE.$CID.complete.zip";
        printf "\n%s\n" "Downloading $CID into $FILENAME...";
        curl --silent --output "$FILENAME" -b "$COOKIES" -d "cmd=exDownload&file=&cidReset=true&cidReq=$CID" -G $DOWNLOAD;
        printf "\n%s" "Downloaded @ $FILENAME";
        printf "\n%s" "Make sure you delete the ./moleDownloader folder when you are done!";
    fi;
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

return 0;