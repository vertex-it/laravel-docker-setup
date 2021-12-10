# Laravel Docker setup 

Docker setup used for Laravel development based on [bkhul/fpm-nginx](https://hub.docker.com/r/bkuhl/fpm-nginx).  
Uses s6 overlay and php-fpm/nginx in the same image.

## Download dockerize.sh script

Script to easily add docker code infrastructure to your project.

1. Download script

   ```bash
   curl https://raw.githubusercontent.com/vertex-it/laravel-docker-setup/master/dockerize.sh?token=AE4YUUJDNRF7UGMIAYZ6XOLBWNPN2 --output ~/.vertex-it/dockerize.sh
   ```

2. Add executable permission

   ```bash
   chmod +x ~/.vertex-it/dockerize.sh
   ```

3. Create script alias (zsh shell)

   ```bash
   echo "\n# dockerize script\nalias dockerize=\"~/.vertex-it/dockerize.sh\"" >> ~/.zshrc
   ```

Script can be started by command `dockerize`

## Add docker setup code to the project

1. In the root of the project run `dockerize`

2. Optional - add `demo` script alias

   ```bash
   echo "\nalias demo=\"./demo.sh\"" >> ~/.zshrc
   ```

## Install Laravel

1. `demo make-project`
2. Set up .env file
    - APP_URL must not be `http://localhost`, it can be `localhost`
    - DB_USERNAME must not bee root
    - XDEBUG_ENABLE can be added, accepted values are "true" and "false"
3. `demo start`
