function power-off --wraps="hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'" --description "alias power-off=hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
    hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0' $argv
end
