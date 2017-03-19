[![Build Status](https://travis-ci.org/jolynch/synapse-nginx.png?branch=master)](https://travis-ci.org/jolynch/synapse-nginx)

# synapse-nginx
A config_generator for the Synapse framework that supports NGINX.

## Installation ##
To install this plugin for Synapse, gem install it after [`synapse`](https://github.com/airbnb/synapse/)
in your packaging setup.

```bash
$ gem install synapse --install-dir /opt/smartstack/synapse --no-ri --no-rdoc
$ gem install synapse-nginx --install-dir /opt/smartstack/synapse --no-ri --no-rdoc
```

## Configuration ##
The NGINX plugin slots right into the standard [`synapse`](https://github.com/airbnb/synapse/)
configuration file.

### Top level config ###
The NGINX plugin requires a section to be added to the top level of your
Synapse [config](https://github.com/airbnb/synapse#configuration). For example:

```yaml
haproxy:
  # old config for haproxy
nginx:
  contexts:
    main: [
      'worker_processes 1',
      'pid /tmp/nginx.pid'
    ]
    events: [
      'worker_connections 1024'
    ]
  do_writes: false
  do_reloads: false
```

The top level `nginx` section of the config file. If provided, it must have
a `contexts` top level key which contains a hash with the following two
contexts defined:

* `main`: A list of configuration lines to add to the top level of the nginx
configuration. Typically this contains things like pid files or worker process countes.
* `events`: A list of configuration lines to add to the events section of the
nginx configuration. Typically this contians things like worker_connection counts.

The following options may be provided to control how nginx writes config:
* `do_writes`: whether or not the config file will be written (default to `true`)
* `config_file_path`: where Synapse will write the nginx config file. Required if `do_writes` is set.
* `check_command`: the command Synapse will run to ensure the generated NGINX config is valid before reloading.
Required if `do_writes` is set.

You can control reloading with:
* `do_reloads`: whether or not Synapse will reload nginx automatically (default to `true`)
* `reload_command`: the command Synapse will run to reload NGINX. Required if `do_reloads` is set.
* `start_command`: the command Synapse will run to start NGINX the first time. Required if `do_reloads` is set.
* `restart_interval`: number of seconds to wait between restarts of NGINX (default: 2)
* `restart_jitter`: percentage, expressed as a float, of jitter to multiply the `restart_interval` by when determining the next
  restart time. Use this to help prevent storms when HAProxy restarts. (default: 0.0)

You can also provide:
* `listen_address`: force NGINX to listen on this address (default: localhost)

Note that a non-default `listen_address` can be dangerous.
If you configure an `address:port` combination that is already in use on the system, nginx will fail to start.

### Service watcher config ###
Each service watcher may supply custom configuration that tells Synapse how to
configure nginx for just that service.

This section is its own hash, which can contain the following keys:

* `disabled`: A boolean value indicating if nginx configuration management
for just this service instance ought be disabled. For example, if you want
haproxy output for a particular service but not nginx config. (default: `false`)
* `mode`: The type of proxy, either `http` or `tcp`. This impacts whether
nginx generates a stream or an http backend for this service. (default: `http`)
* `upstream`: A list of configuration lines to add to the `upstream` section of
nginx. (default: [])
* `server`: A list of configuration lines to add to the `server` section of
nginx. (default: [])
* `listen_address`: force nginx to listen on this address (default is localhost).
Setting `listen_address` on a per service basis overrides the global `listen_address`
in the top level `nginx` config hash.
* `listen_options`: additional listen options provided as a string,
such as `reuseport`, to append to the listen line. (default is empty string)
* `upstream_order`: how servers should be ordered in the `upstream` stanza. Setting to `asc` means sorting backends in ascending alphabetical order before generating stanza. `desc` means descending alphabetical order. `no_shuffle` means no shuffling or sorting. (default: `shuffle`, which results in random ordering of upstream servers)
* `upstream_name`: The name of the generated nginx backend for this service
  (defaults to the service's key in the `services` section)

