nodejs_prereq:
  pkg.installed:
    - pkgs:
      - gcc-c++
      - make
  cmd.run:
    - name: "curl -sL https://rpm.nodesource.com/setup_15.x | sudo -E bash -"
    - name: "sudo yum install -y nodejs"

nodejs:
  pkg.installed:
    - name: nodejs
