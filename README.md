# Pré-requis

Système d'exploitation: **Debian 10**

Installation des dépendances Python:
```bash
pip install -r requirements.txt
```

# Installation Debian

* Installer Debian
* Sélectionner server ssh uniquement
* Se connecter sur le serveur
  * se logger à la machine et autorisé
  * éditer le fichier /etc/ssh/sshd_config
  * modifier la configuration de sshd pour autorisé root à se logger
  ```bash
  PermitRootLogin yes
  ```
  * sauvegarder le fichier
  * redémarrer sshd
  ```bash
  service sshd restart
  ```
  * Se déconnecter du serveur
* envoyer sa clef privée sur le server
  ```bash
  ssh-copy-id root@<IP HOME SERVER>
  ```
* se connecter avec la clef privée au serveur
  * éditer le fichier /etc/ssh/sshd_config
  * modifier la configuration de sshd pour interdire au compte root de se logger avec un mot de passe
  ```bash
  PermitRootLogin prohibit-password
  ```
  * redémarrer sshd

Si au moment de se connecter avec la clef en ssh, vous obtenez cette erreur:
```
Failed to connect to the host via ssh: sign_and_send_pubkey: signing failed for RSA \"/home/<user>/.ssh/id_rsa\" from agent: agent refused operation
```
Il faut exécuter la commande:
```bash
ssh-add
```

# Configuration du playbook

## Configuration du hosts et de ses hosts_vars

1. Dans le répertoire **inventory** créer un répertoire *myhomeserver*
2. Créer le fichier *hosts* et éditer le pour y mettre le nom du groupe **debian** l'ip du serveur (ex: 192.168.0.1):
   ```
   [debian]
   192.168.0.1
   ```
3. Dans le répertoire *homeserver*, créer le répertoires hosts_vars.
4. Créer le fichier **<IP HOMESERVER>.yml**, ce qui donner dans notre exemple le nom *192.168.0.1.yml* et y configurer la connection:
    ```yaml
    ansible_user: root
    ansible_connection: ssh
    ansible_ssh_private_key_file: '<chemin vers la clef privée>/id_rsa'
    ansible_python_interpreter: /usr/bin/python3
    ```
5. Attention à bien positionner la valeur de *ansible_python_interpreter*.

Voir les exemples:
* [hosts](inventory/sample/hosts)
* [host_vars](inventory/sample/host_vars/192.168.0.1.yml)

## Configuration Home Server ou des group_vars

Dans le répertoire *myhomeserver*, créer les répertoires *group_vars/debian*.

### Configuration du système d'exploitation:

Dans *myhomeserver/group_vars/debian*, créer le fichier **os.yml**.

Y configurer le nom du serveur, voir l'exemple [os.yml](inventory/sample/group_vars/debian/os.yaml)

### Configuration samba

Dans *myhomeserver/group_vars/debian*, créer le fichier **samba.yml**.

Dans ce fichier vont être configurable:
* samba_workgroup: le nom du workgroup windows
* samba_netbios_name: le nom sous lequel apparaitra le serveur en explorant le réseau windows.

Voir l'exemple [samba.yml](inventory/sample/group_vars/debian/samba.yaml)

### Configuration des utilisateurs

#### Configuration des utilisateurs et groupes

Dans *myhomeserver/group_vars/debian*, créer le fichier **users.yml**.
Dans ce fichier vont être configurer les identifiants des utilisateurs ainsi que les groupes auxquels ils appartiennent.

Par défaut, il faut laisser l'utilisateur *admin*, car il sera le propriétaire par défaut de certains répertoires. Il faut juste l'ajouter à tous les groupes qui vont être mis aux autres utilisateurs.

Ensuite créer vos utilisateurs, en indiquant l'identifiant, les groupes et si il doit être créé.
```yaml
server_users:
  admin:
    groups:
      - 'ftp_group'
    state: present
  laurent:
    groups:
      - 'ftp_group'
    state: present
```
Voir l'exemple [users.yml](inventory/sample/group_vars/debian/users.yaml)

#### Configuration des mots de passe

Dans *myhomeserver/group_vars/debian*, créer le fichier **pwd.yaml**.
```yaml
# The salt to encrypt password
secret_salt: 'mysalt'

# The list of the passwords by users
server_passwords:
  admin:
    password: 'i-am-admin'
  laurent:
    password: 'no!no!'
```

*server_password* suis la même strucutre que *server_users*

Voir l'exemple [passwd.yml](inventory/sample/group_vars/debian/passwd.yaml)

### Configuration des espaces spaces

C'est dans cet partie que vous aller configurer vos espaces. Un espace est un répertoire qui pour servir de serveur http, de partage réseau et/ou de server ftp.

* **primary**: default space, do not delete, but configure it as you need.
* **space_name**: space name
  * **short_name**: if your space name is too long (user space name creation will throw an error), set a short name value.
  * **user**: user master of this space (see **file_sharing**)
  * **group**: group allowed to use this space (see **file_sharing**)
  * **commen**t: explanation of the space
  * **services**: list of services enabled for this space. Values:
     * **http**: enable apache for this space
     * **samba**: enable windows file sharing for this space
     * **ftp**: enable ftp file sharing for this space
  * **file_sharing**: Autheticated access for file sharing or FTP *[apply to samba, ftp]*:
     * **write_user_read_group**: Write=User, Read=Group
     * **write_group_read_all**: Write=Group, Read=All
     * **write_group_read_group**: Write=Group, Read=Group
  * **file_sharing**: Autheticated access for file sharing or FTP *[apply to samba, ftp]*:
     * **write_user_read_group**: Write=user, Read=Group
       * samba: user and groupe have access to all space dirs (www, files, cgi-bin)
     * **write_group_read_all**: Write=Group, Read=All
       * samba: group has only access to files dir (see **file_sharing_allow_group_all_access** to change behaviour)
     * **write_group_read_group**: Write=Group, Read=Group
       * samba: group has only access to files dir (see **file_sharing_allow_group_all_access** to change behaviour)
  * **file_sharing_allow_group_all_access**: (default: false) When *write_group_\** is configured in **file_sharing**, by default samba only give access to the *files* directory, if this parameter is set to true, they can access to all space directories.
  * **web_access**: Public acces for web or Anonymous FTP *[apply to http, ftp]*
     * **all_internet_no_password**: All Internet with no password required, local network with no password required
     * **all_internet_with_password**: All internet with password required, local network with password required
     * **all_internet_with_password_except_local**: All internet (password required outside local network)
     * **lan_no_password**: Local network only with no password required)
     * **lan_with_password**: Local network only with password required
     * **no_access**: No web (http or ftp) access
  * **exec_dynamic**: Dynamic content execution (CGI, PHP, SSI) *[apply to http]*
     * **disable**: dynamic content execution disabled
     * **enable**: dynamic content execution enabled
  *  **state**:
     * **present**: the space is created
     * **absent**: the space is deleted
* Http specific configurations:
  * **server_name**: virtualhost server name *[apply to http]*
  * **server_alias**: virtualhost alias names *[apply to http]*
  * **server_cert_base_path**: enable ssl by specify letsencrypt certificate dir path *[apply to http]*.
    * By default, set it to: "{{ letsencrypt_cert_path }}/{{ letsencrypt_root_cn }}"
      ```yaml
      server_cert_base_path: "{{ letsencrypt_cert_path }}/{{ letsencrypt_root_cn }}"
      ```

Voir l'exemple [spaces.yml](inventory/sample/group_vars/debian/spaces.yaml)

### Configuration certbot

Certbot permet de gérer les certificats tls de [let's encrypt](https://letsencrypt.org/).

Cette configuration est faite par 3 partie:
* un script qui permet d'utiliser le challenge DNS de let's encrypt
* un service qui va gérer la mise à jour du certificat tls
* un scheduler qui exécuter 1 à 2 fois par jour le service

Dans *myhomeserver/group_vars/debian*, créer le fichier **certbot.yaml**.

Dans ce fichier vous allez pouvoir configurer:
* **certbot_force_create**: Force la mise à jour/création du certificat lors de l'exécution du playbook (defaut: false)
* **letsencrypt_renewal_behaviour**: comportement de de cerbot pour la mise à jour des certificats(defaut:'--keep-until-expiring')
  * lire la documentation de cerbot (*man certbot*), le svaleurs possibles sont:
    * '--renew-by-default'
    * '--keep-until-expiring'
    * '--renew-with-new-domains'
* **letsencrypt_test**: Permet de générer des certificats de tests let's encrypt. Cela permet de debugguer le *hook* qui permet de modifier les paramètres de DNS chez votre registrar. La limite de mise à jour d'un certificat de prod est de 50/semaine.
* **letsencrypt_root_cn**: configure le CN du certificat, toutes les valeurs de **server_name** se trouvant dans server_spaces seront ajoutée en alias du certificat. Cette valeur sera aussi le nom du répertoire letsencrypt.
* **letsencrypt_hook_template**: chemin du gabarit de script de mise à jour
* **letsencrypt_email**: courriel utilisé pour accéder aux services let's encrypt
* **letsencrypt_renew_timer**: Configuration du scheduleur, voir https://www.freedesktop.org/software/systemd/man/systemd.time.html

Dans le fichier *myhomeserver/group_vars/debian/pwd.yaml*, ajouter la clef:
* **certbot_api_key**: Ce sont les identifiants, ou clef ou token requis par votre registrar pour modifier le DNS.

Voir l'exemple [certbot.yml](inventory/sample/group_vars/debian/certbot.yaml)


Le script est specifique à mon registrar DNS bookmyname.

Voir le script [bookmyname-authenticator.sh](templates/certbot/bookmyname-authenticator.sh)

# Tags disponibles

* *crt*: rejoue la configuration de cerbot
* *dir*: rejoue la création des répertoires des espaces et des répertoires home utilisateurs (ajout/supression)
* *frwl*: rejoue la configuration de iptables
* *ftp*: rejoue la configuration de proftpd
* *hms*: rejoue la configuration de os, dir, users
* *http*: rejoue la configuration de apache2
* *os*: rejoue la configuration du hostname, des répertoires de base, de ssh
* *smb*: rejoue la configuration de samba
* *uau*: rejoue la configuration de unanttended upgrades
* *users*: rejoue la configuration des utilisateurs (ajout/supression)
