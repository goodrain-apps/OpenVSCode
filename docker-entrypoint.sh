#!/bin/bash

# Init with extensions Gitlab-workflow
if [ ! -d /home/workspace/.openvscode-server/extensions/gitlab.gitlab-workflow-3.40.2 ] && [ ! -d /home/workspace/.openvscode-server/extensions ];then
  mkdir -p /home/workspace/.openvscode-server/extensions/
  tar xf /home/gitlab.gitlab-workflow-3.40.2.tar -C /home/workspace/.openvscode-server/extensions/
fi

# Start 
${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --without-connection-token

# Exec follow cmd
exec $@