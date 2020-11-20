include:
  - nodejs

install_npm_dependencies:
  npm.bootstrap:
    - name: /srv/app/Portal/aik-app-ui

aik-front.service:
  file.managed:
    - name: /etc/systemd/system/aik-front.service
    - source: salt://aik-ui/files/aik-front.service

/srv/app/Portal/aik-app-ui/server.js:
  file.managed:
    - mode: 777

system-reload:
  cmd.run:
    - name: "sudo systemctl --system daemon-reload"
  service.running:
    - name: aik-front
    - reload: True
    - enable: True
