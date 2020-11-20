include:
  - nodejs
  - aik-ui

aik-api:
  git.latest:
    - name: https://github.com/CarlosIVI/AIK-Portal
    - target: /srv/app

install_npm_back_dependencies:
  npm.bootstrap:
    - name: /srv/app/Portal/aik-app-api

run_aik_back_portal:
  cmd.run:
    - name: "nohup node /srv/app/Portal/aik-app-api/server.js > outputBack.log &"
