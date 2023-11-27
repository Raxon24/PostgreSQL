#! /usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Raxon24/mixt/main/built.func)
clear
function header_info {
cat <<"EOF"
    ____             __                 _____ ____    __ 
   / __ \____  _____/ /_____ _________ / ___// __ \  / / 
  / /_/ / __ \/ ___/ __/ __  / ___/ _ \\__ \/ / / / / /  
 / ____/ /_/ (__  ) /_/ /_/ / /  /  __/__/ / /_/ / / /___
/_/    \____/____/\__/\__, /_/   \___/____/\___\_\/_____/
                     /____/                              
EOF
}

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
catch_errors
setting_up_PosgreSQL
network_check
update_os

msg_info "Installing Dependencies"
$STD sudo apt-get install -y curl
$STD sudo apt-get install -y sudo
$STD sudo apt-get install -y mc
$STD sudo apt-get install -y gnupg2
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL Repository"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
sudo echo "deb http://apt.postgresql.org/pub/repos/apt ${VERSION}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
sudo curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --output /etc/apt/trusted.gpg.d/postgresql.gpg
msg_ok "Setup PostgreSQL Repository"

msg_info "Installing PostgreSQL"
$STD sudo apt-get update

$STD sudo apt-get install -y postgresql

sudo cat <<EOF >/etc/postgresql/16/main/pg_hba.conf
# PostgreSQL Client Authentication Configuration File
local   all             postgres                                peer
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             0.0.0.0/24              md5
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
host    all             all             0.0.0.0/0               md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

sudo cat <<EOF >/etc/postgresql/16/main/postgresql.conf
# -----------------------------
# PostgreSQL configuration file
# -----------------------------

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = '/var/lib/postgresql/16/main'       
hba_file = '/etc/postgresql/16/main/pg_hba.conf'     
ident_file = '/etc/postgresql/16/main/pg_ident.conf'   
external_pid_file = '/var/run/postgresql/16-main.pid'                   

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = '*'                 
port = 5432                             
max_connections = 100                  
unix_socket_directories = '/var/run/postgresql' 

# - SSL -

ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

shared_buffers = 128MB                
dynamic_shared_memory_type = posix      

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

max_wal_size = 1GB
min_wal_size = 80MB

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - What to Log -

log_line_prefix = '%m [%p] %q%u@%d '           
log_timezone = 'Etc/UTC'

#------------------------------------------------------------------------------
# PROCESS TITLE
#------------------------------------------------------------------------------

cluster_name = '16/main'                

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Locale and Formatting -

datestyle = 'iso, mdy'
timezone = 'Etc/UTC'
lc_messages = 'C'                      
lc_monetary = 'C'                       
lc_numeric = 'C'                        
lc_time = 'C'                           
default_text_search_config = 'pg_catalog.english'

#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------

include_dir = 'conf.d'                  
EOF

sudo systemctl restart postgresql
msg_ok "Installed PostgreSQL"

read -r -p "Would you like to add Adminer? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Adminer"
  $STD sudo apt install -y adminer
  $STD sudo a2enconf adminer
  systemctl reload apache2
  msg_ok "Installed Adminer"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD sudo apt-get autoremove
$STD sudo apt-get autoclean
msg_ok "Cleaned"

msg_ok "Completed Successfully!\n"
