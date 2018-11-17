#include "sender.h"

struct EPGMachine EPGClients[2];

char *UVSGMessage(char *headerChar, int checksum, char *charArray) {
    char *hexString = calloc(strlen(charArray)*3+strlen(headerChar), sizeof *hexString);
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
        /*if ((int)result[j] == 0x0d) result[j] = 0x20;
        if ((int)result[j] == 0x0a) result[j] = 0x20;*/
        checksum = checksum ^ (int)result[j];
    }
    
    char *checksumString = calloc(2, sizeof *checksumString);
    sprintf(checksumString, "%x", checksum);
    strcat(hexString, checksumString);
    return hexString;
}

char *UVSGStart(char *selectCodeChar) {
    char *headerString = calloc((6+strlen(selectCodeChar)+4), sizeof *headerString);
    int strLength = 0;
    
    strLength = sprintf(headerString, "55aa41");
    strLength += sprintf(headerString+strLength, "%s", UVSGMessage("", 0xBE, selectCodeChar));
    
    return headerString;
}

char *UVSGHeader(char *selectCodeChar, char *modeCode) {
    char *prepend = "";
    char *startChar = "";
    if (!(strcmp(selectCodeChar, "") == 0)) startChar = UVSGStart(selectCodeChar);
    if (!(strcmp(selectCodeChar, "*") == 0) && !(strcmp(selectCodeChar, "") == 0)) prepend = "55AABBBB00FF";
    char *headerString = calloc(4+(2*sizeof(modeCode))+strlen(startChar)+strlen(prepend), sizeof *headerString);
    
    sprintf(headerString, "%s%s55aa%s", prepend, startChar, modeCode);
    return headerString;
}

void UDPSend(char *hexArray, UVCommand commandType) {
    int j, j2, i, clients;
    clients = sizeof EPGClients/sizeof EPGClients[0];
    char *command[clients];
    int length[clients], single = 0;
    for (j=0;(j<clients&&!single);j++) {
        if (commandType == UVCommandNone) {
            command[0] = calloc(BUFLEN, sizeof *command[0]);
            sprintf(command[0], "%s", hexArray);
            single = 1;
        } else if (commandType == UVCommandStart) {
            command[0] = UVSGStart(hexArray);
            single = 1;
        } else if (commandType == UVCommandEnd) {
            command[j] = UVSGHeader("", "BBBB00FF");
        } else if (commandType == UVCommandTitle) {
            command[j] = UVSGMessage(UVSGHeader(EPGClients[j].EPGSelectCode, "54"), 0xAB, EPGClients[j].EPGTitle);
        } else if (commandType == UVCommandProgram) {
            command[0] = UVSGMessage2(UVSGHeader("", "50"), 0xAF, hexArray);
            single = 1;
        } else if (commandType == UVCommandClock) {
            command[0] = UVSGMessage2(UVSGHeader("*", "4B"), 0xB4, hexArray);
            single = 1;
        } else if (commandType == UVCommandChannel) {
            command[0] = hexArray;
            single = 1;
        }
        length[j] = strlen(command[j]);
    }
    if (single) {
        printf("Sending %s\n", command[0]);
        for (i=0;i<length[0];i+=2) {
            char send[3];
            send[0] = command[0][i];
            send[1] = command[0][i+1];
            send[2] = 0x00;
            printf("%s %d %d\n", send, i, length[0]);
            for (j=0;j<clients;j++) {
                si_other.sin_port = htons(EPGClients[j].EPGPort);
                inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
                if (sendto(s, send, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
            }
            // 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
            float timeToSend = (1.0*5.0/240.0)*1000.0;
            msleep((long)timeToSend);
        }
    } else {
        for (j2=0;j2<clients;j2++) {
            printf("Sending %s\n", command[j2]);
            for (i=0;i<length[j2];i+=2) {
                char send[3];
                send[0] = command[j2][i];
                send[1] = command[j2][i+1];
                send[2] = 0x00;
                printf("%s %d %d\n", send, i, length[j2]);
                for (j=0;j<clients;j++) {
                    si_other.sin_port = htons(EPGClients[j].EPGPort);
                    inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
                    if (sendto(s, send, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
                }
                // 240 bytes per second, 1000 miliseconds in a second, but we need to go slower because of UDP
                float timeToSend = (1.0*5.0/240.0)*1000.0;
                msleep((long)timeToSend);
            }
        }
    }
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

int main(int argc, char *argv[]) {
    system("mkdir -p ~/.prevue");
    slen = sizeof(si_other);
    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket error.");
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    
    EPGClients[0].EPGIP = "127.0.0.1";
    EPGClients[0].EPGPort = 5556;
    EPGClients[0].EPGTitle = "              PREVUE GUIDE";
    EPGClients[0].EPGSelectCode = "GA2*";
    EPGClients[1].EPGIP = "127.0.0.1";
    EPGClients[1].EPGPort = 5541;
    EPGClients[1].EPGTitle = "        Electronic Program Guide";
    EPGClients[1].EPGSelectCode = "*JR*";
    
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
        commandString[i] = 0x00;
        char *argument, *command;
        command = strtok(commandString, " ");
        argument = strtok(NULL, " ");
        
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
