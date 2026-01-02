# Automatización de Yocto

Este documento analiza la secuencia de procesos que requiere un Heimdall desde su fabricación hasta su completa configuración y puesta en funcionamiento con el objetivo de identificar aquellos procesos que sean susceptibles de automatización y definir los próximos pasos para reducir la intervención humana en el proceso.

## Fabricación de PCB de Heimdall

Actualmente, el proceso de fabricación está definido por el documento **RFQ**, la **BOM**, y el **documento de descripción de cableado** de Heimdall. Estos documentos, junto al **proceso de auto-testeo** permiten la fabricación y la verificación del adecuado funcionamiento del hardware.

## Programación inicial de VAR-SOM-MX7

El módulo VAR-SOM-MX7 requiere de un **proceso inicial de programación** para grabar la imagen de Yocto de TycheTools. Para ello, actualmente, los módulos VAR-SOM-MX7 se programan manualmente mediante el módulo VAR-MX7 CustomBoard Single Board Computer (SBC). Se valoran tres opciones para automatizar este proceso:

- Solicitar pre-programación de los módulos VAR-SOM-MX7.
- Solicitar programación en fábrica de los módulos VAR-SOM-MX7.
- Mantener programación manual por el equipo técnico de TycheTools.

## Script ttsetup: Conexión remota

Para administrar el dispositivo o llevar a cabo mantenimiento, Heimdall debe implementar un **acceso remoto por consola**. Actualmente, este acceso se configura de forma manual. Se valoran las siguientes alternativas:

- Automatizar el proceso de creación de túnel SSH. Input:
    - Puerto TCP/UDP.
- Automatizar el proceso de creación de consola remota por WebSockets. Input mediante aplicación de TycheTools Lens:
    - URL de API AWS.
    - Clave HMAC.
    - Mensaje HMAC.

## Script ttsetup: Instalación de clave SSH Bitbucket

El proceso de configuración incluye la descarga e instalación del último software estable. Para ello, es necesaria la **clave SSH de Bitbucket** que permita la lectura de los repositorios de TycheTools. Se valoran las siguientes alternativas:

- Instalar la clave SSH siempre por defecto.
- No instalar la clave SSH ya que no es necesaria para otros pasos.

## Script ttsetup: Instalación de credenciales AWS

El proceso de configuración incluye la descarga e instalación del último firmware estable del microcontrolador nRF52. La última versión estable del firmware compilado del nRF52 se encuentra en un contenedor de AWS, y su para su acceso son necesarias las **credenciales de AWS**. Se valoran las siguientes alternativas:

- Instalar las credenciales de AWS siempre por defecto.

## Script ttsetup: Bashrc

Para mantener **homogeneidad en la configuración del terminal** de Heimdall, actualmente se configura un archivo `bashrc`. Para automatizar esta configuración, se valoran las siguientes alternativas:

- Configurar el archivo de `bashrc` siempre por defecto.

## Script ttsetup: Hostname
- Dejar el hostname por defecto, hasta que se configure el backend y se tenga acceso al numero de serie o al cliente y crear un hostname que incluya ambos campos (solo si no se ha cambiado ya manualmente).

## Script ttsetup: Activación de módulo 4G

Heimdall puede incorporar, de manera opcional, una shield 4G para disponer de conexión a Internet independiente del entorno de instalación. Actualmente, la configuración se realiza de forma manual mediante un fichero de configuración predefinido para distintos proveedores de servicios de Internet. Para automatizar la **configuración del módulo 4G** se valoran las siguientes alternativas:

- Requerir de intervención del instalador para preguntar si se requiere comunicación 4G. Input mediante la aplicación de TycheTools Lens:
    - Configurar comunicación 4G [y/n]
    - APN (nombre de punto de acceso).
    - APN User (if required).
    - APN Password (if required).

## Script ttsetup: Actualizar el firmware del nRF52

El módulo nRF52 requiere de un **proceso de programación inicial** para *flashear* el último firmware estable en el microcontrolador. Se valoran las siguientes alternativas:

- Actualizar siempre el firmware del nRF52 en el proceso de configuración inicial.
- El gw-app actualiza automáticamente el fw cuando es necesario.


## Script ttsetup: Configurar red Wi-Fi

Actualmente, el script inicial de configuración permite al instalador configurar el dispositivo en una **red Wi-Fi**. Se valoran las siguientes alternativas:

- Eliminar esta opción del proceso inicial de configuración, ya que la aplicación de TycheTools Lens ya incluye la configuración de red del Heimdall.

## Script ttsetup: Reiniciar para aplicar cambios

Para aplicar los cambios anteriormente mencionados, el dispositivo debe **llevar a cabo un reinicio**.

- Dado que el proceso de configuración se llevará a cabo exclusivamente mediante la aplicación de TycheTools Lens, dicha aplicación debe avisar que el dispositivo se reiniciará al finalizar el proceso de configuración.
- Realizar el proceso de tal manera que no sea necesario el reinicio.

## Configuración de la contraseña del código QR

Todos los dispositivos Heimdall cuentan con una dirección MAC y una contraseña impresa sobre el soporte físico del dispositivo mediante un código QR. Dicho código QR es leído por la aplicación TycheTools Lens para conectarse por Bluetooth al dispositivo. Actualmente, dicha configuración se realiza manualmente mediante el programa `ble_config_pw`, que actualiza la clave introducida por el instalador. Para automatizar este proceso, se valoran las siguientes alternativas:

- Eludir la comprobación de contraseña la primera vez que se instala configura y, utilizar la contraseña leída por la aplicación de TycheTools Lens contraseña del dispositivo.
- ¿Más propuestas?
- Que se haga como parte de una configuración inicial, bt, que no requiera contraseña, pero que autentique de alguna manera el movil.
- No usar contraseña
- No usar contraseña hasta que esté configurada la conexión al backend y podamos bajarnos la contraseña de hw manufacturing.

## GW config: Seleccionar plataforma

La aplicación del gateway requiere conocer el modelo de Heimdall que está corriendo para determinar las características hardware del dispositivo. Actualmente, esta configuración es configurada por el instalador mediante el fichero `gw.config`. Para automatizar este proceso, se valoran las siguientes alternativas:

- Al primer inicio del gateway, si existe el archivo /etc/ttver, configurar automáticamente la plataforma al crear el archivo gw.config.

## GWRC y aplicaciones del gateway

Actualmente, el instalador configura un fichero en el que especifican los comandos que deben ejecutarse al iniciar la aplicación. Además la aplicación del gateway cuenta con diferentes aplicaciones (SNMP, almacenamiento persistente, calidad del aire, etc.) que pueden ser activadas por defecto. Para automatizar este proceso, se valoran las siguientes alternativas:

- Crear automáticamente el archivo `gwrc` con los comandos `gateway init` y `app enable backend`.
- Adicionalmente, requerir de intervención del instalador para solicitar las aplicaciones que se necesitan activar. Input mediante la aplicación de TycheTools Lens:
    - Activar "Air Quality" [y/n]
    - Activar almacenamiento persistente (CSV) [y/n]
    - Activar SNMP [y/n]
