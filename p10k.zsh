# Powerlevel10k — hand-tuned lean style (no wizard needed).
# Don't like something? Run `p10k configure` to regenerate interactively.

typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

# ---------- Layout: single-line prompt, info on the right ----------
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=false
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true # blank line between commands

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  context   # user@host — only shown over SSH or as root
  dir       # current directory
  vcs       # git branch + status
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # exit code of failed commands
  command_execution_time  # how long the last command took
  background_jobs         # count of background jobs
  nix_shell               # ❄ marker inside nix shells
  time                    # current time
)

# ---------- Lean style: colors on transparent, no powerline bars ----------
typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_WHITESPACE_BETWEEN_LEFT_SEGMENTS=' '
typeset -g POWERLEVEL9K_WHITESPACE_BETWEEN_RIGHT_SEGMENTS=' '
typeset -g POWERLEVEL9K_LEFT_LEFT_WHITESPACE=''
typeset -g POWERLEVEL9K_RIGHT_RIGHT_WHITESPACE=''

# ---------- Directory ----------
typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3 # padlock icon on read-only dirs

# ---------- Git ----------
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=76
typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=196
typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=244
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=''
typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'

# ---------- Right-side segments ----------
typeset -g POWERLEVEL9K_STATUS_OK=false # only show non-zero exit codes
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3 # only if ≥ 3s
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=244
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=178
typeset -g POWERLEVEL9K_NIX_SHELL_FOREGROUND=74
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_FOREGROUND=244

# ---------- Context: only when it matters (SSH or root) ----------
typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=244
typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'

# Instant prompt can only appear once per session
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
