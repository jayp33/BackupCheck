# Backup Check

Backup Check ist ein Bash-Skript zur Überprüfung von Backups zwischen einem Android-Gerät und lokalen Ordnern.

## Installation

1. Klonen Sie das Repository oder kopieren Sie die Dateien in ein Verzeichnis.
2. Passen Sie die Datei `backupcheck.conf` an (tragen Sie Ihre Android-Seriennummer ein).
3. Erstellen Sie eine gerätespezifische Konfigurationsdatei, z.B. `device_<SERIAL>.conf`, und definieren Sie die zu vergleichenden Ordner.

## Nutzung

Verbinden Sie Ihr Android-Gerät per USB und aktivieren Sie das USB-Debugging.

Führen Sie das Skript aus:

```bash
./backupcheck.sh
```

Für ausführliche Ausgabe:

```bash
./backupcheck.sh -v
```

## Konfiguration

- `backupcheck.conf`: Enthält die Android-Seriennummer.
- `device_<SERIAL>.conf`: Definiert die Ordnerpaare für den Vergleich.
