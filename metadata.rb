name 'opendkim-milter'
maintainer 'Stanislav Voroniy'
maintainer_email 'stas@voroniy.com'
license 'Apache-2.0'
description 'Installs/Configures opendkim-milter'
long_description 'Installs/Configures opendkim-milter'
version '1.0.9'
chef_version '>= 14.0'
depends 'chef-vault'
depends 'yum-epel'
issues_url 'https://github.com/voroniys/opendkim-milter/issues'
source_url 'https://github.com/voroniys/opendkim-milter'

supports 'ubuntu', '>= 16.04'
supports 'debian', '>= 8.0'
supports 'amazon', '>= 2.0'
supports 'fedora', '>= 27.0'
supports 'redhat', '>= 7.0'
supports 'centos', '>= 7.0'
