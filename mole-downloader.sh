#!/bin/sh
UN="";
PW="";
TEMP="moleDownloader";
COOKIES="$TEMP/cookies.txt";
LOGINDATA="$TEMP/login.txt";
LOGIN="https://mole.citycollege.sheffield.eu/claroline/auth/login.php";
LOGINCHECK="My course list";

getLoginData() {

    while [[ true ]]; do

        while [[ true ]]; do
            printf "\nPlease enter your mole.citycollege.sheffield.eu username: ";
            read -r UN;

            if [[ `expr "$UN" : '[a-z]*'` == 0 ]]; then
                printf "Invalid username.\n";
            else
                break;
            fi
        done

        while [[ true ]]; do
            printf "\nPlease enter your mole.citycollege.sheffield.eu password: ";
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
    curl -c "$COOKIES" -d "login=$UN&password=$PW" -X POST $LOGIN -L --post302 2>&1 | grep -q "$LOGINCHECK";

    if [[ $? != 0 ]]; then #LOGIN DIDNT SUCCEED
        printf "\nIncorrect login data.\n";
        getLoginData;
    fi;
}

if [[ ! -d "$TEMP" ]]; then # Temp folder does not exist
    printf "\nCreating data folder...\n";
    mkdir "$TEMP";
fi

if [[ ! -a "$LOGINDATA" ]]; then # Login Data do not exist
    getLoginData;
else
    readLoginData;
fi

while [[ true ]]; do
    printf "\nPlease insert the course code:\n";
    read -r CID;

    if [[ `expr "$CID" : 'CCP[0-9]\{4\}'` == 0 ]]; then
        printf "\nInvalid course code.\n";
    else
        curl --silent --output "./MOLE.$CID.complete.zip" -b "$COOKIES" -d "cmd=exDownload&file=&cidReset=true&cidReq=$CID" -G https://mole.citycollege.sheffield.eu/claroline/document/document.php;
        printf "\nDownloaded: ./MOLE.$CID.complete.zip\nMake sure you press Ctrl+C and delete the moleDownloader when you are done! ^_^\n";
    fi;
done
