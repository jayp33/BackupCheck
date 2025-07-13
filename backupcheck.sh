#!/bin/bash

VERBOSE=0

# Konfiguration laden
CONFIG_FILE="$(dirname "$0")/backupcheck.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Konfigurationsdatei $CONFIG_FILE nicht gefunden."
    exit 1
fi
source "$CONFIG_FILE"

# Parameter prüfen
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=1
fi

# Ordner-Kombinationen aus Konfiguration einlesen
ANDROID_FOLDERS=()
LOCAL_FOLDERS=()
while IFS= read -r line; do
    [[ "$line" =~ ^ANDROID_FOLDER\[([0-9]+)\]= ]] && ANDROID_FOLDERS[${BASH_REMATCH[1]}]="${line#*=}"
    [[ "$line" =~ ^LOCAL_FOLDER\[([0-9]+)\]= ]] && LOCAL_FOLDERS[${BASH_REMATCH[1]}]="${line#*=}"
done < "$CONFIG_FILE"

for idx in "${!LOCAL_FOLDERS[@]}"; do
    # Expandiert Umgebungsvariablen wie $HOME
    LOCAL_FOLDERS[$idx]=$(eval echo "${LOCAL_FOLDERS[$idx]}")
done

# Prüfen, ob Gerät verbunden ist
adb get-state 2>/dev/null | grep -q "device"
if [ $? -ne 0 ]; then
    echo "Kein Android-Gerät verbunden."
    exit 1
fi

CONNECTED_SERIAL=$(adb get-serialno 2>/dev/null)
if [ "$CONNECTED_SERIAL" != "$ANDROID_SERIAL" ]; then
    echo "Das gewünschte Gerät ($ANDROID_SERIAL) ist nicht verbunden. Verbunden: $CONNECTED_SERIAL"
    exit 1
fi

DIFF_FOUND=0

for idx in "${!ANDROID_FOLDERS[@]}"; do
    ANDROID_FOLDER="${ANDROID_FOLDERS[$idx]}"
    LOCAL_FOLDER="${LOCAL_FOLDERS[$idx]}"

    # Prüfen, ob Ordner auf dem Android-Gerät existiert
    adb shell "[ -d \"$ANDROID_FOLDER\" ]"
    if [ $? -ne 0 ]; then
        echo "Ordner $ANDROID_FOLDER auf dem Android-Gerät nicht gefunden."
        continue
    fi

    # Prüfen, ob lokaler Ordner existiert
    if [ ! -d "$LOCAL_FOLDER" ]; then
        echo "Lokaler Ordner $LOCAL_FOLDER nicht gefunden."
        continue
    fi

    # Dateiliste vom Android-Gerät holen (rekursiv, relative Pfade)
    adb shell "cd \"$ANDROID_FOLDER\" && find . -type f | sed 's|^\./||'" > android_files.txt

    # Dateiliste vom lokalen Backup holen (rekursiv, relative Pfade)
    find "$LOCAL_FOLDER" -type f | sed "s|^$LOCAL_FOLDER/||" > local_files.txt

    # Sortieren der Dateilisten
    sort android_files.txt -o android_files.txt
    sort local_files.txt -o local_files.txt

    # Vergleich der Listen
    DIFF_ANDROID=$(comm -23 android_files.txt local_files.txt)
    DIFF_LOCAL=$(comm -13 android_files.txt local_files.txt)

    if [ "$VERBOSE" -eq 1 ]; then
        if [ -n "$DIFF_ANDROID" ] || [ -n "$DIFF_LOCAL" ]; then
            echo "Vergleich: $ANDROID_FOLDER <-> $LOCAL_FOLDER"
            echo "Dateien nur auf dem Android-Gerät:"
            echo "$DIFF_ANDROID"
            echo ""
            echo "Dateien nur im lokalen Backup:"
            echo "$DIFF_LOCAL"
            DIFF_FOUND=1
        fi
    else
        if [ -n "$DIFF_ANDROID" ] || [ -n "$DIFF_LOCAL" ]; then
            DIFF_FOUND=1
        fi
    fi

    rm android_files.txt local_files.txt
done

if [ "$VERBOSE" -eq 0 ]; then
    if [ $DIFF_FOUND -eq 1 ]; then
        echo "Es gibt Unterschiede zwischen Android-Gerät und lokalem Backup."
    else
        echo "Keine Unterschiede gefunden."
    fi
fi