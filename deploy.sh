#!/usr/bin/env sh

for FILE in ./*/*
do
    FILE_NAME=`echo "$FILE" | cut -d'/' -f3`
    NAME=`echo "$FILE_NAME" | cut -d'.' -s -f1`
    EXTENSION=`echo "$FILE_NAME" | cut -d'.' -s -f2`
    
    if [[ "$EXTENSION" == "sh" || "$EXTENSION" == "ps1" ]]
    then
    echo "found $FILE_NAME, $NAME : $EXTENSION"
        mkdir -p deployed/$EXTENSION
        cp $FILE deployed/$EXTENSION/$NAME
    fi

done