# Laravel Docker setup 

Production and development Docker setup used for Laravel.
Uses s6 overlay and php-fpm/nginx in the same image.

## Dev setup

### Download dockerize.sh script

Script to easily add docker code infrastructure to your project.

1. Download script

   ```bash
   curl https://raw.githubusercontent.com/vertex-it/laravel-docker-setup/master/dockerize.sh --output ~/.vertex-it/dockerize.sh --create-dirs
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

1. Initialize Laravel project with the command
```
ver make-project
```
2. Set up .env file
    - Set APP_URL to `http://example-project.test` or `localhost`
    - DB_USERNAME must not bee root
    - XDEBUG_ENABLE can be added, accepted values are "true" and "false"
3. Start the project with `ver start`
4. Export APP_URL to /etc/hosts with `ver hosts`

### (Optional) Enable xDebug

TODO document

## Production setup

- Remove npm-builder stage from Dockerfile if your project doesn't have any npm dependencies
- To build the production image specify "final" target from Dockerfile:
```
docker build --target final . --file .docker/prod.Dockerfile
```

## Continuous Integration

To init ci pipelines click "Set Up Project" on [CircleCi](https://app.circleci.com/) in Projects view.

### Add env variables

In CircleCI add env variables in Project settings
- CI_REGISTRY_USER - dockerhub username
- CI_REGISTRY_PASSWORD - dockerhub password

### Test coverage badge

To show coverage badge add this code below to your markdown file:
```
[![CircleCI](https://circleci.com/gh/<ORGANIZATION>/<PROJECT>/tree/<BRANCH>.svg?style=svg)](https://circleci.com/gh/<ORGANIZATION>/<PROJECT>/tree/<BRANCH>)
```

If your repo is private:
- CircleCI project settings > API Permissions > Add API Token with scope "Status"
- Add `&circle-token=<TOKEN>` after `?style=svg`
