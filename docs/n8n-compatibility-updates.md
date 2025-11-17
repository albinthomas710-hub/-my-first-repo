# 🔄 n8n Latest Version Compatibility Updates

**Last Updated**: November 2025
**Compatible with**: n8n v1.103.0+

This document covers important updates to ensure the workflows work with the latest n8n version and best practices.

---

## ⚠️ **CRITICAL: Airtable Credentials Update (Feb 2024)**

**IMPORTANT**: Airtable deprecated API keys in February 2024. You MUST use Personal Access Tokens instead.

### Old Method (NO LONGER WORKS):
```
❌ Airtable API Key
```

### New Method (REQUIRED):
```
✅ Airtable Personal Access Token
```

### How to Set Up Airtable Personal Access Token:

1. **Create Token**:
   - Go to: https://airtable.com/create/tokens
   - Click "+ Create new token"
   - Name it: "n8n Insurance Automation"

2. **Add Required Scopes**:
   ```
   ✅ data.records:read     (Read records)
   ✅ data.records:write    (Write/update records)
   ✅ schema.bases:read     (Access table schema)
   ```

3. **Add Bases**:
   - Click "Add base" under Access
   - Select your "Insurance Automation" base
   - Click "Create token"

4. **Copy Token**:
   - Copy the token (shown only once!)
   - In n8n: Credentials → Create New → Airtable Personal Access Token
   - Paste token → Save

5. **Update All Workflows**:
   - Open each workflow
   - Find Airtable nodes
   - Change credential to your new Personal Access Token
   - Save workflow

---

## 🔐 **Gmail OAuth2 Setup (Recommended for Production)**

For production use, OAuth2 is more secure and reliable than App Passwords.

### Setup Steps:

1. **Create Google Cloud Project**:
   - Go to: https://console.cloud.google.com
   - Create project: "n8n-Insurance-Automation"

2. **Enable Gmail API**:
   - Search for "Gmail API"
   - Click "Enable"

3. **Configure OAuth Consent Screen**:
   - Select "External"
   - App name: "Insurance Automation"
   - Add your email as test user
   - Save

4. **Create OAuth Credentials**:
   - Go to "Credentials" → "Create Credentials" → "OAuth Client ID"
   - Application type: "Web application"
   - **Authorized redirect URIs**: Copy from n8n credential screen
   - Click "Create"

5. **Add to n8n**:
   - Copy Client ID and Client Secret
   - In n8n: Create Gmail OAuth2 credential
   - Paste credentials
   - Click "Sign in with Google"
   - Authorize

**Important**: Refresh tokens expire after 7 days in testing mode. For production, publish your Google Cloud app.

---

## 📡 **Webhook Node Configuration Updates**

### Best Practice: Use "Respond to Webhook" Node

**Old Method** (Basic):
```json
{
  "responseMode": "responseNode"
}
```

**New Method** (Recommended):
```
1. Set Webhook node to "Respond using 'Respond to Webhook' node"
2. Add "Respond to Webhook" node at the end
3. Configure response format
```

### Security Features (n8n v1.103.0+):

**1. CORS Configuration**:
```javascript
// In Webhook node → Options → Allowed Origins
*                    // Allow all (default)
https://yoursite.com // Specific domain
```

**2. IP Whitelisting**:
```javascript
// In Webhook node → Options → IP(s) Whitelist
192.168.1.1,192.168.1.2  // Comma-separated IPs
```

**3. Bot Protection**:
```javascript
// In Webhook node → Options
☑ Ignore Bots  // Ignore link previewers and crawlers
```

**4. Payload Size Limit**:
```javascript
// Default: 16MB
// For self-hosted, set environment variable:
N8N_PAYLOAD_SIZE_MAX=32  // 32MB
```

---

## 🔧 **Workflow JSON Structure Updates**

### Current Format (n8n v1.103.0+):

```json
{
  "name": "Workflow Name",
  "nodes": [
    {
      "parameters": { ... },
      "id": "unique-node-id",
      "name": "Node Name",
      "type": "n8n-nodes-base.nodeName",
      "typeVersion": 2,     // Use latest typeVersion
      "position": [x, y]
    }
  ],
  "connections": { ... },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  }
}
```

### Important Changes:

1. **Node Type Versions**: Always use latest typeVersion
   ```json
   "typeVersion": 3.3  // For Set node
   "typeVersion": 2.1  // For Gmail node
   "typeVersion": 4.2  // For HTTP Request node
   ```

2. **Data Format**: Array of items
   ```javascript
   // Data flows as array of objects
   [
     { json: { field1: "value1" } },
     { json: { field2: "value2" } }
   ]
   ```

3. **Credentials Reference**: Use credential IDs
   ```json
   "credentials": {
     "airtableTokenApi": {
       "id": "credential-id",
       "name": "Insurance Airtable"
     }
   }
   ```

---

## 📊 **Updated Node Configurations**

### Airtable Node (Latest):

```json
{
  "parameters": {
    "operation": "create",
    "base": {
      "__rl": true,
      "value": "appYourBaseId",
      "mode": "list",
      "cachedResultName": "Insurance Leads"
    },
    "table": {
      "__rl": true,
      "value": "tblYourTableId",
      "mode": "list",
      "cachedResultName": "Leads"
    },
    "columns": {
      "mappingMode": "defineBelow",
      "value": { ... }
    }
  },
  "type": "n8n-nodes-base.airtable",
  "typeVersion": 2
}
```

### Gmail Node (OAuth2):

```json
{
  "parameters": {
    "authentication": "oAuth2",
    "sendTo": "={{ $json.email }}",
    "subject": "Subject",
    "emailType": "html",
    "message": "HTML content"
  },
  "type": "n8n-nodes-base.gmail",
  "typeVersion": 2.1,
  "credentials": {
    "gmailOAuth2": {
      "id": "your-credential-id"
    }
  }
}
```

### Twilio Node:

```json
{
  "parameters": {
    "fromNumber": "+1234567890",
    "toNumber": "={{ $json.phone }}",
    "message": "SMS content"
  },
  "type": "n8n-nodes-base.twilio",
  "typeVersion": 1,
  "credentials": {
    "twilioApi": {
      "id": "your-credential-id"
    }
  }
}
```

### HTTP Request Node (Latest):

```json
{
  "parameters": {
    "url": "https://api.example.com",
    "method": "POST",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [...]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ ... }}"
  },
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

---

## 🚀 **Environment Variables (Self-Hosted)**

### Required for Production:

```bash
# Webhook Configuration
WEBHOOK_URL=https://your-n8n-domain.com

# If behind reverse proxy
N8N_PROXY_HOPS=1

# Payload size (default 16MB)
N8N_PAYLOAD_SIZE_MAX=32

# Timezone
GENERIC_TIMEZONE=America/New_York

# Execution timeout (default 2 minutes)
EXECUTIONS_TIMEOUT=600

# Max executions to keep
EXECUTIONS_DATA_MAX_AGE=168  # 7 days
```

### Security Settings:

```bash
# Secure cookies
N8N_SECURE_COOKIE=true

# JWT secret (generate strong secret)
N8N_JWT_SECRET=your-secure-secret

# Basic auth (optional)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-password
```

---

## ⚡ **Performance Optimizations**

### 1. Use Batch Operations:

```javascript
// Airtable bulk operations
{
  "operation": "append",
  "columns": {
    "mappingMode": "autoMapInputData"  // Faster for multiple items
  },
  "options": {
    "bulkSize": 10  // Process 10 records at once
  }
}
```

### 2. Enable Workflow Caching:

```javascript
// In workflow settings
{
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all"
  }
}
```

### 3. Use Code Node Efficiently:

```javascript
// Process all items at once instead of one by one
const items = $input.all();
return items.map(item => ({
  json: {
    ...item.json,
    processed: true
  }
}));
```

---

## 🔍 **Testing & Debugging**

### Test Webhook URLs:

```
Production: https://your-n8n.com/webhook/endpoint
Test:       https://your-n8n.com/webhook-test/endpoint

// Test URLs stay active for 120 seconds
// Use "Listen for test event" button
```

### Debug Mode:

```javascript
// Add to workflow to log data
console.log('Debug:', $json);

// View in execution log
// Settings → Executions → View execution
```

### Error Handling:

```javascript
// Add Error Trigger node
{
  "type": "n8n-nodes-base.errorTrigger",
  "parameters": {}
}

// Continue on fail
{
  "continueOnFail": true,
  "alwaysOutputData": true
}
```

---

## 📝 **Migration Checklist**

When updating workflows to latest n8n version:

- [ ] Update Airtable credentials to Personal Access Token
- [ ] Replace Gmail App Password with OAuth2 (production)
- [ ] Update webhook nodes to use "Respond to Webhook"
- [ ] Add security options to webhooks (CORS, IP whitelist)
- [ ] Update node typeVersions to latest
- [ ] Test all workflows thoroughly
- [ ] Update environment variables
- [ ] Enable error handling
- [ ] Configure execution retention
- [ ] Set up monitoring and logging

---

## 🔄 **Workflow Import/Export**

### Exporting:

```
1. Open workflow
2. Click "..." menu → Download
3. Save as JSON
4. Remove credentials before sharing!
```

### Importing:

```
1. Go to Workflows
2. Click "Import from File"
3. Select JSON file
4. Update credentials
5. Test workflow
6. Activate
```

### Security Note:
**Always remove credential IDs from exported workflows before sharing:**

```javascript
// Find and remove:
"credentials": {
  "gmailOAuth2": {
    "id": "123",  // ← Remove this
    "name": "My Gmail"
  }
}
```

---

## 📞 **Common Issues & Solutions**

### Issue 1: Webhooks Not Working
```
✅ Check workflow is Active
✅ Verify WEBHOOK_URL environment variable
✅ Check firewall/reverse proxy settings
✅ Test with Test webhook URL first
```

### Issue 2: Airtable "Invalid API Key"
```
✅ You're using old API key - switch to Personal Access Token
✅ Token has correct scopes (read, write, schema)
✅ Token has access to the specific base
```

### Issue 3: Gmail "Invalid Credentials"
```
✅ OAuth2 refresh token expired (re-authenticate)
✅ App not published (7-day limit in testing)
✅ Gmail API not enabled in Google Cloud
```

### Issue 4: SMS Not Sending
```
✅ Twilio credentials correct (SID + Auth Token)
✅ Phone number format: +1XXXXXXXXXX
✅ Trial account has credits
✅ Verified phone numbers (trial accounts)
```

### Issue 5: Workflow Timeout
```
✅ Increase EXECUTIONS_TIMEOUT environment variable
✅ Split large workflows into smaller ones
✅ Use batch operations for bulk data
```

---

## 🎯 **Next Steps**

1. **Update Credentials**: Switch Airtable to Personal Access Token immediately
2. **Test Workflows**: Import and test each workflow with new credentials
3. **Add Security**: Enable webhook security options (CORS, IP whitelist)
4. **Monitor**: Set up execution logging and error notifications
5. **Optimize**: Review performance and adjust batch sizes

---

## 📚 **Additional Resources**

- Official n8n Documentation: https://docs.n8n.io
- n8n Community Forum: https://community.n8n.io
- Webhook Documentation: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- Airtable Node Docs: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.airtable/
- Gmail Node Docs: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.gmail/

---

**Note**: These workflows are built for n8n v1.103.0+. If you're using an older version, we recommend upgrading for the best experience and security features.
