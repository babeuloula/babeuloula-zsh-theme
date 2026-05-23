# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

# Configurable icons — override in .zshrc before sourcing oh-my-zsh
# Set to empty string to disable: ZSH_THEME_BABEULOULA_CLOCK_ICON=""
: ${ZSH_THEME_BABEULOULA_CLOCK_ICON:="🕐"}
: ${ZSH_THEME_BABEULOULA_TIMER_ICON:="⏱"}

# Variables for execution time tracking
typeset -F SECONDS
CMD_START_TIME=""
CMD_EXEC_TIME=""

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

function _babeuloula_preexec() {
  CMD_START_TIME=$SECONDS
}

function _babeuloula_precmd() {
  if [[ -n $CMD_START_TIME ]]; then
    CMD_EXEC_TIME=$((SECONDS - CMD_START_TIME))
    CMD_START_TIME=""
  else
    CMD_EXEC_TIME=""
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _babeuloula_preexec
add-zsh-hook precmd  _babeuloula_precmd

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Time: current time
prompt_time() {
  local current_time=$(date '+%H:%M:%S')
  prompt_segment cyan black "${ZSH_THEME_BABEULOULA_CLOCK_ICON:+$ZSH_THEME_BABEULOULA_CLOCK_ICON }$current_time"
}

# Execution time: show command execution time if available
prompt_exec_time() {
  if [[ -n $CMD_EXEC_TIME ]] && (( CMD_EXEC_TIME > 0.1 )); then
    local exec_time_formatted
    
    if (( CMD_EXEC_TIME >= 60 )); then
      # More than a minute: convert to integer seconds first
      local total_seconds=${CMD_EXEC_TIME%.*}
      local minutes=$((total_seconds / 60))
      local remaining_seconds=$((total_seconds % 60))
      exec_time_formatted="${minutes}m ${remaining_seconds}s"
    elif (( CMD_EXEC_TIME >= 1 )); then
      local formatted_time=$(LC_NUMERIC=C printf "%.2f" $CMD_EXEC_TIME)
      formatted_time=${formatted_time%0}
      formatted_time=${formatted_time%0}
      formatted_time=${formatted_time%.}
      exec_time_formatted="${formatted_time}s"
    else
      local ms=$(LC_NUMERIC=C printf "%.0f" $(( CMD_EXEC_TIME * 1000 )))
      exec_time_formatted="${ms}ms"
    fi
    
    # Change color based on execution time
    if (( CMD_EXEC_TIME >= 10 )); then
      prompt_segment red white "${ZSH_THEME_BABEULOULA_TIMER_ICON:+$ZSH_THEME_BABEULOULA_TIMER_ICON }$exec_time_formatted"
    elif (( CMD_EXEC_TIME >= 3 )); then
      prompt_segment yellow black "${ZSH_THEME_BABEULOULA_TIMER_ICON:+$ZSH_THEME_BABEULOULA_TIMER_ICON }$exec_time_formatted"
    else
      prompt_segment green black "${ZSH_THEME_BABEULOULA_TIMER_ICON:+$ZSH_THEME_BABEULOULA_TIMER_ICON }$exec_time_formatted"
    fi
  fi
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  prompt_segment white black "%(!.%{%F{yellow}%}.)%n"
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green $CURRENT_FG
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    branch_name=$(git symbolic-ref HEAD --short 2> /dev/null)
    tag=$(git describe --exact-match --tags HEAD 2> /dev/null)

    if [[ ! -z "${tag}" ]]; then      
      tag=" (${tag})"
    fi

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${PL_BRANCH_CHAR} ${branch_name}${tag}${vcs_info_msg_0_%% }${mode}"
  fi
}

prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment yellow black
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment yellow black
                echo -n "bzr@"$revision

            else
                prompt_segment green black
                echo -n "bzr@"$revision
            fi
        fi
    fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green $CURRENT_FG
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if hg st | grep -q "^[?]"; then
        prompt_segment red black
        st='±'
      elif hg st | grep -q "^[MA]"; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green $CURRENT_FG
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $CURRENT_FG '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols

  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

prompt_newline() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR
%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n " %{%k%}"
  fi

  echo -n " %{%f%}"
  CURRENT_BG=''
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_time
  prompt_exec_time
  prompt_context
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_newline
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
