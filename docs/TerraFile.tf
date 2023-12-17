// CONFIGURACION BASICA
terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0.1"
        }
    }
}

// PROVEEDOR - DOCKER
provider "docker" {
    host = "npipe:////.//pipe//docker_engine" 
}

// IMAGENES 
resource "docker_image" "dind" {
    name = "docker:dind"
    keep_locally = true
}

resource "docker_image" "jenkinsBase" {
    name = "jenkins/jenkins"
    keep_locally = true
}

// VOLUMENES
resource "docker_volume" "jenkinsCerts" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkinsData" {
  name = "jenkins-data"
}

// NETWORKS
resource "docker_network" "net"{
    name = "jenkins"
}

// CONTENEDORES
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

resource "docker_container" "jenkins" {
    // Definicion
    image = "jenkinsmod"//docker_image.jenkinsmod.name
    name = "jenkinsContainer"

    // Configuracion de lanzamiento
    env = [ "DOCKER_HOST=tcp://docker:2376", "DOCKER_CERT_PATH=/cert/client", "DOCKER_TLS_VERIFY=1" ]
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