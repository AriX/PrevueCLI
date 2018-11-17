#include <windows.h>
#include <winsock2.h>
#include <stdint.h>
#define BUFLEN 8192
#define PORT 5556
HANDLE hSerial;
void uSleep(int waitTime);

void CTRL(int r) {
	if (r) EscapeCommFunction(hSerial, SETRTS);
	else EscapeCommFunction(hSerial, CLRRTS);
	uSleep(3176);
}

void CTRLGroup(int r, int s) {
	printf("%d", r);
	int i;
	for (i=0;i<5;i++) {
		CTRL(r);
	}
    for (i=0;i<5;i++) {
		CTRL(s);
	}
}

void sendByte(int8_t byt) {
		CTRL(1); CTRL(1); CTRL(1); CTRL(1); CTRL(1); CTRL(1);
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

int main() {
	// Set up serial
	LPCSTR portname = "COM1";
	DWORD accessdirection = GENERIC_WRITE;
	hSerial = CreateFile(portname, accessdirection, 0, 0, OPEN_EXISTING, 0, 0);
	DCB dcbSerialParams = {0};
	dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
	GetCommState(hSerial, &dcbSerialParams);
	dcbSerialParams.BaudRate = 2400;
	dcbSerialParams.ByteSize = 8;
	dcbSerialParams.StopBits = ONESTOPBIT;
	dcbSerialParams.Parity = NOPARITY;
	dcbSerialParams.fRtsControl = RTS_CONTROL_ENABLE;
	SetCommState(hSerial, &dcbSerialParams);
	COMMTIMEOUTS timeouts = {0};
	timeouts.WriteTotalTimeoutConstant = 50;
	timeouts.WriteTotalTimeoutMultiplier = 10;
	SetCommTimeouts(hSerial, &timeouts);
	
	// Set up UDP
	char buf[BUFLEN];
	struct sockaddr_in si_me, si_other;
	int slen = (int)sizeof(si_other);
	struct WSAData data;
	WSAStartup(0x0101, &data);

	si_me.sin_family = AF_INET;
	si_me.sin_addr.s_addr = inet_addr(INADDR_ANY);
	si_me.sin_port = htons(PORT);

	SOCKET s = socket(AF_INET, SOCK_DGRAM, 0);
	char host_name[256];
    gethostname(host_name, sizeof(host_name));
    struct hostent *hp = gethostbyname(host_name);
	
    si_me.sin_addr.S_un.S_un_b.s_b1 = hp->h_addr_list[0][0];
    si_me.sin_addr.S_un.S_un_b.s_b2 = hp->h_addr_list[0][1];
    si_me.sin_addr.S_un.S_un_b.s_b3 = hp->h_addr_list[0][2];
    si_me.sin_addr.S_un.S_un_b.s_b4 = hp->h_addr_list[0][3];
	bind(s, (struct sockaddr *)&si_me, sizeof(si_me));
	
	while(1) {
        if (recvfrom(s, buf, BUFLEN, 0, (struct sockaddr *)&si_other, &slen) == -1) {
			printf("Receive error: %d", WSAGetLastError());
			break;
		}
        int i = 0, j, q;
        char *hexPtr = buf;
        unsigned int *result = calloc(strlen(buf)/2 + 1, sizeof *result);
    
        while (sscanf(hexPtr, "%02x", &result[i++])) {
            hexPtr += 2;
            if (hexPtr >= buf + strlen(buf)) break;
        }
        
        printf("Received packet from %s:%d\nHex: %s\nData: ", 
        inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), buf);
		DWORD dwBytesRead = 0;
		//for (q = 0; q < 5000; q++) {
			for (j = 0; j < i; j++) {
				//WriteFile(hSerial, &result[j], 1, &dwBytesRead, NULL);
				sendByte(result[j]);
			}
		//	p += 3;
		//}
        printf("\n\n");
		free(result);
    }
	
	CloseHandle(hSerial);
	return 1;
}

void uSleep(int waitTime) {
    __int64 time1 = 0, time2 = 0, sysFreq = 0;

    QueryPerformanceCounter((LARGE_INTEGER *) &time1);
    QueryPerformanceFrequency((LARGE_INTEGER *)&sysFreq);

    do {
        QueryPerformanceCounter((LARGE_INTEGER *) &time2);
    } while((time2-time1) < waitTime);
}