import os
def jilog(text):
    print(f"{text}")

def jinput(texto):
    return input(f"{texto} > ")



def conf():
    # Hostapd
    h_name = jinput("Nombre del hotspot")
    h_iface = jinput("Interfaz de red (Debe estar en modo monitor)")
    h_channel = jinput("Canal del hotspot")
    os.system(f'echo "interface={h_iface}" > hostapd.conf')
    os.system(f'echo "driver=nl80211" >> hostapd.conf')
    os.system(f'echo "ssid={h_name}" >> hostapd.conf')
    os.system(f'echo "hw_mode=g" >> hostapd.conf')
    os.system(f'echo "channel={h_channel}" >> hostapd.conf')
    os.system(f'echo "macaddr_acl=0" >> hostapd.conf')
    os.system(f'echo "auth_algs=1" >> hostapd.conf')
    os.system(f'echo "ignore_broadcast_ssid=0" >> hostapd.conf')
    # Dnsmasq
    os.system(f'echo "interface={h_iface}\n" > dnsmasq.conf')
    os.system(f'echo "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h\n" >> dnsmasq.conf')
    os.system(f'echo "dhcp-option=3,192.168.1.1\n" >> dnsmasq.conf')
    os.system(f'echo "dhcp-option=6,192.168.1.1\n" >> dnsmasq.conf')
    os.system(f'echo "server=8.8.8.8\n" >> dnsmasq.conf')
    os.system(f'echo "log-queries\n" >> dnsmasq.conf')
    os.system(f'echo "log-dhcp\n" >> dnsmasq.conf')
    os.system(f'echo "listen-address=127.0.0.1\n" >> dnsmasq.conf')
    os.system(f'echo "address=/#/192.168.1.1\n" >> dnsmasq.conf')
    
def iniciar_hostapd():
    jilog("Iniciando hostapd.")
    os.system("hostapd hostapd.conf > /dev/null 2>&1 &")
if __name__ == "__main__":
    conf()
    iniciar_hostapd()