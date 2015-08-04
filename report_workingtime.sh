#!/bin/bash

start_date="20150701"
end_date="20150731"
worktxt="working_time_$(date +"%Y%m" -d ${start_date}).txt"
standard_work_time=$(expr $(date +%s -d "18:00") - $(date +%s -d "09:00"))
small_worktime=60

for i in $(seq ${start_date} ${end_date})
do
	if [ "$(cat ${worktxt} | grep "$(date +"%Y/%m/%d" -d ${i})")" != "" ]
	then
		s_sec=$(date +%s -d "$(cat ${worktxt} | grep "$(date +"%Y/%m/%d" -d ${i})" | awk '{if($5=="上班")printf("%s %s\n", $3, $4)}')")
		e_sec=$(date +%s -d "$(cat ${worktxt} | grep "$(date +"%Y/%m/%d" -d ${i})" | awk '{if($5=="下班")printf("%s %s\n", $3, $4)}')")
		work_sec=$(expr $(expr ${e_sec} - ${s_sec} - ${standard_work_time}) / 60 )
		if [ ${work_sec} -ge ${small_worktime} ]
		then
			printf "%s,  %s,  %s\t%d\n" ${i} $(date +%H:%M -d @${s_sec}) $(date +%H:%M -d @${e_sec}) ${work_sec}
		fi
	fi
done