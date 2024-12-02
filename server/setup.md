# Fuzzing Server Setup Notes (For Lab Leads)

## GCP

Create a project and create a GCE box.
For the instance shape, core count matters the most and we don't need a lot of memory.
Either x86 or Arm works.
Spot instances are much cheaper but they can occasionally get shut down, which isn't a big issue in practice since it doesn't happen very often.
Try all the instance shapes and regions to find the cheapest one.
The physical location doesn't matter much as long as it is in the US.
If the server is on another continent, there will be noticeable lag when typing in SSH.
Use a big distro like Debian or Fedora.

When creating the project, change the default network service tier to standard.
Remove the default compute engine service account from the box since that gives it edit access to the whole project.
Add admin SSH keys to the box or the project configuration.
The comment fields of the keys will be used as the username on the box.
Use the scripts in this directory to create unprivileged users for the lab members.

## HTTP Server

Install Apache and setup the userdir module.
You might have to change directory permissions so that the server can read the files since it runs as an unprivileged user.
User Certbot to automatically configure certificates for HTTPS.
You have to allow HTTP traffic in the GCE box configuration.
