---
layout: post
title: Forward root mail from Ubuntu Server 14.04
tags: sysadmin
---

I recently found my home file server in a sorry state. My backup drive had died,
causing my nightly backup cronjob to fail, and one of the disks in the RAID
array of the main data partition had died long ago without me realizing it. When
I finally checked the local mail on the server for the `root` user, it was full
of warnings about the degraded array and the failing backup job. The problem is
that I never really think to check the root mail on the server. Time for a new
solution. The goal is to forward `root` mail to my gmail account where I'll
actually see it.

Postfix should be configured in a "send-only" configuration. My server probably
can't receive smtp traffic anyway due to my ISP blocking ports and my router not
being configured to forward those ports to my server, but I'd like to have it
configured in a safe way that my server doesn't become some kind of open relay.

## Configuring Postfix

The following steps are done with Ubuntu 14.04.

At first I followed [this tutorial][digital-ocean] taking the following steps:

1. Run `sudo dpkg-reconfigure postfix` to select "Internet Site" and supply a
   proper system mail name with my domain.
2. Edit `/etc/postfix/main.cf` to change `inet_interfaces = all` to
 `inet_interfaces = loopback-only`. This ensures we are set up in "send-only"
  mode so postfix will only receive mail on the local loopback network.
3. Then restart postfix `sudo service postfix restart`

Sending a test email failed.

```
echo "This is the body of the email" | mail -s "This is the subject line" your_email_address
```

When attempting to send to my gmail I saw an error similar to the following in
`/var/log/mail.log`:

```
Mar  9 10:49:47 icculus postfix/smtp[55073]: connect to gmail-smtp-in.l.google.com[2607:f8b0:400d:c0a::1b]:25: Network is unreachable
```

My ISP blocks port 25 and gmail prefers port 587. I tried editing
`/etc/postfix/main.cf` to add `relayhost = [smtp.gmail.com]:587` which allowed
me to connect to gmail, but I was then hit with an authentication error.

The solution I wound up using was to have my server authenticate with valid
gmail account credentials. I have a Google Apps account set up for
ryanjhouston.com so I added a new user specifically for my server mail. That way
I did not have to put my own email account password on the server and any issues
can be isolated to this specific purpose account.

## Send mail via a Gmail account

To enable authentication:

1. Add the following line to `/etc/postfix/sasl_passwd` using the newly created
   account and password.

    ```
    [smtp.gmail.com]:587    username@gmail.com:password
    ```

2. Ensure the permissions are correct on the file:

    ```
    sudo chmod 600 /etc/postfix/sasl_passwd
    sudo chown postfix /etc/postfix/sasl_passwd
    ```

3. Ensure the following block is in `/etc/postfix/main.cf`:

    ```
    relayhost = [smtp.gmail.com]:587
    smtp_use_tls = yes
    smtp_sasl_auth_enable = yes
    smtp_sasl_security_options =
    smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
    smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
    ```

4. Update the postmap password database to use the new credentials

    ```
    sudo postmap /etc/postfix/sasl_passwd
    ```

5. Restart postfix `sudo service postfix restart`
6. You will have to [allow less secure apps][gmail-less-secure] for the gmail
   account.

You should then be able to send a test mail and receive it in gmail:
```
echo "This is the body of the email" | mail -s "This is the subject line" your_email_address
```

This mail will actually show up in the "Sent" mail folder for the authenticated
gmail account and be delivered to the recipient specified.

## Forwarding root mail

Add your email address to `/etc/aliases`. The file should look something like:

```
# See man 5 aliases for format
postmaster:    root
root: youremail@yourdomain.com
```

Run `sudo newaliases` to update the alias database with your new settings.

You'll now receive all mail that is normally delivered to the local root mailbox
in the inbox of your choice.

[digital-ocean]: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-16-04
[gmail-less-secure]: https://support.google.com/accounts/answer/6010255
