#!/bin/sh
# @author  KyleDiao 
# @date    2013-12-05

if [ $LANG != "zh_CN.UTF-8" ];then
    echo "[ 0. This script will change all three password for your account ]"
    echo "[ 1. The samba account password which can be changed by command: smbpasswd ]"
    echo "[ 2. The VNC remote Desktop login password which use command: vncpasswd ]"
    echo "[ 3. The system account which use command: passwd ]"
    echo -e "\e[1;31m[ Note! You must make sure all three password are now The Same. ]\e[0m"
    echo "Please input your old password"

else
    echo "[ 0. 这个命令会修改所有3处密码 ]"
    echo "[ 1. samba 账户密码，单独修改可以使用命令： smbpasswd ]"
    echo "[ 2. VNC远程桌面密码，单独修改可以用命令： vncpasswd ]"
    echo "[ 3. 系统用户密码，单独修改使用命令： passwd ]"
    echo -e "\e[1;31m[ 注意！ 继续使用该命令修改密码需要保证三处密码一致. ]\e[0m"
    echo "请输入您之前的密码"
fi
read -s oldpasswd
res=0
if [ $LANG == "zh_CN.UTF-8" ]
then
expect <<EOF
    spawn su $USER -c "exit"
    expect {
        "密码：" { send "$oldpasswd\n"; exp_continue }
        "su:*" { exit 1 }
    }
EOF
else
expect <<EOF
    spawn su $USER -c "exit"
    expect {
        "password：" { send "$oldpasswd\n"; exp_continue }
        "su:*" { exit 1 }
    }
EOF
fi
#echo $?
#exit 0
if [ $? -ne 0 ]
then
    exit 1
fi
retry_time=0
while [ $retry_time -lt 3 ]
do
    echo "Please type your new password"
    echo "请输入您的新密码："
    read -s passwd1
    echo "Please retype your new password"
    echo "请再次输入您的新密码："
    read -s passwd2
    if [ $passwd1 = $passwd2 ];then	
	break
    else
	echo "Mismatch, passwords are not the same"
        echo "两次输入密码不一致"
    fi
    let retry_time++
done

if [ $retry_time -eq 3 ];then
    echo "Retried 3 times, abort."
    exit -1
fi
#echo $passwd1

expect<<EOF
    spawn passwd
    expect {
        "*UNIX 密码：" { send "$oldpasswd\n"; exp_continue }
        "新的 密码：" { send "$passwd1\n"; exp_continue }
        "*输入新的 密码：" { send "$passwd1\n"; exp_continue }
        "*无效的密码*" { exit 1 }
        "*最多次数*" { exit 1 }
        "*成功更新*" {
            spawn smbpasswd
            expect {
                "Old SMB password:" { send "$oldpasswd\n"; exp_continue }
                "New SMB password:" { send "$passwd1\n"; exp_continue }
                "Retype new SMB password:" { send "$passwd1\n"; exp_continue }
                "Could*" { exit 1 }
                "Password changed*" { exp_continue }
            }
        }
    }
EOF
if [ $? -eq 0 ];then
    echo -e "$passwd1\n$passwd1" | vncpasswd
    echo -e "\n[ 所有三处密码已更新 ]"
fi
