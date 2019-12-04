cat input.txt | grep '[0-9]' | cut -d" " -f1-5 | sed -e 's/^/Vlan /' | sed 's/\<Vlan [0-9][0-9][0-9]\>/& \nname/' | sed 's/\<Vlan [0-9]\>/& \nname/' | sed 's/\<Vlan [0-9][0-9]\>/& \nname/' | sed '/Vlan     /d' > output.txt

#created by Thomas F from eazeysec.com
