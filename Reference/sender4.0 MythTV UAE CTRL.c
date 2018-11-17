#include "sender.h"

struct EPGMachine EPGClients[255];
int quiet = 0;

void CTS(int val) {
    int j;
    char send[9];
    sprintf(send, "%02x55AA47", val);
    if (quiet<2) printf("Sending %s\n", send);
    for (j=0;j<EPGMachines;j++) {
        si_other.sin_port = htons(EPGClients[j].EPGPort);
        inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
        sendto(s, send, BUFLEN, 0, (const struct sockaddr *)&si_other, slen);
    }
    usleep(90000);
}

void CTRLGroup(int r, int s) {
	printf("%d", r);
	int i;
	for (i=0;i<5;i++) {
		CTS(r);
	}
    for (i=0;i<5;i++) {
		CTS(s);
	}
}

void sendByte(int8_t byt) {
		CTS(1); CTS(1); CTS(1);
		CTRLGroup(1, !(byt&1)>0); // start
		CTRLGroup(!(byt&1)>0, !(byt&2)>0); // data
		CTRLGroup(!(byt&2)>0, !(byt&4)>0); // data
		CTRLGroup(!(byt&4)>0, !(byt&8)>0); // data
		CTRLGroup(!(byt&8)>0, !(byt&16)>0); // data
		CTRLGroup(!(byt&16)>0, !(byt&32)>0); // data
		CTRLGroup(!(byt&32)>0, !(byt&64)>0); // data
		CTRLGroup(!(byt&64)>0, !(byt&128)>0); // data
		CTRLGroup(!(byt&128)>0, 0); // data
		CTRLGroup(0, 0); // stop
		printf("\n");
}

char *UVSGMessage(char *headerChar, int checksum, char *charArray) {
    char *hexString = calloc(strlen(charArray)*2+strlen(headerChar)+6+4, sizeof *hexString);
    int i, j, strLength = 0;
    strLength = sprintf(hexString, "%s", headerChar);
    for (i=0;i<strlen(charArray);i++) {
        strLength += sprintf(hexString+strLength, "%x", (int)charArray[i]);
        /*if ((int)charArray[i] == 0x0d) charArray[i] = 0x20;
		 if ((int)charArray[i] == 0x0a) charArray[i] = 0x20;*/
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
        /*if ((int)result[j] == 0x0d) result[j] = 0x20;
		 if ((int)result[j] == 0x0a) result[j] = 0x20;*/
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
        /*if ((int)result[j] == 0x0d) result[j] = 0x20;
		 if ((int)result[j] == 0x0a) result[j] = 0x20;*/
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
    if (!(strcmp(selectCodeChar, "") == 0)) startChar = UVSGStart(selectCodeChar);
    if (!(strcmp(selectCodeChar, "*") == 0) && !(strcmp(selectCodeChar, "") == 0)) prepend = "55AABBBB00FF0D0A";
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
	sendEnd();
	sendStart("*R*");
    UDPSend("55AA46414333304000000002325900590000000000000000C8", UVCommandNone);
}

void sendReset(char *selectCode) {
    UDPSend(selectCode, UVCommandReset);
}

void sendPrograms() {
    system("curl http://home.winxblog.com/channellist.php > ~/.prevue/channellist");
    char *path = "/.prevue/channellist";
    char *home = getenv("HOME");
    char *fullPath = calloc(strlen(path)+strlen(home)+1, sizeof *fullPath);
    sprintf(fullPath, "%s%s", home, path);
    FILE *file = fopen(fullPath, "rb");
    if (file) {
        char line[128];
        
        UDPSend("*", UVCommandStart);
        while (fgets(line, sizeof line, file) != NULL) {
            int i;
            int channel = atoi(line);
            for (i=0;i<48;i++) {
                char *URLString = "curl http://home.winxblog.com/prevueprogram.php?channel=%d\\&timeslot=%d > ~/.prevue/program";
                char *programURL = calloc(strlen(programURL)+1, sizeof *programURL);
                sprintf(programURL, URLString, channel, i);
                system(programURL);
                char *path2 = "/.prevue/program";
                char *fullPath2 = calloc(strlen(path2)+strlen(home)+1, sizeof *fullPath2);
                sprintf(fullPath2, "%s%s", home, path2);
                char *hexProgram = hexOfFile(fullPath2);
                if (hexProgram && (strcmp(hexProgram, "") != 0)) UDPSend(hexProgram, UVCommandProgram);
                free(fullPath2);
                free(programURL);
            }
        }
        fclose(file);
    }
    free(fullPath);
}

void sendChannels() {
    int j, clients;
    clients = sizeof EPGClients/sizeof EPGClients[0];
    for (j=0;j<clients;j++) {
         char *URLString = "curl http://home.winxblog.com/prevuechannel.php?selectcode=%s > ~/.prevue/channels";
        char *channelURL = calloc(strlen(URLString)+strlen(EPGClients[j].EPGSelectCode), sizeof *channelURL);
        sprintf(channelURL, URLString, EPGClients[j].EPGSelectCode);
        system(channelURL);
        char *path = "/.prevue/channels";
        char *home = getenv("HOME");
        char *fullPath = calloc(strlen(path)+strlen(home)+1, sizeof *fullPath);
        sprintf(fullPath, "%s%s", home, path);
        UDPSend(UVSGMessage2(UVSGHeader(EPGClients[j].EPGSelectCode, "43"), 0xBC, hexOfFile(fullPath)), UVCommandChannel);
        free(fullPath);
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
    system("mkdir -p ~/.prevue");
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
			sendChannels(0);
			sendPrograms(0);
            sendQueue();
			sendClock();
			sendTitles();
			sendSettings();
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
		sendAd(argument);
	} else if (strcmp(command, "download") == 0) {
		sendDownload();
    } else if (strcmp(command, "config") == 0) {
		sendConfig();
	} else if (strcmp(command, "T1") == 0) {
		CTS(1);
    } else if (strcmp(command, "T0") == 0) {
		CTS(0);
    } else if (strcmp(command, "T") == 0) {
		if (!argument || (strcmp(argument, "") == 0));
		else {
            if (strlen(argument) == 1) sendByte(argument[0]);
            else sendByte(htoi(argument));
        }
    } else if (strcmp(command, "T2") == 0) {
        srand(time(NULL));
        int m;
        for (m=0;m<100;m++) {
            uint8_t byte = rand()%256;
            sendByte(byte);
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
		free(argument-1);
		free(command);
		free(commandBuffer);
		close(s);
		int i;
		exit(0);
	} else if (strcmp(command, "") == 0) {
		;
	} else {
		char *path = calloc(50+strlen(commandString), sizeof *path);
		sprintf(path, "/Users/Ari/Desktop/Prevue Technical/Files/%s", commandString);
		char *hex = hexOfFile(path);
		if (hex) UDPSend(hex, UVCommandNone);
		else UDPSend(commandString, UVCommandNone);
		free(path);
	}
}

void initializeMachines() {
    EPGClients[0].EPGSelectCode = "DKJR6";
    EPGClients[0].EPGIP = "127.0.0.1";
    EPGClients[0].EPGPort = 5556;
    EPGClients[0].EPGTitle = "        Electronic Program Guide";
    EPGClients[0].EPGGrabber = "";
    EPGClients[1].EPGSelectCode = "GA24005";
    EPGClients[1].EPGIP = "127.0.0.1";
    EPGClients[1].EPGPort = 5541;
    EPGClients[1].EPGTitle = "         Prevue Guide";
    EPGClients[1].EPGGrabber = "";
    
	EPGMachines = 2;
}
