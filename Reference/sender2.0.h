#include <libc.h>
#define BUFLEN 3

struct sockaddr_in si_other;
int s, slen;

struct EPGMachine {
    char *EPGIP;
    char *EPGSelectCode;
    char *EPGTitle;
    int EPGPort;
};

enum {
    UVCommandNone = 0,
    UVCommandStart = 1, 
    UVCommandEnd = 2,
    UVCommandClock = 3,
    UVCommandTitle = 4,
    UVCommandChannel = 5,
    UVCommandProgram = 6,
    UVCommandSettings = 7,
    UVCommandAd = 8
};
typedef int UVCommand;

int msleep(unsigned long milisec);
char *UVSGMessage(char *headerChar, int checksum, char *charArray);
char *UVSGMessage2(char *headerChar, int checksum, char *charDataArray);
char *UVSGStart(char *selectCodeChar);
char *UVSGHeader(char *selectCodeChar, char *modeCode);
void UDPSend(char *hexArray, UVCommand commandType);

int msleep(unsigned long milisec) {
    struct timespec req={0};
    time_t sec=(int)(milisec/1000);
    milisec=milisec-(sec * 1000);
    req.tv_sec=sec;
    req.tv_nsec=milisec * 1000000L;
    while(nanosleep(&req,&req) == -1) continue;
    return 1;
}
unsigned char *textToHex(const unsigned char *text, int len) {
    int i;
    unsigned char *buffer = calloc((2*len)+1, sizeof *buffer);
    for (i=0; i<len; i++) sprintf(buffer+2*i, "%02x", (unsigned int)text[i]);
    return buffer;
}
char *hexOfFile(char *filename) {
    char *buffer = 0;
    int length;
    FILE *f = fopen(filename, "rb");
    if (f) {
        fseek (f, 0, SEEK_END);
        length = ftell(f);
        fseek (f, 0, SEEK_SET);
        buffer = malloc(length);
        if (buffer) {
            fread(buffer, 1, length, f);
        } else {
            return 0;
        }
        fclose(f);
    } else {
        return 0;
    }
    return textToHex(buffer, length);
}
void sendTitles() {
    UDPSend("", UVCommandTitle);
}
void sendStart(char *selectCode) {
    UDPSend(selectCode, UVCommandStart);
}
void sendEnd() {
    UDPSend("", UVCommandEnd);
}
void sendSettings() {
    UDPSend("55AA46414333304000000002325900590000000000000000C8", UVCommandNone);
}
void sendClock() {
    time_t now = time(NULL);
    struct tm *ts = gmtime(&now);
    
    char month[3];
    strftime(month, sizeof(month), "%m", ts);
    char dayofmonth[3];
    strftime(dayofmonth, sizeof(dayofmonth), "%d", ts);
    char year[3];
    strftime(year, sizeof(year), "%y", ts);
    char hour[3];
    strftime(hour, sizeof(hour), "%H", ts);
    char min[3];
    strftime(min, sizeof(min), "%M", ts);
    char sec[3];
    strftime(sec, sizeof(sec), "%S", ts);
    
    char dayofweek[3];
    strftime(dayofweek, sizeof(dayofweek), "0%w", ts);
    char hexMonth[3];
    sprintf(hexMonth, "%02x", atoi(month)-1);
    char hexDay[3];
    sprintf(hexDay, "%02x", atoi(dayofmonth)-1);
    char hexYear[3];
    sprintf(hexYear, "%02x", atoi(year));
    char hexHour[3];
    sprintf(hexHour, "%02x", atoi(hour));
    char hexMin[3];
    sprintf(hexMin, "%02x", atoi(min));
    char hexSec[3];
    int secInt = atoi(sec);
    if (secInt == 60) secInt -= 1;
    if (secInt == 61) secInt -= 2;
    sprintf(hexSec, "%02x", secInt);
    char dst[3];
    dst[0] = 0x30;
    if (ts->tm_isdst) dst[1] = 0x31;
    else dst[1] = 0x30;
    
    char modeK[18];
    modeK[0] = dayofweek[0];
    modeK[1] = dayofweek[1];
    modeK[2] = hexMonth[0];
    modeK[3] = hexMonth[1];
    modeK[4] = hexDay[0];
    modeK[5] = hexDay[1];
    modeK[6] = hexYear[0];
    modeK[7] = hexYear[1];
    modeK[8] = hexHour[0];
    modeK[9] = hexHour[1];
    modeK[10] = hexMin[0];
    modeK[11] = hexMin[1];
    modeK[12] = hexSec[0];
    modeK[13] = hexSec[1];
    modeK[14] = dst[0];
    modeK[15] = dst[1];
    modeK[16] = dst[0];
    modeK[17] = dst[0];
    modeK[18] = 0x00;
    UDPSend(modeK, UVCommandClock);
}