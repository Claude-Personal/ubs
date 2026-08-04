# CLI message catalog runtime. Not standalone-safe — do not source from install.sh.
#
# Language resolution: $UBS_LANG > $LC_ALL > $LC_MESSAGES > $LANG > en.
# Supported: ko en ja zh. Anything else (including "C"/"POSIX") falls back to en.

_UBS_I18N_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UBS_I18N_DIR/i18n_messages.sh"

ubs_detect_lang() {
  local raw="${UBS_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}}"
  case "$raw" in
    ko*) echo ko ;;
    ja*) echo ja ;;
    zh*) echo zh ;;
    *) echo en ;;
  esac
}

UBS_LANG_RESOLVED="$(ubs_detect_lang)"

# ubs_msg KEY [printf-args...]
# Looks up UBS_MSG_<lang>_<KEY>, falls back to UBS_MSG_en_<KEY>, then to KEY itself.
# Prints without a trailing newline (call sites keep using echo/echo -e for that).
ubs_msg() {
  local key="$1"; shift
  local template
  eval "template=\"\${UBS_MSG_${UBS_LANG_RESOLVED}_${key}:-}\""
  if [ -z "$template" ]; then
    eval "template=\"\${UBS_MSG_en_${key}:-}\""
  fi
  [ -n "$template" ] || template="$key"
  if [ "$#" -gt 0 ]; then
    printf -- "$template" "$@"
  else
    printf '%s' "$template"
  fi
}
