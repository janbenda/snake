#!/usr/bin/python
#nebo taky takhle
#from socket import *

#serverName = '127.0.0.1'
#serverPort = 12000
#clientSocket = socket(AF_INET, SOCK_DGRAM)
#message = input('Input lowercase sentence:')
#clientSocket.sendto(message,(serverName, serverPort))
#modifiedMessage, serverAddress = clientSocket.recvfrom(2048)
#print (modifiedMessage)
#clientSocket.close()

 # Socket client example in python

import socket
import sys  

#host = 'localhost'
#port = 49200  # test
host = '80.82.152.87'
port = 52222  # test

# create socket
print('# Creating socket')
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
except socket.error:
    print('Failed to create socket')
    sys.exit()

print('# Getting remote IP address') 
try:
    remote_ip = socket.gethostbyname( host )
except socket.gaierror:
    print('Hostname could not be resolved. Exiting')
    sys.exit()

# Connect to remote server
print('# Connecting to server, ' + host + ' (' + remote_ip + ')')
s.connect((remote_ip , port))

# Send data to remote server
print('# Sending data to server')
#request = 'Ahoj Svete\n'
request = '''
{
    "Parameters": [
        {
            "Name": "odeberatel",
            "Value": ""
        }
        {
            "Name": "par2",
            "Value": "val2"
        }
    ]
}
\n'''

try:
    s.sendall(request.encode())
except socket.error:
    print('Send failed')
    sys.exit()

# Receive data
print('# Receive data from server')
reply = s.recv(4096).decode()

print(reply)

print('# Sending data to server')
request = 'nashledanou\n'

try:
    s.sendall(request.encode())
except socket.error:
    print('Send failed')
    sys.exit()

# Receive data
print('# Receive data from server')
reply = s.recv(4096).decode()

print(reply)
