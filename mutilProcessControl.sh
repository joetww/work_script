#!/bin/bash
# https://natelandau.com/boilerplate-shell-script-template/
# bash s.sh 2 2 3 4 12 12 11 2 4 5 2 6 32 3 7 18 10 21 23 24 25 27 20 31 32 36 35 2 8 9 11 23 34 26


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
for((i=0; $#>i;));
do
{
    # 进程控制;
    read -u 9
    {
        bash -c "sleep $1s && echo $1;"
        echo -ne "\n" 1>&9
    }&
    shift 1
}
done
wait
echo "执行结束: `date +%s`"
rm $TMPFILE
