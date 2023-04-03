#!/bin/bash

# Define variables
SSH_SERVICE="ssh"
SSH_PORT="22"
NEW_USER=""
NEW_PASSWORD=""

# Function to print usage
function print_usage {
  echo "Usage: ./script.sh [options]"
  echo "Options:"
  echo "-i, --install-ssh             Install SSH if not already installed"
  echo "-r, --enable-root-login       Set up root SSH login with password"
  echo "-c, --create-user             Create new user and set password"
  echo "-k, --install-ssh-key         Install SSH public key for current user"
  echo "-p, --change-ssh-port         Change SSH default port"
  echo "-d, --disable-password-login  Disable SSH password login"
  echo "-t, --set-timezone            Set the system timezone"
  echo "-n, --set-hostname            Set the hostname"
  echo "--set-proxy                   Set proxy settings on the system"
  echo "--unset-proxy                 Cancel proxy settings on the system"
  echo "-o, --install-docker          Install Docker and Docker Compose"
  echo "-h, --help                    Display this help message"
  exit 1
}

# Function to install SSH if not already installed
function install_ssh {
  if [[ $(dpkg-query -W -f='${Status}' $SSH_SERVICE 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
    echo "SSH is not installed. Installing..."
    apt-get update && apt-get install -y $SSH_SERVICE
  else
    echo "SSH is already installed."
  fi
}

# Function to set up root SSH login with password
function enable_root_login {
  echo "Setting up root SSH login with password..."
  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  service ssh restart
}

# Function to create new user and set password
function create_user {
  echo "Creating new user..."
  if [[ -z $NEW_USER ]]; then
    read -p "Please enter a username for the new user: " NEW_USER
  fi
  if [[ -z $NEW_PASSWORD ]]; then
    read -s -p "Please enter a password for the new user: " NEW_PASSWORD
    echo
  fi
  useradd -m $NEW_USER
  echo "$NEW_USER:$NEW_PASSWORD" | chpasswd
}

# Function to install SSH public key for current user
function install_ssh_key {
  echo "Installing SSH public key for $USER..."
  mkdir -p ~/.ssh
  touch ~/.ssh/authorized_keys
  echo "Will install SSH public key in \"$(realpath ~/.ssh/authorized_keys)\""
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  read -p "Please enter the SSH public key for $USER: " SSH_KEY
  echo "$SSH_KEY" >> ~/.ssh/authorized_keys
  chown -R $USER:$USER ~/.ssh
}

# Function to change SSH default port
function change_ssh_port {
  echo "Changing SSH default port..."
  if ! [[ $SSH_PORT =~ ^[0-9]+$ ]]; then
    echo "Invalid SSH port number. Please enter a number between 1 and 65535."
    exit 1
  fi
  if [[ $SSH_PORT -lt 1 || $SSH_PORT -gt 65535 ]]; then
    echo "Invalid SSH port number. Please enter a number between 1 and 65535."
    exit 1
  fi
  sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
  service ssh restart
}

# Function to disable SSH password login
function disable_password_login {
  echo "Disabling SSH password login..."
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  service ssh restart
}

# Function to set the system timezone
function set_timezone {
  if [[ -z $TIMEZONE ]]; then
    read -p "Please enter the timezone (e.g. America/Los_Angeles, Asia/Shanghai): " TIMEZONE
  fi
  
  # set timezone by timedatectl
  timedatectl set-timezone $TIMEZONE
  echo "Current timezone is: $(timedatectl status | grep "$TIMEZONE")"
  service cron restart

  # set timezone by modify /etc/localtime
  # if [[ -f /usr/share/zoneinfo/$TIMEZONE ]]; then
    # ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    # dpkg-reconfigure -f noninteractive tzdata
    # echo "Timezone set to $TIMEZONE"
  # else
    # echo "Invalid timezone: $TIMEZONE"
  # fi
}

# Function to set the system hostname
function set_hostname {
  if [[ -z $HOST_NAME ]]; then
    read -p "Please enter the hostname: " HOST_NAME
  fi
  
  # set hostname by hostnamectl
  hostnamectl set-timezone $HOST_NAME
  echo "Current hostname is: $(hostnamectl status | grep "$HOST_NAME")"
  echo "Please relogin terminal to show the new hostname."
}

# Function to set proxy settings on the system
function set_proxy {
  if [[ -z $PROXY_MODE ]]; then
    read -p "Please enter the proxy type (e.g. system, apt, git. Default: system): " PROXY_MODE
    [ -z "${PROXY_MODE}" ] && PROXY_MODE="system"
  fi
  if [[ -z $PROXY || -z $NO_PROXY ]]; then
    read -p "Please enter the proxy server and port (e.g. http://proxy.example.com:8080): " PROXY
    read -p "Please enter the comma-separated list of hosts that should not use the proxy (e.g. localhost,127.0.0.1): " NO_PROXY
  fi
  case "$1" in
    system)
      # System Proxy
      echo "Setting system proxy..."
      export http_proxy=$PROXY
      export https_proxy=$PROXY
      export ftp_proxy=$PROXY
      export no_proxy=$NO_PROXY
      echo "System proxy settings:\nhttp_proxy=$PROXY\nhttps_proxy=$PROXY\nftp_proxy=$PROXY\nno_proxy=$NO_PROXY"
      shift;;
    apt)
      # apt proxy
      echo "Setting apt proxy..."
      echo "Acquire::http::Proxy \"$PROXY\";" >> /etc/apt/apt.conf
      echo "Acquire::https::Proxy \"$PROXY\";" >> /etc/apt/apt.conf
      echo "apt proxy settings:\nAcquire::http::Proxy \"$PROXY\";\nAcquire::https::Proxy \"$PROXY\";"
      shift;;
    git)
      #git proxy
      echo "Setting git proxy..."
      git config --global http.proxy "$PROXY"
      git config --global https.proxy "$PROXY"
      echo "git proxy settings: $PROXY"
      shift;;
  esac
}

# Function to cancel proxy settings on the system
function unset_proxy {
  if [[ -z $UNSET_PROXY_MODE ]]; then
    read -p "Please enter the proxy type (e.g. system, apt, git. Default: system): " UNSET_PROXY_MODE
    [ -z "${UNSET_PROXY_MODE}" ] && UNSET_PROXY_MODE="system"
  fi
  
  case "$1" in
    system)
      # System Proxy
      echo "Canceling system proxy..."
      unset http_proxy
      unset https_proxy
      unset ftp_proxy
      unset no_proxy
      echo "System proxy settings canceled."
      shift;;
    apt)
      # apt proxy
      echo "Canceling apt proxy..."
      sed -i '/Acquire::http::Proxy/'d /etc/apt/apt.conf
      sed -i '/Acquire::https::Proxy/'d /etc/apt/apt.conf
      echo "apt proxy settings canceled."
      shift;;
    git)
      #git proxy
      echo "Setting git proxy..."
      git config --global --unset http.proxy
      git config --global --unset https.proxy
      echo "git proxy settings canceled."
      shift;;
  esac
}

# Function to install Docker and Docker Compose
function install_docker {
  echo "Installing Docker and Docker Compose..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker $USER
  docker-compose --version
}

# Check for user input and execute corresponding function
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--install-ssh)
      install_ssh
      shift;;
    -r|--enable-root-login)
      enable_root_login
      shift;;
    -c|--create-user)
      create_user
      shift;;
    -k|--install-ssh-key)
      install_ssh_key
      shift;;
    -p|--change-ssh-port)
      SSH_PORT=$2
      change_ssh_port
      shift 2;;
    -d|--disable-password-login)
      disable_password_login
      shift;;
    -t|--set-timezone)
      set_timezone
      shift;;
    -n|--set-hostname)
      set_hostname
      shift;;
    --set-proxy)
      set-proxy
      shift;;
    --unset-proxy)
      unset_proxy
      shift;;
    -o|--install-docker)
      install_docker
      shift;;
    -h|--help)
      print_usage
      shift;;
    *)
      echo "Invalid option: $1"
      print_usage
      shift;;
  esac
done
