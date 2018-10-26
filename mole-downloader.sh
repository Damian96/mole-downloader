#!/bin/sh

# Enable Debugging Mode
set -x;

UN="";
PW="";
TEMP="moleDownloader";
COOKIES="$TEMP/cookies.txt";
LOGINDATA="$TEMP/login.txt";
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php";
LOGINCHECK="My course list";
DOWNLOAD="https://mole.citycollege.sheffield.eu/claroline/document/document.php";

getLoginData() {

    while [[ true ]]; do

        while [[ true ]]; do
            printf -- "\nPlease enter your mole.citycollege.sheffield.eu username: ";
            read -r UN;

            if [[ `expr "$UN" : '[a-z]*'` == 0 ]]; then
                printf "\nInvalid username.";
            else
                break;
            fi
        done

        while [[ true ]]; do
            printf -- "\nPlease enter your mole.citycollege.sheffield.eu password: ";
            read -r -s PW;

            if [[ -z "$PW" ]]; then
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
    COUNT=0;
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
        printf "\nIncorrect login data.";
        getLoginData;
    fi;
}

# @TODO: Implement getCourseList
# getCourseList() {
#     OUTPUT=`curl -c "$COOKIES" -d "login=$UN&password=$PW" -X POST $LOGIN -L --post302 2>&1 | grep -o "CCP[0-9]\{4\}"`;
#     while IFS='' read -r line || [[ -n "$line" ]]; do

#         echo $line;

#     done < $OUTPUT;    
# }

if [[ ! -d "$TEMP" ]]; then # Temp folder does not exist
    printf "\nCreating data folder...";
    mkdir "$TEMP";
fi

if [[ ! -a "$LOGINDATA" ]]; then # Login Data do not exist
    getLoginData;
else
    readLoginData;
fi

getCourseList;
exit 0;

while [[ true ]]; do
    printf -- "\nPlease insert the course code, or 'q' to exit: ";
    read -r CID;

    if [[ "$CID" == "q" ]]; then
        printf "\nBye!\n";
        exit 0;
    elif [[ `expr "$CID" : 'CCP[0-9]\{4\}'` == 0 ]]; then
        printf "\nInvalid course code.";
    else
        curl --silent --output "./MOLE.$CID.complete.zip" -b "$COOKIES" -d "cmd=exDownload&file=&cidReset=true&cidReq=$CID" -G $DOWNLOAD;
        printf "\nDownloaded: ./MOLE.$CID.complete.zip";
        printf "\nMake sure you delete the ./moleDownloader folder when you are done!";
    fi;
done

# Disable Debugging mode
set +x;

exit 0;