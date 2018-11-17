#include <libc.h>

#define BUFLEN 512

struct EPGMachine {
    char *EPGIP;
    char *EPGSelectCode;
    char *EPGTitle;
    int EPGPort;
};

struct EPGMachine EPGClients[1];

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

char *UVSGHeader(char *selectCodeChar, char *modeCode) {
    char *headerString = calloc(16+(2*sizeof(modeCode)), sizeof *headerString);
    int strLength = 0;
    
    strLength = sprintf(headerString, "55aa41");
    strLength += sprintf(headerString+strLength, "%s", selectCode(selectCodeChar));
    strLength += sprintf(headerString+strLength, "55aa");
    strLength += sprintf(headerString+strLength, "%s", modeCode);
    
    return headerString;
}

char *titleMessage(char *charArray, char *selectCode) {
    return UVSGMessage(UVSGHeader(selectCode, "54"), 0xAB, charArray);
}

char *channelMessage(char *hexCharArray, char *selectCode) {
    return UVSGMessage2(UVSGHeader(selectCode, "43"), 0xBC, hexCharArray);
}

char *programMessage(char *hexCharArray, char *selectCode) {
    return UVSGMessage2(UVSGHeader(selectCode, "50"), 0xAF, hexCharArray);
}

char *timeMessage(char *hexCharArray, char *selectCode) {
    return UVSGMessage2(UVSGHeader(selectCode, "4B"), 0xB4, hexCharArray);
}

char *endMessage(char *selectCode) {
    return UVSGHeader(selectCode, "BBBB00FF");
}

void sendTitles(int soc, struct sockaddr_in si_other, int slen) {
    int j;
    for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
        si_other.sin_port = htons(EPGClients[j].EPGPort);
        inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
        char *commandMessage = titleMessage(EPGClients[j].EPGTitle, EPGClients[j].EPGSelectCode);
        char buf[BUFLEN];
        printf("Sending %s\n", commandMessage);
        sprintf(buf, "%s", commandMessage);
        if (sendto(soc, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
    }
}

void sendChannels(int soc, struct sockaddr_in si_other, int slen) {
    int j;
    for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
        si_other.sin_port = htons(EPGClients[j].EPGPort);
        inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
        
        char *commandMessage = channelMessage("265B2020203220000000000000424253303036004B4242530000000081FFFFFFFFFFFF0000000000008AFFFF303000000342425330303600", EPGClients[j].EPGSelectCode);
        char buf[BUFLEN];
        printf("Sending %s\n", commandMessage);
        sprintf(buf, "%s", commandMessage);
        if (sendto(soc, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
    }
}

void sendEnd(int soc, struct sockaddr_in si_other, int slen) {
    int j;
    for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
        si_other.sin_port = htons(EPGClients[j].EPGPort);
        inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
        char *commandMessage = endMessage(EPGClients[j].EPGSelectCode);
        char buf[BUFLEN];
        printf("Sending %s\n", commandMessage);
        sprintf(buf, "%s", commandMessage);
        if (sendto(soc, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
    }
    return;
}

void sendSettings(int soc, struct sockaddr_in si_other, int slen) {
    int j;
    for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
        si_other.sin_port = htons(EPGClients[j].EPGPort);
        inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
        char *commandMessage = "55AA412A009455AA46414333304000000002355900590000000000000000CF";
        char buf[BUFLEN];
        printf("Sending %s\n", commandMessage);
        sprintf(buf, "%s", commandMessage);
        if (sendto(soc, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
    }
    return;
}

void sendPrograms(int soc, struct sockaddr_in si_other, int slen) {
    char buf[BUFLEN];
    return;
}

void sendClock(int soc, struct sockaddr_in si_other, int slen) {
    char buf[BUFLEN];
    return;
}

int main(int argc, char *argv[]) {
    struct sockaddr_in si_other;
    int s, i, slen=sizeof(si_other);
    
    if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) printf("Socket error.");
    
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    
    EPGClients[0].EPGIP = "127.0.0.1";
    EPGClients[0].EPGPort = 5556;
    EPGClients[0].EPGTitle = "        Electronic Program Guide";
    EPGClients[0].EPGSelectCode = "*";
    //EPGClients[0].EPGIP = "127.0.0.1";
    //EPGClients[0].EPGPort = 5556;
    //EPGClients[0].EPGTitle = "              PREVUE GUIDE";
    //EPGClients[0].EPGSelectCode = "*";
    
    char commandString[255];
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
        fgets(commandString, sizeof(commandString), stdin);
        if (strcmp(commandString, "title") == 10) {
            sendTitles(s, si_other, slen);
        } else if (strcmp(commandString, "settings") == 10) {
            sendSettings(s, si_other, slen);
        } else if (strcmp(commandString, "channel") == 10) {
            sendChannels(s, si_other, slen);
        } else if (strcmp(commandString, "end") == 10) {
            sendEnd(s, si_other, slen);
        } else {
            int j;
            for (j=0;j<(sizeof EPGClients / sizeof EPGClients[0]);j++) {
                si_other.sin_port = htons(EPGClients[j].EPGPort);
                inet_aton(EPGClients[j].EPGIP, &si_other.sin_addr);
                char buf[BUFLEN];
                printf("Sending %s\n", commandString);
                sprintf(buf, "%s", commandString);
                if (sendto(s, buf, BUFLEN, 0, (const struct sockaddr *)&si_other, slen) == -1) printf("sendto() failed");
            }
        }
    }
    
    close(s);
    return 0;
}