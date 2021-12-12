# NGINX CHAMELEON BANER
![Screenshot](nx_chameleon.png)

## ¿Qué es chameleon baner?

Chameleon baner es un script escrito en bash que escanea el log de nginx filtrando errores, requests y headers que cumplan con las reglas establecidas por el usuario. A traves de pesos se pueden controlar los intentos de los clientes, si se incumplen los intentos definidos por el usuario se banea la ip a traves de iptables. Se pueden establecer reglas de 4 tipos:

- Request: La regla request inspecciona la request recibida e intenta machear con las reglas definidas por el usuario.

- Error: La regla error, inspecciona el codigo resultante de la peticion recibida e intenta machear con las reglas definidas por el usuario.

- Header: La regla header, inspecciona los header de la peticion en busca de palabras definidas por el usuario.

- Whitelist: Con esta regla se identifican las ips que no queremos que se baneen aunque incumplan con la politica de seguridad establecida en las reglas.

## Instalacion