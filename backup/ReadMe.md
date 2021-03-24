Скрипт читает конфиг файл backup.conf, некоторые опции из конфига могут быть переопределены через параметры командной строки.
При запуске без опций выполняется инкрементный бэкап, настройки берутся из конфига
При запуске полного бэкапа (ключ -f) происходит ротация бэкапа
Имеется опция принудительной ротации бэкапа (ключ -l)
Процесс и рeзультат работы выводится в syslog

Usage:  ./create_backup.sh <arguments>
-b <BKP_DIR>  : Baсkups dir
-u <USER>     : ssh user
-i <IP>       : ssh IP
-d            : debug
-r <DIRS>     : <list of the remote dirs for backup>
-f            : create full backup
-l            : force rotate backup and exit
-h            : this help

