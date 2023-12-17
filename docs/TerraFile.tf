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
    keep_locally = false
}

resource "docker_image" "jenkinsBase" {
    name = "jenkins/jenkins"
    keep_locally = false
}

resource "docker_image" "jenkinsMod" {
    name = "jenkinsMod"
    build {
        context = "."
        tag = ["jenkinsMod:develop"]
    }
}

// NETWORKS
resource "docker_network" "net"{
    name = "jenkinsNet"
}

// CONTENEDORES
resource "docker_container" "dind" {
    // Definicion
    image = docker_image.dind.image_id
    name = "dindContainer"

    // Configuracion de lanzamiento
    rm = true
    privileged = true
    env = [ "DOCKER_TLS_CERTDIR=/certs" ]
    volumes {
        volume_name = "jenkins-docker-certs"
        container_path = "/certs/client"
    }
    volumes {
        volume_name = "jenkins-data"
        container_path = "/var/jenkins_home"
    }
    networks_advanced { 
        name = docker_network.net.name 
        aliases = [ "docker" ]
    }
    ports {
        internal = 2376
        external = 2376
    }
}

resource "docker_container" "jenkins" {
    // Definicion
    image = docker_image.jenkinsMod.image_id
    name = "jenkinsContainer"

    // Configuracion de lanzamiento
    env = [ "DOCKER_HOST=tcp://docker:2376", "DOCKER_CERT_PATH=/cert/client", "DOCKER_TLS_VERIFY=1" ]
    volumes {
        volume_name = "jenkins-docker-certs"
        container_path = "/certs/client:ro"
    }
    volumes {
        volume_name = "jenkins-data"
        container_path = "/var/jenkins_home"
    }
    networks_advanced { name = docker_network.net.name }
    ports {
        internal = 8080
        external = 8080
    }
    ports {
        internal = 50000
        external = 50000
    }   
}