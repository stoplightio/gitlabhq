#!/bin/bash
#
# This script converts a generic Gitlab CE installation into a
# Stoplight version.
#
# Run from the root of the Gitlab git repository.
#

set -ex

rm -rf \
    /opt/gitlab/embedded/service/gitlab-rails/app \
    /opt/gitlab/embedded/service/gitlab-rails/db \
    /opt/gitlab/embedded/service/gitlab-rails/lib \
    /opt/gitlab/embedded/service/gitlab-rails/config

cp -rf ./app/assets/images/mailers/stoplight_* /opt/gitlab/embedded/service/gitlab-rails/public/assets/mailers/
cp -rf ./public/stoplight-images/* /opt/gitlab/embedded/service/gitlab-rails/public/assets/

cp -rf ./app /opt/gitlab/embedded/service/gitlab-rails/app/
cp -rf ./db /opt/gitlab/embedded/service/gitlab-rails/db/
cp -rf ./lib /opt/gitlab/embedded/service/gitlab-rails/lib/
cp -rf ./config /opt/gitlab/embedded/service/gitlab-rails/config/
