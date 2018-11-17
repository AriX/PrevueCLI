#include "sender.h"

struct EPGMachine EPGClients[255];
int quiet = 0;

char *UVSGMessage(char *headerChar, int checksum, char *charArray) {
    char *hexString = calloc(strlen(charArray)*2+strlen(headerChar)+6, sizeof *hexString);
    int i, j, strLength = 0;
    strLength = sprintf(hexString, "%s", headerChar);
    for (i=0;i<strlen(charArray);i++) {
        strLength += sprintf(hexString+strLength, "%x", (int)charArray[i]);
        /*if ((int)charArray[i] == 0x0d) charArray[i] = 0x20;
        if ((int)charArray[i] == 0x0a) charArray[i] = 0x20;*/
        checksum = checksum ^ (int)charArray[i];
    }
    strLength += sprintf(hexString+strLength, "00%x", checksum);
    
    return hexString;
}

char *UVSGMessage2(char *headerChar, int checksum, char *charDataArray) {
    char *hexString = calloc(strlen(headerChar)+strlen(charDataArray)+3, sizeof *hexString);
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
        /*if ((int)result[j] == 0x0d) result[j] = 0x20;
        if ((int)result[j] == 0x0a) result[j] = 0x20;*/
        checksum = checksum ^ (int)result[j];
    }
    
	free(result);
    char checksumString[2];
    sprintf(checksumString, "%x", checksum);
    strcat(hexString, checksumString);
    return hexString;
}

char *UVSGStart(char *selectCodeChar) {
    char *headerString = calloc((2*strlen(selectCodeChar))+12, sizeof *headerString);
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
    if (!(strcmp(selectCodeChar, "") == 0)) startChar = UVSGStart(selectCodeChar);
    if (!(strcmp(selectCodeChar, "*") == 0) && !(strcmp(selectCodeChar, "") == 0)) prepend = "55AABBBB00FF";
    char *headerString = calloc(4+(2*sizeof(modeCode))+strlen(startChar)+strlen(prepend), sizeof *headerString);
    
    sprintf(headerString, "%s%s55aa%s", prepend, startChar, modeCode);
	
	if (!(strcmp(selectCodeChar, "") == 0)) free(startChar);
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
        } else if (commandType == UVCommandEnd) {
            command[0] = UVSGHeader("", "BBBB00FF");
			single = 1;
			freeAfter = 1;
        } else if (commandType == UVCommandTitle) {
			char *header = UVSGHeader(EPGClients[j].EPGSelectCode, "54");
            command[j] = UVSGMessage(header, 0xAB, EPGClients[j].EPGTitle);
			free(header);
			freeAfter = 1;
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
        }
        length[j] = strlen(command[j]);
    }
    if (single) {
        if (quiet<2) printf("Sending %s\n", command[0]);
        for (i=0;i<length[0];i+=2) {
            char send[3];
            send[0] = command[0][i];
            send[1] = command[0][i+1];
            send[2] = 0x00;
            if (quiet<1) printf("%s %d %d\n", send, i, length[0]);
            for (j=0;j<EPGMachines;j++) {
                si_other.sin_port = htons(EPGClients[j].EPGPort);
                inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
                if (sendto(s, send, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
            }
            // 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
            float timeToSend = (1.0*3.0/240.0)*1000.0;
            msleep((long)timeToSend);
        }
    } else {
        for (j2=0;j2<EPGMachines;j2++) {
            if (quiet<2) printf("Sending %s\n", command[j2]);
            for (i=0;i<length[j2];i+=2) {
                char send[3];
                send[0] = command[j2][i];
                send[1] = command[j2][i+1];
                send[2] = 0x00;
                if (quiet<1) printf("%s %d %d\n", send, i, length[j2]);
                for (j=0;j<EPGMachines;j++) {
                    si_other.sin_port = htons(EPGClients[j].EPGPort);
                    inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
                    if (sendto(s, send, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
                }
                // 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
                float timeToSend = (1.0*3.0/240.0)*1000.0;
                msleep((long)timeToSend);
            }
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
	sendEnd();
	sendStart("*R*");
    UDPSend("55AA46414333304000000002325900590000000000000000C8", UVCommandNone);
}

void sendPrograms() {
    time_t now = time(NULL);
	struct tm *ts = gmtime(&now);
	char dayChar[4];
	strftime(dayChar, sizeof(dayChar), "%j", ts);
	int day = atoi(dayChar)-1;
	if (day > 255) day -= 255;
	
	char programQuery[40], *queryString = "SELECT * FROM programs WHERE day=%d";
	sprintf(programQuery, queryString, day);		
	mysql_real_query(SQLConnection, programQuery, (unsigned int)strlen(programQuery));
	MYSQL_RES *result = mysql_store_result(SQLConnection);
	MYSQL_ROW row;
	
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
		
		char *hexChannelName = textToHex(channelname, strlen(channelname));
		char *hexTitle = textToHex(title, strlen(title));
		sprintf(programCommand, "%02x%02x%s1201%s00", atoi(timeslot), atoi(daychar), hexChannelName, hexTitle);
		free(hexChannelName);
		free(hexTitle);
		UDPSend(programCommand, UVCommandProgram);
	}
	mysql_free_result(result);
}

void sendChannels() {
	int j;
    for (j=0;j<EPGMachines;j++) {
		char channelQuery[123], *queryString = "SELECT * FROM channels WHERE grabber = '%s' ORDER BY (number+0)";
        sprintf(channelQuery, queryString, EPGClients[j].EPGGrabber);		
		mysql_real_query(SQLConnection, channelQuery, (unsigned int)strlen(channelQuery));
		MYSQL_RES *result = mysql_store_result(SQLConnection);
		MYSQL_ROW row;
		char *channelCommand = calloc(mysql_num_rows(result)*48, sizeof *channelCommand);
		
		time_t now = time(NULL);
		struct tm *ts = gmtime(&now);
		char dayChar[4];
		strftime(dayChar, sizeof(dayChar), "%j", ts);
		int day = atoi(dayChar)-1;
		if (day > 255) day -= 255;
		int strLength = sprintf(channelCommand, "%02x", day);
		
		while ((row = mysql_fetch_row(result))) {
			char *sixbyteflag = "", *flag = "01";
			char *row0 = textToHex(row[0], strlen(row[0]));
			char *row1 = textToHex(row[1], strlen(row[1]));
			char *row2 = textToHex(row[2], strlen(row[2]));
			strLength += sprintf(channelCommand+strLength, "12%s%s11%s01%s%s", flag, row2, row0, row1, sixbyteflag);
			free(row0);
			free(row1);
			free(row2);
		}
		strLength += sprintf(channelCommand+strLength, "00");
		char *header = UVSGHeader(EPGClients[j].EPGSelectCode, "43");
		char *message = UVSGMessage2(header, 0xBC, channelCommand);
		UDPSend(message, UVCommandChannel);
		free(header);
		free(message);
		mysql_free_result(result);
		free(channelCommand);
    }
}

int main(int argc, char *argv[]) {
    system("mkdir -p ~/.prevue");
    slen = sizeof(si_other);
    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket error.");
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
		
	if (!(SQLConnection = mysql_init(NULL))) {
		printf("Prevue Server: MySQL Initialization Error\n");
		exit(0);
	}
	if (!mysql_real_connect(SQLConnection, "localhost", "prevueguide", "500whatson", "prevueserver", 0, NULL, 0)) {
		printf("Prevue Server: MySQL Connection error\n");
		exit(0);
	}
	
    while(1) {
		if (argc>1 && strcmp(argv[1], "carousel") == 0) {
			if (argc>2) quiet = atoi(argv[2]);
			initializeMachines();
			sendClock();
			sendTitles();
			sendSettings();
			sendChannels();
			sendPrograms();
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
			
			if (strcmp(command, "title") == 0) {
				sendTitles();
			} else if (strcmp(command, "settings") == 0) {
				sendSettings();
			} else if (strcmp(command, "clock") == 0) {
				sendClock();
			} else if (strcmp(command, "channel") == 0) {
				sendChannels();
			} else if (strcmp(command, "program") == 0) {
				sendPrograms();
			} else if (strcmp(command, "start") == 0) {
				if (!argument || (strcmp(argument, "") == 0)) sendStart("*");
				else sendStart(argument);
			} else if (strcmp(command, "end") == 0) {
				sendEnd();
			} else if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0) {
				mysql_close(SQLConnection);
				mysql_library_end();
				free(argument-1);
				free(command);
				close(s);
				int i;
				for (i=0;i<EPGMachines;i++) {
					free(EPGClients[i].EPGSelectCode);
					free(EPGClients[i].EPGIP);
					free(EPGClients[i].EPGTitle);
					free(EPGClients[i].EPGGrabber);
				}
				exit(0);
			} else if (strcmp(command, "") == 0) {
				;
			} else {
				char *path = calloc(50+strlen(commandString), sizeof *path);
				sprintf(path, "/home/ninjastar/prevueserver/resources/testdir/%s", commandString);
				char *hex = hexOfFile(path);
				if (hex) UDPSend(hex, UVCommandNone);
				else UDPSend(commandString, UVCommandNone);
				free(path);
			}
			free(argument-1);
			free(command);
		}
    }

    close(s);
    return 0;
}

void initializeMachines() {
	if (EPGMachines > 0) {
		int i;
		for (i=0;i<EPGMachines;i++) {
			free(EPGClients[i].EPGSelectCode);
			free(EPGClients[i].EPGIP);
			free(EPGClients[i].EPGTitle);
			free(EPGClients[i].EPGGrabber);
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
		sprintf(EPGClients[i].EPGIP, row[1]);
		EPGClients[i].EPGPort = atoi(row[2]);
		EPGClients[i].EPGTitle = calloc(strlen(row[3])+1, sizeof *EPGClients[i].EPGTitle);
		sprintf(EPGClients[i].EPGTitle, row[3]);	
		EPGClients[i].EPGGrabber = calloc(strlen(row[5])+1, sizeof *EPGClients[i].EPGGrabber);
		sprintf(EPGClients[i].EPGGrabber, row[5]);
		i++;
	}
	EPGMachines = i;
	mysql_free_result(result);
}
