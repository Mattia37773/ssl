#!/bin/bash

# Farbe für die Textausgabe
color_green() {
    tput setaf 46
    echo "$1"
    tput sgr0
}

color_red() {
    tput setaf 196
    echo "$1"
    tput sgr0
}

# Seätzt den Basisbefehl fest
command=$1
shift
echo ""

case "$command" in

    # *!SECTION Validation

    # zeigt das Ablaufsdatum einer File an 
    "date")
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            color_red "use -a to see all arguments"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi
        # 
        cd $basedir
        nginxfile=$(ls | grep "nginx")
        color_green "Expiring Date"
        openssl x509 -enddate -noout -in $nginxfile
    ;;

    # überprüft ob das ca bundle und nginx zusammen passen
    ca-nginx)
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "No directory given"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exists"
            false
            exit
        fi

        cd $basedir
        nginxfile=$(ls | grep "nginx")
        cabundle=$(ls | grep "ca-bundle")

        openssl verify -CAfile $cabundle -show_chain $nginxfile
    ;;

    # chekct die daten im nginx.crt
    solo-nginx)
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "No directory given"
            color_red "use -a to see all arguments"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "directory does not exist"
            false
            exit
        fi

        cd $basedir
        nginxfile=$(ls | grep "nginx")

        openssl x509 -in $nginxfile -noout -text
    ;;

    # überprüft ob der key und nginx zusammen passen
    key-nginx)
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            color_red "use -a to see all arguments"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi

        cd $basedir
        nginxfile=$(ls | grep "nginx")
        keyfile=$(ls | grep ".key")

        color_green "1. Nginx.crt 2.key "
        openssl x509 -noout -modulus -in $nginxfile | openssl md5
        openssl rsa -noout -modulus -in $keyfile | openssl md5
    ;;

    # zeigt das Ablaufsdatum aller nginx crt's in allen sachen
    all-cert-date)
        find . -name '*.nginx.crt' -exec sh -c 'for cert; do echo "$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2) $cert"; done' sh {} + | sort -r
    ;;

    # checkt online ob das zertifkat gültig ist
    online)
        domain=$1
        shift
        if [[ -z $domain ]];then
            color_red "Kein Domain Name angegeben"
            color_red "use -a to see all arguments"
            false
            exit
        fi
        color_green "Ablaufsdatum von $domain"

        echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates
    ;;


    # *!SECTION creating 

    # bundelt die dateien zu einem nginx crt
    nginx|nginx-create|new-ssl)
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            color_red "use -a to see all arguments"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi

        cd $basedir
        nginxfile=$(ls | grep "nginx")

        if [[ -f $nginxfile ]];then
            rm -f $nginxfile
        fi
        
        crtfile=$(ls | grep ".crt")
        cabundle=$(ls | grep "ca-bundle")
        nginx="${crtfile%.*}"
        
        cat "$crtfile" <(echo "") "$cabundle" > "$nginx.nginx.crt"    
        color_green "File Created Succesfully"
    ;;

    # 3 files
    3-files|odrk|pem)
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            color_red "use -a to see all arguments"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi
        cd $basedir

        nginxfile=$(ls | grep "nginx")

        if [[ -f $nginxfile ]];then
            rm -f $nginxfile
        fi
        
        crtfile=$(ls | grep ".crt")
        intermediate=$(ls | grep "intermediate.pem")
        root=$(ls | grep "root.pem")
        nginx="${crtfile%.*}"
        
        cat $crtfile $intermediate  $root > $nginx.nginx.crt
        color_green "$nginx.nginx.crt created succesfully"
    ;;

    # create the new files
    zip|copy-zip)
        # Checks for the base dir
        basedir=$1
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi

        cd $basedir
      
        # downloaded directory
        newfile=$1 # ? Neue Datei ganzer pfad als parameter gegeben
        shift
        if [[ -z $newfile ]];then
            color_red "no File given"
            false
            exit
        fi

        if [[ ! -f $newfile ]];then
            color_red "File does not exist"
            false
            exit
        fi

        basefilename="${newfile##*/}" #Dateiname ohne pfad
        cp -f $newfile ./$basefilename
        # Unzipping the file 
        unzip $basefilename  -d .

        # Entfernt die Unterstriche
        for file in __*; do
            [ -f "$file" ] || continue
            filename="$(basename "$file")"
            newname="${filename#__}"
            mv "$file" "$newname"
        done
    ;;

    # create the new files
    save|copy|move|move-files)
        # Checks for the base dir
        basedir=$1
        
        shift
        if [[ -z $basedir ]];then
            color_red "no directory given"
            false
            exit
        fi

        if [[ ! -d $basedir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi

        cd $basedir
        fullpath=$(pwd)
      
        # downloaded directory
        newdir=$1 # ? Neue Datei ganzer pfad als parameter gegeben
        shift
        if [[ -z $newdir ]];then
            color_red "no Directory given"
            false
            exit
        fi

        if [[ ! -d $newdir ]];then
            color_red "Directory does not exist"
            false
            exit
        fi

        # Entfernt die Unterstriche
        for file in "$newdir"/__*; do
            [ -e "$file" ] || continue
            filename="$(basename "$file")"
            newname="${filename#__}"  
            cp "$file" "$fullpath/$newname"
        done
    ;;



    #!SECTION Help command
    
    #  Shows all the required Arguments for the command
   -a|-A)
        color_green "date             Directoryname which includes an nginx.crt file"
        color_green "ca-nginx         Directoryname which includes an nginx.crt and a .ca-bundle file"
        color_green "solo-nginx       Directoryname which includes an nginx.crt file"
        color_green "key-nginx        Directoryname which includes an nginx.crt and a .key file"
        color_green "online           Domain"
        echo ""
        color_green "nginx            Directoryname which includes an .crt and a .ca-bundle file"
        color_green "3-files          Directoryname with the the intermate, root and ca.bundle"
        color_green "copy-zip         Directoryname  where the files are getting and an .zip file with the full paths"
        color_green "copy             Directoryname  where the files are getting and and the directory with the new files"
        echo ""
    ;;

    # Help command
    -h|--h|--help|-help)
        color_green "date             Show the expiry date of an SSL"
        color_green "ca-nginx         Show if the the SSL Chain with ca-bundle and nginx Arguments"
        color_green "solo-nginx       Validates the nignx.crt and show the Data"
        color_green "key-nginx        Checks the accordance between key and nginx.crt"
        color_green "all-cert-date    Shows the expiry date from all SSL's in all Subdirectorys"
        color_green "online           Checks expiry date for an SSL online"
        echo ""
        color_green "nginx            Creates the nginx.crt"
        color_green "3-files          Creates an nginx.crt which has an intermediate.pem, .crt, root.pemfiles "
        color_green "copy-zip         Copies the files from a zip Archive and unxpt them in the project directory"
        color_green "copy             Copies the files from a directory"
        echo ""
        color_green "-a               Shows a List with required all arguments for the command"
    ;;

        # Default 
    *)
        color_red "Error: No such command $command"
        color_red "Try --help for help."
        false
    ;;  

esac
