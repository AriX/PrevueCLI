#include "sender.h"

struct EPGMachine EPGClients[255];
int quiet = 0;

char *UVSGCTRLMessage(char *charDataArray) {
    char *hexString = calloc(strlen(charDataArray)+3, sizeof *hexString);
    strcat(hexString, charDataArray);
    int i = 0, j, checksum = 0;
    char *hexPtr = charDataArray;
    unsigned int *result = calloc(strlen(charDataArray)/2 + 1, sizeof *result);
    
    while (sscanf(hexPtr, "%02x", &result[i++])) {
        hexPtr += 2;
        if (hexPtr >= charDataArray + strlen(charDataArray)) break;
    }
    
    for (j = 0; j < i; j++) {
        checksum = checksum ^ (int)result[j];
    }
    
	free(result);
    char checksumString[3];
    sprintf(checksumString, "%02x", checksum);
    strcat(hexString, checksumString);
    
    return hexString;
}

char *UVSGMessage(char *headerChar, int checksum, char *charArray) {
    char *hexString = calloc(strlen(charArray)*2+strlen(headerChar)+6+4, sizeof *hexString);
    int i, j, strLength = 0;
    strLength = sprintf(hexString, "%s", headerChar);
    for (i=0;i<strlen(charArray);i++) {
        strLength += sprintf(hexString+strLength, "%x", (int)charArray[i]);
        checksum = checksum ^ (int)charArray[i];
    }
    strLength += sprintf(hexString+strLength, "00%x0D0A", checksum);
    
    return hexString;
}

char *UVSGMessage2(char *headerChar, int checksum, char *charDataArray) {
    char *hexString = calloc(strlen(headerChar)+strlen(charDataArray)+3+4, sizeof *hexString);
    strcat(hexString, headerChar);
    strcat(hexString, charDataArray);
    int i = 0, j;
    char *hexPtr = charDataArray;
    unsigned int *result = calloc(strlen(charDataArray)/2 + 1, sizeof *result);
    
    while (sscanf(hexPtr, "%02x", &result[i++])) {
        hexPtr += 2;
        if (hexPtr >= charDataArray + strlen(charDataArray)) break;
    }
    
    for (j = 0; j < i; j++) {
        checksum = checksum ^ (int)result[j];
    }
    
	free(result);
    char checksumString[7];
    sprintf(checksumString, "%x0D0A", checksum);
    strcat(hexString, checksumString);
    return hexString;
}

char *UVSGMessage3(char *headerChar, int checksum, char *charDataArray) {
    char *hexString = calloc(strlen(headerChar)+strlen(charDataArray)+3+6, sizeof *hexString);
    strcat(hexString, headerChar);
    strcat(hexString, charDataArray);
    int i = 0, j;
    char *hexPtr = charDataArray;
    unsigned int *result = calloc(strlen(charDataArray)/2 + 1, sizeof *result);
    
    while (sscanf(hexPtr, "%02x", &result[i++])) {
        hexPtr += 2;
        if (hexPtr >= charDataArray + strlen(charDataArray)) break;
    }
    
    for (j = 0; j < i; j++) {
        checksum = checksum ^ (int)result[j];
    }
    
	free(result);
    char checksumString[9];
    sprintf(checksumString, "%x000D0A", checksum);
    strcat(hexString, checksumString);
    return hexString;
}

char *UVSGStart(char *selectCodeChar) {
    char *headerString = calloc((2*strlen(selectCodeChar))+12+4, sizeof *headerString);
    int strLength = 0;
	
	char *messageString = UVSGMessage("", 0xBE, selectCodeChar);
    strLength = sprintf(headerString, "55aa41");
    strLength += sprintf(headerString+strLength, "%s", messageString);
	
	free(messageString);
	return headerString;
}

char *UVSGHeader(char *selectCodeChar, char *modeCode) {
    char *prepend = "";
    char *startChar = "";
    if (strcmp(selectCodeChar, "") != 0) startChar = UVSGStart(selectCodeChar);
    if (strcmp(selectCodeChar, "*") != 0 && strcmp(selectCodeChar, "") != 0) prepend = "55AABBBB00FF0D0A";
    char *headerString = calloc(4+(2*sizeof(modeCode))+strlen(startChar)+strlen(prepend), sizeof *headerString);
    
    sprintf(headerString, "%s%s55aa%s", prepend, startChar, modeCode);
	
	if (strcmp(selectCodeChar, "") != 0) free(startChar);
    return headerString;
}

void UDPSend(char *hexArray, UVCommand commandType) {
    int j, j2, i, freeAfter = 0, single = 0, length[EPGMachines];
    char *command[EPGMachines];
    for (j=0;(j<EPGMachines&&!single);j++) {
        if (commandType == UVCommandNone) {
            command[0] = calloc(strlen(hexArray)+1, sizeof *command[0]);
            sprintf(command[0], "%s", hexArray);
            single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandStart) {
            command[0] = UVSGStart(hexArray);
            single = 1;
			freeAfter = 1;
		} else if (commandType == UVCommandReset) {
			char *header = UVSGHeader(hexArray, "52");
			char *header2 = calloc(strlen(header)+12, sizeof *header2);
			sprintf(header2, "55AABBBB00FF%s", header);
			free(header);
            command[0] = UVSGMessage2(header2, 0xAD, "00");
			free(header2);
            single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandEnd) {
            command[0] = UVSGHeader("", "BBBB00FF0D0A");
			single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandTitle) {
			char *header = UVSGHeader(EPGClients[j].EPGSelectCode, "54");
            command[j] = UVSGMessage(header, 0xAB, EPGClients[j].EPGTitle);
			free(header);
			freeAfter = 1;
        } else if (commandType == UVCommandAd) {
			char *header = UVSGHeader("*", "4C");
            command[j] = UVSGMessage2(header, 0xB3, hexArray);
			free(header);
			single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandDownload) {
            command[0] = hexArray;
            single = 1;
        } else if (commandType == UVCommandProgram) {
			char *header = UVSGHeader("", "50");
            command[0] = UVSGMessage2(header, 0xAF, hexArray);
			free(header);
			free(hexArray);
            single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandClock) {
			char *header = UVSGHeader("*", "4B");
            command[0] = UVSGMessage2(header, 0xB4, hexArray);
			free(header);
            single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandChannel) {
            command[0] = hexArray;
            single = 1;
        } else if (commandType == UVCTRL) {
            command[0] = UVSGCTRLMessage(hexArray);
			single = 1;
			freeAfter = 1;
        }
        length[j] = strlen(command[j]);
    }
    if (single) {
        if (quiet<2) printf("Sending %s\n", command[0]);
		for (j=0;j<EPGMachines;j++) {
			int complete=0;
			while (!complete) {
				char *commandPointer = command[0];
				si_other.sin_port = htons(EPGClients[j].EPGPort);
				inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
				if (sendto(s, commandPointer, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
				if (strlen(commandPointer)>BUFLEN) commandPointer += BUFLEN;
				else complete = 1;
			}
		}
		// 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
		float timeToSend = ((float)length[0]/1.5/240.0)*1000.0;
		msleep((long)timeToSend);
    } else {
        for (j2=0;j2<EPGMachines;j2++) {
            if (quiet<2) printf("Sending %s\n", command[j2]);
			for (j=0;j<EPGMachines;j++) {
				int complete=0;
				while (!complete) {
					char *commandPointer = command[0];
					si_other.sin_port = htons(EPGClients[j].EPGPort);
					inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
					if (sendto(s, commandPointer, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
					if (strlen(commandPointer)>BUFLEN) commandPointer += BUFLEN;
					else complete = 1;
				}
			}
			// 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
			float timeToSend = ((float)length[j2]/1.5/240.0)*1000.0;
			msleep((long)timeToSend);
        }
    }
	if (freeAfter){
		if (single) {
			free(command[0]);
		} else {
			for (i=0;i<EPGMachines;i++) {
				free(command[i]);
			}
		}
	}
}

void sendSettings() {
    int j;
    for (j=0;j<EPGMachines;j++) {
        char *header = UVSGHeader(EPGClients[j].EPGSelectCode, "46");
        char *settingsMessage = UVSGMessage2(header, 0xB9, EPGClients[j].EPGSettings);
        free(header);
        UDPSend(settingsMessage, UVCommandNone);
        free(settingsMessage);
    }
}

void sendReset(char *selectCode) {
    UDPSend(selectCode, UVCommandReset);
}

void sendPrograms(int dayoffset) {
    time_t now = time(NULL);
	struct tm *ts = gmtime(&now);
	char dayChar[4];
	char hourChar[3];
	strftime(dayChar, sizeof(dayChar), "%j", ts);
	strftime(hourChar, sizeof(hourChar), "%H", ts);
	int day = atoi(dayChar);
	int hour = atoi(hourChar);
	if (day > 255) day -= 254;
	printf("%d", day);
	if (hour<5) day -=1;
	//day-=1;
	
	char programQuery[40], *queryString = "SELECT * FROM programs WHERE day=%d";
	sprintf(programQuery, queryString, day+dayoffset);
	mysql_real_query(SQLConnection, programQuery, (unsigned int)strlen(programQuery));
	//printf(" %s ", mysql_error(SQLConnection));
	MYSQL_RES *result = mysql_store_result(SQLConnection);
	//printf("%d", mysql_num_rows(result));
	MYSQL_ROW row;
	
	sendEnd();
	sendStart("*");
    sendStart("*");
	
	while ((row = mysql_fetch_row(result))) {
		char *programCommand = calloc(500, sizeof *programCommand);
		
		char timeslot[3];
		char daychar[4];
		char *title = row[1];
		char *channelname = row[0]+5;
		timeslot[0] = row[0][0];
		timeslot[1] = row[0][1];
		timeslot[2] = 0x00;
		daychar[0] = row[0][2];
		daychar[1] = row[0][3];
		daychar[2] = row[0][4];
		daychar[3] = 0x00;
		
		int channellength = strlen(channelname);
		char *hexChannelName = textToHex(channelname, channellength);
		char *hexTitle = textToHex(title, strlen(title));
		sprintf(programCommand, "%02x%02x%s1201%s00", atoi(timeslot), atoi(daychar), hexChannelName, hexTitle);
		free(hexChannelName);
		free(hexTitle);
		sendQueue();
		UDPSend(programCommand, UVCommandProgram);
	}
	mysql_free_result(result);
}

void sendChannels(int dayoffset) {
	int j, istrue=1,i=0;
    for (j=0;j<EPGMachines;j++) {
		char channelQuery[226], *queryString = "SELECT * FROM channels WHERE grabber = '%s' OR persistantgrabber = '%s' ORDER BY (number+persistantnumber+0)";
        sprintf(channelQuery, queryString, EPGClients[j].EPGGrabber, EPGClients[j].EPGGrabber);
		mysql_real_query(SQLConnection, channelQuery, (unsigned int)strlen(channelQuery));
		MYSQL_RES *result = mysql_store_result(SQLConnection);
		MYSQL_ROW row;
		char *channelCommand = calloc(mysql_num_rows(result)*48, sizeof *channelCommand);
		
		time_t now = time(NULL);
		struct tm *ts = gmtime(&now);
		char dayChar[4];
		char hourChar[3];
		strftime(dayChar, sizeof(dayChar), "%j", ts);
		strftime(hourChar, sizeof(hourChar), "%H", ts);
		int hour = atoi(hourChar);
		int day = atoi(dayChar);
		if (day > 255) day -= 254;
		if (hour<5) day -=1;
		//day-=2; // HUGE hack. why isn't the date code right??
		
		int strLength = sprintf(channelCommand, "%02x", day+dayoffset);
		
		while ((row = mysql_fetch_row(result))&&istrue) {
			i++;
			char *sixbyteflag = "", *flag = row[6];
			int row2len = strlen(row[2]);
			int row1len = strlen(row[1]);
			if (EPGClients[j].EPGType==1&&row1len>5) row1len = 5;
			char *row0 = textToHex(row[0], strlen(row[0]));
			char *row1 = textToHex(row[1], row1len);
			char *row2 = textToHex(row[2], row2len);
			strLength += sprintf(channelCommand+strLength, "12%s%s11%s01%s%s", flag, row2, row0, row1, sixbyteflag);
			free(row0);
			free(row1);
			free(row2);
			if (EPGClients[j].EPGType == 1) {
				if (i>48) istrue=0;
			} else {
				if (i>65) istrue=0;
			}
			//if (EPGClients[j].EPGType==1&&i>48) istrue=0;
		}
		strLength += sprintf(channelCommand+strLength, "00");
		char *header = UVSGHeader(EPGClients[j].EPGSelectCode, "43");
		char *message = UVSGMessage2(header, 0xBC, channelCommand);
		UDPSend(message, UVCommandChannel);
		free(header);
		free(message);
		mysql_free_result(result);
		free(channelCommand);
		istrue=1;
		i=0;
    }
}

void sendConfig() {
	int j;
    //for (j=0;j<EPGMachines;j++) {
	//char *data = calloc(48, sizeof *data);
	char *data = "433031303830384E3200DA08613938687032383970617069687569613B696F68393838396170393866647039386839653B696F393033383964616F696F69696F66696F61646F3B696A73383975616566383930663238396877656668613938616473383973643938323839696F736461383975616639383075736661616164393233393832336F69736430393861663938306166736439386861733039386466683077393834687274706F75776968617075676861397765663039713866303938A8D098AD098AD09823098A098DF0A98DF029809A079C0A720E572034987098504918345098E0A798DF0793414FADFADCDCE087E0E840732780AD087AD087378478492322494983289428948948484848474764542434E5A679DA978F0237856080A87D697568706138646866617039387365686670313938ADF7809837498AA98DF0785309780A7E072350870A87DF0A87F20873491873401879EFA087FDA08D7F087DF0A807";
	char *header = UVSGHeader("", "66");
	char *message = UVSGMessage2(header, 0x99, data);
	UDPSend(message, UVCommandDownload);
	free(header);
	free(message);
	//free(data);
    //}
}

void sendDownload() {
	int j;
    //for (j=0;j<EPGMachines;j++) {
	//char *data = calloc(48, sizeof *data);
	char *data = "4446303A636F6E6669672E64617400";
	char *header = UVSGHeader("GA24005", "48");
	char *message = UVSGMessage2(header, 0xB7, data);
	UDPSend(message, UVCommandDownload);
	free(header);
	free(message);
	data = "00343243303130383038474E414530314E4E4E4E4E4E4C32393036595959323333363036303135313030594E59438E384E4E4E4E4E32";
	header = UVSGHeader("", "48");
	message = UVSGMessage3(header, 0xB7, data);
	UDPSend(message, UVCommandDownload);
	free(header);
	free(message);
	data = "0100";
	header = UVSGHeader("", "48");
	message = UVSGMessage2(header, 0xB7, data);
	UDPSend(message, UVCommandDownload);
	free(header);
	free(message);
	//free(data);
    //}
}

void UDPListener() {
	while (1) {
		if (recvfrom(s2, buf2, BUFLEN, 0, &si_other2, &slen2) != -1) {
			while (bufferLocked);
			bufferLocked = 1;
			sprintf(commandBuffer+currentBufferLength, "\n%s", buf2);
			currentBufferLength += strlen(buf2)+1;
			printf("%s %d\n", commandBuffer, currentBufferLength);
			fflush(stdout);
			bufferLocked = 0;
		} else {
			msleep(100);
		}
	}
}

void sendAds() {
	char *queryString = "SELECT * FROM ads";
	mysql_real_query(SQLConnection, queryString, (unsigned int)strlen(queryString));
	MYSQL_RES *result = mysql_store_result(SQLConnection);
	MYSQL_ROW row;
	
	while ((row = mysql_fetch_row(result))) {
		int adslot = atoi(row[0]);
		char *ad = textToHex(row[1], strlen(row[1]));
		
		char *slotandcommand = calloc(strlen(ad)*2+3, sizeof *slotandcommand);
		sprintf(slotandcommand, "%02x%s00", adslot, ad);
		char *header = UVSGHeader(row[2], "4C");
		char *command = UVSGMessage2(header, 0xB3, slotandcommand);
		free(header);
		free(slotandcommand);
		UDPSend(command, UVCommandNone);
		free(command);
	}
	mysql_free_result(result);
}

void sendAd(char *ad) {
	char adnum[2];
	adnum[0] = ad[0];
	adnum[1] = 0x00;
	int adint = atoi(adnum);
	ad += 1;
	
	char *fullcommand = calloc(strlen(ad)*2+3, sizeof *fullcommand);
	sprintf(fullcommand, "%02x%s00", adint, textToHex(ad, strlen(ad)));
	UDPSend(fullcommand, UVCommandAd);
}

void sendQueue() {
	while (bufferLocked);
	bufferLocked = 1;
	int i;
	for (i=currentBufferLength;i>=0;i--) {
		if (commandBuffer[i] == '\n') {
			char *commandString = commandBuffer+i+1;
			int i, space = 0;
			char *argument = calloc(128, sizeof *argument), *command = calloc(128, sizeof *argument);
			for(i=0;i<strlen(commandString);i++) {
				if (commandString[i] == 0x20 && space == 0) space = i;
				if (space>0) argument[i-space] = commandString[i];
				else command[i] = commandString[i];
			}
			if (space == 0) space = i;
			command[space] = 0x00;
			argument[i-space] = 0x00;
			argument += 1;
			
			runCommand(command, argument, commandString);
			free(argument-1);
			free(command);
			int curlen = strlen(commandString);
			commandBuffer[currentBufferLength-(i+1)] = 0x00;
			currentBufferLength -= (curlen+1);
		}
	}
	bufferLocked = 0;
}

int main(int argc, char *argv[]) {
    slen = sizeof(si_other);
    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket error.");
	if ((s2=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket 2 error.");
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
	int flags2 = fcntl(s2, F_GETFL);
	flags2 |= O_NONBLOCK;
	fcntl(s2, F_SETFL, flags2);
	memset((char *) &si_me2, 0, sizeof(si_me2));
    si_me2.sin_family = AF_INET;
    si_me2.sin_port = htons(INTERNALPORT);
    si_me2.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(s2, &si_me2, sizeof(si_me2)) == -1) printf("Socket 2 bind error.");
	
	commandBuffer = calloc(BUFLEN, sizeof *commandBuffer);
	
	if (!(SQLConnection = mysql_init(NULL))) {
		printf("Prevue Server: MySQL Initialization Error\n");
		exit(0);
	}
	if (!mysql_real_connect(SQLConnection, "127.0.0.1", "prevueguide", "500whatson", "prevueserver", 0, NULL, 0)) {
		printf("Prevue Server: MySQL Connection error\n");
		exit(0);
	}
	
	pthread_t UDPThread;
	pthread_create(&UDPThread, NULL, UDPListener, NULL);
	
    while(1) {
		if (argc>1 && strcmp(argv[1], "carousel") == 0) {
			if (argc>2) quiet = atoi(argv[2]);
			initializeMachines();
			sendQueue();
			sendClock();
			sendTitles();
			sendSettings();
			sendAds();
			sendChannels(0);
			sendPrograms(0);
            sendQueue();
			sendClock();
			sendTitles();
			sendSettings();
			sendAds();
			sendChannels(1);
			sendPrograms(1);
		} else {
			if (argc>1) quiet = atoi(argv[1]);
			printf("Enter a UVSG satellite data command, or type 'channel', 'title', 'settings', 'end', etc.\nPREVUE>");
			char origCommandString[255];
			char commandString[255];
			fgets(origCommandString, sizeof(origCommandString), stdin);
			int i, space = 0;
			for (i=0;i<strlen(origCommandString)-1;i++) {
				commandString[i] = origCommandString[i];
			}
			commandString[i] = 0x00;
			char *argument = calloc(128, sizeof *argument), *command = calloc(128, sizeof *argument);
			for(i=0;i<strlen(commandString);i++) {
				if (commandString[i] == 0x20 && space == 0) space = i;
				if (space>0) argument[i-space] = commandString[i];
				else command[i] = commandString[i];
			}
			if (space == 0) space = i;
			command[space] = 0x00;
			argument[i-space] = 0x00;
			argument += 1;
			
			initializeMachines();
			
			runCommand(command, argument, commandString);
			free(argument-1);
			free(command);
		}
    }
	
    close(s);
    return 0;
}

void runCommand(char *command, char *argument, char *commandString) {
	if (strcmp(command, "title") == 0) {
		sendTitles();
	} else if (strcmp(command, "settings") == 0) {
		sendSettings();
	} else if (strcmp(command, "clock") == 0) {
		if (!argument || (strcmp(argument, "") == 0)) sendClock();
		else UDPSend(argument, UVCommandClock);
	} else if (strcmp(command, "channel") == 0) {
		sendChannels(0);
	} else if (strcmp(command, "program") == 0) {
		if (!argument || (strcmp(argument, "") == 0)) sendPrograms(0);
		else {
			char *programCommand = malloc(strlen(argument)+1);
			sprintf(programCommand, "%s", argument);
			UDPSend(programCommand, UVCommandProgram);
		}
	} else if (strcmp(command, "ad") == 0) {
		if (!argument || (strcmp(argument, "") == 0)) sendAds();
		else sendAd(argument);
	} else if (strcmp(command, "download") == 0) {
		sendDownload();
    } else if (strcmp(command, "config") == 0) {
		sendConfig();
	} else if (strcmp(command, "T") == 0) {
		if (!argument || (strcmp(argument, "") == 0));
		else {
            UDPSend(argument, UVCTRL);
        }
    } else if (strcmp(command, "start") == 0) {
		if (!argument || (strcmp(argument, "") == 0)) sendStart("*");
		else sendStart(argument);
	} else if (strcmp(command, "reset") == 0) {
		if (!argument || (strcmp(argument, "") == 0)) sendReset("*");
		else sendReset(argument);
	} else if (strcmp(command, "end") == 0) {
		sendEnd();
	} else if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0) {
		mysql_close(SQLConnection);
		mysql_library_end();
		free(argument-1);
		free(command);
		free(commandBuffer);
		close(s);
		int i;
		for (i=0;i<EPGMachines;i++) {
			free(EPGClients[i].EPGSelectCode);
			free(EPGClients[i].EPGIP);
			free(EPGClients[i].EPGTitle);
			free(EPGClients[i].EPGGrabber);
			free(EPGClients[i].EPGSettings);
		}
		exit(0);
	} else if (strcmp(command, "") == 0) {
		;
	} else {
		char *path = calloc(50+strlen(commandString), sizeof *path);
		sprintf(path, TESTPATH, commandString);
		char *hex = hexOfFile(path);
		if (hex) UDPSend(hex, UVCommandNone);
		else UDPSend(commandString, UVCommandNone);
		free(path);
	}
}

void initializeMachines() {
	if (EPGMachines > 0) {
		int i;
		for (i=0;i<EPGMachines;i++) {
			free(EPGClients[i].EPGSelectCode);
			free(EPGClients[i].EPGIP);
			free(EPGClients[i].EPGTitle);
			free(EPGClients[i].EPGGrabber);
			free(EPGClients[i].EPGSettings);
		}
		EPGMachines = 0;
	}
	
	mysql_query(SQLConnection, "SELECT * FROM machines");
	MYSQL_RES *result = mysql_store_result(SQLConnection);
	MYSQL_ROW row;
	int i=0;
	
	while ((row = mysql_fetch_row(result))) {
		EPGClients[i].EPGSelectCode = calloc(strlen(row[0])+1, sizeof *EPGClients[i].EPGSelectCode);
		sprintf(EPGClients[i].EPGSelectCode, row[0]);
		EPGClients[i].EPGIP = calloc(strlen(row[1])+1, sizeof *EPGClients[i].EPGIP);
		sprintf(EPGClients[i].EPGIP, EPGIPFORMAT);
		EPGClients[i].EPGPort = atoi(row[2]);
		EPGClients[i].EPGType = atoi(row[6]);
		EPGClients[i].EPGTitle = calloc(strlen(row[3])+1, sizeof *EPGClients[i].EPGTitle);
		sprintf(EPGClients[i].EPGTitle, row[3]);	
		EPGClients[i].EPGGrabber = calloc(strlen(row[5])+1, sizeof *EPGClients[i].EPGGrabber);
		sprintf(EPGClients[i].EPGGrabber, row[5]);
		EPGClients[i].EPGSettings = calloc(43, sizeof *EPGClients[i].EPGSettings);
		if (atoi(row[19])) {
            sprintf(EPGClients[i].EPGSettings, row[18]);
		} else {
            char dayStartHours = 'E'; // C = 3 AM, D = 4 AM, E = 5 AM, I?
            char dayStartMinutes = 'A'; // A = 0, B = 30
            if (EPGClients[i].EPGType == 1) {
                dayStartHours = row[9][0]+0x41; // A = 0, B = 1, C = 2, D = 3, E = 4
                dayStartMinutes = row[8][0]+0x41; // A = 0, B = 1, C = 2, D = 3, E = 4
            }
            char scrollSpeed = row[10][0]; // Speeds 1 through 7, default 4
            char adTens = row[11][0]; // Tens column number of ads allowed, default 0
            char adOnes = row[11][1]; // Ones column number of ads allowed, default 6
            char linesPerAd = row[12][0]; // Number of lines allowed per ad, ignored on Atari, default 6
            char unknown1 = 'N'; // Unknown byte 7 (default N?)
            char adsShown1 = 0x00; // something to do with ads shown or how often, 0x00 to 0x03? default 0x00
            char adsShown2 = 0x02; // something to do with ads shown or how often, 0x00 to 0x03? default 0x02
            char timezone = row[13][0]; // 6 = 0
            char useDST = row[14][0]; // Y or N
            char unknown2 = 'Y'; // Unknown byte C (default N, Amiga default Y?)
            char keyboardEnabled = row[15][0]; // Allow local ad editing. This disables centrally sent ads, default null
            char unknown3 = 'N'; // Unknown byte E (Y/N?)
            char unknown4 = 'Y'; // Unknown byte F (Y/N?)
            char unknown5 = 'Y'; // Unknown byte 10 (Y/N?)
            char unknown6 = 'N'; // Unknown byte 11 (N?)
            char GRPH = row[16][0]; // Unknown byte 12 ([GRPH] N/E/L on Amiga)
            char VIN = row[17][0]; // Unknown byte 13 ([VIN] X/L/N on Amiga)
            char unknown7 = 0x00; // Unknown byte 14 (X?)
            sprintf(EPGClients[i].EPGSettings, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x00", dayStartMinutes, dayStartHours, scrollSpeed, adTens, adOnes, linesPerAd, unknown1, adsShown1, adsShown2, timezone, useDST, unknown2, keyboardEnabled, unknown3, unknown4, unknown5, unknown6, GRPH, VIN, unknown7);
		}
		i++;
	}
	EPGMachines = i;
	mysql_free_result(result);
}
