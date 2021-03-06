# RumblEc2
The following are the steps I took in order to set up an Elixir cluster on Amazon EC2.

## Prerequisite

### Prerequisites on development machine
  - Elixir 1.2.x or later
  - Phoenix 1.2.x or later

### Prerequisites on Instances
  - Ubuntu 14.04
  - Git
  - Erlang
  - Elixir

### Prerequisites on DB Instance
  - Postgres DB instance in amazonaws
    - needs a security group that allows the connection from the EC2 instance

## Preparing Phoenix application

  1. Add `:edeliver` as part of application

```elixir
# ./mix.exs

def application do
  [mod: {RumblEc2, []},
   applications: [:phoenix, :phoenix_pubsub, :phoenix_html,
                  :cowboy, :logger, :gettext,:phoenix_ecto,
                  :postgrex, :exrm, :edeliver]] # <---- 1
end
```

  2. add `{:edeliver, "~> 1.4.0"}`
  3. add `{:exrm, "~> 1.0.3"}`

```elixir
# ./mix.exs
defp deps do
  [{:phoenix, "~> 1.2.1"},
   {:phoenix_pubsub, "~> 1.0"},
   {:phoenix_ecto, "~> 3.0"},
   {:postgrex, ">= 0.0.0"},
   {:phoenix_html, "~> 2.6"},
   {:phoenix_live_reload, "~> 1.0", only: :dev},
   {:gettext, "~> 0.11"},
   {:cowboy, "~> 1.0"},
   {:edeliver, "~> 1.4.0"}, # <---- 2
   {:exrm, "~> 1.0.3"}] # <---- 3
end
```

Once dependencies are included, install dependencies:

```bash
# command line

mix deps.get
```

## Configuration of config/prod.exs
We need to configure the production environment

```elixir
# config/prod.exs

config :rumbl_ec2, RumblEc2.Endpoint,
  http: [port: 8080], # <---- 1
  url: [host: "ec2-184-72-96-182.compute-1.amazonaws.com", port: 80], # <---- 2
  cache_static_manifest: "priv/static/manifest.json"

config :logger, level: :info
config :phoenix, :serve_endpoints, true # <---- 3
import_config "prod.secret.exs"
```

Few things to note here:
  1. Configure the `http` option to point to port `8080`.
  2. Configure the `host` to the domain name that we are using.
  3. Make sure this line is `uncommented`. This line instructs Phoenix to start the server for all endpoints. This option is needed when doing an OTP release.

## Configuring Edeliver
Create a new `.deliver` folder under root directory. In the `.deliver` folder, create a `config` file.

```sh
# .deliver/config

#1. Name of the app
APP="rumbl_ec2"

#2. The following adds a git tag to each release
AUTO_VERSION=revision

#3. Declaration of the servers and assignment of public DNS. One for now, will be testing with more soon.

MAIN="ec2-184-72-96-182.compute-1.amazonaws.com"
#MAIN2=
#MAIN3=

#4. Specify the user of server, same user needs to be used throughout all servers for an OTP release.
USER="ubuntu"

#5. Which host do you want to build release on? This will choose which server to build the release on. The release needs to be build in the same type of machine of where it will be deployed.
BUILD_HOST=$MAIN
BUILD_USER=$USER
BUILD_AT="/tmp/edeliver/$APP/builds"

#6. Specify the staging host. Not specifying that for now
#STAGING_HOSTS=
#STAGING_USER=
#DELIVER_TO=

#7. Specify which host(s) the app is going to be deployed to
# we can add more than one, separated by spaces
PRODUCTION_HOSTS="$MAIN"
PRODUCTION_USER=$USER
DELIVER_TO="/home/ubuntu"

#8. Point to the vm.args file, this is used for OTP releases. At the moment there is only one server.
LINK_VM_ARGS="/home/ubuntu/vm.args"

#9. For Phoenix Projects
# the following is a hook for `edeliver` take the prod.secret.exs file into consideration when compiling. Also gets dependencies, installs npm and does a brunch build.
pre_erlang_get_and_update_deps() {
  local _prod_secret_path="/home/$USER/prod.secret.exs"
  if [ "$TARGET_MIX_ENV" = "prod" ]; then
    __sync_remote "
      ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'

      cd '$BUILD_AT'

      mkdir -p priv/static

      mix deps.get

      npm install

      brunch build --production

      APP='$APP' MIX_ENV='$TARGET_MIX_ENV' $MIX_CMD phoenix.digest $SILENCE
    "
  fi
}
```

Explaining the file a bit by numbered comments:

  1. Naming the app
    - name of the directory on the server containing the application.
  2. Using revision for auto versioning
    - edeliver adds a tag to the version based on the commit that it is based on.
  3. Declare the names of your servers and assign the public DNS
    - Only one server will be named for now, it is called MAIN.
    - A different naming scheme can be picked.
    - It should point to the public DNS given to the server by Amazon.
      - Using the public DNS solves the issue that occurs when the virtual machine somehow reboots and gets assigned a new private IP, the public IP will remained unchanged.
  4. Specify a user
    - The user that has SSH and folder access on the declared servers.
    - All servers need to have the same user name.
  5. Specifying the host to build the release on
    - At the moment there is only one host. Therefore the release will be build and deployed in one host.
  6. Specifying the staging host
    - No staging host at the moment
  7. Specifying which host(s) the app is going to be deployed to
    - `PRODUCTION_HOSTS` specifies the production hosts. Each host is separated by a space.
  8. Point to the vm.args file
    - `LINK_VM_ARGS` specifies the path to the `vm.args` file. The file specifies the flags used to start the Erlang virtual machine.
  9. Prepare the Phoenix app
    - This function runs a few commands that prepare the Phoenix application. These commands perform tasks such as installing the necessary dependencies, and perform asset compilation.

## Configuring the Nodes
I will be updating this part as soon as we have 2 or more hosts. This section will talk about setting up the `vm.args` file and `your_app.config` file.

## Creating the secrets production file
The last file to create is `prod.secret.exs`. The file should look like this:

```elixir
use Mix.Config

config :rumbl_ec2, RumblEc2.Endpoint,
  secret_key_base: "PDbHy12cRq51+IyZnfbe5kwLsyicVbfqhxCtM4lyYj55VP8UQCiZYMberoOLN3p0"

config :rumbl_ec2, RumblEc2.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "phoenixdb",
  password: "phoenixdbtest",
  database: "rumbl_ec2",
  hostname: "phoenix-ubuntu-testing.cdspfwxmvm1o.us-east-1.rds.amazonaws.com",
  port: 5432
```

This file is not committed to into source control, therefore all production specific credential should be added to this file. This file will be `scp` into the server building the release and needs to be located in the home folder. In an ubuntu server with as user called `ubuntu` it should be `/home/ubuntu/`.

## Configuring Amazon EC2
The only configuration that needs to be done for the EC2 instance is which ports are open in the Security Groups used by the instances.

Ports for:

  - Phoenix: `8080`
  - Erlang Port Mapper Daemon (epmd): `4369`
  - Distributed communication: `9100 - 9155`

Port `8080` was configured in `config.prod.exs`, while the port range of `9100 - 9155` will be specified in `vm.args`.

  > The source of each rule added to the security groups needs to be specified. The source cannot be `0.0.0.0/0` as this will allow connections to the instances from anywere.

Once an Amazon EC2 instance has been created, we need to install a few things:

  - `wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb`
  - `sudo apt-get update -y`
  - `sudo apt-get install -y esl-erlang`
  - `sudo apt-get install -y elixir`
  - `sudo apt-get install -y erlang`
  - `sudo apt-get install -y git`
  - `sudo apt-get install -y nginx`

We will not be needing nodejs, npm or brunch. So we are skipping that step.

  > Node is an optional dependency. Phoenix will use brunch.io to compile static assets (js, css, etc), by default. Brunch.io uses the node package manager (npm) to install its dependencies, and npm requires node.js. [Read more](http://www.phoenixframework.org/docs/installation).

As a side note, if you have dependencies like `:comeonin` or `:gettext`, you will need to install a few other packages.

- `sudo apt-get install build-essential`
- `sudo apt-get install -y erlang-dev`
- `sudo apt-get install -y erlang-parsetools`

Once the above has been installed, we need to make sure that `git` is able to pull from our private repo. We do this by adding a new SSH key to our GitHub account. [Read more](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/#platform-linux)


## Setup Nginx
The file below shows the basic content for `/etc/nginx/sites-available/rumbl_ec2` file, that needs to be put in the EC2 instance. [Read More](http://www.phoenixframework.org/docs/advanced-deployment#section-setting-up-our-web-server)

Let's create our config file for our application. By default, everything in `/etc/nginx/sites-enabled` is included into the main `/etc/nginx/nginx.conf` file that is used to configure nginx's runtime environment. Standard practice is to create our file in `/etc/nginx/sites-available` and make a symbolic link to it in `/etc/nginx/sites-enabled`.

```
$ sudo touch /etc/nginx/sites-available/hello_phoenix
$ sudo ln -s /etc/nginx/sites-available/hello_phoenix /etc/nginx/sites-enabled
$ sudo vi /etc/nginx/sites-available/hello_phoenix
```

```
# /etc/nginx/sites-available/rumbl_ec2

upstream rumbl_ec2 {
  server 127.0.0.1:8080;
}

map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}
server {
  listen 80;
  server_name ec2-184-72-96-182.compute-1.amazonaws.com;

  location / {
    try_files $uri @proxy;
  }

  location @proxy {
    include proxy_params;
    proxy_redirect off;
    proxy_pass http://rumbl_ec2;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}
```

Restart nginx with `sudo service nginx restart` to load our new config.

Nginx is set to listen in port 80 with HTTP. Instance will only allow requests from load balancer through security groups. The load balancer in amazon will take care of accepting HTTPS.


## Setting up Circle-CI
The file below shows the basic content for `circle.yml` file.

```yml
#./circle.yml
dependencies:
  pre:
    - ./bin/ci/prepare.sh
  cache_directories:
    - ~/dependencies
    - ~/.mix
    - _build
    - deps

test:
  override:
    - ./bin/ci/test.sh

deployment:
  staging:
    branch: master
    commands:
      - ./bin/ci/edeliver-staging.sh
  production:
    branch: production
    commands:
      - ./bin/ci/edeliver-production.sh
```

This file sets ups circle-ci with erlang, elixir and everything else it needs to deploy to all environments.

The following three files are the the scripts been called in `circle.yml`.

```
#./bin/ci/prepare.sh
#!/bin/bash

set -e

export ERLANG_VERSION="19.1"
export ELIXIR_VERSION="v1.3.4"

# If you have a elixir_buildpack.config, do this instead:
#export ERLANG_VERSION=$(cat elixir_buildpack.config | grep erlang_version | tr "=" " " | awk '{ print $2 }')
#export ELIXIR_VERSION=v$(cat elixir_buildpack.config | grep elixir_version | tr "=" " " | awk '{ print $2 }')

export INSTALL_PATH="$HOME/dependencies"

export ERLANG_PATH="$INSTALL_PATH/otp_src_$ERLANG_VERSION"
export ELIXIR_PATH="$INSTALL_PATH/elixir_$ELIXIR_VERSION"

mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Install erlang
if [ ! -e $ERLANG_PATH/bin/erl ]; then
  curl -OL http://www.erlang.org/download/otp_src_$ERLANG_VERSION.tar.gz
  tar xzf otp_src_$ERLANG_VERSION.tar.gz
  cd $ERLANG_PATH
  ./configure --enable-smp-support \
              --enable-m64-build \
              --disable-native-libs \
              --disable-sctp \
              --enable-threads \
              --enable-kernel-poll \
              --disable-hipe \
              --without-javac
  make

  # Symlink to make it easier to setup PATH to run tests
  ln -sf $ERLANG_PATH $INSTALL_PATH/erlang
fi

# Install elixir
export PATH="$ERLANG_PATH/bin:$PATH"

if [ ! -e $ELIXIR_PATH/bin/elixir ]; then
  git clone https://github.com/elixir-lang/elixir $ELIXIR_PATH
  cd $ELIXIR_PATH
  git checkout $ELIXIR_VERSION
  make

  # Symlink to make it easier to setup PATH to run tests
  ln -sf $ELIXIR_PATH $INSTALL_PATH/elixir
fi

export PATH="$ERLANG_PATH/bin:$ELIXIR_PATH/bin:$PATH"

# Install package tools
if [ ! -e $HOME/.mix/rebar ]; then
  yes Y | LC_ALL=en_GB.UTF-8 mix local.hex
  yes Y | LC_ALL=en_GB.UTF-8 mix local.rebar
fi

# Fetch and compile dependencies and application code (and include testing tools)
export MIX_ENV="test"
cd $HOME/$CIRCLE_PROJECT_REPONAME
mix do deps.get, deps.compile, compile
```

```
#./bin/ci/test.sh
#!/bin/bash

export MIX_ENV="test"
export PATH="$HOME/dependencies/erlang/bin:$HOME/dependencies/elixir/bin:$PATH"

mix test
```

```
#./bin/ci/edeliver.sh
#!/bin/bash

export PATH="$HOME/dependencies/erlang/bin:$HOME/dependencies/elixir/bin:$PATH"

mix edeliver update production
```
