function add_-r_to_command
    set -l prev_cmd (history | head -n 1)

    # Use string replace to insert '-r ' right after 'rm' or 'cp'
    set -l modified_cmd (string replace -r '(^|\s)(rm|cp)(\s|$)' '$1$2 -r$3' "$prev_cmd")

    if test "$prev_cmd" != "$modified_cmd"
        commandline -r "$modified_cmd"
    else
        echo -e "\nThe previous command did not start with 'cp' or 'rm'"
        commandline -f repaint
    end
end


