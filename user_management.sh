
#!/usr/bin/env bash

set -o nounset
set -o pipefail

# ==========================================
# USER MANAGEMENT TOOL
# ==========================================


# ==========================================
# VALIDATE USERNAME
# ==========================================

validate_username() {

    local username="$1"

    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "[ERROR] Invalid username."
        return 1
    fi

    if (( ${#username} > 32 )); then
        echo "[ERROR] Username must not exceed 32 characters."
        return 1
    fi

    return 0
}


# ==========================================
# CREATE USER
# ==========================================

create_user() {

    echo
    echo "========== CREATE USER =========="

    local username

    read -rp "Enter username: " username

    validate_username "$username" || return

    if id "$username" &>/dev/null; then
        echo "[ERROR] User already exists."
        return
    fi

    if useradd -m -s /bin/bash "$username"; then
        echo "[SUCCESS] User created successfully."

        echo
        passwd "$username"

        echo
        echo "User details:"
        id "$username"
    else
        echo "[ERROR] User creation failed."
    fi
}


# ==========================================
# DELETE USER
# ==========================================

delete_user() {

    echo
    echo "========== DELETE USER =========="

    local username confirmation

    read -rp "Enter username to delete: " username

    validate_username "$username" || return

    if ! id "$username" &>/dev/null; then
        echo "[ERROR] User does not exist."
        return
    fi

    if [[ "$username" == "root" || "$username" == "$(id -un)" ]]; then
        echo "[ERROR] Cannot delete root or the currently logged-in user."
        return
    fi

    echo
    echo "WARNING: This will delete the account and its home directory."
    read -rp "Type DELETE to confirm: " confirmation

    if [[ "$confirmation" != "DELETE" ]]; then
        echo "[INFO] Deletion cancelled."
        return
    fi

    if userdel -r "$username"; then
        echo "[SUCCESS] User and home directory deleted."
    else
        echo "[ERROR] User deletion failed."
    fi
}


# ==========================================
# LOCK USER ACCOUNT
# ==========================================

lock_user() {

    echo
    echo "========== LOCK USER =========="

    local username

    read -rp "Enter username: " username

    validate_username "$username" || return

    if ! id "$username" &>/dev/null; then
        echo "[ERROR] User does not exist."
        return
    fi

    if passwd -l "$username"; then
        echo "[SUCCESS] Account locked."
    else
        echo "[ERROR] Could not lock account."
    fi
}


# ==========================================
# UNLOCK USER ACCOUNT
# ==========================================

unlock_user() {

    echo
    echo "========== UNLOCK USER =========="

    local username

    read -rp "Enter username: " username

    validate_username "$username" || return

    if ! id "$username" &>/dev/null; then
        echo "[ERROR] User does not exist."
        return
    fi

    if passwd -u "$username"; then
        echo "[SUCCESS] Account unlocked."
    else
        echo "[ERROR] Could not unlock account."
    fi
}


# ==========================================
# CHANGE USER PASSWORD
# ==========================================

change_password() {

    echo
    echo "========== CHANGE PASSWORD =========="

    local username

    read -rp "Enter username: " username

    validate_username "$username" || return

    if ! id "$username" &>/dev/null; then
        echo "[ERROR] User does not exist."
        return
    fi

    passwd "$username"
}


# ==========================================
# USER INFORMATION
# ==========================================

user_information() {

    echo
    echo "========== USER INFORMATION =========="

    local username

    read -rp "Enter username: " username

    validate_username "$username" || return

    if ! id "$username" &>/dev/null; then
        echo "[ERROR] User does not exist."
        return
    fi

    echo
    echo "Account Information:"
    getent passwd "$username"

    echo
    echo "UID, GID and Groups:"
    id "$username"

    echo
    echo "Password Status:"
    passwd -S "$username"
}


# ==========================================
# LIST LOGGED-IN USERS
# ==========================================

logged_in_users() {

    echo
    echo "========== LOGGED-IN USERS =========="

    who
}


# ==========================================
# LIST ALL USERS
# ==========================================

list_users() {

    echo
    echo "========== SYSTEM USERS =========="

    getent passwd | awk -F: '
    {
        printf "%-20s UID: %-8s Home: %s\n", $1, $3, $6
    }'
}


# ==========================================
# MAIN MENU
# ==========================================

main() {

    if (( EUID != 0 )); then
        echo "[ERROR] Please run this script with sudo."
        exit 1
    fi

    while true; do

        echo
        echo "=========================================="
        echo "          LINUX USER MANAGEMENT"
        echo "=========================================="

        echo "1. Create User"
        echo "2. Delete User"
        echo "3. Lock User Account"
        echo "4. Unlock User Account"
        echo "5. Change User Password"
        echo "6. User Information"
        echo "7. List Logged-in Users"
        echo "8. List All System Users"
        echo "9. Exit"

        echo "=========================================="

        local choice

        read -rp "Enter your choice: " choice

        case "$choice" in

            1) create_user ;;
            2) delete_user ;;
            3) lock_user ;;
            4) unlock_user ;;
            5) change_password ;;
            6) user_information ;;
            7) logged_in_users ;;
            8) list_users ;;
            9)
                echo "Exiting User Management Tool."
                break
                ;;
            *)
                echo "[ERROR] Invalid choice. Try again."
                ;;
        esac

    done
}

main "$@"
