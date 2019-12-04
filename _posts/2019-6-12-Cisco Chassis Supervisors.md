---
layout: post
title: Cisco Supervisors 4 promotion!
writtendate: 12th Jun 2019
img: images/linecard.JPG
---

Thought I'd make a quick post about Cisco Chassis Supervisors. That is Cisco 4500/ 9400/ 6500 etc Catalyst Switches

The Cisco documentation for these things are like a minefield, of both good and bad information. (in my experience) I’ve put some helpful links at bottom.

I recently did a Supervisor + Access modules upgrade on one of our End of Support devices and figured I'd document how we go about something like this.

This is very real world, mistakes and all. 

# Basics:

![Linecard2](/images/linecard2.JPG)

- Cisco Chassis switches are like big dumb pieces of metal with a certain number of slots/ lines.

- Each slot can contain one line card module. 
(the naming for these can be confusing at times, i tend to use the term "line card", VMware admins tend to say blade, Cisco call it modules but confusingly they re-purpose this term for SFP's as well.)

- Each Chassis requires a "Supervisor" this is the brains of the operation, it is also the location where your configuration is stored. meaning if you swap Supervisor. you lose config, go figure!

- Supervisors usually have fastest port types. So is often used for Cross Connect to redundant Devices. eg. CORE switch to CORE switch.

- Each Line card module has to be compatible with the Chassis you connect it to, it also needs to be compatible with the Supervisor that is running the show. I've also seen cases where certain IOS versions don't like particular line card modules. 

- Access line card modules are hot swappable. generally you end up doing this Out of Hours though.

- At time of writing, I am aware that Cisco has removed the "legacy" backwards compatibility features on some IOS. This sucks btw! It was never great but could allow you to use older (generally unsupported) line cards in conjunction with newer supervisors 

![Linecard1](/images/linecard1.JPG)


### Helpful links

- [VMware Workstation](https://www.vmware.com/uk/products/workstation-player.html)
- [Cisco 4500 Datasheet](https://www.cisco.com/c/en/us/products/collateral/switches/catalyst-4500-series-switches/product_data_sheet0900aecd801792b1.html)
- [Cisco 4500 Line cards](https://www.cisco.com/c/en/us/products/collateral/interfaces-modules/catalyst-4500-series-line-cards/product_data_sheet0900aecd802109ea.pdf)



# Prep:

-	Assess the current set up and check Fibre ports/ EtherChannel’s/ Redundancy set up/ Switching & Routing / QoS

- Pre-test Benchmarking! Probably the most important thing. Test everything to see what works and what doesn't. Document as you go basic nature of site and services.

-	Check compatibility matrix and purchase new Supervisors for Correct chassis. In my case 4507. 
2 x WS-X45-SUP8L-E – SUPERVISOR LINE CARDS
3 x WS-X4748-RJ45V+E  - ACCESS LINE CARDS

-	When you upgrade a line card you need to migrate all the associated cabling. If like my example you have 3 x 48 ports worth of cabling, this is messy. So Identify and Label all of the key ports. ESX servers/ Trunks/ ISP links/ MPLS links/ etc. 

-	Get Remote console access to the device using an external method (internet via 4G phone/ Laptop & console cable). Use team viewer/ Any Desk/ Zoom to connect.

-	For simplicity, I usually eliminate devices from AAA on TACACs to reduce complexity of getting console to device. Ensuring I don’t end up locked out... nothing worse!

-	Backup configuration of the device, The supervisor holds this, so we will need to re-apply. Have a local copy of old config handy, so you can rebuild quickly. I usually roughly separate the config into fields: Basics (hostnames, domain names, SSH, RSA keys), Interfaces & HSRP, L2 VLANS, STP/ VTP, L3 VLANS, Routing, AAA/ TACACS. Notepad++ your friend! 

# Supervisor Upgrade:

-	Power down the switch.

-	Swap Supervisor module/s. unplug any cables, unscrew the left and right side, pull both levers and slide out like a kitchen drawer. New supervisor goes in the exact same way. From experience, this can sometimes be a 2 man job, due to surrounding cabling. Just be careful when inserting new line card. 

-	Connect up any associated Cross Connect cabling. Leave the Access Line cards for now, these are hot swappable. Plus our aim is to get a Proof of concept, ensuring no DoA (dead on arrival) line card modules.

-	Power on the switch

-	It should boot up and hopefully be just a default config screen.

-	Confirm that the license is LAN BASE 

``` show ver | i base ```

-	 Issue command "license boot level ipbase"

``` license boot level ipbase ```

``` wr mem ```

-	Reboot the switch

-	Might have to adjust conf reg: [Config Reg guide](http://www.cisco.com/c/en/us/support/docs/routers/10000-series-routers/50421-config-register-use.html)

-	At this point the switch comes up with IP Base 

``` show ver | I base ```

# Reconfigure:

-	Apply our backed up configuration! 
Basics (hostnames, domain names, SSH, RSA keys), Interfaces & HSRP, L2 VLANS, STP/ VTP, L3 VLANS, Routing, AAA/ TACACS.

-	Confirm connectivity and TSHOOT any issues at this point. Whilst you focus on the config, maybe ask an extra pair of hands to start work on the ACCESS line cards and associated cabling. These are dumb devices, and are hot swapable. So unplug all 48 cables, remove old ACCESS line card, replace with new one and plug cables back in. Once it’s inserts, you can see it using the ` show module ` command.

- Post Upgrade Testing: Remember all that Pre Upgrade Benchmarking? Do it again, ensure everything is as it was!

- Something that I always see missed from these types of posts, but I think is key... COMMUNICATE! Tell the world what you did, let them know to report issues as they see them, be on hand for troubleshooting if problems arrise. And lastly, take credit. These type of works are anything but routine. Be proud of your work!

Cheers,
Thomas

