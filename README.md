# 3x-ui-pro

Simple bash script to install pre-configured 3x-ui webpanel, subscriptions and inbound with
client under some domain

Notices:

- The only opened ports after installation will be 22 (ssh), 80 (http) and 443 (https);
- All content such as dummy site, webpanel, subscriptions and inbounds is available
  under 443 port;
- Index page will be https://nometa.xyz content as a dummy site against TMCT analyze;
- There is no reality in configuration, everything is done purely under your domain as "true"
  self-hosted site does.

## Quick Start

```bash
bash <(curl -sSL https://raw.githubusercontent.com/vlad7583/3x-ui-pro/master/install.sh) example.org
```

Successful output:

```
[ Successfully Installed Proxy ]
URL: https://example.org/[random-generated-path]/"
Username: admin
Password: [random-generated-password]
```

You can visit 3X-UI panel by URL provided after installation

_Do not_ lose url, username and password! Without it you _will not_ be able to enter panel.

## Special thanks

- [3x-ui](https://github.com/MHSanaei/3x-ui) for panel for users!

- [xray](https://github.com/XTLS/Xray-core) for their crying shit because "oh no 3x-ui do not
  force users to use ssl BeCAusE THeY'rE paID By IRAN GOVeRnmeNt" and giving me more job to
  clear script, **fuck you idiots**
