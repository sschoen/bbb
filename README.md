
# bbb-lfb-ansible

Ansible playbook zur Installation von BBB auf den LFB Maschinen.

## Installation BBB

* Einen oder mehrere Server mit Ubuntu 16.04 mit IPv4 Adresse
* DNS Einträge für alle Server müssen angelegt sein (BSP bbb01.q-gym.de, bbb02.q-gym.de)
* Sicherstellen, dass man sich als root mit SSH-Key auf den Server verbinden kann
* Anpassen der Einstellungen für die BBB Version und den Turn-Server im Playbook wenn nötig.
* Wenn man mehrere Maschinen ausrollen möchte, kann man ein Inventory File anlegen und mit ``ansible-playbook -i hosts bbb-install.yml --ask-vault-pass`` alle Maschinen auf einmal installieren.
* Wennb man nur eine Maschine installieren möchte kann man das ohne Inventory tun: ``ansible-playbook -i "bbb.q-gym.de," bbb-install.yml --ask-vault-pass``
* Wenn man direkten Zugriff auf Greenlight haben möchte, muss man dort Accounts anlegen, zumindest einen admin-Account. Dazu als root auf dem Server anmelden, ``cd greenlight``, dort ``docker exec greenlight-v2 bundle exec rake user:create["Lokaler Admin","admin@bbb.local","SUPERGEHEIMESPASSWORT","admin"]``

Das Playbook ``bbb-without-install-script.yml`` arbeitet alle Roles ab, bis auf das eigentliche bbb-Installationssskript. Das kann verwendet werden, um die Umgebung um ein installiertes BBB anzupassen, z.B. wenn man ``apply-config.sh`` verändert.

Wenn man das Passwort für den ansible-Vault nicht kennt, muss man im Variablen-Block der Playbooks seine eigenen Werte direkt eintragen:

    scriptoptlemail: "{{ vault_scriptoptlemail }}"
    scriptoptsturnsrv: "{{ vault_scriptoptsturnsrv }}"
    scriptoptsturnpw: "{{ vault_scriptoptsturnpw }}"

wir dann z.B. zu:

    scriptoptlemail: "webmaster.meinedomain.dom"
    scriptoptsturnsrv: "turn.meinedomain.dom"
    scriptoptsturnpw: "xxggrree55"


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
