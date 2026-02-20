# docker-logs-web-server

&emsp;

Web server for docker logs

I was looking for a quick way to access my docker logs without the fuss of setting up a compicated monitoring tool like Grafana, Prometheus or other. This is a 3hours project to offer a webserver for docker logs for any homlabber.
The web server is served on port `8080` and is written to be exposed to all interfaces (i.e. Tailscale, VPN tunnel of any sort, LAN and/or web if your host is exposed to the web too. You can restrict the interfaces in the netcat command in the script.

&emsp;

⚠️ This is a WIP and will add features as we go like auto-refresh or filtering/search abilities

&emsp;

⚠️ Make sure you have all dependencies installed. If not, run `sudo apt install gq netcat-traditional`

&emsp;

---

&emsp;

Best is to set up the script as a service on Linux rather than run it directly from terminal. Below is a short recipe to run this as a service:

1. Copy the repo into a folder

`git clone https://github.com/melbv/docker-logs-web-server`

2. Save the file in your `systemd` path:

`sudo cp /folder/where/repo/cloned/docker-logs-web.sh /usr/local/bin/docker-logs-web.sh`

3. Make the file executable

`sudo chmod +x /usr/local/bin/docker-logs-web.sh`

4. Create the service file

`/etc/systemd/system/docker-logs-web.service`

5. Add the following

```bash
[Unit]
Description=Docker Logs Web Server
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/docker-logs-web.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

6. Reload `systemd`, enable the service and start it

```bash
sudo systemctl daemon-reload
sudo systemctl enable docker-logs-web.service
sudo systemctl start docker-logs.web.service
```

🎉 Well done! You now have a rudimentary webserver that allows you to access your docker logs without the fuss of modern monitoring tools.
