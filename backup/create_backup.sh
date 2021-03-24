#!/bin/bash
#
# Created by vps 24.03.2021
#

# == constants
BACKUP_TIME=`date +"%Y-%m-%d_%H-%M"`
LOG_TAG="$0"
WORK_DIR="$(dirname $0)"
if [ ${WORK_DIR} == '.' ]
then
  WORK_DIR=$(pwd)
fi
# == end of constants

# == preferences
CONF_FILE_NAME='backup.conf'
. $(dirname $0)/${CONF_FILE_NAME} || err "Unable to load config from: $(dirname $0)/${CONF_FILE_NAME}"
# == end of preferences

# == functions
say() {
    MESSAGE="$1"
    TIMESTAMP=$(date +"%F %T")
    echo -e "$TIMESTAMP $MESSAGE"
    logger -t $LOG_TAG -p $LOG_FACILITY.$LOG_LEVEL "$MESSAGE"
}

err()  {
    MESSAGE="ERROR: $1"
    TIMESTAMP=$(date +"%F %T")
    echo -e $TIMESTAMP $MESSAGE >&2
    logger -t $LOG_TAG -p $LOG_FACILITY.$LOG_LEVEL_ERR "$MESSAGE"
    LockUnset
    exit 1
}

quit() {
    MESSAGE="$1"
    TIMESTAMP=$(date +"%F %T")
    echo -e $TIMESTAMP $MESSAGE >&2
    logger -t $LOG_TAG -p $LOG_FACILITY.$LOG_LEVEL_ERR "$MESSAGE"
    LockUnset
    exit 0
}

LockSet() {
    me=`basename "$0"`
    lock_file="/tmp/${me}.lock"
    [ -f $lock_file ] && err "$lock_file exist: $0 runned by another user?"
    touch $lock_file
}

LockUnset() {
    rm -rf $lock_file
}

usage() {
    echo "Usage:  $0 <arguments>"
    echo "-b <BKP_DIR>  : Backups dir"
    echo "-u <USER>     : ssh user"
    echo "-i <IP>       : ssh IP"
    echo "-d            : debug"
    echo "-r <DIRS>     : <list of the remote dirs for backup>"
    echo "-f            : create full backup"
    echo "-l            : force rotate backup and exit"
    echo "-h            : this help"
}

logrotate() {
  say "Running logrotate"
  [[ ${debug} > 0 ]] && echo "RUN: ${LOGROTATE} -s ${WORK_DIR}/logrotateStatus.tmp -f ${WORK_DIR}/logrotate.conf"
  pushd "${BKP_DIR}" >/dev/null
  OUT=$(${LOGROTATE} -s ${WORK_DIR}/logrotateStatus.tmp -f "${WORK_DIR}/logrotate.conf" 2>&1) || err "Unable rotate backup: ${OUT}"
  popd >/dev/null
  return 1;
}
# == end of functions

# ==
# == main program
# == 
# cath control-c
trap 'quit "Exit by SIGINT"'  INT

while getopts b:u:i:dr:flh flag
do
    case "${flag}" in
        b) BKP_DIR=${OPTARG};;
        u) USER=${OPTARG};;
        i) IP=${OPTARG};;
        d) debug=1;;
        r) REMOTE_DIRS=${OPTARG};;
        f) FULL_BACKUP=1;;
        l) logrotate; exit;;
        h) usage; exit;;
    esac
done

say "!!! Staring $0"
LockSet

# Set variables
FULL_DIR=${BKP_DIR}/Full
FULL_OLD=${BKP_DIR}/Full/FullOld
INC_DIR=${BKP_DIR}/Inc
INC_OLD=${BKP_DIR}/Inc/IncOld
# Create dirs
for dir in ${BKP_DIR} ${FULL_DIR} ${FULL_OLD} ${INC_DIR} ${INC_OLD}
do
  [[ -d ${dir} ]] || mkdir -p ${dir}   
done

# Take steps to prepare full backup
if [[ ${FULL_BACKUP} ]]; then
  [[ ${debug} > 0 ]] && echo "Make full backup"
  # Run logrotate
  logrotate
  # Remove incremental log file
  [[ ${debug} > 0 ]] && echo "RUN: ${SSH} ${USER}@${IP} rm -f ${INC_FILE}"
  OUT=$(${SSH} ${USER}@${IP} rm -f ${INC_FILE} 2>&1) || err "Unable delete ${INC_FILE}: ${OUT}"
  # Set backup path
  BKP_PATH="${FULL_DIR}/${BKP_FILE_NAME}-${BACKUP_TIME}.tar.gz.gpg"
fi

# Take steps to prepare incremential backup
if [[ ! ${FULL_BACKUP} ]]; then
  [[ ${debug} > 0 ]] && echo "Make incremential backup"
  # Set backup path
  BKP_PATH="${INC_DIR}/${BKP_FILE_NAME}-${BACKUP_TIME}.tar.gz.gpg"
fi

# Create backup
say "Creating backup file ${BKP_PATH}"
[[ ${debug} > 0 ]] && echo "RUN: ${SSH} ${USER}@${IP} ${TAR} --listed-incremental=${INC_FILE} -czf - ${REMOTE_DIRS} | ${GPG} -o ${BKP_PATH}"
OUT=$(${SSH} ${USER}@${IP} ${TAR} --listed-incremental=${INC_FILE} -czf - ${REMOTE_DIRS} | ${GPG} -o ${BKP_PATH} 2>&1) || err "Unable cteate backup: ${OUT}"

quit "!!! Done $0"
