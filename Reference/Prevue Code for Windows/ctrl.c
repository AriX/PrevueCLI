#include <windows.h>
#include <winsock2.h>
#include <stdint.h>
void uSleep(int waitTime);
HANDLE hSerial;

void CTS(int r) {
	if (r) EscapeCommFunction(hSerial, SETRTS);
	else EscapeCommFunction(hSerial, CLRRTS);
	uSleep(1000);
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

int main() {
	// Set up serial
	hSerial = CreateFile("COM1", GENERIC_READ|GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
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
	
	int num = 0;
	//while(1) {
		//uint8_t byt;
		//scanf("%02x", &byt);
		sendByte(0x05);
		Sleep(500);
		sendByte(0x01);
		Sleep(500);
		sendByte(0x01);
		Sleep(500);
		sendByte(0x0D);
		Sleep(500);
		sendByte(0x09);
		Sleep(500);
		/*num++;
		printf("%d\n", num);
		sendByte(0x43);
		num++;
		printf("%d\n", num);
		sendByte(0x43);
		num++;
		printf("%d\n", num);
		sendByte(0x0D);
		num++;
		printf("%d\n", num);
		sendByte(0x08);
		num++;
		printf("%d\n", num);
		Sleep(1000);*/
	//}
	
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