function restart --wraps="hyprshutdown -t 'Restarting...' --post-cmd 'reboot'" --description "alias restart=hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
    hyprshutdown -t 'Restarting...' --post-cmd 'reboot' $argv
end
