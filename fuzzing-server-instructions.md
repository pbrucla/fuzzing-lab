# Fuzzing Server Instructions

We will be using the AI safety server to perform our fuzzing, since there are GPUs on the server with which we can run a local Qwen3.8 model.
It's similar to the SEASnet servers, but we will connect to it using keys instead of passwords.
You can use VS Code to edit files on the server.

## SSH client

We will use the SSH protocol to remotely log into the server, so you need to have an SSH client installed on your computer.
macOS should have an SSH client installed by default.
For Windows, go to *Settings > System > Optional Features* and install *OpenSSH Client*.
You can also use the SSH client in WSL or PuTTY if you want, but if you use PuTTY you'll need to follow different steps to generate a key.
If you want to use VS Code installed locally instead of in your browser, you have to use the Windows OpenSSH client.

If you have issues using SSH locally, you can use https://shell.cloud.google.com instead, a Linux machine in the cloud accessible via your browser.

## SSH keys

We will use SSH keys to prove our identity to the server.
If you already have SSH keys, you can skip the next couple of steps.
Note that the Windows SSH client, the SSH client in WSL, and PuTTY all store keys in different places, so keys generated with one SSH client won't automatically work with other SSH clients.

To generate an SSH key, run `ssh-keygen -t ed25519` in a terminal (outside of WSL if you're on Windows).
When prompted for the location where the key will be saved, choose the default by pressing Enter.
Your keys will be stored in the `.ssh` folder of your home directory, which is hidden by default on macOS and Linux.
Your public key will be stored in a file named `id_ed25519.pub` and your private key will be in `id_ed25519`.
Submit this [form](https://docs.google.com/forms/d/e/1FAIpQLSf5OSA7U8VZ4MtdvXCd-P6pGczuQ77rSg_MoeZQcTHnMQwiYQ/viewform) with your **public** key so that we can give you access to the server.
The private key is used to prove that you own the public key and you should keep it secret.

## Editing your SSH Configuration

In the `.ssh` folder of your home directory, create a file with the name `config` (or append to it if it already exists), and add the following contents

```
Host sullivan
  ForwardAgent yes
  HostName sullivan.seas.ucla.edu
  User <USERNAME>

Host temescal
  ForwardAgent yes
  ProxyJump sullivan
  HostName temescal.seas.ucla.edu
  User <USERNAME>

Host ynez
  ForwardAgent yes
  ProxyJump sullivan
  HostName ynez.seas.ucla.edu
  User <USERNAME>

Host serrano
  ForwardAgent yes
  ProxyJump sullivan
  HostName serrano.seas.ucla.edu
  User <USERNAME>
```

Remember to replace `<USERNAME>` with actual username.

## Connecting to the AI Safety Server with SSH

> [!NOTE]
> To access the AI safety servers, you will need to first connect to the UCLA VPN, even if you are using an on-campus wifi like eduroam. You can learn how to do this at [Campus VPN](https://dts.ucla.edu/products-services/software-downloads/virtual-private-network-vpn).

Once we tell you that we've added your user to the server, you should be able to connect by running `ssh ynez`, `ssh temescal` or `ssh serrano` based on the server you want to connect to.

> When you do this for the first time, you will be asked to verify the server's host key. You can ask us for the fingerprint if you're really concerned, otherwise just type `yes`.

The no. of GPUs for each server are as follows

| Server Name | No. of Nvidia RTX 3090 GPUs |
| ----------- | --------------------------- |
| temescal | 3 |
| ynez | 4 |
| serrano | 5 |

If everything worked, you should see a green shell prompt that looks like `<username>@<server-name>:~$`.
Type `exit` to disconnect from the server.

## VS Code

After you log into the server, you can open VS Code in your browser by running `code tunnel` on the server.
Alternatively, if you have VS Code installed locally, you can install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension and run the **Remote-SSH: Connect to Host** command.
See the [documentation](https://code.visualstudio.com/docs/remote/ssh) for more details.
