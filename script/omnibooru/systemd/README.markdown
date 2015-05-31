The Capistrano tasks assume that the systemd services for Unicorn and
delayed_job have been set up so that the Danbooru user can manage them.
This can be done by placing the service files in the per-user directory
`~/.config/systemd/user/` and configuring systemd to automatically start
the user instance at boot with the command:

    # loginctl enable-linger danbooru
