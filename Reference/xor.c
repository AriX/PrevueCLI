#import <stdio.h>

int main(int argc, char *argv[]) {
    int i=0, j, checksum;
    //char *buf = "0F12014127450083";
    char *buf = "333237043139393633303130323A3030133139393730393630323A303000B5";
    char *hexPtr = buf;
    unsigned int *result = calloc(strlen(buf)/2 + 1, sizeof *result);

    while (sscanf(hexPtr, "%02x", &result[i++])) {
        hexPtr += 2;
        if (hexPtr >= buf + strlen(buf)) break;
    }
    
    for (j = i; j > -1; j--) {
        //printf("%02x", (int)result[j]);
        if (j == (i-1)) {
            checksum = (int)result[j];
            printf("%02x", checksum);
        }
        if (j < (i-1)) {
            checksum = checksum ^ (int)result[j];
            printf("%02x", (int)result[j]);
            
        }
        //printf("%c", result[j]);
    }
    
    printf("\n%02x\n", checksum);
    //printf("%02x\n", 0xBC^0x0F^0x12^0x01^0x41^0x27^0x45^0x00);
    //printf("%02x\n", 0x83^0x00^0x45^0x27^0x41^0x01^0x12^0x0F);
}
