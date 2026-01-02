# Configurar Wifi HotSpot en Yocto

Para crear un HotSpot wifi se puede hacer desde nmcli con el siguiente comando:

```
nmcli dev wifi hotspot ifname wlan0 con-name Hotspot ssid TychePruebas password "TT2020gw"
```

Antes de ejecutar este comando es recomendable asegurarse de que no hay otra conexión wifi activa y si la hay la podemos borrar o desactivar:

```
nmcli con down Tychetools

# o

nmcli con del TycheTools
```

Para activar y desactivar el HotSpot se usa:

```
nmcli con up Hotspot
nmcli con down Hotspot
nmcli con del Hotspot
```

## Listar clientes conectados

Para mostrar la lista de clientes conectados al HotSpot se ejecuta el siguiente comando:

```
$ iw dev wlan0 station dump
Station 1e:19:6f:3a:c8:bb (on wlan0)
	inactive time:	0 ms
	rx bytes:	28873
	rx packets:	196
	tx bytes:	57713
	tx packets:	662
	tx failed:	1
	tx bitrate:	58.5 MBit/s
	rx bitrate:	52.0 MBit/s
	authorized:	yes
	authenticated:	yes
	associated:	yes
	WMM/WME:	no
	TDLS peer:	no
	DTIM period:	2
	beacon interval:100
	short slot time:yes
	connected time:	6 seconds
	current time:	18446744071628657994 ms
Station 00:25:ca:8c:19:67 (on wlan0)
	inactive time:	1000 ms
	rx bytes:	27735
	rx packets:	220
	tx bytes:	52616
	tx packets:	688
	tx failed:	0
	tx bitrate:	72.2 MBit/s
	rx bitrate:	24.0 MBit/s
	authorized:	yes
	authenticated:	yes
	associated:	yes
	WMM/WME:	no
	TDLS peer:	no
	DTIM period:	2
	beacon interval:100
	short slot time:yes
	connected time:	397 seconds
	current time:	18446744071628657996 ms
```

Este comando muestra la dirección MAC de los clientes, pero no su dirección IP, para ello debemos ejecutar:

```
$ arp -i wlan0
Address                  HWtype  HWaddress           Flags Mask            Iface
10.42.0.47               ether   1e:19:6f:3a:c8:bb   C                     wlan0
10.42.0.188              ether   00:25:ca:8c:19:67   C                     wlan0
```

El cual nos muestra las IP relacionadas con cada MAC, pero hay que tener en cuenta que en esta tabla pueden aparecer clientes antiguos que ya no están conectados a la red.

## Redireción y conexión a internet

El Heimdall que crea el HotSpot comparte su conexión a internet a través de el, por lo que hay que tener esto en cuenta cuando se conectan otros dispositivos para evitar el consumo excesivo de los datos de la tarjeta SIM.

Para desactivar la conexión a internet compartida, en el dispositivo que crea el HotSpot podemos modificar las iptables de la siguiente manera:

```
sudo iptables -t nat -D POSTROUTING -s ip_addr -j MASQUERADE
```

Para evitar que se use la conexión a internet a través del HotSpot desde otros clientes excepto si es el último recurso, podemos subirle la métrica a la conexión para darle prioridad a lás demás:

```
nmcli connection modify Hotspot ipv4.route-metric 800
```
