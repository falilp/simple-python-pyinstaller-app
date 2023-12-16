terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0.1"
        }
    }
}

provider "docker" {
    host = "npipe:////.//pipe//docker_engine" 
}

resource "docker_network" "net"{
    name = "jenkins"
}

resource "docker_image" "dind" {
    name = "docker:dind"
    keep_locally = false
}

resource "docker_image" "jenkins" {
    name = "jenkins/jenkins"
    keep_locally = false
}

resource "docker_image" "jenkinsmodify" {
    name = "jenkinsmodify"
    build {
        context = "."
        tag = ["jenkinsmodify:develop"]
    }
}

resource "docker_container" "dind" {
    image = docker_image.dind.image_id
    name = "dockerdindT"
    networks_advanced { name = docker_network.net.name }
    ports {
        internal = 80
        external = 8081
    }
}

resource "docker_container" "jenkins" {
    image = docker_image.jenkinsmodify.image_id
    name = "jenkins-blueoceanT"
    networks_advanced { name = docker_network.net.name }
    ports {
        internal = 80
        external = 8080
    }
}