function sudovim
    if string match -q 'vim *' $history[1]
        eval (string replace 'vim' 'sudoedit' $history[1])
    else
        echo -e "\nThe previous command did not start with 'vim'"
        commandline -f repaint
    end
end
