provider "docker" {

}

resource "docker_container" "frontend"{
    image = docker_image.img_frontend.latest//Llamado a la linea 30
    name = "container_frontend"
    attach = false
    ports {
        internal = var.ports                     
        external = var.ports
    }
}

resource "docker_container" "backend"{
    image = docker_image.img_backend.latest //Llamado a la linea 26
    name = "container_backend"
    attach = false
    ports {
        internal = var.ports2   // en el archivo Variables.tf agregar ports2 con el 3000
        external = var.ports2  //en el archivo terraforms.tfvars agregar ports2 con el 3000
    }
}


resource "docker_image" "img_backend" {
    name = "container_backend"
}

resource "docker_image" "img_frontend" {
    
    name = "container_frontend"

}
