# 3x-ui-pro

Simple bash script to install pre-configured 3x-ui webpanel, subscriptions and inbound with
client under some domain

Notices:

- The only opened ports after installation will be 22 (ssh), 80 (http) and 443 (https);
- All content such as dummy site, webpanel, subscriptions and inbounds is available
  under 443 port;
- Index page will be https://nometa.xyz content as a dummy site against TMCT analyze;
- The only installed pre-configured inbound is vless+ws (more options will be added later);
- There is no reality in configuration, everything is done purely under your domain as "true"
  self-hosted site does.

## Quick Start

```bash
curl https://raw.githubusercontent.com/vlad7583/3x-ui-pro/master/install.sh --output install.sh
chmod +x ./install.sh
sudo ./install.sh your-mega.cool-domain.com
```

Successful output:

```
[ Successfully Installed Proxy ]
URL: https://your-mega.cool-domain.com/[random-generated-path]/"
Username: admin
Password: [random-generated-password]
```

You can visit 3X-UI panel by URL provided after installation
