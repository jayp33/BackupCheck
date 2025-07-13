#!/bin/bash

VERBOSE=0

# Konfiguration laden
CONFIG_FILE="$(dirname "$0")/backupcheck.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Konfigurationsdatei $CONFIG_FILE nicht gefunden."
    exit 1
fi
source "$CONFIG_FILE"

# Prüfen, ob Gerät verbunden ist
adb get-state 2>/dev/null | grep -q "device"
if [ $? -ne 0 ]; then
    echo "Kein Android-Gerät verbunden."
    exit 1
fi

# Prüfen, ob das gewünschte Gerät verbunden ist
CONNECTED_SERIAL=$(adb get-serialno 2>/dev/null)
if [ "$CONNECTED_SERIAL" != "$ANDROID_SERIAL" ]; then
    echo "Das gewünschte Gerät ($ANDROID_SERIAL) ist nicht verbunden. Verbunden: $CONNECTED_SERIAL"
    exit 1
fi

# Prüfen, ob Ordner auf dem Android-Gerät existiert
adb shell "[ -d \"$ANDROID_FOLDER\" ]"
if [ $? -ne 0 ]; then
    echo "Ordner $ANDROID_FOLDER auf dem Android-Gerät nicht gefunden."
    exit 1
fi

# Prüfen, ob lokaler Ordner existiert
if [ ! -d "$LOCAL_FOLDER" ]; then
    echo "Lokaler Ordner $LOCAL_FOLDER nicht gefunden."
    exit 1
fi

# Dateiliste vom Android-Gerät holen
adb shell "ls -1 $ANDROID_FOLDER" > android_files.txt

# Dateiliste vom lokalen Backup holen
ls -1 "$LOCAL_FOLDER" > local_files.txt

# Sortieren der Dateilisten
sort android_files.txt -o android_files.txt
sort local_files.txt -o local_files.txt

# Vergleich der Listen
DIFF_ANDROID=$(comm -23 android_files.txt local_files.txt)
DIFF_LOCAL=$(comm -13 android_files.txt local_files.txt)

# Parameter prüfen
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=1
fi

if [ "$VERBOSE" -eq 1 ]; then
    if [ -n "$DIFF_ANDROID" ] || [ -n "$DIFF_LOCAL" ]; then
        echo "Dateien nur auf dem Android-Gerät:"
        echo "$DIFF_ANDROID"
        echo ""
        echo "Dateien nur im lokalen Backup:"
        echo "$DIFF_LOCAL"
    else
        echo "Keine Unterschiede gefunden."
    fi
else
    if [ -n "$DIFF_ANDROID" ] || [ -n "$DIFF_LOCAL" ]; then
        echo "Es gibt Unterschiede zwischen Android-Gerät und lokalem Backup."
    else
        echo "Keine Unterschiede gefunden."
    fi
fi

# Aufräumen
rm android_files.txt local_files.txt