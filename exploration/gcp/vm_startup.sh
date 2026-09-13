#!/usr/bin/env bash
# GCE startup script: runs on EVERY boot, including the restart after a spot preemption.
# If the scout is already installed, resume the alignment; on the very first boot (before
# provision_m32.sh has shipped the files) there is nothing to do yet, and that is fine.
if [ -x /opt/scout/run.sh ]; then
  # run as the provisioning user, not root, so cargo/rustup live in the same $HOME
  U=$(ls /home | head -1)
  su - "$U" -c "nohup /opt/scout/run.sh > /opt/scout/run.out 2>&1 &"
fi
