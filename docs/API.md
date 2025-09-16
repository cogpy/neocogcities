# API Documentation

## Overview

The Neocities API provides programmatic access to manage your website files and retrieve site information. The API supports both REST endpoints and WebDAV for file operations.

## Authentication

### HTTP Basic Authentication
Use your Neocities username and password:
```bash
curl -u username:password https://neocities.org/api/info
```

### API Key Authentication
Use your API key (available in your site settings):
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" https://neocities.org/api/info
```

## API Endpoints

### GET /api/info
Retrieve information about your site.

**Response:**
```json
{
  "result": "success",
  "info": {
    "sitename": "yourusername",
    "views": 1337,
    "hits": 1337,
    "created_at": "Sat, 29 Jun 2013 10:11:38 +0000",
    "last_updated": "Tue, 23 Jul 2013 20:04:03 +0000",
    "domain": "example.com",
    "tags": ["art", "music"]
  }
}
```

### GET /api/list
List files for your site with optional path parameter.

**Parameters:**
- `path` (optional): Directory path to list

**Response:**
```json
{
  "result": "success",
  "files": [
    {
      "path": "index.html",
      "is_directory": false,
      "size": 1024,
      "updated_at": "Tue, 23 Jul 2013 20:04:03 +0000",
      "sha1_hash": "da39a3ee5e6b4b0d3255bfef95601890afd80709"
    }
  ]
}
```

### POST /api/upload
Upload files to your site.

**Parameters:**
- Files as multipart form data
- Optional `folder` parameter to specify destination directory

**Example:**
```bash
curl -F "index.html=@index.html" \
     -F "folder=/subdirectory" \
     -u username:password \
     https://neocities.org/api/upload
```

### POST /api/delete
Delete files from your site.

**Parameters:**
- `filenames[]`: Array of filenames to delete

**Example:**
```bash
curl -d "filenames[]=oldfile.html" \
     -d "filenames[]=unused.css" \
     -u username:password \
     https://neocities.org/api/delete
```

## WebDAV Interface

Neocities supports WebDAV for file management using standard WebDAV clients.

**Endpoint:** `https://neocities.org/webdav/`

### Supported Operations
- **PROPFIND**: List directory contents
- **GET**: Download files
- **PUT**: Upload files
- **DELETE**: Delete files
- **MKCOL**: Create directories
- **MOVE**: Rename/move files

### Example Usage
```bash
# Mount WebDAV (Linux/macOS)
curl -u username:password -X PROPFIND https://neocities.org/webdav/

# Upload file via WebDAV
curl -u username:password -T local_file.html https://neocities.org/webdav/remote_file.html
```

## Rate Limiting

API requests are rate limited to prevent abuse:
- **File Operations**: 10 requests per minute
- **Info/List**: 60 requests per minute

## Error Responses

All API endpoints return JSON with error information:

```json
{
  "result": "error",
  "error_type": "file_not_found",
  "message": "The requested file was not found"
}
```

### Common Error Types
- `authentication_failed`: Invalid credentials
- `file_not_found`: File doesn't exist
- `file_size_too_large`: File exceeds size limit
- `invalid_file_type`: File type not allowed
- `quota_exceeded`: Storage quota exceeded
- `rate_limit_exceeded`: Too many requests

## File Upload Restrictions

### Allowed File Types
- HTML, CSS, JavaScript
- Images: PNG, JPEG, GIF, SVG, WebP, AVIF
- Fonts: TTF, OTF, WOFF, WOFF2
- Documents: PDF, TXT, CSV, XML, JSON
- Audio: MIDI
- 3D Models: glTF

### File Size Limits
- **Free accounts**: 10MB per file, 1GB total storage
- **Supporter accounts**: 50MB per file, 50GB total storage

### Naming Restrictions
- Files must have valid extensions
- No executable file types allowed
- Special characters in filenames may be restricted

## Code Examples

### Node.js Example
```javascript
const fs = require('fs');
const FormData = require('form-data');
const fetch = require('node-fetch');

async function uploadFile(filename, content) {
  const form = new FormData();
  form.append(filename, content, filename);
  
  const response = await fetch('https://neocities.org/api/upload', {
    method: 'POST',
    body: form,
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY'
    }
  });
  
  return response.json();
}
```

### Python Example
```python
import requests

def get_site_info(api_key):
    headers = {'Authorization': f'Bearer {api_key}'}
    response = requests.get('https://neocities.org/api/info', headers=headers)
    return response.json()

def upload_file(api_key, filename, file_content):
    headers = {'Authorization': f'Bearer {api_key}'}
    files = {filename: file_content}
    response = requests.post('https://neocities.org/api/upload', 
                           headers=headers, files=files)
    return response.json()
```

### Ruby Example
```ruby
require 'net/http'
require 'uri'
require 'json'

class NeocitiesAPI
  def initialize(api_key)
    @api_key = api_key
  end
  
  def site_info
    uri = URI('https://neocities.org/api/info')
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
end
```

## Best Practices

### Error Handling
Always check the `result` field in API responses:
```javascript
const response = await api_call();
if (response.result === 'error') {
  console.error(`API Error: ${response.error_type} - ${response.message}`);
  return;
}
```

### File Management
- Use `/api/list` to check existing files before uploading
- Implement retry logic for network failures
- Validate file types and sizes before uploading
- Use WebDAV for bulk file operations

### Security
- Keep API keys secure and never commit them to version control
- Use environment variables for API keys in production
- Implement proper error handling to avoid exposing sensitive information
- Regularly rotate API keys

### Performance
- Batch file uploads when possible
- Implement client-side file compression for large files
- Cache API responses when appropriate
- Use WebDAV for file synchronization workflows