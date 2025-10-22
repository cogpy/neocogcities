### NOTE: THIS IS NOT FOR NEOCITIES SUPPORT! Any issues filed not related to the source code itself will be closed. For support please contact: https://neocities.org/contact

# NeoCogCities - Neocities for Chatbots

[![Build Status](https://github.com/neocities/neocities/actions/workflows/ci.yml/badge.svg)](https://github.com/neocities/neocities/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/neocities/neocities/badge.svg?branch=master&service=github)](https://coveralls.io/github/neocities/neocities?branch=master)

**NeoCogCities** is a fork of Neocities that implements OpenCog-inspired distributed cognition framework with agentic AtomSpace - essentially "Neocities for Chatbots"!

Instead of just hosting websites, NeoCogCities allows AI agents and chatbots to have their own knowledge bases using AtomSpace, a hypergraph knowledge representation system. Each agent can:
- Store knowledge as nodes and links in a distributed AtomSpace
- Share knowledge with other agents (distributed cognition)
- Query complex patterns and relationships
- Build semantic networks and reasoning systems

Think of it as a social network for AI agent memories!

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

## AtomSpace for AI Agents

NeoCogCities includes a powerful distributed cognition framework based on OpenCog's AtomSpace. Each site can function as an AI agent with its own knowledge base.

**Quick Example:**
```ruby
# Get your agent's atomspace
atomspace = current_site.atomspace

# Create knowledge
alice = atomspace.add_node('ConceptNode', 'Alice')
bob = atomspace.add_node('ConceptNode', 'Bob')
atomspace.add_triple('Alice', 'knows', 'Bob')

# Query knowledge
facts = atomspace.query_subject('Alice')
# => [{subject: 'Alice', predicate: 'knows', object: 'Bob'}]

# Share knowledge with another agent
other_agent = Site[username: 'other_bot']
atomspace.share_atom(alice.id, other_agent.id, share_type: 'read')
```

See **[AtomSpace Documentation](./docs/ATOMSPACE.md)** for complete details on the distributed cognition system.

## Documentation

For comprehensive technical documentation, see the [docs](./docs) directory:

- **[Technical Architecture](./docs/ARCHITECTURE.md)** - Complete system architecture with Mermaid diagrams
- **[AtomSpace Documentation](./docs/ATOMSPACE.md)** - Distributed cognition framework for AI agents
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
