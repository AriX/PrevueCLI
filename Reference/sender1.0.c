#include "sender.h"

int msleep(unsigned long milisec) {
    struct timespec req={0};
    time_t sec=(int)(milisec/1000);
    milisec=milisec-(sec * 1000);
    req.tv_sec=sec;
    req.tv_nsec=milisec * 1000000L;
    while(nanosleep(&req,&req) == -1) continue;
    return 1;
}

char *UVSGMessage(char *headerChar, int checksum, char *charArray) {
    char *hexString = calloc(strlen(charArray)*3+strlen(headerChar), sizeof *hexString);
    int i, j, strLength = 0;
    strLength = sprintf(hexString, "%s", headerChar);
    for (i=0;i<strlen(charArray);i++) {
        strLength += sprintf(hexString+strLength, "%x", (int)charArray[i]);
        if ((int)charArray[i] == 0x0d) charArray[i] = 0x20;
        if ((int)charArray[i] == 0x0a) charArray[i] = 0x20;
        checksum = checksum ^ (int)charArray[i];
    }
    strLength += sprintf(hexString+strLength, "00%x", checksum);
    
    return hexString;
}

char *UVSGMessage2(char *headerChar, int checksum, char *charDataArray) {
    char *hexString = calloc(strlen(headerChar)+strlen(charDataArray)+2, sizeof *hexString);
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
        if ((int)result[j] == 0x0d) result[j] = 0x20;
        if ((int)result[j] == 0x0a) result[j] = 0x20;
        checksum = checksum ^ (int)result[j];
    }
    
    char *checksumString = calloc(2, sizeof *checksumString);
    sprintf(checksumString, "%x", checksum);
    strcat(hexString, checksumString);
    return hexString;
}

char *selectCode(char *charArray) {
    return UVSGMessage("", 0xBE, charArray);
}

char *UVSGStart(char *selectCodeChar) {
    char *headerString = calloc((6+strlen(selectCodeChar)+4), sizeof *headerString);
    int strLength = 0;
    
    strLength = sprintf(headerString, "55aa41");
    strLength += sprintf(headerString+strLength, "%s", selectCode(selectCodeChar));
    
    return headerString;
}

char *UVSGHeader(char *selectCodeChar, char *modeCode) {
    char *headerString = calloc(4+(2*sizeof(modeCode)), sizeof *headerString);
    sprintf(headerString, "55aa%s", modeCode);
    return headerString;
}

char *titleMessage(char *charArray, char *selectCode) {
    return UVSGMessage(UVSGHeader(selectCode, "54"), 0xAB, charArray);
}

char *programMessage(char *hexCharArray, char *selectCode) {
    return UVSGMessage2(UVSGHeader(selectCode, "50"), 0xAF, hexCharArray);
}

char *channelMessage(char *hexCharArray, char *selectCode) {
    return UVSGMessage2(UVSGHeader(selectCode, "43"), 0xBC, hexCharArray);
}

char *startMessage(char *selectCode) {
    return UVSGStart(selectCode);
}

char *endMessage(char *selectCode) {
    return UVSGHeader(selectCode, "BBBB00FF");
}

void UDPSend(char *hexArray, UVCommand commandType) {
    int j, length;
    for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
        int complete = 0, i=0;
        char *buf;
        if (commandType == UVCommandNone) {
            buf = calloc(BUFLEN, sizeof *buf);
            sprintf(buf, "%s", hexArray);
            if (j == 0) printf("Sending %s\n", buf);
        } else if (commandType == UVCommandStart) {
            buf = startMessage(EPGClients[j].EPGSelectCode);
            printf("Sending %s\n", buf);
        } else if (commandType == UVCommandEnd) {
            buf = endMessage(EPGClients[j].EPGSelectCode);
            printf("Sending %s\n", buf);
        } else if (commandType == UVCommandTitle) {
            buf = titleMessage(EPGClients[j].EPGTitle, EPGClients[j].EPGSelectCode);
            printf("Sending %s\n", buf);
        } else if (commandType == UVCommandProgram) {
            buf = programMessage(hexArray, "*");
            printf("Sending %s\n", buf);
        } else if (commandType == UVCommandChannel) {
            buf = channelMessage(hexArray, EPGClients[j].EPGSelectCode);
            printf("Sending %s\n", buf);
        }
        while (!complete) {
            length = strlen(buf);
            si_other.sin_port = htons(EPGClients[j].EPGPort);
            inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
            if (sendto(s, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
            if (strlen(buf)>BUFLEN) buf += BUFLEN;
            else complete = 1;
            // 8 bits per byte, 2400 bits per second, 1000 miliseconds in a second
        }
    }
    float timeToSend = ((float)length/2.0/240.0)*1000.0;
    msleep((long)timeToSend);
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
        
        while (fgets(line, sizeof line, file) != NULL) {
            int i;
            int channel = atoi(line);
            /*char channel[2];
            strncpy(channel, line, strlen(line)-1);
            str2[5]='\0';*/
            for (i=0;i<48;i++) {
                char *URLString = "curl http://home.winxblog.com/prevueprogram.php?channel=%d\\&timeslot=%d > ~/.prevue/program";
                char *programURL = calloc(strlen(programURL)+1, sizeof *fullPath);
                sprintf(programURL, URLString, channel, i);
                //printf("\n%s\n", programURL);
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
    system("curl http://home.winxblog.com/prevuechannel.php > ~/.prevue/channels");
    char *path = "/.prevue/channels";
    char *home = getenv("HOME");
    char *fullPath = calloc(strlen(path)+strlen(home)+1, sizeof *fullPath);
    sprintf(fullPath, "%s%s", home, path);
    UDPSend(hexOfFile(fullPath), UVCommandChannel);
    free(fullPath);
}

int main(int argc, char *argv[]) {
    system("mkdir -p ~/.prevue");
    slen = sizeof(si_other);
    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket error.");
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    
    EPGClients[0].EPGIP = "127.0.0.1";
    EPGClients[0].EPGPort = 5556;
    EPGClients[0].EPGTitle = "              PREVUE GUIDE";
    EPGClients[0].EPGSelectCode = "*";
    EPGClients[1].EPGIP = "127.0.0.1";
    EPGClients[1].EPGPort = 5541;
    EPGClients[1].EPGTitle = "        Electronic Program Guide";
    EPGClients[1].EPGSelectCode = "*";
    
    while(1) {
        /*sendClock(s, si_other, slen);
        msleep(800);
        sendTitles(s, si_other, slen);
        msleep(800);        
        sendSettings(s, si_other, slen);
        msleep(800);
        sendChannels(s, si_other, slen);
        msleep(800);
        sendPrograms(s, si_other, slen);
        msleep(800);*/
        printf("Enter a UVSG satellite data command, or type 'channel', 'title', 'settings', or 'end'.\nPREVUE>");
        char origCommandString[255];
        char commandString[255];
        fgets(origCommandString, sizeof(origCommandString), stdin);
        int i;
        
        for (i=0;i<strlen(origCommandString)-1;i++) {
            commandString[i] = origCommandString[i];
        }
        commandString[i+1] = 0x00;
        if (strcmp(commandString, "title") == 0) {
            sendTitles();
        } else if (strcmp(commandString, "settings") == 0) {
            sendSettings();
        } else if (strcmp(commandString, "clock") == 0) {
            sendClock();
        } else if (strcmp(commandString, "channel") == 0) {
            sendChannels();
        } else if (strcmp(commandString, "program") == 0) {
            sendPrograms();
        } else if (strcmp(commandString, "start") == 0) {
            sendStart();
        } else if (strcmp(commandString, "end") == 0) {
            sendEnd();
        } else if (strcmp(commandString, "bigc") == 0) {
            UDPSend(hexOfFile("/Users/Ari/Desktop/Files/BIGC"), UVCommandNone);
        } else if (strcmp(commandString, "filechannel") == 0) {
            UDPSend(hexOfFile("/Users/Ari/Desktop/Prevue Technical/channel"), UVCommandChannel);
        } else if (strcmp(commandString, "fileprogram") == 0) {
            UDPSend(hexOfFile("/Users/Ari/Desktop/Prevue Technical/program"), UVCommandProgram);
        } else {
            char *path = calloc(40, sizeof *path);
            strcpy(path, "/Users/Ari/Desktop/Files/");
            strcat(path, commandString);
            char *hex = hexOfFile(path);
            if (hex) UDPSend(hex, UVCommandNone);
            else UDPSend(commandString, UVCommandNone);
        }
    }
    
    close(s);
    return 0;
}