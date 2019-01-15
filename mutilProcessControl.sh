#!/bin/bash
# 來源: http://www.ywnds.com/?p=10901

# 其他發想參考
# https://natelandau.com/boilerplate-shell-script-template/
# https://github.com/natelandau/shell-scripts
# bash mutilProcessControl.sh -c "sleep " $(for i in {1..40}; do echo $(( ( RANDOM % 10 )  + 1 )); done)

scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilsLocation="${scriptPath}/lib/utils.sh" # Update this path to find the utilities.
if [ -f "${utilsLocation}" ]; then
  source "${utilsLocation}"
else
  echo "Please find the file util.sh and add a reference to it in this script. Exiting."
  exit 1
fi

# Print usage
usage() {
  echo -n "${scriptName} [OPTION]... [Argments]...

This is my script template.

 Options:
  -c, --command     Command want to run
  -h, --help        Display this help and exit
      --version     Output version information and exit
"
}
# 整理參數
# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
        case $1 in
                -h|--help) usage >&2; exit ;;
                -c|--command) shift; command=${1} ;;
                *) die "invalid option: '$1'." ;;
        esac
        shift
done

# Store the remaining part as arguments.
args+=("$@")

# 允许的进程数;
THREAD_NUM=20
TMPFILE=$(mktemp -u)
# 定义描述符为9的管道;
mkfifo $TMPFILE
exec 9<> $TMPFILE

# 预先写入指定数量的换行符，一个换行符代表一个进程;
for ((i=0;i<$THREAD_NUM;i++))
do
    echo -ne "\n" 1>&9
done

# 循环执行sleep命令;
echo "执行开始: `date +%s`"
for((i=0; ${#}>i;));
do
{
    # 进程控制;
    read -u 9
    {
        bash -c "${command} $1s && echo $1;"
        echo -ne "\n" 1>&9
    }&
    shift 1
}
done
wait
echo "执行结束: `date +%s`"
rm $TMPFILE
