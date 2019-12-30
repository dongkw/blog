#!/bin/sh

# 发生异常回滚
set -e

# 设置git相关信息，不设置默认为博主的=.=
GIT_USER_NAME=${GIT_USER_NAME:-dongkw}

GIT_USER_MAIL=${GIT_USER_MAIL:-1038459754@qq.com}

# 你想要的用户名
NEW_USER_NAME=${NEW_USER_NAME:-dkw}

# 由于每次启动容器都会执行这个脚本，但这个只需要执行一次，在此标志一下
if [ $(git config --system user.name)x = ${GIT_USER_NAME}x ]
then
    su ${NEW_USER_NAME}
else
    # 修改用户名
    /usr/sbin/usermod -l ${NEW_USER_NAME} ${USER_NAME}

    /usr/sbin/usermod -c ${NEW_USER_NAME} ${NEW_USER_NAME}

    /usr/sbin/groupmod -n ${NEW_USER_NAME} ${USER_NAME}

    chown -R ${NEW_USER_NAME}.${NEW_USER_NAME} /home/${USER_NAME}/blog

    chmod -R 766 /home/${USER_NAME}/blog

    # 设置git全局信息
    git config --system user.name $GIT_USER_NAME

    git config --system user.email $GIT_USER_MAIL

    su ${NEW_USER_NAME}
fi

# 执行脚本之后的命令
exec "$@"