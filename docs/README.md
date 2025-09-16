# Neocities Documentation

Welcome to the comprehensive technical documentation for Neocities. This documentation provides detailed information about the system architecture, APIs, security, deployment, and development practices.

## 📋 Documentation Index

### Core Documentation
- **[Technical Architecture](./ARCHITECTURE.md)** - System overview, application architecture, and component relationships with detailed Mermaid diagrams
- **[API Documentation](./API.md)** - REST API endpoints, WebDAV interface, authentication, and code examples
- **[Database Schema](./DATABASE.md)** - Database design, table relationships, and migration strategies
- **[Security Architecture](./SECURITY.md)** - Security controls, authentication, authorization, and best practices
- **[Deployment Guide](./DEPLOYMENT.md)** - Infrastructure setup, deployment procedures, and scaling strategies

## 🎯 Quick Start

### For Developers
1. Read the [Technical Architecture](./ARCHITECTURE.md) to understand the system design
2. Follow the development setup in the main [README.md](../README.md)
3. Review the [Security Architecture](./SECURITY.md) for security best practices
4. Explore the [API Documentation](./API.md) for programmatic access

### For System Administrators
1. Review the [Deployment Guide](./DEPLOYMENT.md) for infrastructure requirements
2. Study the [Database Schema](./DATABASE.md) for data management
3. Implement security measures from [Security Architecture](./SECURITY.md)
4. Set up monitoring as described in the deployment guide

### For API Users
1. Start with the [API Documentation](./API.md)
2. Review authentication methods and rate limiting
3. Explore code examples in your preferred language
4. Test with the provided endpoints and examples

## 🏗️ System Overview

Neocities is a web hosting platform built with:
- **Backend**: Ruby with Sinatra framework
- **Database**: PostgreSQL with Sequel ORM
- **Caching**: Redis for sessions and background jobs
- **Background Processing**: Sidekiq workers
- **File Storage**: Local filesystem or cloud storage
- **Security**: Multi-layer security with CSRF, CSP, and encryption

## 📊 Architecture Diagrams

The documentation includes comprehensive Mermaid diagrams showing:
- System overview and component relationships
- Application architecture and request flow
- Database entity relationships
- API architecture and authentication flow
- Security architecture and protection layers
- Background job processing flow
- Deployment and infrastructure architecture
- Data flow diagrams for key operations

## 🔒 Security Features

Comprehensive security implementation including:
- **Authentication**: BCrypt password hashing, session management
- **Authorization**: Role-based access control
- **Input Validation**: File type validation, content sanitization
- **CSRF Protection**: Token-based CSRF prevention
- **XSS Prevention**: Content Security Policy, output encoding
- **Rate Limiting**: API and upload rate limiting
- **Monitoring**: Security event logging and anomaly detection

## 🚀 API Capabilities

Full-featured API supporting:
- **REST Endpoints**: Site information, file listing, upload, delete
- **WebDAV Interface**: Standard WebDAV protocol for file management
- **Authentication**: HTTP Basic Auth and API token authentication
- **File Operations**: Upload, download, delete, rename operations
- **Metadata Access**: Site statistics, file information, user data

## 📈 Scalability

Designed for scale with:
- **Horizontal Scaling**: Multiple application servers with load balancing
- **Database Scaling**: Read replicas and connection pooling
- **Caching Strategy**: Redis caching and CDN integration
- **Background Processing**: Scalable Sidekiq worker processes
- **File Storage**: Distributed storage options

## 🛠️ Development

Development best practices:
- **Code Organization**: Modular Sinatra architecture
- **Testing**: Comprehensive test suite with Minitest
- **Security**: Security-first development practices
- **Performance**: Database optimization and caching
- **Documentation**: Inline documentation and architectural decisions

## 📝 Contributing

When contributing to Neocities:
1. Review the technical architecture to understand the system
2. Follow security best practices outlined in the security documentation
3. Write tests for new functionality
4. Update documentation for significant changes
5. Follow the existing code style and patterns

## 🆘 Support

For technical questions:
- Review the relevant documentation section
- Check the issue tracker for known issues
- Follow the contribution guidelines for submitting issues

For general support:
- Visit https://neocities.org/contact for user support
- This repository is for technical and development issues only

## 📚 Additional Resources

- [Main Repository](https://github.com/neocities/neocities)
- [Neocities Website](https://neocities.org)
- [API Documentation Online](https://neocities.org/api)

---

**Note**: This documentation reflects the current architecture and may be updated as the system evolves. Always refer to the latest version for accurate information.