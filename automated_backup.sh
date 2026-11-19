
#!/bin/bash

# Linux Automated Backup Script

# ---------------- CONFIGURATION ----------------

BACKUP_DIR="/var/backups/linux_admin"
BACKUP_DATE=$(date '+%Y%m%d_%H%M%S')

ARCHIVE_FILE="$BACKUP_DIR/backup_$BACKUP_DATE.tar.gz"
TEMP_ARCHIVE="$ARCHIVE_FILE.tmp"

# ---------------- CHECK REQUIREMENTS ----------------

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Please run this script with sudo."
    exit 1
fi

if ! command -v tar &>/dev/null; then
    echo "[ERROR] tar is not installed."
    exit 1
fi

if ! command -v realpath &>/dev/null; then
    echo "[ERROR] realpath is not available."
    exit 1
fi

# ---------------- CHECK INPUT ----------------

if [[ $# -eq 0 ]]; then
    echo "Usage: sudo $0 <directory1> <directory2> ..."
    echo
    echo "Example:"
    echo "sudo $0 /etc /home/faiz /opt"
    exit 1
fi

# ---------------- CREATE BACKUP DIRECTORY ----------------

if ! mkdir -p "$BACKUP_DIR"; then
    echo "[ERROR] Cannot create backup directory."
    exit 1
fi

# ---------------- COLLECT DIRECTORIES ----------------

VALID_DIRS=()
RELATIVE_DIRS=()

echo "=================================================="
echo "             AUTOMATED BACKUP SYSTEM"
echo "=================================================="
echo "Hostname      : $(hostname)"
echo "Backup Date   : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Backup Location: $BACKUP_DIR"
echo "=================================================="

echo
echo "========== VALIDATING DIRECTORIES =========="

for DIR in "$@"; do

    if [[ ! -d "$DIR" ]]; then
        echo "[SKIPPED] Directory does not exist: $DIR"
        continue
    fi

    REAL_DIR=$(realpath -e "$DIR")

    # Prevent the backup archive from backing itself up
    if [[ "$BACKUP_DIR/" == "$REAL_DIR/"* || "$REAL_DIR" == "/" ]]; then
        echo "[SKIPPED] Backup directory is inside this source: $DIR"
        continue
    fi

    # Avoid duplicate directories
    if [[ " ${VALID_DIRS[*]} " == *" $REAL_DIR "* ]]; then
        echo "[SKIPPED] Duplicate directory: $DIR"
        continue
    fi

    VALID_DIRS+=("$REAL_DIR")
    RELATIVE_DIRS+=("${REAL_DIR#/}")

    echo "[ACCEPTED] $REAL_DIR"

done

if [[ ${#VALID_DIRS[@]} -eq 0 ]]; then
    echo
    echo "[ERROR] No valid directories available for backup."
    exit 1
fi

# ---------------- CREATE BACKUP ----------------

echo
echo "========== CREATING BACKUP =========="

if tar -czf "$TEMP_ARCHIVE" -C / -- "${RELATIVE_DIRS[@]}"; then

    # Verify archive integrity before saving it
    if tar -tzf "$TEMP_ARCHIVE" >/dev/null 2>&1; then

        if mv "$TEMP_ARCHIVE" "$ARCHIVE_FILE"; then
            echo "[SUCCESS] Backup archive created."
        else
            echo "[ERROR] Unable to move backup archive."
            rm -f "$TEMP_ARCHIVE"
            exit 1
        fi

    else
        echo "[ERROR] Backup archive verification failed."
        rm -f "$TEMP_ARCHIVE"
        exit 1
    fi

else
    echo "[ERROR] Backup creation failed."
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi

# ---------------- BACKUP SUMMARY ----------------

echo
echo "=================================================="
echo "                 BACKUP SUMMARY"
echo "=================================================="

echo "Directories Backed Up : ${#VALID_DIRS[@]}"

echo
echo "Included Directories:"

for DIR in "${VALID_DIRS[@]}"; do
    echo "  - $DIR"
done

echo
echo "Archive Name : $(basename "$ARCHIVE_FILE")"
echo "Backup Size  : $(du -h "$ARCHIVE_FILE" | cut -f1)"
echo "Backup Path  : $ARCHIVE_FILE"

echo
echo "=================================================="
echo "            BACKUP COMPLETED SUCCESSFULLY"
echo "=================================================="
