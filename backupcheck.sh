#!/bin/bash

# Android-Ordner (z.B. DCIM)
ANDROID_FOLDER="/sdcard/DCIM"
# Lokaler Backup-Ordner
LOCAL_FOLDER="$HOME/Backup/DCIM"

# Prüfen, ob Gerät verbunden ist
adb get-state 2>/dev/null | grep -q "device"
if [ $? -ne 0 ]; then
    echo "Kein Android-Gerät verbunden."
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