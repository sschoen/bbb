For english description see below.

# bbb-lfb-ansible

Ansible playbook zur Installation von BBB auf den LFB Maschinen.

## Installation BBB

* Einen oder mehrere Server mit Ubuntu 16.04 mit IPv4 Adresse
* DNS Einträge für alle Server müssen angelegt sein (BSP bbb01.q-gym.de, bbb02.q-gym.de)
* Sicherstellen, dass man sich als root mit SSH-Key auf den Server verbinden kann
* Anpassen der Einstellungen für die BBB Version und den Turn-Server im Playbook wenn nötig.
* Wenn man mehrere Maschinen ausrollen möchte, kann man ein Inventory File anlegen und mit ``ansible-playbook -i hosts bbb-install.yml --ask-vault-pass`` alle Maschinen auf einmal installieren.
* Wennb man nur eine Maschine installieren möchte kann man das ohne Inventory tun: ``ansible-playbook -i "bbb.q-gym.de," bbb-install.yml --ask-vault-pass``


Das Playbook ``bbb-without-install-script.yml`` arbeitet alle Roles ab, bis auf das eigentliche bbb-Installationssskript. Das kann verwendet werden, um die Umgebung um ein installiertes BBB anzupassen, z.B. wenn man ``apply-config.sh`` verändert.

Wenn man das Passwort für den ansible-Vault nicht kennt, muss man im Variablen-Block der Playbooks seine eigenen Werte direkt eintragen:

    scriptoptlemail: "{{ vault_scriptoptlemail }}"
    scriptoptsturnsrv: "{{ vault_scriptoptsturnsrv }}"
    scriptoptsturnpw: "{{ vault_scriptoptsturnpw }}"

wir dann z.B. zu:

    scriptoptlemail: "webmaster.meinedomain.dom"
    scriptoptsturnsrv: "turn.meinedomain.dom"
    scriptoptsturnpw: "xxggrree55"

und die Zeile

    vars_files: vault

muss man auskommentieren.

* Wenn man direkten Zugriff auf das BBB über Greenlight haben möchte, muss man dort Accounts noch anlegen, zumindest einen admin-Account. Dazu als root auf dem Server anmelden, ``cd greenlight``, dort ``docker exec greenlight-v2 bundle exec rake user:create["Lokaler Admin","admin@bbb.local","SUPERGEHEIMESPASSWORT","admin"]``
* Um die Konfigurationsdaten für das Moodle-Plugin zu erhalten, führt man auf dem BBB-Server den Befehl ``bbb-conf --secret`` aus. Wenn man nur das Moodle-Plugin zum Zugriff auf das BBB nutzen will, benötit man keine Greenlight Benutzer.

## Konfigurationsvariablen

Der Host- und Domainname muss nicht mehr als Variable gesetzt werden, sondern wird aus dem Inventory-Hostnamen abgeleitet.

``ansible-playbook -i "bbb.q-gym.de," bbb-install.yml``

Sollte also automagisch für den Host bbb.q-gym.de alles richtig machen.


## Installation Turnserver

Sollte auf Debian Derivaten laufen (gestetet debian buster). Voraussetzung: Frisch installiertes Debian/Ubuntu mit DNS Eintrag.

Anzupassen ist das Secret im Playbook, das kann erzeugt werden mit ``openssl rand -hex 16``

``ansible-playbook -i "turn.q-gym.de," bbb-coturn.yml``

Verwendet die Rolles

* up2date-ubuntu
* coturn
* monitoring
* reboot


## Roles

* up2date-ubuntu: Bringt das Ubuntu auf den neuesten Patchstand und installiert alle im Playbook geforderten Packages
* prepare-bbb: Bereitet die BBB Installation vor (FQDN setzen, hostname etc.)
* install-bbb: Kopiert das bbb-install.sh aufs Target und führt es aus.
* configure-bbb: Nimmt spezifische Anpassungen der BBB Konfiguration vor
* security: Sichert den Server (etwas) ab - kein Zugriff ohne Key.
* monitoring: Installiert check_mk-Agent und den Lokalen BBB Check
* reboot: Genau das
* coturn: Installiert einen coturn-Server nach den Spezifikationen von BBB unter https://docs.bigbluebutton.org/2.2/setup-turn-server.html

======================================================================

# Providing BigBlueButton-Servers on Powerfull Hardware
The ansible playbooks provided here have been developed mostly in
April 2020, during the Corona-Pandemic to provide online teaching and
conference tools for all schools in Baden-Württemberg, south-west
Germany.  They are work in progress, but work fine as far as we can
tell today, and are used to prepare a total of several hundred
BigBlueButton Servers (BBBs) on dozens of powerful (32 core, 64
threads) machines.

## Setup
Our setup is as follows:

### Ubuntu 16.04 Container
To facilitate the most efficient use of the hardware at hand and the
limitation/recommendation to run BBB on Ubuntu 16.04, we set up BBB in
containers, which are in turn run and managed by systemd-nspawn.  The
host system is Debian Buster and no problems running the BBB container
with the Debian stable kernel have been observed.  This light weight
setup provides very good sharing of hardware resources and hopefully
sufficiently good response times for the real-time A/V-application,
even under heavy load.

Right now, we run 28 BBB container on a single machine (64 threads),
which might be a bit to much under-provisioning.  The best ratio of
threads/cores per BBBs is still an area under investigation.

#### Modifications of the BBB Container
When preparing the initial Ubuntu 16.04 container, no very special
modifications have been applied.  Almost all if not all customization
from the straight forward setup described in the BBB documentation is
available in the playbook ``bbbcontainerhosts.yml`` now, as any update
of BBB seems to happily overwrite applied configuration settings.  The
initial container is archived with ``machinectl export-tar bbb000
bbb000-$(date +%Y%m%d).tar.xz`` and needs to be provided on roll-out:

``vault_container_image: "https://PROVIDE.CONTAINER.TLD/image/bbb000.tar.xz"``

#### STUN/TURN Server
In addition to the BBB containers, every host provides a containerized
STUN/TURN server (``coturn``) which is used by all BBBs of the
associated host.  The setup is straight forward, based on a
``debootstrap``ed Debian Buster.

### Network
We use a single NIC of the host with several IP-addresses:  The
IP-address of the host itself as well as all IP-addresses of the
containers.  All container configuration is calculated from the subnet
provided at install time for every machine.  In the ansible inventory
hosts file, we provide for example:

``[containerhost]``
``HOST.DOMAIN.TLD  vault_guest_network="172.93.28.160/28"``.

With this set, the playbook assigns the first usable subnet address
(``172.93.28.161``) to the bridge ``virbr0``, the second
(``172.93.28.162``) to the turn server (a minimal Debian
Buster with ``coturn``, see above) and then all further addresses to
BBBs, as long as they are resolvable by the DNS
(cf. ``bbbcontainerhosts.yml``).

## Roll-Out
On roll-out, we need the server with minimal Debian Buster installed
and ssh pubkey authentification.  In addition, subnet information
(``vault_guest_network=…``) needs to be provided.  Further more, all
DNS entries need to be ready for the BBBs.  After that, the host
carrying the STUN/TURN server and a bunch of BBBs is ready after
running:

``ansible-playbook -u root -i hosts --vault-password-file vault.pwd --limit HOSTS2INSTALL rollout-master.yml``

### Disable, Enable, Check and Upgrade BBBs
To remove all BBBs of a host from the load balancer pool, use the
master playbook with the ``--tags=bbb_disable`` option.  Add them back
to the pool with ``--tags=bbb_enable``.

To run only the set of checks on the BBB containers, use the
``--tags=bbb_check`` option.

To upgrade the BBBs, use ``--tags=bbb_upgrade``.

## Miscellaneous
We use several monitoring systems to optimize and further develop the
setup.  We are happy to provide further information if needed and
of course appreciate recommendations and better ideas.
