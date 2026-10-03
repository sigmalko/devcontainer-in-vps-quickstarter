# Catppuccin Mocha-inspired truecolor prompt for dark terminals.
case $- in
  *i*) ;;
  *) return ;;
esac

export COLORTERM=truecolor
if [ -z "${TERM:-}" ] || [ "${TERM}" = "dumb" ]; then
  export TERM=xterm-256color
fi

__devcontainer_truecolor_prompt() {
  local exit_status=$?
  local git_branch git_segment status_segment
  local blue='\[\e[38;2;137;180;250m\]'
  local green='\[\e[38;2;166;227;161m\]'
  local peach='\[\e[38;2;250;179;135m\]'
  local red='\[\e[38;2;243;139;168m\]'
  local mauve='\[\e[38;2;203;166;247m\]'
  local dim='\[\e[38;2;166;173;200m\]'
  local reset='\[\e[0m\]'

  git_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || true)"
  if [ -n "$git_branch" ]; then
    git_segment=" ${peach}(${git_branch})${reset}"
  else
    git_segment=''
  fi

  if [ "$exit_status" -ne 0 ]; then
    status_segment=" ${red}×${exit_status}${reset}"
  else
    status_segment=''
  fi

  PS1="${blue}\u@\h${dim} in ${green}\w${git_segment}${status_segment}${reset}\n${mauve}❯${reset} "
}

PROMPT_COMMAND=__devcontainer_truecolor_prompt
