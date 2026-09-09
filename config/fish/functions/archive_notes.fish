function archive_notes --description "Consolidate and cleanup .txt notes into Archived Notes.txt"
    set -l archive_file "Archived Notes.txt"
    set -l count 0

    for file in *.txt
        if not test -f "$file"; or test "$file" = "$archive_file"
            continue
        end

        set -l title (string replace -r '\.txt$' '' -- "$file")

        # 1. Prepend the note title to the very beginning of the archive file
        set -l temp_archive (mktemp)
        echo "$title" > "$temp_archive"
        if test -f "$archive_file"
            cat "$archive_file" >> "$temp_archive"
        end
        mv "$temp_archive" "$archive_file"

        # 2. Append the section header and content to the end of the archive file
        printf "\n### %s\n\n" "$title" >> "$archive_file"
        cat "$file" >> "$archive_file"
        printf "\n" >> "$archive_file"

        # 3. Clean up the original note
        rm "$file"
        set count (math $count + 1)
    end

    if test $count -gt 0
        echo "Archived and removed $count note(s) into '$archive_file'."
    else
        echo "No .txt notes found to archive."
    end
end
