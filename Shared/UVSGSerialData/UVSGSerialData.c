//
//  UVSGSerialData.c
//  PrevuePackage
//
//  Created by Ari on 4/18/20.
//

#include "UVSGSerialData.h"
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <Ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

// MARK: Platform-specific declarations

#ifdef _WIN32

/**
 Windows declarations
 */
typedef SOCKET UVSGSocket;
#define close _close

#ifndef EWOULDBLOCK
#define EWOULDBLOCK WSAEWOULDBLOCK
#define EAGAIN EWOULDBLOCK
#define ECONNRESET WSAECONNRESET
#endif

#ifndef __MINGW32__
typedef size_t ssize_t;
#endif

#else

/**
 POSIX declarations
 */
typedef int UVSGSocket;
#define SOCKADDR_INET struct sockaddr_storage
#define INVALID_SOCKET -1

#endif

static int getUVSGSocketError(void) {
#ifdef _WIN32
    return WSAGetLastError();
#else
    return errno;
#endif
}

// MARK: Internal

#define SERIAL_TCP_BUFFER_LENGTH 1024

typedef enum {
    UVSGConnectionStatusStopped = 0,
    UVSGConnectionStatusError,
    UVSGConnectionStatusWaitingForConnection,
    UVSGConnectionStatusConnected
} UVSGConnectionStatus;

struct UVSGSerialDataReceiver {
    UVSGConnectionStatus connectionStatus;
    UVSGSocket tcpSocket;
    UVSGSocket tcpConnection;
    char buffer[SERIAL_TCP_BUFFER_LENGTH];
};

struct UVSGSerialDataSender {
    UVSGSocket tcpSocket;
};

static void UVSGInitializeSocketSupport(void) {
    static bool initialized = false;
    if (initialized)
        return;
    
    // Perform Windows-specific initialization
#ifdef _WIN32
    static WSADATA wsadata;
    if (WSAStartup(MAKEWORD(2, 2), &wsadata))
        fprintf(stderr, "UVSGSerialData: WSAStartup failed with error %d", WSAGetLastError());
#endif

    initialized = true;
}

static UVSGSocket UVSGCreateTCPSocket(void) {
    UVSGInitializeSocketSupport();

    // Create socket
    UVSGSocket tcpSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (tcpSocket == INVALID_SOCKET)
        fprintf(stderr, "UVSGSerialDataReceiver: TCP socket creation error: %d", getUVSGSocketError());
    
    return tcpSocket;
}

static UVSGSocket UVSGCreateTCPSocketForReceiving(int port) {
    UVSGSocket tcpSocket = UVSGCreateTCPSocket();
    if (tcpSocket == INVALID_SOCKET)
        return tcpSocket;
    
    // Set reuse address option on socket
    int socketOptionValue = 1;
    int result = setsockopt(tcpSocket, SOL_SOCKET, SO_REUSEADDR, (char *)&socketOptionValue, sizeof(socketOptionValue));
    if (result < 0) {
        fprintf(stderr, "UVSGSerialDataReceiver: setsockopt(SO_REUSEADDR) failed: %d", getUVSGSocketError());
        close(tcpSocket);
        return INVALID_SOCKET;
    }
    
    // Set socket to non-blocking
#ifdef _WIN32
    u_long mode = 1;  // 1 to enable non-blocking socket
    int status = ioctlsocket(tcpSocket, FIONBIO, &mode);
#else
    int status = fcntl(tcpSocket, F_SETFL, fcntl(tcpSocket, F_GETFL, 0) | O_NONBLOCK);
#endif
    if (status != 0) {
        fprintf(stderr, "UVSGSerialDataReceiver: fcntl(O_NONBLOCK) failed: %d", getUVSGSocketError());
        close(tcpSocket);
        return INVALID_SOCKET;
    }
    
    // Bind socket to a port
    struct sockaddr_in serverAddress = {0};
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(port);
    serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    result = bind(tcpSocket, (struct sockaddr *)&serverAddress, sizeof(serverAddress));
    if (result < 0) {
        fprintf(stderr, "UVSGSerialDataReceiver: bind() failed: %d", getUVSGSocketError());
        close(tcpSocket);
        return INVALID_SOCKET;
    }
    
    // Make socket ready to accept connections
    result = listen(tcpSocket, 1);
    if (result < 0) {
        fprintf(stderr, "UVSGSerialDataReceiver: listen() failed: %d\n", getUVSGSocketError());
        close(tcpSocket);
        return INVALID_SOCKET;
    }

    return tcpSocket;
}

static void UVSGSerialDataReceiverAcceptConnection(UVSGSerialDataReceiver *receiver) {
    // Accept any waiting connection requests
    socklen_t clientAddressLength = sizeof(SOCKADDR_INET);
    char clientAddress[sizeof(SOCKADDR_INET)];
    UVSGSocket connection = accept(receiver->tcpSocket, (struct sockaddr *)clientAddress, &clientAddressLength);
    if (connection == -1) {
        int error = getUVSGSocketError();
        
        // No connections are waiting
        if (error == EWOULDBLOCK)
            return;
        
        fprintf(stderr, "UVSGSerialDataReceiver: accept() failed: %d\n", error);
        return;
    }
    
    receiver->connectionStatus = UVSGConnectionStatusConnected;
    receiver->tcpConnection = connection;
}

static size_t UVSGSerialDataReceiverReadFromConnection(UVSGSerialDataReceiver *receiver, void **receivedData) {
    ssize_t byteCount = recv(receiver->tcpConnection, receiver->buffer, SERIAL_TCP_BUFFER_LENGTH, 0);
    int error = getUVSGSocketError();

    if (byteCount == 0 || (byteCount < 0 && error == ECONNRESET)) {
        // Client disconnected
        close(receiver->tcpConnection);
        receiver->connectionStatus = UVSGConnectionStatusWaitingForConnection;
        return 0;
    }

    if (byteCount < 0) {
        // No data is waiting
        if (error == EAGAIN)
            return 0;
        
        fprintf(stderr, "UVSGSerialDataReceiver: Error reading from socket: %d\n", error);
        return 0;
    }
    
    *receivedData = receiver->buffer;
    return byteCount;
}

// MARK: Public interface

UVSGSerialDataReceiver *UVSGSerialDataReceiverCreate(void) {
    UVSGSerialDataReceiver *receiver = malloc(sizeof(UVSGSerialDataReceiver));
    receiver->connectionStatus = UVSGConnectionStatusStopped;
    return receiver;
}

bool UVSGSerialDataReceiverStart(UVSGSerialDataReceiver *receiver, int port) {
    UVSGSocket socket = UVSGCreateTCPSocketForReceiving(port);
    
    if (socket == INVALID_SOCKET) {
        receiver->connectionStatus = UVSGConnectionStatusError;
        return false;
    }
    
    receiver->connectionStatus = UVSGConnectionStatusWaitingForConnection;
    receiver->tcpSocket = socket;
    return true;
}

void UVSGSerialDataReceiverStop(UVSGSerialDataReceiver *receiver) {
    switch (receiver->connectionStatus) {
        case UVSGConnectionStatusStopped:
        case UVSGConnectionStatusError:
            return;
        case UVSGConnectionStatusWaitingForConnection:
            close(receiver->tcpConnection);
        case UVSGConnectionStatusConnected:
            close(receiver->tcpSocket);
            receiver->connectionStatus = UVSGConnectionStatusStopped;
    }
}

void UVSGSerialDataReceiverFree(UVSGSerialDataReceiver *receiver) {
    UVSGSerialDataReceiverStop(receiver);
    free(receiver);
}

bool UVSGSerialDataReceiverIsStarted(UVSGSerialDataReceiver *receiver) {
    UVSGConnectionStatus connectionStatus = receiver->connectionStatus;
    return (connectionStatus == UVSGConnectionStatusWaitingForConnection || connectionStatus == UVSGConnectionStatusConnected);
}

size_t UVSGSerialDataReceiverReceiveData(UVSGSerialDataReceiver *receiver, void **receivedData) {
    switch (receiver->connectionStatus) {
        case UVSGConnectionStatusStopped:
        case UVSGConnectionStatusError:
        default:
            return 0;
        case UVSGConnectionStatusWaitingForConnection:
            UVSGSerialDataReceiverAcceptConnection(receiver);
            return 0;
        case UVSGConnectionStatusConnected:
            return UVSGSerialDataReceiverReadFromConnection(receiver, receivedData);
    }
}

UVSGSerialDataSender *UVSGSerialDataSenderCreate(const char *host, int port) {
    UVSGSocket tcpSocket = UVSGCreateTCPSocket();
    if (tcpSocket == INVALID_SOCKET)
        return NULL;
    
    UVSGSerialDataSender *sender = malloc(sizeof(UVSGSerialDataSender));
    sender->tcpSocket = tcpSocket;
    
    struct sockaddr_in serverAddress = {0};
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(port);
    serverAddress.sin_addr.s_addr = inet_addr(host);

    // Connect to the server
    int result = connect(sender->tcpSocket, (struct sockaddr *)&serverAddress, sizeof(serverAddress));
    if (result != 0) {
        fprintf(stderr, "UVSGSerialData: connect() failed: %d\n", getUVSGSocketError());
        return false;
    }
    
    printf("UVSGSerialDataSender: Connected to server %s:%d\n", host, port);
    
    return sender;
}

void UVSGSerialDataSenderFree(UVSGSerialDataSender *sender) {
    printf("UVSGSerialDataSender: Disconnecting\n");
    
    close(sender->tcpSocket);
    free(sender);
}

bool UVSGSerialDataSenderSendData(UVSGSerialDataSender *sender, const void *data, size_t dataSize) {
    ssize_t bytesWritten = send(sender->tcpSocket, data, dataSize, 0);
    if (bytesWritten < 0) {
        fprintf(stderr, "UVSGSerialDataSender: send() failed: %d\n", getUVSGSocketError());
        return false;
    }
    
    return true;
}
