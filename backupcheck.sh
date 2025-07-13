#!/bin/bash

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

# Vergleich der Listen
echo "Dateien nur auf dem Android-Gerät:"
comm -23 android_files.txt local_files.txt

echo ""
echo "Dateien nur im lokalen Backup:"
comm -13 android_files.txt local_files.txt

# Aufräumen
rm android_files.txt local_files.txt