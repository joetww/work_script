REM 增加KeepAliveInterval(預設 1000毫秒)
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "KeepAliveInterval" /t REG_DWORD /d 1000 /f

REM 增加KeepAliveTime(預設 7200000毫秒)
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "KeepAliveTime" /t REG_DWORD /d 300000 /f

REM 增加TcpMaxDataRetransmissions(預設 5次)
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "TcpMaxDataRetransmissions" /t REG_DWORD /d 5 /f

REM 增加TcpTimedWaitDelay(預設 240s)
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d 30 /f
