SELECT
        q1.QueryDay, q1.WorkerNo, q4.WorkerName, q1.SeatOnTime, q1.SeatOffTime,
        q2.values_1, q2.values_2, q2.values_3, q2.values_10_1, q2.values_10_3,
        q2.values_10_4, q2.values_10_5, q2.values_16, q2.values_7, q2.values_9,
        q3.CallIn, q3.CallInTime, q3.CallOut, q3.CallOutTime
FROM
(
        Select t.WorkerNo, t.QueryDay,
        convert(char(19), Min(t.StartTimeLoca), 120) as SeatOnTime,
        convert(char(19), Max(t.EndTimeLoca), 120) as SeatOffTime
        from
        (
                select WorkerNo, STATUS, convert(char(10), StartTimeLoca, 20) as QueryDay, StartTimeLoca, EndTimeLoca
                from [callcenterdb].[dbo].[tbseatstatus]
                where StartTimeLoca between '2017/03/01 00:00:00' and '2017/03/29 23:59:59' and
                ( [STATUS] = '1'  )
        )       as t
        group by t.WorkerNo, t.QueryDay
) as q1
join
(
        select s.WorkerNo, s.Calltime,
                        sum(case when STATUS = 1 then Duration else 0 end) as values_1,
                        sum(case when STATUS = 2 then Duration else 0 end) as values_2,
                        sum(case when STATUS = 3 then Duration else 0 end) as values_3,
                        sum(case when STATUS = 10 and flag = 1 then Duration else 0 end) as values_10_1,
                        sum(case when STATUS = 10 and flag = 3 then Duration else 0 end) as values_10_3,
                        sum(case when STATUS = 10 and flag = 4 then Duration else 0 end) as values_10_4,
                        sum(case when STATUS = 10 and flag = 5 then Duration else 0 end) as values_10_5,
                        sum(case when STATUS = 7 then Duration else 0 end) as values_7,
                        sum(case when STATUS = 9 then Duration else 0 end) as values_9,
                        sum(case when STATUS = 16 then Duration else 0 end) as values_16         
        from
        (
        select Duration, WorkerNo, STATUS, Flag, CONVERT(char(10), StartTimeLoca, 20) as CallTime
                from tbSeatStatus
                where StartTimeLoca between '2017/03/01 00:00:00' and '2017/03/29 23:59:59'
        ) as s
        group by s.CallTime, s.WorkerNo
) as q2
on q1.WorkerNo = q2.WorkerNo and q1.QueryDay = q2.CallTime
join
(
        SELECT
                t.CallDay,
                t.WorkerNo,
                SUM(case when CallInOut = 1 then 1 else 0 end) as CallIn,
                SUM(case when CallInOut = 1 then t.DiffTime else 0 end) as CallInTime,
                SUM(case when CallInOut = 2 then 1 else 0 end) as CallOut,
                SUM(case when CallInOut = 2 then t.DiffTime else 0 end) as CallOutTime
        from
        (
                select
                        CONVERT(char(10), CallTime, 20) as CallDay,
                        WorkerNo,
                        CallInOut,
                        SeatAnsId,
                        Datediff(Second, SeatAnsTime, RelTime) as DiffTime
                from
                        tbcallcdr
                where
                        CallTime between '2017/03/01 00:00:00' and '2017/03/30 23:59:59'
                        and SrvType <> 255
                        and SeatAnsId = 1 and WorkerNo <> ''
        ) as t
        group by t.CallDay, t.WorkerNo
) as q3
on q1.QueryDay = q3.CallDay and q1.WorkerNo = q3.WorkerNo
join
(
        select WorkerNo, WorkerName from tbworker
) as q4
on q1.WorkerNo = q4.WorkerNo
order by q1.QueryDay, q1.WorkerNo;
