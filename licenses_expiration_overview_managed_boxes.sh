#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_castatus.db>"
    echo "Default path is /opt/phion/rangetree/castatus.db"
    exit 1
fi

DB_FILE="$1"

if command -v db_dump185 &> /dev/null; then
    DUMP_CMD="db_dump185 -p"
elif command -v db_dump &> /dev/null; then
    DUMP_CMD="db_dump -p"
else
    echo "Error: db_dump185 or db_dump is not installed."
    exit 1
fi

# 1. First pass: Dump data into temporary arrays and find the maximum box name length
declare -a keys
declare -a values
max_len=15 # Default minimum width for the Box Name column

while IFS= read -r key; do
    IFS= read -r value
    [ -z "$key" ] && continue
    
    box_name=$(echo "$key" | sed 's/\\00//g')
    keys+=("$box_name")
    values+=("$value")
    
    # Track the longest box name length
    if [ ${#box_name} -gt $max_len ]; then
        max_len=${#box_name}
    fi
done < <($DUMP_CMD "$DB_FILE" | sed '1,/HEADER=END/d')

# 2. Create a dynamic separator line based on the longest name
total_width=$((max_len + 45))
separator=$(printf '%*s' "$total_width" '' | tr ' ' '-')

# 3. Print the formatted header
echo "$separator"
printf "%-${max_len}s | %-25s | %s\n" "Box Name" "License Type" "Expiration Date"
echo "$separator"

# 4. Second pass: Format and print the collected data
for i in "${!keys[@]}"; do
    box_name="${keys[$i]}"
    value="${values[$i]}"
    
    if [[ "$value" == *"Invalid serial number"* || "$value" == *"|na|"* ]]; then
        printf "%-${max_len}s | %-25s | %s\n" "$box_name" "Invalid / No License" "N/A"
        echo "$separator"
    else
        # Extract and parse the sub-licenses
        has_sub_lic=false
        while read -r sub_licence; do
            [ -z "$sub_licence" ] && continue
            has_sub_lic=true
            
            licence_name=$(echo "$sub_licence" | awk -F'#' '{print $5}')
            timestamp=$(echo "$sub_licence" | awk -F'#' '{print $3}')
            
            if [[ "$timestamp" =~ ^1[6-9][0-9]{8}$ ]]; then
                expiry_date=$(date -d "@$timestamp" +"%Y-%m-%d" 2>/dev/null || date -r "$timestamp" +"%Y-%m-%d" 2>/dev/null)
            else
                expiry_date="Unknown"
            fi
            
            printf "%-${max_len}s | %-25s | %s\n" "$box_name" "$licence_name" "$expiry_date"
            box_name="" # Only print the name on the first license line
            
        done < <(echo "$value" | tr '$' '\n' | grep -E "(AdvancedThreatProtection|EnergizeUpdates|MalwareProtection)")
        
        # If the box is valid but has no specific sub-licenses listed
        if [ "$has_sub_lic" = false ]; then
            status=$(echo "$value" | awk -F'|' '{print $5}')
            [ -z "$status" ] && status="Active"
            printf "%-${max_len}s | %-25s | %s\n" "$box_name" "$status" "No sub-licenses found"
        fi
        echo "$separator"
    fi
done
