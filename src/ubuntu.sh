#!/bin/bash

read -p "setting start?(y) : " accept
echo "---------------- Your answer is $accept"

if [[ "$accept" == "Y" || "$accept" == "y" || "$accept" == "yes" ]]; then
    echo "start"
else
    echo "exit"
    exit 9
fi

# passwd 에서 user 목록 저장
# USERS=`cat /etc/passwd | aws -F ":" '{print $1}'`

# 사용자 id 입력
read -p "user id : " id
echo "--------------------------------------------------------------"
echo "---------------- Your user id is $id"
echo "--------------------------------------------------------------"
# 시용지 비밀번호 확인
read -sp "password : " password
echo "--------------------------------------------------------------"
echo "---------------- Password Completed"
echo "--------------------------------------------------------------"

# 도메인이 있다면 도메인 호스트 설정
read -p "Do you want to modify the hostname by entering the domain?(ex:domain.com) : " hostDomain

# /etc/passwd에서 user가 존재하는지 확인
# for user in $USERS
# do
# if [ $user == $id ]; then
#     echo "user exist"
# else
#     echo "user not exist"

#     echo "add user start"

#     useradd $id
#     passwd $password
#     mkdir /home/$id
#     chown -R $id:$id /home/$id
#     # echo "$id:$password" | chpasswd
#     groupadd testgroup
#     usermod -G testgroup $id
#     usermod -s /bin/bash $id

#     echo "add user end"
# fi

if [ -d "/home/$id" ]; then
    echo "--------------------------------------------------------------"
    echo "---------------- user home directory exist ----------------"
    echo "--------------------------------------------------------------"
else
    echo "--------------------------------------------------------------"
    echo "---------------- user home directory not exist ----------------"
    echo "--------------------------------------------------------------"

    echo "---------------- add user start ----------------"

    useradd $id
    passwd $password
    mkdir /home/$id
    chown -R $id:$id /home/$id
    # echo "$id:$password" | chpasswd
    groupadd testgroup
    usermod -G testgroup $id
    usermod -s /bin/bash $id

    echo "---------------- add user end ----------------"
fi

# 입력된 사용자는 관리자 권한으로 실행
if [ -f "/etc/sudoers" ]; then
    echo "---------------- add sudouser start ----------------"

    USERID="$id"
    chmod 700 /etc/sudoers && \
    echo "$USERID ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod 440 /etc/sudoers
fi

# OS 패키지 업데이트 및 업그레이드 및 불필요한 패키지 정리
echo "--------------------------------------------------------------"
echo "---------------- OS package update start ----------------"
echo "--------------------------------------------------------------"

export DEBIAN_FRONTEND=noninteractive && \
apt-get update && \
apt-get -o Dpkg::Options::="--force-confnew" -fuy dist-upgrade -y && \
apt -y autoremove


# 서버 시간 변경
echo "--------------------------------------------------------------"
echo "---------------- server time change start ----------------"
echo "--------------------------------------------------------------"
# timedatectl set-timezone Asia/Seoul
apt -y install tzdata
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime


# 만약 도메인을 설정하는 서버라면 도메인을 hosts에 등록하여
# 외부 네임서버를 거치지 않고 바로 스크립트등을 수행할 수 있도록 설정

if [[ "$hostDomain" != "" ]]; then
    echo "add domain start"

    echo "${hostDomain}" > /etc/hostname
    hostname -F /etc/hostname
    sed -i "s/127.0.0.1\tlocalhost/127.0.0.1\tlocalhost\t${hostDomain}/g" /etc/hosts
fi



# iptables enable settings
apt-get install iptables-persistent -y

# iptables -P INPUT DROP
# iptables -P FORWARD DROP
# iptables -S

# mariadb port 3306
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
# ssh port 22
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# http port 80
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# https port 443
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 재부팅시 허용 내역 유지
netfilter-persistent save
netfilter-persistent reload


echo "default server setting completed!!!"