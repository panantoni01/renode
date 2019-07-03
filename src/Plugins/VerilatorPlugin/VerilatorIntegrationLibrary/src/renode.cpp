//
// Copyright (c) 2010-2021 Antmicro
//
// This file is licensed under the MIT License.
// Full license text is available in 'licenses/MIT.txt'.
//
#include "renode.h"

#define IO_THREADS 1

RenodeAgent::RenodeAgent(BaseBus* bus)
{
    interfaces.push_back(bus);
    interfaces[0]->tickCounter = 0;

    auto LogPrinter = [](const std::string& strLogMsg) { std::cout << strLogMsg << std::endl;  };
    mainSocket.reset(new CTCPClient(LogPrinter));
    senderSocket.reset(new CTCPClient(LogPrinter));
}

void RenodeAgent::addBus(BaseBus* bus)
{
    interfaces.push_back(bus);
}

void RenodeAgent::writeToBus(unsigned long long addr, unsigned long long value)
{
    try {
        interfaces[0]->write(addr, value);
        mainSocketSend(Protocol(ok, 0, 0));
    }
    catch(const char* msg) {
        log(3, msg);
        mainSocketSend(Protocol(error, 0, 0));
        isConnected = false;
    }
}

void RenodeAgent::readFromBus(unsigned long long addr)
{
    try {
        unsigned long long readValue = interfaces[0]->read(addr);
        mainSocketSend(Protocol(readRequest, addr, readValue));
    }
    catch(const char* msg) {
        log(3, msg);
        mainSocketSend(Protocol(error, 0, 0));
        isConnected = false;
    }
}

void RenodeAgent::pushToAgent(unsigned long addr, unsigned long value)
{
    senderSocketSend(Protocol(pushData, addr, value));
}

unsigned long RenodeAgent::requestFromAgent(unsigned long addr)
{
    senderSocketSend(Protocol(getData, addr, 0));
    Protocol* received = receive();
    return received->value;
}

void RenodeAgent::handshakeValid()
{
    Protocol* received = receive();
    if(received->actionId == handshake) {
        mainSocketSend(Protocol(handshake, 0, 0));
        isConnected = true;
    }
}

void RenodeAgent::tick(bool countEnable, unsigned long steps)
{
    for(BaseBus* b : interfaces)
        b->tick(countEnable, steps);
}

void RenodeAgent::reset()
{
    for(BaseBus* b : interfaces)
        b->reset();
}

void RenodeAgent::simulate(int receiverPort, int senderPort)
{
    mainSocket->Connect("127.0.0.1", std::to_string(receiverPort));
    senderSocket->Connect("127.0.0.1", std::to_string(senderPort));

    Protocol *result;
    long ticks;
    unsigned long readValue;
    handshakeValid();
    reset();

    while(isConnected) {
        result = receive();
        switch(result->actionId) {
            case invalidAction:
                break;
            case tickClock:
                ticks = result->value - interfaces[0]->tickCounter;
                if(ticks < 0) {
                    interfaces[0]->tickCounter -= result->value;
                }
                else {
                    tick(false, ticks);
                }
                interfaces[0]->tickCounter = 0;
                break;
            case writeRequest:
                writeToBus(result->addr, result->value);
                break;
            case readRequest:
                readFromBus(result->addr);
                break;
            case resetPeripheral:
                reset();
                break;
            case disconnect:
                isConnected = false;
                senderSocketSend(Protocol(ok, 0, 0));
                break;
            default:
                handleCustomRequestType(result);
                break;
        }
	delete result;
    }
}

void RenodeAgent::handleCustomRequestType(Protocol* message)
{
    log(2, std::string("Unhandled request type: %d", message->actionId).c_str());
}

void RenodeAgent::log(int logLevel, const char* data)
{
    senderSocketSend(Protocol(logMessage, strlen(data), logLevel));
    senderSocketSend(data);
}

void RenodeAgent::mainSocketSend(Protocol message)
{
    mainSocket->Send((char *)&message, sizeof(struct Protocol));
}

void RenodeAgent::senderSocketSend(Protocol request)
{
    senderSocket->Send((char *)&request, sizeof(Protocol));
}

void RenodeAgent::senderSocketSend(const char* text)
{
    senderSocket->Send(text, strlen(text));
}

Protocol* RenodeAgent::receive()
{
    size_t length = sizeof(Protocol);
    char *buffer = new char[length];
    mainSocket->CTCPClient::Receive(buffer, length);
    return (Protocol *)buffer;
}
