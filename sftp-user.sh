#!/usr/bin/env bash

# Fix chroot permission
chown root:root ${VHOSTS_DIR}/$domain
chmod o-r ${VHOSTS_DIR}/$domain
