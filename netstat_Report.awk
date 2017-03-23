#!/bin/awk

BEGIN{}
{
	#整理port號
	match($2, /:[0-9]+$/);
	targetPort = substr($2, RSTART+1, RLENGTH);

	#整理網路狀態
	statusNetwork = $3;
	
	#整理ProcessID
	processID = $4;
	
	#arrTypeTotal可能其實不會被用到
	arrTypeTotal[statusNetwork]++;
	arrType[targetPort","statusNetwork]++;

	
	if(processID != "-" && statusNetwork == "ESTABLISHED")
	{
		arrEPS[processID]++;
		arrEPSByPort[targetPort","processID]++;
	}
	
}
END{
	#for(key in arrTypeTotal){print key" => "arrTypeTotal[key];}
	#for(key in arrType){print key" => "arrType[key];}

	#for(key in arrEPS){print key" => "arrEPS[key];}
	#for(key in arrEPSByPort){print key" => "arrEPSByPort[key];}
	
	
	
	n = asorti(arrType, dest);
	for(key in dest)
	{
		split(dest[key], arrKey, ",");
		strPrint = strPrint" "arrKey[1]","arrKey[2]","arrType[arrKey[1]","arrKey[2]];
	}
	
	
	for(i in arrEPS)
	{
		## 同一個ProcessID出現的次數 arrEPS[i];
		## 統計不同出現次數的次數......
		arrEPSSum[arrEPS[i]]++;
	}
	
	## 測試用 for(key in arrEPSSum){print key" => "arrEPSSum[key];}
	
	for(i in arrEPSByPort)
	{
		##i 像是 11213,9876/php-fpm arrKey[1] => 11213   arrKey[2] => 9876/php-fpm
		split(i, arrKey, ",");
		
		## 不同Port出現不同次數 的次數
		arrEPSSumByPort[arrEPSByPort[i]","arrKey[1]]++;
	}
	
	n = asorti(arrEPSSum, arrEPSSumSorted);
	for(i = 1; i <= n; i++)
	{
		#strPrint = strPrint" PS:"arrEPSSumSorted[i]"-(11213&11215:"arrEPSSum[arrEPSSumSorted[i]]";";
		strPrint = strPrint" 11213&11215,PS-"arrEPSSumSorted[i]","arrEPSSum[arrEPSSumSorted[i]];
		
		for(j in arrEPSSumByPort)
		{
			split(j, arrKey, ",");
			if (arrKey[1]==i)
			{
				strPrint=strPrint" "arrKey[2]",PS-"arrEPSSumSorted[i]","arrEPSSumByPort[j]"";
			}
		}
	}
	
	print strPrint;
}
