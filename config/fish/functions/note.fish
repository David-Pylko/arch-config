function note --description "Create a note in ~/note-taking"
    set filename (date +'%Y-%m-%d_%H%M.txt')
    vim ~/note-taking/$filename
end
