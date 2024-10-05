# Fuzzing Server Instructions

We have a Linux server for you to do your work on.
It's similar to the SEASnet servers, but we will connect to it using keys instead of passwords.
You can use VS Code to edit files on the server.

## SSH client

We will use the SSH protocol to remotely log into the server, so you need to have an SSH client installed on your computer.
macOS should have an SSH client installed by default.
For Windows, go to *Settings > System > Optional Features* and install *OpenSSH Client*.
You can also use the SSH client in WSL or PuTTY if you want, but if you use PuTTY you'll need to follow different steps to generate a key.
If you want to use VS Code installed locally instead of in your browser, you have to use the Windows OpenSSH client.

## SSH keys

We will use SSH keys to prove our identity to the server.
If you already have SSH keys, you can skip the next couple of steps.
Note that the Windows SSH client, the SSH client in WSL, and PuTTY all store keys in different places, so keys generated with one SSH client won't automatically work with other SSH clients.

To generate an SSH key, run `ssh-keygen -t ed25519` in a terminal (outside of WSL if you're on Windows).
When prompted for the location where the key will be saved, choose the default by pressing Enter.
Your keys will be stored in the `.ssh` folder of your home directory, which is hidden by default on macOS and Linux.
Your public key will be stored in a file named `id_ed25519.pub` and your private key will be in `id_ed25519`.
Submit this [form](https://docs.google.com/forms/d/e/1FAIpQLSc9rahtsB0_MOjaj53k9oTJRdC5wd2gsMypsINK3N8EAguQ2g/viewform?usp=sf_link) with your **public** key so that we can give you access to the server.
The private key is used to prove that you own the public key and you should keep it secret.
Once I tell you that I've added your key to the server, you should be able to connect by running `ssh <username>@fuzz.acmcyber.com`.

## VS Code

After you log into the server, you can open VS Code in your browser by running `code tunnel` on the server.
Alternatively, if you have VS Code installed locally, you can install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension and run the **Remote-SSH: Connect to Host** command.
See the [documentation](https://code.visualstudio.com/docs/remote/ssh) for more details.
