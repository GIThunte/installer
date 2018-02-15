#!/bin/bash

#vars

PATH_INSTALL="/usr/local/bin/build_ubuntu"
URL_GIT="https://github.com/GIThunte/build-ubuntu.git"
LINK_FILE="$PATH_INSTALL/start.sh"
LINK_PRE_START="$PATH_INSTALL/start"
LINK_ON_START="/usr/local/bin/lb-ubuntu"
INST_PKG="git vsftpd initramfs-tools-core "
PATH_CONF="base_img.conf"

#MSG
MSG_IF_ROOT="This script must be run as root"
MSG_TEST_FILE="Check existence"
MSG_ERR_FILE="Could not find"
MSG_ERR_DIR="Could not find dir"
MSG_DIR_EXT="Directory exists"
MSG_EXT_FOLDER="==============================================================\n\n\n"
MSG_EXT_FOLDER_1="\n\n\n=============================================================="
MSG_RUN_SC="Running the script"
MSG_IF_FO="Do you want to run the script again? (y/n)?"
MSG_STOP="Script execution stopped"
MSG_GN_INITRD="Creating an initrd file"
MSG_CHECK_FILE="\033[32m Check if the file exists: \033[0m"
MSG_OK_STATUS="\033[32m OK \033[0m"
MSG_NO_EX="\033[31m File is missing! \033[0m"
MSG_CHECK_DIR="\033[32m Checking the existence of the directory: \033[0m"
MSG_NO_DIR="\033[31m Directory is missing! \033[0m"
MSG_END_INST="\n\n\n\033[32m  ==================== Now you can start the boot-ubuntu using the command sudo lb-build  =============== \033[0m\n\n\n"

#ftp
FTP_CONFIG="/etc/vsftpd.conf"
FTP_TMP_CONF="/tmp/vsftpd.conf"
REWRITE_LINE="anonymous_enable=NO"
NEW_REW_LINE="anonymous_enable=YES"
PATH_FTP="/srv/ftp"

#img
IMAGE_NVER="4.4.0-98"
IMAGE_VER="linux-image-$IMAGE_NVER-generic"
INS_TMP_CONF="/tmp/install.sh"

#functions

function IF_ROOT() #you root ?
{
    if [[ $EUID -ne 0 ]]; then
        echo "$MSG_IF_ROOT"
        exit 1
    fi
}
function PRE_INST()
{
    if [ -d $PATH_INSTALL ]; then
        read -p "$MSG_IF_FO" answer
        case ${answer:0:1} in
            y|Y )
                echo $MSG_RUN_SC
                sudo rm -rf $PATH_INSTALL $LINK_ON_START
            ;;
            * )
                echo "$MSG_STOP"
                exit
            ;;
        esac
    else
        echo $MSG_RUN_SC
    fi
}

function IF_FILE()
{
    for FILE_EX in $@; do
        echo -ne "$MSG_CHECK_FILE \033[33m $FILE_EX \033[0m"
        if [[ -f $FILE_EX ]]; then
            echo -e " $MSG_OK_STATUS"
        else
            echo -e " $MSG_NO_EX"
            exit 1
        fi
    done
}

function IF_DIR()
{
    for D_EX in $@; do
        echo -ne "$MSG_CHECK_DIR \033[33m $D_EX \033[0m"
        if [[ -d $D_EX ]]; then
            echo -e " $MSG_OK_STATUS"
        else
            echo -e " $MSG_NO_DIR"
            exit 1
        fi
    done
}

function CREATE_LINK()
{
    if [[ -z "$@" ]]; then
        echo "$MSG_STOP: $@"
        exit 1
    else
        ln -v -s -f $1 $2
        IF_FILE $1
        IF_FILE $2
    fi
}

function COMMON()
{
    for INSTALL_BASE_PKG_1 in $@ ; do
        which $INSTALL_BASE_PKG_1 >/dev/null ||  apt-get install $INSTALL_BASE_PKG_1 -y --force-yes
    done
    apt-get clean
}

function VSFTP()
{
    IF_FILE $FTP_CONFIG
    sed "s/$REWRITE_LINE/$NEW_REW_LINE/g" $FTP_CONFIG > $FTP_TMP_CONF
    IF_FILE $FTP_TMP_CONF
    cat $FTP_TMP_CONF > $FTP_CONFIG
    IF_FILE $FTP_CONFIG
    sudo service vsftpd restart
}

function GIT_CLONE()
{
    git clone $URL_GIT $PATH_INSTALL
    IF_DIR $PATH_INSTALL
    IF_FILE $LINK_FILE
}

function POST_B()
{
    IF_FILE $PATH_INSTALL/$PATH_CONF
    NAME_CHROOT_SC=`cat $PATH_INSTALL/$PATH_CONF | grep CHROOT_SCRIPT | awk -F"=" '{print $2}' | head -n1 | awk -F'"' '{print $2}'`
    IF_FILE $PATH_INSTALL/$NAME_CHROOT_SC
    CHECK_IMG_VER=`cat $PATH_INSTALL/$NAME_CHROOT_SC | grep "^IMAGE_VER" | awk -F'"' '{print $2}'`
    IF_FILE $PATH_INSTALL/base_img.conf
    echo "PATH_FTP=$PATH_FTP" >> $PATH_INSTALL/$PATH_CONF
    echo "IMAGE_NVER=$IMAGE_NVER" >> $PATH_INSTALL/$PATH_CONF
    echo "IMAGE_VER=$IMAGE_VER" >> $PATH_INSTALL/$PATH_CONF
    IF_FILE $PATH_INSTALL/$NAME_CHROOT_SC
    sudo sed "s/$CHECK_IMG_VER/$IMAGE_VER/g" $PATH_INSTALL/$NAME_CHROOT_SC > $INS_TMP_CONF
    IF_FILE $INS_TMP_CONF
    sudo cat $INS_TMP_CONF > $PATH_INSTALL/$NAME_CHROOT_SC
}

function POST_F()
{
    echo -e "$MSG_END_INST"
}

########################################

IF_ROOT
PRE_INST
COMMON $INST_PKG
GIT_CLONE
VSFTP
CREATE_LINK $LINK_FILE $LINK_ON_START
POST_B
POST_F

########################################
