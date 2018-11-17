#include <stdio.h>
#include <time.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <grp.h>
#include <pwd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/ipc.h>
#include <sys/time.h>
#include <sys/shm.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <mysql/mysql.h>
#include <netinet/in.h>
#include <pthread.h>

#define BUFLEN 8192
#define INTERNALPORT 5500

#ifdef __APPLE__
#define EPGIPFORMAT "192.168.1.119"
#define TESTPATH "/Users/Ari/Desktop/Prevue Technical/Files/%s"
#else
#define EPGIPFORMAT row[1]
#define TESTPATH "/home/ninjastar/prevueserver/resources/testdir/%s"
#include <memcache.h>
#endif

struct sockaddr_in si_other, si_me2, si_other2;
int s, slen, s2, slen2=sizeof(si_other2), EPGMachines, currentBufferLength=0, bufferLocked;
char buf2[BUFLEN], *commandBuffer;

MYSQL *SQLConnection;

struct EPGMachine {
    char *EPGIP;
    char *EPGSelectCode;
    char *EPGTitle;
	char *EPGGrabber;
	char *EPGSettings;
    int EPGPort;
	int EPGType;
};

enum {
    UVCommandNone = 0,
    UVCommandStart = 1, 
    UVCommandEnd = 2,
	UVCommandReset = 3,
    UVCommandClock = 4,
    UVCommandTitle = 5,
    UVCommandChannel = 6,
    UVCommandProgram = 7,
    UVCommandSettings = 8,
    UVCommandAd = 9,
    UVCommandDownload = 10,
    UVCommandConfig = 11,
    UVCTRL = 12
};
typedef int UVCommand;

int msleep(unsigned long milisec);
char *UVSGStart(char *selectCodeChar);
char *UVSGHeader(char *selectCodeChar, char *modeCode);
void UDPSend(char *hexArray, UVCommand commandType);
void runCommand(char *command, char *argument, char *commandString);
void initializeMachines();

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
unsigned char *hex(const unsigned char *text) {
	return textToHex(text, strlen(text));
}
/*int hexsprintf(char *charPointer, char *format, ...) {
 va_list args;
 int d;
 char c, *s;
 
 va_start(args, fmt);
 while (*fmt)
 switch(*fmt++) {
 case 's':                       // string
 s = va_arg(args, char *);
 printf("string %s\n", s);
 break;
 case 'd':                       // int
 d = va_arg(args, int);
 printf("int %d\n", d);
 break;
 case 'c':                       // char
 // need a cast here since va_arg only
 // takes fully promoted types
 c = (char) va_arg(args, int);
 printf("char %c\n", c);
 break;
 }
 va_end(args);
 }*/
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
void sendClock() {
    time_t now = time(NULL);
	struct tm *ts = gmtime(&now);
    /*putenv("TZ=EST5EDT");
    tzset();*/
	struct tm *localizedtime = localtime(&now);
    
    char month[3];
    strftime(month, sizeof(month), "%m", ts);
    char dayofmonth[3];
    strftime(dayofmonth, sizeof(dayofmonth), "%d", ts);
    char year[5];
    strftime(year, sizeof(year), "%Y", ts);
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
    sprintf(hexYear, "%02x", atoi(year)-1900);
    char hexHour[3];
    sprintf(hexHour, "%02x", atoi(hour));
    char hexMin[3];
    sprintf(hexMin, "%02x", atoi(min));
    char hexSec[3];
    int secInt = atoi(sec);
    if (secInt > 59) secInt = 59;
    sprintf(hexSec, "%02x", secInt);
    char dst[3];
    dst[0] = 0x30;
    if (localizedtime->tm_isdst) dst[1] = 0x31;
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

unsigned int htoi(const char *ptr) {
    unsigned int value = 0;
    char ch = *ptr;
    while (ch == ' ' || ch == '\t') ch = *(++ptr);

    for (;;) {
        if (ch >= '0' && ch <= '9') value = (value << 4) + (ch - '0');
        else if (ch >= 'A' && ch <= 'F') value = (value << 4) + (ch - 'A' + 10);
        else if (ch >= 'a' && ch <= 'f') value = (value << 4) + (ch - 'a' + 10);
        else return value;
        ch = *(++ptr);
    }
}
