#!/bin/bash

set -xe

yum install -y \
    rpm-build \
    openssh-server \
    policycoreutils-python \
    curl \
    git

# TODO - add creds
rpm -Uvh https://$REPO_USERNAME:$REPO_PASSWORD@pkg.stoplight.io/archives/rpmrebuild-2.11-2.noarch.rpm

# TODO - update versions
curl -sL \
     -o gitlab-ce-10.7.2-ce.0.el7.x86_64.rpm \
     https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-10.7.2-ce.0.el7.x86_64.rpm/download.rpm
rpm -i gitlab-ce-10.7.2-ce.0.el7.x86_64.rpm

git clone https://github.com/stoplightio/gitlabhq.git
cd gitlabhq && ./scripts/stoplight-bootstrap.sh

echo "Now run: rpmrebuild -e gitlab-ce"

# When editing the RPM, remember to rename the package and remove the
# files.
#
# The last time I did this, I had to remove lines 69 - 78959 (or
# everything under '%files').
#
# In vim, you can do this by:
#
# - going to line 69 with '69G'
# - removing lines up to the one we want with 'd78959G'
#
