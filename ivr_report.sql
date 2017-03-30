SELECT
        q1.QueryDay, q1.WorkerNo, q4.WorkerName, q1.SeatOnTime, q1.SeatOffTime,
        q2.values_1, q2.values_2, q2.values_3, q2.values_10_1, q2.values_10_3,
        q2.values_10_4, q2.values_10_5, q2.values_16, q2.values_7, q2.values_9,
        q3.CallIn, q3.CallInTime, q3.CallOut, q3.CallOutTime
FROM
(
        SELECT t.WorkerNo, t.QueryDay, CONVERT(char(19), MIN(t.StartTimeLoca), 120) as SeatOnTime,  CONVERT(char(19), MAX(t.EndTimeLoca), 120) as SeatOffTime
        FROM
        (
                SELECT WorkerNo, STATUS, CONVERT(char(10), StartTimeLoca, 20) as QueryDay, StartTimeLoca, EndTimeLoca
                FROM [callcenterdb].[dbo].[tbseatstatus]
                WHERE StartTimeLoca between '2017/03/01 00:00:00' AND '2017/03/31 23:59:59' AND
                ( [STATUS] = '1'  )
        )       as t
        GROUP BY t.WorkerNo, t.QueryDay
) as q1
JOIN
(
        SELECT s.WorkerNo, s.Calltime,
                        SUM(case when STATUS = 1 then Duration else 0 end) as values_1,
                        SUM(case when STATUS = 2 then Duration else 0 end) as values_2,
                        SUM(case when STATUS = 3 then Duration else 0 end) as values_3,
                        SUM(case when STATUS = 10 AND flag = 1 then Duration else 0 end) as values_10_1,
                        SUM(case when STATUS = 10 AND flag = 3 then Duration else 0 end) as values_10_3,
                        SUM(case when STATUS = 10 AND flag = 4 then Duration else 0 end) as values_10_4,
                        SUM(case when STATUS = 10 AND flag = 5 then Duration else 0 end) as values_10_5,
                        SUM(case when STATUS = 7 then Duration else 0 end) as values_7,
                        SUM(case when STATUS = 9 then Duration else 0 end) as values_9,
                        SUM(case when STATUS = 16 then Duration else 0 end) as values_16        
        FROM
        (
        SELECT Duration, WorkerNo, STATUS, Flag, CONVERT(char(10), StartTimeLoca, 20) as CallTime
                FROM tbSeatStatus
                WHERE StartTimeLoca between '2017/03/01 00:00:00' AND '2017/03/31 23:59:59'
        ) as s
        GROUP BY s.CallTime, s.WorkerNo
) as q2
on q1.WorkerNo = q2.WorkerNo AND q1.QueryDay = q2.CallTime
JOIN
(
        SELECT WorkerNo, WorkerName FROM tbworker
) as q4
on q1.WorkerNo = q4.WorkerNo
inner JOIN
(
        SELECT
                u.CallDay,
                u.WorkerNo,
                SUM(case when CallInOut = 1 then 1 else 0 end) as CallIn,
                SUM(case when CallInOut = 1 then u.DiffTime else 0 end) as CallInTime,
                SUM(case when CallInOut = 2 then 1 else 0 end) as CallOut,
                SUM(case when CallInOut = 2 then u.DiffTime else 0 end) as CallOutTime
        FROM
        (
                SELECT
                        CONVERT(char(10), CallTime, 20) as CallDay,
                        WorkerNo,
                        CallInOut,
                        SeatAnsId,
                        Datediff(Second, SeatAnsTime, RelTime) as DiffTime
                FROM
                        tbcallcdr
                WHERE
                        CallTime between '2017/03/01 00:00:00' AND '2017/03/31 23:59:59'
                        AND SrvType <> 255
                        AND SeatAnsId = 1 AND WorkerNo <> ''
        ) as u
        GROUP BY u.CallDay, u.WorkerNo
) as q3
on q1.WorkerNo = q3.WorkerNo AND q1.QueryDay = q3.CallDay
ORDER BY q1.QueryDay, q1.WorkerNo
