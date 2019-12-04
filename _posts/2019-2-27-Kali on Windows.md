---
layout: post
title: Kali on Windows
writtendate: 27th Feb 2019
img: images/subsystem.JPG
---

I usually run my Kali distro in a VM, but since I'm attacking another VM and my computer is powered by a bag of cats I needed another method.

I discovered a cool Windows feature (not heavily documented) that could assist in running basic Bash commands natively using Windows Subsystem for Linux (sounds like pure techno-babble but honestly that’s what it's called). 

Here how it's done on Windows 10:

### Helpful Links

- [Windows Subsystem FAQ](https://docs.microsoft.com/en-us/windows/wsl/faq)


### Step 1

` Windows key + R > Type "control" `

Click "Turn Windows features on of off"
![Native VM-1](/images/Native VM-1.JPG)

Tick the magic box
"Windows Subsystem for Linux

![Native VM-2](/images/Native VM-2.JPG)


### Step 2

` Windows key + R > Type "bash" `

It should prompt you to download a Linux APP from the store.

` Windows key + R > Type "ms-windows-store:" ` (don't forget the colon at the end there)

Pick a Linux version you would like, I'd recommend Kali for our purposes but I have a  soft spot for SUSE since it was my first Linux distro.

![Native VM-3](/images/Native VM-3.JPG)

Click get (SUSE in this example)

![Native VM-4](/images/Native VM-4.JPG)


### Step 3

Will need a restart after Install

` Windows key + R > Type "bash" `

Should start a Linux bash terminal for you to work on with all the bells and whistles.



For me this meant I could run apt-get to install python, then run python scripts against a vulnerable VM utilizing the buffer overflow I mentioned above. Pretty sweet.

Cheers,

Thomas




