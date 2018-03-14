#!/bin/bash
#
# This is a modified version of https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/docker/assets/wrapper
#
# This was customized to support CentOS/RHEL base images

function sigterm_handler() {
    echo "SIGTERM signal received, try to gracefully shutdown all services..."
    gitlab-ctl stop
}

function failed_pg_upgrade() {
    echo 'Upgrading the existing database to 9.6 failed and was reverted.'
    echo 'Please check the output, and open an issue at:'
    echo 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
    echo 'If you would like to restart the instance without attempting to'
    echo 'upgrade, add the following to your docker command:'
    echo '-e GITLAB_SKIP_PG_UPGRADE=true'
    exit 1
}

trap "sigterm_handler; exit" TERM

# Copy gitlab.rb for the first time
if [[ ! -e /etc/gitlab/gitlab.rb ]]; then
	echo "Installing gitlab.rb config..."
	cp /opt/gitlab/etc/gitlab.rb.template /etc/gitlab/gitlab.rb
	chmod 0600 /etc/gitlab/gitlab.rb
fi

# Generate ssh host key for the first time
if [[ ! -f /etc/gitlab/ssh_host_rsa_key ]]; then
	echo "Generating ssh_host_rsa_key..."
	ssh-keygen -f /etc/gitlab/ssh_host_rsa_key -N '' -t rsa
	chmod 0600 /etc/gitlab/ssh_host_rsa_key
fi
if [[ ! -f /etc/gitlab/ssh_host_ecdsa_key ]]; then
	echo "Generating ssh_host_ecdsa_key..."
	ssh-keygen -f /etc/gitlab/ssh_host_ecdsa_key -N '' -t ecdsa
	chmod 0600 /etc/gitlab/ssh_host_ecdsa_key
fi
if [[ ! -f /etc/gitlab/ssh_host_ed25519_key ]]; then
	echo "Generating ssh_host_ed25519_key..."
	ssh-keygen -f /etc/gitlab/ssh_host_ed25519_key -N '' -t ed25519
	chmod 0600 /etc/gitlab/ssh_host_ed25519_key
fi

# Remove all services, the reconfigure will create them
echo "Preparing services..."
rm -f /opt/gitlab/service/*
ln -s /opt/gitlab/sv/sshd /opt/gitlab/service
ln -sf /opt/gitlab/embedded/bin/sv /opt/gitlab/init/sshd
mkdir -p /var/log/gitlab/sshd

# Start service manager
echo "Starting services..."
GITLAB_OMNIBUS_CONFIG= /opt/gitlab/embedded/bin/runsvdir-start &

grep 'load sysctl' /opt/gitlab/embedded/cookbooks/package/resources/sysctl.rb &>/dev/null
if [[ $? -eq 0 ]]; then
    # dont set kernel limits
    sed -i"" -e '58,62d' /opt/gitlab/embedded/cookbooks/package/resources/sysctl.rb
    sed -i"" -e '62,76d' /opt/gitlab/embedded/cookbooks/gitlab/recipes/postgresql.rb
fi

echo "Configuring GitLab..."
gitlab-ctl reconfigure

# Make sure PostgreSQL is at the latest version.
# If it fails, print a message with a workaround and exit
if [ "${GITLAB_SKIP_PG_UPGRADE}" != true ]; then
    gitlab-ctl pg-upgrade -w || failed_pg_upgrade
fi

# Tail all logs
gitlab-ctl tail &

# Wait for SIGTERM
wait
