function gl --wraps='git log --oneline --decorate=no' --description 'alias gl=git log --oneline --decorate=no'
  git log --oneline --decorate=no $argv; 
end
