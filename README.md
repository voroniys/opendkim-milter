# opendkim-milter Cookbook

[![Build Status](https://travis-ci.org/voroniys/opendkim-milter.svg?branch=master)](https://travis-ci.org/voroniys/opendkim-milter)
[![Cookbook Version](https://img.shields.io/cookbook/v/opendkim-milter.svg)](https://supermarket.chef.io/cookbooks/opendkim-milter)

This cookbook allow to install and configure opendkim milter in many RedHat and Debian alike linux distributions.
Unlike many other implementations this one allows full flexibility in configuration and even provide a possibility to run
multiple instances of Opendkim - for instance signer and verifier as separate instances.

## Attributes
- `node['opendkim-milter']['package']` - name of the package to be installed. Defaults to `opendkim` and normaly doesn't need to be changed
- `node['opendkim-milter']['services']` - hash with configuration for milters. Key of the hash is the name of the service, the hash with
parameters described bellow

### Services configuration
Each hash with parameters can contain the following fields:
- `service_name` - string with the name for systemd service if it is needed to be different from the key pointing to this configuration
- `config` - hash in format `key: value` with all necessary configuration directives for Opendkim. This configuration will be saved
to file /etc/opendkim/`service_name`.conf
- `base_path` - optional, defaults to `/etc/opendkim`. Gives a possibility to choose another location for configuration files.
- `user_targets` - array, optional, allows to specify additional systemd targets that needs to be started before opendkim service. 
Useful if database is used in configuration for instance. See examples bellow.
- `user_options` - array, optional, provides list of additional options for the opendkim. See examples bellow.
- `owner` - string, optional, defaults to `opendkim`. Allows to run opendkim service as another user.
- `group` - string, optional, defaults to `opendkim`. Allows to run opendkim service with different group, for instance `postfix`
- `databag_files` - optional, hash with keys and other additional files that needs to be fetched from (encrypted) databag or chef-vault.
Key of the hash is the path name of the file relative to `base_path`. The value is also hash with 2 essentional and 1 optional fields:
  - `databag` - name of the databag or vault
  - `item` - name of the item in databag or vault
  - `mode` - optional, defaults to `0640`, access mode for the file
- `config_files` - optional, hash with keys and other additional files which provided directly via attributes.
Key of the hash is the path name of the file relative to `base_path`. The value can be string, array or hash of `key: value` pairs.
String is directly placed to the file, array represents multiline file with each element is a separate file line, each hash pair
will be placed to separate file line, key/value separator is space.

#### Examples

```json
{
  "opendkim-milter": {
    "services": {
      "verifier": {
        "config": {
          "PidFile":          "/var/run/opendkim/verifier.pid",
          "Mode":             "v",
          "Syslog":           "yes",
          "SyslogSuccess":    "yes",
          "LogWhy":           "yes",
          "UserID":           "opendkim:postfix",
          "Socket":           "local:/var/run/opendkim/verifier.sock",
          "Umask":            "007",
          "OversignHeaders":  "From",
        },
        "group": "postfix",
        "user_targets": ["mysql.target"]
      },
      "signer": {
        "config": {
          "PidFile":          "/var/run/opendkim/signer.pid",
          "Mode":             "s",
          "Syslog":           "yes",
          "SyslogSuccess":    "yes",
          "LogWhy":           "yes",
          "UserID":           "opendkim:opendkim",
          "Socket":           "local:/var/run/opendkim/signer.sock",
          "Umask":            "007",
          "OversignHeaders":  "From",
          "Canonicalization": "relaxed/simple",
          "InternalHosts":    "refile:/etc/opendkim/TrustedHosts",
          "KeyTable":         "refile:/etc/opendkim/KeyTable",
          "SigningTable":     "refile:/etc/opendkim/SigningTable",
          "SignatureAlgorithm": "rsa-sha256",
        },
        "config_files": {
          "TrustedHosts": ["127.0.0.1", "::1"],
          "KeyTable": {
            "default._domainkey.example.com": "example.com:default:/etc/opendkim/keys/example.private",
            "default._domainkey.test.com": "test.com:default:/etc/opendkim/keys/test.private"
          },
          "SigningTable": {
            "*@example.com": "default._domainkey.example.com",
            "*@test.com": "default._domainkey.test.com"
          }
        },
        "databag_files": {
          "keys/example.private": {
            "databag": "dkimkeys",
            "item": "example",
            "mode": "0600"
          },
          "keys/test.private": {
            "databag": "dkimkeys",
            "item": "test"
          }
        }
      }
    }
  }
}
```

Note: the examples above are for demonstration of cookbook usage and do not pretend to be correct opendkim configuration.

## Recipes
There are only 2 recipes 
- `default` - the main one, which install the services accordingly to provided configuration
- `install` - called by default if no `opendkim` package is installed. Note that on RHEL and its derivates (CentOS, Amazonlinux) it also installs EPEL repo using `yum-epel` cookbook.


## Resources
If desirable it is possible to set `node['opendkim-milter']['services']` to empty hash and use only provided LWPR.
The resource name is `opendkim_milter` and meaning of all its properties described above. Here is small example:

```ruby
opendkim_milter 'my_own_milter' do
  service_name  'verifier'
  base_path     '/opt/dkim'
  config        my_config_hash
  user_targets  ['mysql.target']
  owner         'postfix'
  group         'postfix'
  databag_files my_dkim_keys
  config_files  my_dkim_files
end
```

## License & Authors

- Author:: Stanislav Voroniy ([stas@voroniy.com](mailto:stas@voroniy.com))

```text
Copyright 2018-2019, Stanislav Voroniy

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
