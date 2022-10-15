#!/bin/bash
prometheus_package=https://github.com/prometheus/prometheus/releases/download/v2.39.1/prometheus-2.39.1.linux-amd64.tar.gz
alertmanager_package=https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz

prometheus_install() {
 cd /data
 yum install wget -y
 yum update -y
 wget $prometheus_package
 useradd --no-create-home --shell /bin/false prometheus
 mkdir /etc/prometheus
 mkdir /data/prometheus
 chown prometheus:prometheus /etc/prometheus
 chown prometheus:prometheus /data/prometheus
 tar -xvzf prometheus-2.39.1.linux-amd64.tar.gz
  mv prometheus-2.39.1.linux-amd64 prometheuspackage
  cp prometheuspackage/prometheus /usr/local/bin/
  cp prometheuspackage/promtool /usr/local/bin/
  chown prometheus:prometheus /usr/local/bin/prometheus
  chown prometheus:prometheus /usr/local/bin/promtool
  cp -r prometheuspackage/consoles /data/prometheus
  cp -r prometheuspackage/console_libraries /data/prometheus
  cp -r prometheuspackage/prometheus.yml /etc/prometheus
  chown -R prometheus:prometheus /data/prometheus
  chown -R prometheus:prometheus /etc/prometheus
  cat <<EOF > /etc/systemd/system/prometheus.service
  [Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /data/prometheus/ \
--web.console.templates=/data/prometheus/consoles \
--web.console.libraries=/data/prometheus/console_libraries \
--web.enable-lifecycle \
--storage.tsdb.retention.time=30d
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable prometheus.service
systemctl start prometheus.service
cat <<EOF > /usr/local/bin/promchk
promtool check config /etc/prometheus/prometheus.yml
EOF
chmod 755 /usr/local/bin/promchk
chown prometheus:prometheus /usr/local/bin/promchk
cat <<EOF > /usr/local/bin/promreload
curl -vv -X POST localhost:9090/-/reload
EOF
chmod 755 /usr/local/bin/promreload
chown prometheus:prometheus /usr/local/bin/promreload
}
alertmanager_install (){
    cd /data
    wget $alertmanager_package
    tar -xvzf alertmanager-0.24.0.linux-amd64.tar.gz
    cp alertmanager-0.24.0.linux-amd64/amtool /usr/local/bin/amtool
    cp alertmanager-0.24.0.linux-amd64/alertmanager /usr/local/bin/alertmanager
    mkdir -p /etc/alertmanager
    cp alertmanager-0.24.0.linux-amd64/alertmanager.yml /etc/alertmanager
    chown -R prometheus:prometheus /etc/alertmanager
    mkdir -p /data/alertmanager
    chown -R prometheus:prometheus /data/alertmanager
cat <<EOF > /etc/systemd/system/alertmanager.service
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/data/alertmanager

Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable alertmanager.service
systemctl start alertmanager.service
}
grafana_install(){
    wget https://dl.grafana.com/oss/release/grafana-9.2.0-1.x86_64.rpm
sudo yum install grafana-9.2.0-1.x86_64.rpm -y
systemctl enable grafana-server
systemctl start grafana-server
}
prometheus_install
alertmanager_install
grafana_install