//
//  UVSGSerialData.h
//  PrevuePackage
//
//  Created by Ari on 4/18/20.
//

#include <stdbool.h>
#include <stdio.h>

typedef struct UVSGSerialDataReceiver UVSGSerialDataReceiver;
typedef struct UVSGSerialDataSender UVSGSerialDataSender;

/**
 UVSG TCP serial data receiver
 */

UVSGSerialDataReceiver *UVSGSerialDataReceiverCreate(void);
void UVSGSerialDataReceiverFree(UVSGSerialDataReceiver *receiver);

bool UVSGSerialDataReceiverStart(UVSGSerialDataReceiver *receiver, int port);
void UVSGSerialDataReceiverStop(UVSGSerialDataReceiver *receiver);
bool UVSGSerialDataReceiverIsStarted(UVSGSerialDataReceiver *receiver);

size_t UVSGSerialDataReceiverReceiveData(UVSGSerialDataReceiver *receiver, void **receivedData);

/**
 UVSG TCP serial data sender
 */
UVSGSerialDataSender *UVSGSerialDataSenderCreate(const char *host, int port);
void UVSGSerialDataSenderFree(UVSGSerialDataSender *sender);

bool UVSGSerialDataSenderSendData(UVSGSerialDataSender *sender, const void *data, size_t dataSize);
int UVSGSerialDataSenderGetSocket(UVSGSerialDataSender *sender);
