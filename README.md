### NOTE: THIS IS NOT FOR NEOCITIES SUPPORT! Any issues filed not related to the source code itself will be closed. For support please contact: https://neocities.org/contact

# Neocities.org

[![Build Status](https://github.com/neocities/neocities/actions/workflows/ci.yml/badge.svg)](https://github.com/neocities/neocities/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/neocities/neocities/badge.svg?branch=master&service=github)](https://coveralls.io/github/neocities/neocities?branch=master)

The web site for Neocities! It's open source. Want a feature on the site? Send a pull request!

## Getting Started

Neocities can be quickly launched in development mode with [Vagrant](https://www.vagrantup.com). Vagrant builds a virtual machine that automatically installs everything you need to run Neocities as a developer. Install Vagrant, then from the command line:

```
vagrant up --provision
```

![Vagrant takes a while, make a pizza while waiting](https://i.imgur.com/dKa8LUs.png)

Make a copy of `config.yml.template` in the root directory, and rename it to `config.yml`. Then:

```
vagrant ssh
bundle exec rackup -o 0.0.0.0
```

Now you can access the running site from your browser: http://127.0.0.1:9292

## Documentation

For comprehensive technical documentation, see the [docs](./docs) directory:

- **[Technical Architecture](./docs/ARCHITECTURE.md)** - Complete system architecture with Mermaid diagrams
- **[API Documentation](./docs/API.md)** - REST API and WebDAV interface documentation
- **[Database Schema](./docs/DATABASE.md)** - Database design and relationships
- **[Security Architecture](./docs/SECURITY.md)** - Security controls and best practices
- **[Deployment Guide](./docs/DEPLOYMENT.md)** - Infrastructure and deployment procedures

## Want to contribute?

If you'd like to fix a bug, or make an improvement, or add a new feature, it's easy! Just send us a Pull Request.

1. Fork it (https://github.com/neocities/neocities/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Please read the [Technical Architecture documentation](./docs/ARCHITECTURE.md) to understand the codebase structure and development guidelines before contributing.
