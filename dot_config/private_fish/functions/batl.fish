function batl --argument-names file --description "Open a file with tail and bat"
  tail -f $file | batcat --paging=never -l log
end
