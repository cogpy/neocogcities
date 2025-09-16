# Neocities Technical Architecture Documentation

## Table of Contents
- [System Overview](#system-overview)
- [Application Architecture](#application-architecture)
- [Database Schema](#database-schema)
- [API Architecture](#api-architecture)
- [Security Architecture](#security-architecture)
- [Background Jobs & Workers](#background-jobs--workers)
- [Deployment & Infrastructure](#deployment--infrastructure)
- [Data Flow](#data-flow)
- [Key Components](#key-components)
- [Development Guidelines](#development-guidelines)

## System Overview

Neocities is a web hosting service built with Ruby using the Sinatra framework. It provides free static website hosting with a simple file upload interface, social features, and an API for programmatic access.

```mermaid
graph TB
    User[Users] --> LB[Load Balancer]
    LB --> App[Neocities Web App]
    App --> DB[(PostgreSQL Database)]
    App --> Redis[(Redis Cache)]
    App --> Files[File Storage]
    App --> Workers[Background Workers]
    Workers --> DB
    Workers --> Files
    Workers --> External[External Services]
    
    subgraph "External Services"
        Stripe[Stripe Payments]
        Twilio[Twilio SMS]
        LE[Let's Encrypt]
        Email[Email Services]
    end
    
    subgraph "Web App Components"
        Routes[Route Handlers]
        Models[Sequel Models]
        Views[ERB Templates]
        Static[Static Assets]
    end
    
    App --> Routes
    Routes --> Models
    Models --> Views
```

### Technology Stack
- **Backend**: Ruby with Sinatra framework
- **Database**: PostgreSQL with Sequel ORM
- **Caching**: Redis with Redis Namespace
- **Background Jobs**: Sidekiq
- **File Processing**: ImageMagick, ImageOptim
- **Authentication**: BCrypt for password hashing
- **Payments**: Stripe integration
- **SSL**: Let's Encrypt automation
- **CSS**: Sass preprocessing
- **Testing**: Minitest with Fabrication for fixtures

## Application Architecture

The application follows a modular Sinatra architecture with separate route handlers for different functional areas.

```mermaid
graph TB
    subgraph "Sinatra Application"
        Main[app.rb - Main Application]
        Helpers[app_helpers.rb - Helper Methods]
        Env[environment.rb - Environment Setup]
        
        subgraph "Route Handlers (/app)"
            Admin[admin.rb - Admin Interface]
            API[api.rb - API Endpoints]
            Browse[browse.rb - Site Discovery]
            Dashboard[dashboard.rb - User Dashboard]
            Settings[settings.rb - User Settings]
            SiteFiles[site_files.rb - File Management]
            Auth[signin.rb - Authentication]
            Create[create.rb - Account Creation]
            Domain[domain.rb - Custom Domains]
            Plan[plan.rb - Subscription Plans]
            Webhooks[webhooks.rb - Payment Webhooks]
        end
        
        subgraph "Models (/models)"
            Site[site.rb - Core Site Model]
            SiteFile[site_file.rb - File Model]
            User[User Data in Site Model]
            Tag[tag.rb - Site Tags]
            Comment[comment.rb - Comments]
            Stats[stat.rb - Analytics]
        end
        
        subgraph "Background Workers (/workers)"
            Email[email_worker.rb]
            Thumbnail[thumbnail_worker.rb]
            Screenshot[screenshot_worker.rb]
            LetsEncrypt[lets_encrypt_worker.rb]
            Cache[purge_cache_worker.rb]
        end
    end
    
    Main --> Helpers
    Main --> Env
    Env --> Models
    Main --> Routes
    Routes --> Models
    Models --> Workers
```

### Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant Rack
    participant App
    participant Auth
    participant Route
    participant Model
    participant DB
    participant View
    
    Client->>Rack: HTTP Request
    Rack->>App: Process Request
    App->>Auth: Check Authentication
    Auth->>App: Auth Status
    App->>Route: Route to Handler
    Route->>Model: Business Logic
    Model->>DB: Database Query
    DB->>Model: Data
    Model->>Route: Processed Data
    Route->>View: Render Template
    View->>Route: HTML Response
    Route->>App: Response
    App->>Rack: HTTP Response
    Rack->>Client: Response
```

## Database Schema

The database uses PostgreSQL with the Sequel ORM. Key entities and their relationships:

```mermaid
erDiagram
    sites {
        int id PK
        string username UK
        string email
        string password_hash
        boolean is_deleted
        boolean is_banned
        timestamp created_at
        timestamp updated_at
        string domain
        boolean profile_enabled
        text description
        int views
        float score
        boolean site_changed
        string plan_type
        timestamp plan_expires
    }
    
    site_files {
        int id PK
        int site_id FK
        string path
        int size
        string sha1_hash
        timestamp created_at
        timestamp updated_at
        boolean is_directory
        string mime_type
    }
    
    tags {
        int id PK
        string name UK
        timestamp created_at
    }
    
    sites_tags {
        int site_id FK
        int tag_id FK
    }
    
    comments {
        int id PK
        int site_id FK
        int commenter_site_id FK
        text message
        timestamp created_at
        boolean is_deleted
    }
    
    follows {
        int id PK
        int site_id FK
        int actioned_site_id FK
        timestamp created_at
    }
    
    stats {
        int id PK
        int site_id FK
        string ip_address
        string path
        string referrer
        string user_agent
        timestamp created_at
    }
    
    events {
        int id PK
        int site_id FK
        string event_type
        text data
        timestamp created_at
    }
    
    sites ||--o{ site_files : has
    sites ||--o{ sites_tags : tagged_with
    tags ||--o{ sites_tags : applies_to
    sites ||--o{ comments : receives
    sites ||--o{ comments : makes
    sites ||--o{ follows : followed_by
    sites ||--o{ follows : follows
    sites ||--o{ stats : generates
    sites ||--o{ events : triggers
```

### Key Database Features
- **Paranoid Deletion**: Soft deletes using `is_deleted` flags
- **Timestamping**: Automatic `created_at` and `updated_at` timestamps
- **Indexing**: Optimized indexes for common query patterns
- **Validation**: Model-level validation helpers
- **Migrations**: Sequel migrations for schema changes

## API Architecture

The Neocities API provides programmatic access to site management functions.

```mermaid
graph TB
    subgraph "API Endpoints"
        Auth[Authentication]
        Info[/info - Site Information]
        List[/list - File Listing]
        Upload[/upload - File Upload]
        Delete[/delete - File Deletion]
        WebDAV[WebDAV Interface]
    end
    
    subgraph "Authentication Methods"
        Basic[HTTP Basic Auth]
        Token[API Token]
    end
    
    subgraph "Response Formats"
        JSON[JSON Responses]
        XML[XML for WebDAV]
    end
    
    Client --> Auth
    Auth --> Basic
    Auth --> Token
    
    Auth --> Info
    Auth --> List
    Auth --> Upload
    Auth --> Delete
    Auth --> WebDAV
    
    Info --> JSON
    List --> JSON
    Upload --> JSON
    Delete --> JSON
    WebDAV --> XML
```

### API Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Auth
    participant Model
    participant Storage
    
    Client->>API: API Request with Credentials
    API->>Auth: Validate Credentials
    Auth-->>API: Authentication Result
    
    alt Authentication Successful
        API->>Model: Execute Business Logic
        Model->>Storage: File Operations
        Storage-->>Model: Operation Result
        Model-->>API: Response Data
        API-->>Client: JSON Response
    else Authentication Failed
        API-->>Client: 401 Unauthorized
    end
```

## Security Architecture

Neocities implements multiple layers of security controls:

```mermaid
graph TB
    subgraph "Input Security"
        CSRF[CSRF Protection]
        Validation[Input Validation]
        Sanitization[HTML Sanitization]
        FileType[File Type Validation]
    end
    
    subgraph "Authentication & Authorization"
        BCrypt[BCrypt Password Hashing]
        Sessions[Secure Sessions]
        2FA[Phone Verification]
        EmailConfirm[Email Confirmation]
    end
    
    subgraph "Transport Security"
        HTTPS[HTTPS/TLS]
        HSTS[HTTP Strict Transport Security]
        CSP[Content Security Policy]
        LetsEncrypt[Let's Encrypt SSL]
    end
    
    subgraph "Application Security"
        Permissions[File Permissions]
        Quotas[Storage Quotas]
        RateLimit[Rate Limiting]
        Monitoring[Security Monitoring]
    end
    
    subgraph "Infrastructure Security"
        Firewall[Network Firewall]
        Updates[Security Updates]
        Backups[Encrypted Backups]
        Logging[Security Logging]
    end
    
    Request --> CSRF
    CSRF --> Validation
    Validation --> Sanitization
    Sanitization --> FileType
    
    User --> BCrypt
    BCrypt --> Sessions
    Sessions --> 2FA
    2FA --> EmailConfirm
    
    Client --> HTTPS
    HTTPS --> HSTS
    HSTS --> CSP
    CSP --> LetsEncrypt
```

### Security Features
- **CSRF Protection**: All forms include CSRF tokens
- **Password Security**: BCrypt hashing with salt
- **File Upload Security**: MIME type validation and file size limits
- **Content Security Policy**: Strict CSP headers to prevent XSS
- **SQL Injection Prevention**: Parameterized queries via Sequel ORM
- **Session Security**: HTTPOnly, Secure, and SameSite cookie flags

## Background Jobs & Workers

Asynchronous processing is handled by Sidekiq workers:

```mermaid
graph TB
    subgraph "Sidekiq Workers"
        EmailWorker[EmailWorker - Email Notifications]
        ThumbnailWorker[ThumbnailWorker - Image Thumbnails]
        ScreenshotWorker[ScreenshotWorker - Site Screenshots]
        LetsEncryptWorker[LetsEncryptWorker - SSL Certificates]
        CacheWorker[PurgeCacheWorker - Cache Management]
        BanWorker[BanWorker - User Moderation]
        SpamWorker[StopForumSpamWorker - Spam Detection]
        BlackBoxWorker[BlackBoxWorker - Analytics]
    end
    
    subgraph "Job Triggers"
        FileUpload[File Upload] --> ThumbnailWorker
        FileUpload --> ScreenshotWorker
        
        UserAction[User Actions] --> EmailWorker
        
        DomainAdd[Custom Domain] --> LetsEncryptWorker
        CertRenewal[Certificate Renewal] --> LetsEncryptWorker
        
        ContentChange[Content Changes] --> CacheWorker
        
        AdminAction[Admin Actions] --> BanWorker
        
        Registration[User Registration] --> SpamWorker
        
        Analytics[Analytics Events] --> BlackBoxWorker
    end
    
    subgraph "External Dependencies"
        SMTP[SMTP Server]
        ImageMagick[ImageMagick]
        PhantomJS[Screenshot Service]
        ACME[ACME/Let's Encrypt]
        CDN[CDN/Cache]
        SpamAPI[Spam Detection APIs]
    end
    
    EmailWorker --> SMTP
    ThumbnailWorker --> ImageMagick
    ScreenshotWorker --> PhantomJS
    LetsEncryptWorker --> ACME
    CacheWorker --> CDN
    SpamWorker --> SpamAPI
```

### Worker Processing Flow

```mermaid
sequenceDiagram
    participant App
    participant Redis
    participant Sidekiq
    participant Worker
    participant External
    
    App->>Redis: Enqueue Job
    Redis-->>App: Job Queued
    
    Sidekiq->>Redis: Poll for Jobs
    Redis-->>Sidekiq: Job Data
    
    Sidekiq->>Worker: Execute Job
    Worker->>External: External Service Call
    External-->>Worker: Service Response
    Worker-->>Sidekiq: Job Result
    
    alt Job Successful
        Sidekiq->>Redis: Mark Complete
    else Job Failed
        Sidekiq->>Redis: Schedule Retry
    end
```

## Deployment & Infrastructure

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[nginx/HAProxy]
    end
    
    subgraph "Application Servers"
        App1[App Server 1]
        App2[App Server 2]
        App3[App Server N]
    end
    
    subgraph "Background Processing"
        Sidekiq1[Sidekiq Worker 1]
        Sidekiq2[Sidekiq Worker 2]
        SidekiqN[Sidekiq Worker N]
    end
    
    subgraph "Data Layer"
        DB[(PostgreSQL Primary)]
        DBReplica[(PostgreSQL Replica)]
        Redis[(Redis)]
        Files[File Storage]
    end
    
    subgraph "External Services"
        CDN[CDN/CloudFlare]
        Monitoring[Error Tracking]
        Payments[Stripe]
        Email[Email Service]
    end
    
    Internet --> CDN
    CDN --> LB
    LB --> App1
    LB --> App2
    LB --> App3
    
    App1 --> DB
    App2 --> DB
    App3 --> DB
    
    App1 --> Redis
    App2 --> Redis
    App3 --> Redis
    
    Sidekiq1 --> DB
    Sidekiq2 --> DB
    SidekiqN --> DB
    
    Sidekiq1 --> Redis
    Sidekiq2 --> Redis
    SidekiqN --> Redis
    
    App1 --> Files
    App2 --> Files
    App3 --> Files
    
    Sidekiq1 --> Files
    Sidekiq2 --> Files
    SidekiqN --> Files
    
    App1 --> Monitoring
    App2 --> Monitoring
    App3 --> Monitoring
    
    App1 --> Payments
    App2 --> Payments
    App3 --> Payments
    
    Sidekiq1 --> Email
    Sidekiq2 --> Email
    SidekiqN --> Email
```

## Data Flow

### File Upload Flow

```mermaid
sequenceDiagram
    participant User
    participant WebApp
    participant FileSystem
    participant DB
    participant Workers
    participant Cache
    
    User->>WebApp: Upload File
    WebApp->>WebApp: Validate File
    WebApp->>FileSystem: Store File
    WebApp->>DB: Create SiteFile Record
    WebApp->>Workers: Queue Thumbnail Job
    WebApp->>Workers: Queue Screenshot Job
    WebApp->>Cache: Invalidate Cache
    WebApp-->>User: Upload Success
    
    Workers->>FileSystem: Generate Thumbnail
    Workers->>FileSystem: Generate Screenshot
    Workers->>DB: Update File Metadata
```

### User Registration Flow

```mermaid
sequenceDiagram
    participant User
    participant WebApp
    participant DB
    participant Email
    participant AntiSpam
    
    User->>WebApp: Submit Registration
    WebApp->>AntiSpam: Check for Spam
    AntiSpam-->>WebApp: Spam Check Result
    
    alt Not Spam
        WebApp->>DB: Create Site Record
        WebApp->>Email: Send Confirmation
        WebApp-->>User: Registration Success
        User->>WebApp: Click Email Link
        WebApp->>DB: Activate Account
        WebApp-->>User: Account Activated
    else Spam Detected
        WebApp-->>User: Registration Rejected
    end
```

## Key Components

### Site Model
The central model representing a user's website:
- **File Management**: Handles file uploads, validation, and storage
- **Authentication**: User login and password management
- **Billing**: Integration with Stripe for premium plans
- **Statistics**: Page view tracking and analytics
- **Social Features**: Following, comments, and discovery

### File Upload System
- **Validation**: File type, size, and content validation
- **Storage**: Organized file system storage with user directories
- **Processing**: Automatic thumbnail and screenshot generation
- **Versioning**: File change tracking and history

### API System
- **REST API**: Standard HTTP methods for CRUD operations
- **WebDAV**: Standard protocol for file management
- **Authentication**: HTTP Basic Auth and API tokens
- **Rate Limiting**: Prevents abuse and ensures fair usage

### Background Processing
- **Email Delivery**: Asynchronous email sending
- **Image Processing**: Thumbnail and screenshot generation
- **SSL Management**: Automated certificate provisioning and renewal
- **Cache Management**: Intelligent cache invalidation

## Development Guidelines

### Getting Started
1. **Environment Setup**: Use Vagrant for consistent development environment
2. **Configuration**: Copy `config.yml.template` to `config.yml`
3. **Dependencies**: Run `bundle install` to install Ruby gems
4. **Database**: Migrations run automatically on startup
5. **Testing**: Use `rake test` to run the test suite

### Code Organization
- **Models**: Business logic and data access in `/models`
- **Routes**: HTTP request handling in `/app`
- **Views**: ERB templates in `/views`
- **Workers**: Background jobs in `/workers`
- **Tests**: Comprehensive test coverage in `/tests`

### Development Workflow
1. **Feature Branches**: Create feature branches for new work
2. **Testing**: Write tests for new functionality
3. **Code Review**: Submit pull requests for review
4. **Documentation**: Update documentation for new features
5. **Deployment**: Use CI/CD pipeline for automated deployment

### Performance Considerations
- **Database Queries**: Use eager loading to avoid N+1 queries
- **Caching**: Implement appropriate caching strategies
- **File Storage**: Optimize file storage and delivery
- **Background Jobs**: Use workers for expensive operations
- **Monitoring**: Track performance metrics and errors

### Security Best Practices
- **Input Validation**: Validate all user inputs
- **SQL Injection**: Use parameterized queries
- **XSS Prevention**: Escape output and use CSP headers
- **CSRF Protection**: Include CSRF tokens in forms
- **File Upload Security**: Validate file types and sizes
- **Authentication**: Use secure session management