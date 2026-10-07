# Created by newuser for 5.9.1
source /usr/lib/spaceship-prompt/spaceship.zsh

# Configuration Cache Shaders NVIDIA (RTX 4060)
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=21474836480
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1

# Share one ssh-agent across all terminals
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
ssh-add -l >/dev/null 2>&1
if [ "$?" -eq 2 ]; then
    rm -f "$SSH_AUTH_SOCK"
    eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)" >/dev/null
fi
