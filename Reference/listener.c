#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <unistd.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <pthread.h>
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
#include <netinet/in.h>

#define BUFLEN 8192
#define PORT 5541

void diep(char *s) {
    perror(s);
    exit(1);
}

int main(void) {
    struct sockaddr_in si_me, si_other;
    int s, i, slen=sizeof(si_other);
    char buf[BUFLEN];
    
    struct termios options;
    int baudRate = 2400;
    int serialFileDescriptor = open("/dev/cu.usbserial", O_RDWR | O_NOCTTY | O_NONBLOCK);
    
    if (serialFileDescriptor == -1) { 
		printf("NOPE");
    } else {
        printf("YEP %d", serialFileDescriptor);
    }
    ioctl(serialFileDescriptor, TIOCEXCL);
    fcntl(serialFileDescriptor, F_SETFL, 0);
    tcgetattr(serialFileDescriptor, &options);
    cfmakeraw(&options);
    ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
    
    if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) diep("Socket error.");
    
    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(PORT);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(s, &si_me, sizeof(si_me)) == -1) diep("bind");
    
    while(1) {
        if (recvfrom(s, buf, BUFLEN, 0, &si_other, &slen) == -1) diep("recvfrom()");
        int i=0, j;
        char *hexPtr = buf;
        unsigned int *result = calloc(strlen(buf)/2 + 1, sizeof *result);
    
        while (sscanf(hexPtr, "%02x", &result[i++])) {
            hexPtr += 2;
            if (hexPtr >= buf + strlen(buf)) break;
        }
        
        printf("Received packet from %s:%d\nHex: %s\nData: ", 
        inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port), buf);
        for (j = 0; j < i; j++) {
            printf("%c", result[j]);
            write(serialFileDescriptor, &result[j], 1);
        }
        printf("\n\n");
    }
    close(s);
    return 0;
}
