<?php
        define("CRYPT_KEY", "$1$1245678$");


        $f = fopen('php://stdin', 'r');
        while ($line = fgets($f))
        {
                $matches = preg_split('/[\s,]+/', $line);
                $account = trim($matches[0]);
                $pass_temp = trim($matches[1]);
                $password = crypt($pass_temp ,CRYPT_KEY);
                $account = chk_account ($account);
                echo add_account ($account,$password);
        }

        function chk_account ($account)
        {
                #$account = strtolower($account);
                $size = strlen($account);
                $fixed_account = "";

                for($i=0;$i < $size;$i++)
                {
                        $ascii = ord($account[$i]);
                        // a~z or 0~9 or _

                //      if(($ascii>=97 && $ascii<=122) || ($ascii>=48 && $ascii<=57) || $ascii==95)
                //              $fixed_account .= $account[$i];
                        if(preg_match('/[A-Za-z0-9_]/', $account[$i]))
                        {
                                $fixed_account .= $account[$i];
                        }
                }
                return $fixed_account;
        }

        function add_account ($account,$password)
        {
                if(empty($account))
                        return "";
                $table = "bho_a".$account[0];
                $sql = "INSERT INTO ".$table."(
                        account, ptype, priority, \"password\", expire, diamonds,
                        max_char, first_login, last_login, gift, source, last_server,
                        pass_valid, spec_game, spec_lan, spec_ver, spec_com, pay_date,
                        free_diamonds, last_ip, bindtype, create_time, charlist)
                        VALUES ('".$account."', 0, 0, '".$password."', now(), 0,
                        0, now(), now(), '', '', -1,
                        now(), '', '', '', '', now(),
                        0, '', 0, now(), 0);\n";

                $sql = "select out_member_guid,out_account from bdis_create_account('0','".$account."','".$password."',0, '');\n";
                return $sql;
        }
?>
