<?php
// +-----------------------------------------------------------------------+
// |  Copyright (c) CoCoSoft 2005-14                                 |
// +-----------------------------------------------------------------------+
// | This file is free software; you can redistribute it and/or modify     |
// | it under the terms of the GNU General Public License as published by  |
// | the Free Software Foundation; either version 2 of the License, or     |
// | (at your option) any later version.                                   |
// | This file is distributed in the hope that it will be useful           |
// | but WITHOUT ANY WARRANTY; without even the implied warranty of        |
// | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          |
// | GNU General Public License for more details.                          |
// +-----------------------------------------------------------------------+
// | Author: CoCoSoft                                                      
// +-----------------------------------------------------------------------+
// 

// read the config
	$config=array();
	if (!file_exists("/opt/asha/asha.conf")) {
		logIt("SHADOW110 ==> SNO!! Shadow is running but there is no asha.conf");
		`touch /opt/asha/service/shadow/down`;
		`sv d /etc/service/shadow`;	
		exit(2);
	}		
	$fin = @fopen("/opt/asha/asha.conf", "r"); 
	if ($fin) { 
		while (!feof($fin)) { 
			$buffer = trim(fgets($fin)); 
			if (preg_match('/^#/',$buffer) || !strlen($buffer) ) {
				continue;
			}
			$stanza = explode("=", $buffer);
			if ($stanza[0]) {
				$config{trim($stanza[0])} = trim($stanza[1]);
			}
		}
	}
    fclose($fin);
//    print_r($config);  
	
	if ($config['RHINOSPF'] != 'YES') {
		logIt("SHADOW110 ==> SNO!! Shadow is running but there is no RHINO Card");
		`touch /opt/asha/service/shadow/down`;
		`sv d /etc/service/shadow`;	
		exit(4);
	} 
	
	if ( ! file_exists($config['RHINOUSB']) ) {
		logIt("SHADOW301 ==> Config states RHINO SPF but none found");
		`touch /opt/asha/service/shadow/down`;
		`sv d /etc/service/shadow`;	
		exit(4);			
	}		
	
	$hostname = trim(`hostname`);
	if ( $config['BNODENAME']  == $hostname ) {
		logIt("SHADOW120 ==> SNO!! Shadow is running on STANDBY host $hostname");
		`touch /opt/asha/service/shadow/down`;
		`sv d /etc/service/shadow`;
		exit(4);
	}
	else {
		logIt("SHADOW121 ==> Shadow is running on PRIMARY host $hostname");
	}
	

	logIt("SHADOW130 ==> Shadow is starting in passive mode");
// initially set rhno to NC mode - assume that asterisk isn't runningf
	`/usr/local/bin/rhinofailover /dev/ttyUSB0 RESET`;
	sleep (1);
	failOver($config);
	
/*
 *  Main loop 
 */
	while(1) {
	
/*
 *  Wait for asterisk to come up
 */
		while ( ! checkAst() ) {	
			sleep(30);
		}
/*
 *  Asterisk is running; set the card to NO (local)
 */
		`/usr/local/bin/rhinofailover /dev/ttyUSB0 RELAYON 0`;
		logIt("SHADOW140 ==> Rhino SPF set to NO(primary) mode\n");

// start watchdog
		logIt("SHADOW141 ==> Shadow is entering active mode\n");

		while(1) {
			if ( ! checkAst() ) {
				$msg = 'Asterisk is Dead! - failing over RHINO card';
				logIt("SHADOW100 ==> $msg \n");
				informAdmin($msg, $config);
				failOver($config);
				break;
			}			
			sleep(10);
		}
	}

/*
 * end of main loop 
 */ 

function failOver( $config=array() ) {	
	
	if ($config['RHINOSPF']) {
		if ( file_exists($config['RHINOUSB']) ) {
			`/usr/local/bin/rhinofailover /dev/ttyUSB0 RELAYOFF 0`;
			logIt("SHADOW200 ==> Rhino SPF set to NC(Secondary) mode\n");
		}
	}	
    logIt("SHADOW201 ==> Shadow is entering passive mode\n");
}

function logIt($sometext) {
	syslog(LOG_WARNING, date("M j H:i:s") . ": " . $sometext . "\n");
//	echo $sometext . "\n";
}

function checkAst() {
	exec( '/usr/sbin/asterisk -rx \'core show channels\'', $out, $status );
	if ( $status != 0 ) {
		return false;
	}
	return true;	
}


function informAdmin($msg, $config=array()) {
	$to      = $config{MAILTO};
	$subject = 'SARK Rhino HA Failover';
	$message = $msg . "\r\n";
	$message .= "Host " . `hostname --fqdn`;
	$headers = 'From: ' . $config{CLUSTERALERT} . "\r\n" .
		'Reply-To: ' . $config{CLUSTERALERT} . "\r\n" .
		'X-Mailer: PHP/' . phpversion();
	mail($to, $subject, $message, $headers);   
}
?>
