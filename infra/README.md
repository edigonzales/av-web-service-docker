## cloud config

```
#cloud-config
users:
  - name: avws
    shell: /bin/bash
    groups: docker

package_upgrade: false

runcmd:
  - [su, avws, -c, "git clone https://github.com/edigonzales/av-web-service-docker.git /home/avws/av-web-service-docker"]
```

Bessere Variante:

```
#cloud-config
package_update: true
package_upgrade: false

packages:
  - git
  - curl
  - ca-certificates
  - openjdk-21-jdk
  - postgresql 
  - postgresql-contrib

users:
  - name: avws
    shell: /bin/bash
    groups: docker
    create_home: true

runcmd:
  # JBang als User avws installieren
  - [runuser, -l, avws, -c, "curl -Ls https://sh.jbang.dev | bash -s - app setup"]

  # Sicherstellen, dass JBang auch in Login-Shells gefunden wird
  - [runuser, -l, avws, -c, "grep -q '.jbang/bin' ~/.bashrc || echo 'export PATH=\"$HOME/.jbang/bin:$PATH\"' >> ~/.bashrc"]

  # Optional, aber hilfreich: JAVA_HOME für den User setzen
  - [runuser, -l, avws, -c, "grep -q 'JAVA_HOME' ~/.bashrc || echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc"]

  # Repositories klonen
  - [runuser, -l, avws, -c, "git clone https://github.com/edigonzales/av-web-service-docker.git /home/avws/av-web-service-docker"]
  - [runuser, -l, avws, -c, "git clone https://github.com/edigonzales/pdf4av.git /home/avws/pdf4av"]

  # Sanity checks im Cloud-Init-Log
  - [runuser, -l, avws, -c, "java -version"]
  - [runuser, -l, avws, -c, "$HOME/.jbang/bin/jbang --version"]
```


Floating-IP:

Siehe https://docs.hetzner.com/de/cloud/floating-ips/persistent-configuration/ -> Ubuntu (netplan) auch für Docker CE App Image.


```
chmod 700 /etc/netplan/60-floating-ip.yaml
```

```
sudo netplan apply
```

Stack starten:

```
docker compose -f av-web-service-docker/infra/docker-compose.yml -p avws up (-d)
```

Daten importieren:

```
cd pdf4av
```

```
jbang dev/import-data.java list
```

```
jbang dev/import-data.java schema --db=avws --user=postgres --password=secret
```

```
jbang dev/import-data.java import dmav --db=avws --user=postgres --password=secret
```

...

```
nohup jbang dev/import-data.java import gebaddr --db=avws --user=postgres --password=secret > import-data.log 2>&1 &
```


etc.

Weil Index-Creation noch nicht in import-Script gewesen:

```
psql -h 127.0.0.1 -p 54321 -U postgres -d avws
```

```
CREATE INDEX IF NOT EXISTS offclndss_address_bdg_egid_idx ON stage.offclndss_v2_2officlndxfddrsses_address (bdg_egid);
```


```
http://65.109.251.87:8080/logo/ch.SO
```