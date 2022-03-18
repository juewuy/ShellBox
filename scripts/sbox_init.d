#!/bin/sh /etc/rc.common

START=99

SERVICE_DAEMONIZE=1
SERVICE_WRITE_PID=1
USE_PROCD=1
[ -z "$SBOX_DIR" ] && source /etc/profile >/dev/null

start_service() {
		procd_open_instance
		procd_set_param respawn
		procd_set_param stderr 0
		procd_set_param stdout 0
		procd_set_param command $SBOX_DIR/SBox_main
		procd_close_instance
}

start() {
		service_start  $SBOX_DIR/SBox_main &
		#设置守护进程
		$SBOX_DIR/SBox_ctrl deamon
}
