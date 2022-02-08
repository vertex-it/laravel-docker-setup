# Laravel Docker setup 

Production and development Docker setup used for Laravel.
Uses s6 overlay and php-fpm/nginx in the same image.

## How to run dev setup

### Download dockerize.sh script

Script to easily add docker code infrastructure to your project.

1. Download script

   ```bash
   curl https://raw.githubusercontent.com/vertex-it/laravel-docker-setup/master/dockerize.sh?token=AE4YUUJDNRF7UGMIAYZ6XOLBWNPN2 --output ~/.vertex-it/dockerize.sh --create-dirs
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

### Add docker setup code to the project

1. In the root of the project run `dockerize`

2. Optional - add `ver` script alias

   ```bash
   echo "\nalias ver=\"./ver\"" >> ~/.zshrc
   ```

### Install Laravel project

1. `ver make-project`
2. Set up .env file
    - Change APP_URL to `example-project.test`. APP_URL must not contain "http" or "https"
    - DB_USERNAME must not bee root
    - XDEBUG_ENABLE can be added, accepted values are "true" and "false"
3. Start the project with `ver start`
4. Export APP_URL to /etc/hosts with `ver hosts`

## Production setup

- Add "APP_KEY" to phpunit.xml if missing:
   ```
  <server name="APP_KEY" value="base64:TKd6jQxywTLKHf/CBAaZfKcxYmHwg2TTUKEEZKBUuuk=" />
  ```
- Remove npm-builder stage from Dockerfile if your project doesn't have any npm dependencies
- To build the production image specify "final" target from Dockerfile:
```
docker build --target final . --file .docker/prod.Dockerfile
```
- Add env variables to Circle CI: CI_REGISTRY_USER, CI_REGISTRY_PASSWORD
