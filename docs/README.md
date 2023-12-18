# Tabla de contenido
1. [Explicación general]()
2. [Explicación del archivo Terraform](#explicación-del-archivo-terraform)
    1. [Configuraciones del contenedor "dind"](#configuraciones-del-contenedor-dind)
    2. [Configuraciones del contenedor Jenkins](#configuraciones-del-contenedor-jenkins)
3. [Explicación del archivo Dockerfile](#explicación-del-archivo-dockerfile)
4. [Resolución de la práctica](#resolución-de-la-práctica)
5. [Autores de la práctica](#autores-de-la-práctica)

# Explicación general
Esta práctica consiste en crear un pipeline en Jenkins que realice el despliegue de una aplicación Python en un contenedor Docker.

El despliegue de los dos contenedores Docker necesarios (Docker in Docker y
Jenkins) debe realizarse mediante Terraform. Para crear la imagen personalizada
de Jenkins se debe usar un Dockerfile.

# Explicación del archivo Terraform

Este archivo Terraform define la infraestructura de Docker utilizando el proveedor Docker para Terraform. Aquí está el desglose detallado de cada sección:

## Configuración básica
```
terraform {
   required_providers {
       docker = {
           source = "kreuzwerker/docker"
           version = "~> 3.0.1"
       }
   }
}
```
En esta sección, se especifica el proveedor requerido para este archivo Terraform. En este caso, se utiliza el proveedor Docker, que se obtiene desde el registro de Terraform con la versión 3.0.1 1.
Proveedor Docker

```
provider "docker" {
   host = "npipe:////.//pipe//docker_engine" 
}
```

Aquí se define el proveedor Docker. El host se establece en "npipe:////.//pipe//docker_engine", lo que indica que Terraform debe interactuar con Docker a través de un pipe de Windows

## Imágenes Docker
```
resource "docker_image" "dind" {
   name = "docker:dind"
   keep_locally = true
}

resource "docker_image" "jenkinsBase" {
   name = "jenkins/jenkins"
   keep_locally = true
}
```
Estas secciones definen dos imágenes Docker que se mantendrán localmente. La primera es la imagen Docker-in-Docker (dind), y la segunda es la imagen base de Jenkins .

## Volúmenes Docker
```
resource "docker_volume" "jenkinsCerts" {
 name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkinsData" {
 name = "jenkins-data"
}
```
Estas secciones definen dos volúmenes Docker: "jenkins-docker-certs" y "jenkins-data". Los volúmenes Docker son utilizados por los contenedores para almacenar datos persistentes.

## Redes Docker
```
resource "docker_network" "net" {
   name = "jenkins"
}
```
Esta sección define una red Docker llamada "jenkins". Las redes Docker se utilizan para permitir la comunicación entre contenedores.

## Contenedores Docker

### Contenedor Docker in Docker (dind)
```
resource "docker_container" "dind" {
   // Definicion
   image = docker_image.dind.name
   name = "dindContainer"

   // Configuracion de lanzamiento
   rm = true
   privileged = true
   env = [ "DOCKER_TLS_CERTDIR=/certs" ]
   volumes {
       volume_name = docker_volume.jenkinsCerts.name
       container_path = "/certs/client"
   }
   volumes {
       volume_name = docker_volume.jenkinsData.name
       container_path = "/var/jenkins_home"
   }
   networks_advanced { 
       name = docker_network.net.id
       aliases = [ "docker" ]
   }
   ports {
       internal = 2376
       external = 2376
   }
}
```
#### Configuraciones del Contenedor "dind":
Definición de Imagen:
- Propiedad: image
- Descripción: Especifica la imagen a utilizar para el contenedor, tomando el nombre de la imagen definida previamente en docker_image.dind.name.

Nombre del Contenedor:
- Propiedad: name
- Descripción: Asigna el nombre "dindContainer" al contenedor.

Configuración de Lanzamiento:
- rm:
    - Descripción: Configurado como true.
    - Significado: Indica que el contenedor se eliminará automáticamente después de detenerse.

- privileged:
    - Descripción: Configurado como true.
    - Significado: Otorga privilegios elevados al contenedor, proporcionando acceso a recursos del sistema host.

- Variables de Entorno (env):
    - Descripción: Se establece la variable de entorno DOCKER_TLS_CERTDIR con el valor /certs.

- Volúmenes Montados:

    - Volumen de Certificados (jenkinsCerts):
        - Montaje: Se asigna el volumen docker_volume.jenkinsCerts.name a la ruta /certs/client dentro del contenedor.
    - Volumen de Datos de Jenkins (jenkinsData):
        - Montaje: Se asigna el volumen docker_volume.jenkinsData.name a la ruta /var/jenkins_home dentro del contenedor.

- Configuración de Red (networks_advanced):
    - Nombre: docker_network.net.id.
    - Alias: Se asigna el alias "docker" a esta red.

- Puertos Mapeados:
    - Puerto Interno: 2376 (dentro del contenedor).
    - Puerto Externo: 2376 (del host)

### Contenedor Jenkins
```
resource "docker_container" "jenkins" {
   // Definicion
   image = "jenkinsmod"
   name = "jenkinsContainer"

   // Configuracion de lanzamiento
   env = [ "DOCKER_HOST=tcp://docker:2376", "DOCKER_CERT_PATH=/certs/client", "DOCKER_TLS_VERIFY=1", "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"]
   volumes {
       volume_name = docker_volume.jenkinsCerts.name
       container_path = "/certs/client"
       read_only = true
   }
   volumes {
       volume_name = docker_volume.jenkinsData.name
       container_path = "/var/jenkins_home"
   }
   networks_advanced { 
       name = docker_network.net.id
   }
   ports {
       internal = 8080
       external = 8080
   }
   ports {
       internal = 50000
       external = 50000
   }  
}
```
#### Configuraciones del Contenedor Jenkins:
Definición de Imagen:
- Propiedad: image
- Descripción: Especifica la imagen a utilizar para el contenedor, tomando el nombre de la imagen creada a mano mediante un Dockerfile "jenkinsmod"

Nombre del Contenedor:
- Propiedad: name
- Descripción: Asigna el nombre "jenkinsContainer" al contenedor.

Configuración de Lanzamiento:
- Variables de Entorno (env):
    - Descripción: Se establece la variable de entorno DOCKER_HOST con el valor tcp://docker:2376, DOCKER_CERT_PATH con el valor /certs/client, DOCKER_TLS_VERIFY con el valor 1 y JAVA_OPTS con el valor -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true

- Volúmenes Montados:

    - Volumen de Certificados (jenkinsCerts):
        - Montaje: Se asigna el volumen docker_volume.jenkinsCerts.name a la ruta /certs/client dentro del contenedor y se le da permisos solo de lectura.
    - Volumen de Datos de Jenkins (jenkinsData):
        - Montaje: Se asigna el volumen docker_volume.jenkinsData.name a la ruta /var/jenkins_home dentro del contenedor.

- Configuración de Red (networks_advanced):
    - Nombre: docker_network.net.id.

- Puertos Mapeados:
    - Puerto Interno: 2376 (dentro del contenedor).
    - Puerto Interno: 50000
    - Puerto Externo: 2376 (del host)
    - Puerto Externo: 50000

# Explicación del archivo Dockerfile
```
FROM jenkins/jenkins
```
Establece la imagen base para construir el contenedor, utilizando la imagen oficial de Jenkins como punto de partida.

```
USER root
```
Cambia al usuario "root" dentro del contenedor, otorgando permisos elevados para realizar configuraciones del sistema.

```
RUN apt-get update && apt-get install -y lsb-release
```
Actualiza los repositorios de paquetes e instala el paquete "lsb-release", preparando el entorno del sistema.

```
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg
```
Descarga la clave de firma de Docker para verificar la autenticidad de los paquetes de Docker.

```
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
```
Agrega el repositorio de Docker al sistema para instalar paquetes de Docker desde el repositorio oficial.

```
RUN apt-get update && apt-get install -y docker-ce-cli
```
Actualiza los repositorios e instala el cliente de Docker, permitiendo el uso de comandos de Docker dentro del contenedor.

```
USER jenkins
```
Cambia al usuario "jenkins" dentro del contenedor, mejorando la seguridad al ejecutar el servicio de Jenkins con un usuario específico.

```
RUN jenkins-plugin-cli --plugins "blueocean:1.27.9 docker-workflow:572.v950f58993843"
```
Instala plugins específicos de Jenkins, como Blue Ocean y Docker Workflow, agregando funcionalidades adicionales al entorno de Jenkins.

# Resolución de la práctica
1. Clonar el repositorio
2. Entrar en la carpeta docs
3. Crear la imagen personalizada de Jenkins mediante el comando ```docker build -t jenkinsmod .```
4. Lanzar los contenedores con Terraform
    1. ```terraform init```
    2. ```terraform apply```
5. Iniciar Jenkins
    1. Realizar el comando ```docker logs jenkinsContainer``` para ver la primera contraseña de administrador
    2. Entrar en la ruta ```localhost:8080```
    3. Elegir la instalación por defecto y crear un perfil administrador
    4. Crear un nuevo trabajo en jenkins del tipo Pipeline y configurarlo para que trabaje con Git
6. Crear un fichero Jenkinsfile con el pipeline correspondiente
7. Hacer un commit del nuevo fichero
8. Abrir Blue Ocean y lanzar el pipeline
9. Comprobar que todo funciona correctamente 

# Autores de la práctica

- Manuel Coca Alba
- Rafael Leal Pardo