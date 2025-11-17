# 🔐 Webhook Security & Authentication Guide

**Critical: Securing Your Insurance Automation Webhooks**

Unsecured webhooks are the #1 security vulnerability in automation systems. This guide shows you how to lock them down properly.

---

## ⚠️ The Problem

**Every webhook you create is a public URL that anyone can call.**

Without authentication, attackers can:
- ❌ Flood your system with fake leads
- ❌ Trigger expensive API calls (OpenAI costs money!)
- ❌ Corrupt your database
- ❌ Spam your clients with emails/SMS
- ❌ Perform reconnaissance on your system

**Real example:**
```bash
# Attacker finds your webhook URL
curl -X POST https://your-n8n.com/webhook/new-lead \
  -d '{"first_name":"Spam", "email":"spam@spam.com", ...}'

# Result: Your AI processes it, sends emails, wastes API credits
```

---

## ✅ Solution: Authentication Methods

### Method 1: Header Authentication (RECOMMENDED)

**Best for:** Most use cases, easy to implement, secure

**Setup:**

1. **Generate a strong secret token:**
   ```bash
   # Generate 32-character random string
   openssl rand -hex 32
   # Output: a4f8c2d9e7b1f6a3c8d2e9f7b4a1c6d8e3f9b7a2c5d8e1f4b9a6c3d7e2f8b5a1
   ```

2. **In n8n webhook node:**
   - Open webhook node
   - **Authentication** → "Header Auth"
   - **Header Name:** `X-Auth-Token`
   - **Header Value:** `a4f8c2d9e7b1f6a3c8d2e9f7b4a1c6d8e3f9b7a2c5d8e1f4b9a6c3d7e2f8b5a1`

3. **How clients call it:**
   ```bash
   curl -X POST https://your-n8n.com/webhook/new-lead \
     -H "X-Auth-Token: a4f8c2d9e7b1f6a3c8d2e9f7b4a1c6d8e3f9b7a2c5d8e1f4b9a6c3d7e2f8b5a1" \
     -H "Content-Type: application/json" \
     -d '{"first_name":"John", "last_name":"Doe", "email":"john@example.com"}'
   ```

4. **JavaScript example (for your website):**
   ```javascript
   const response = await fetch('https://your-n8n.com/webhook/new-lead', {
     method: 'POST',
     headers: {
       'X-Auth-Token': 'a4f8c2d9...', // Your secret token
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       first_name: 'John',
       last_name: 'Doe',
       email: 'john@example.com',
       phone: '+12345678900',
       source: 'website'
     })
   });
   ```

---

### Method 2: Basic Authentication

**Best for:** Internal tools, simple implementations

**Setup:**

1. **In n8n webhook node:**
   - **Authentication** → "Basic Auth"
   - **User:** `insurance_api`
   - **Password:** `[Strong password - 20+ characters]`

2. **How clients call it:**
   ```bash
   curl -X POST https://your-n8n.com/webhook/new-lead \
     -u insurance_api:your-strong-password \
     -H "Content-Type: application/json" \
     -d '{"first_name":"John", ...}'
   ```

3. **JavaScript example:**
   ```javascript
   const credentials = btoa('insurance_api:your-strong-password');

   const response = await fetch('https://your-n8n.com/webhook/new-lead', {
     method: 'POST',
     headers: {
       'Authorization': `Basic ${credentials}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({...})
   });
   ```

---

### Method 3: IP Whitelisting (ADVANCED)

**Best for:** Known, fixed IP addresses

**Setup:**

1. **In n8n webhook node:**
   - **Authentication** → "None" (but see step 2)
   - **Options** → "IP Whitelist"
   - **Allowed IPs:**
     ```
     192.168.1.100
     203.0.113.0/24
     2001:db8::/32
     ```

2. **Can combine with Header/Basic Auth for extra security**

**Pros:**
- Very secure
- No credentials needed in code

**Cons:**
- Only works for fixed IPs
- Not suitable for dynamic IPs (home internet, mobile)
- Need to update when IPs change

---

### Method 4: JWT (JSON Web Tokens) - MOST SECURE

**Best for:** Multiple clients, advanced security requirements, API services

**Setup (requires custom validation):**

1. **Client generates JWT:**
   ```javascript
   // Client side (Node.js)
   const jwt = require('jsonwebtoken');
   const SECRET_KEY = 'your-shared-secret-key';

   const token = jwt.sign(
     {
       client_id: 'website_form',
       iat: Math.floor(Date.now() / 1000),
       exp: Math.floor(Date.now() / 1000) + (60 * 15) // 15 min expiry
     },
     SECRET_KEY
   );

   // Send in request
   fetch('https://your-n8n.com/webhook/new-lead', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({...})
   });
   ```

2. **In n8n, validate JWT:**
   - Use "Function" node after webhook
   - Validate JWT token
   - If invalid, return 401 error

   ```javascript
   // n8n Function node
   const jwt = require('jsonwebtoken');
   const SECRET_KEY = process.env.JWT_SECRET_KEY;

   const authHeader = $input.first().headers.authorization;

   if (!authHeader || !authHeader.startsWith('Bearer ')) {
     throw new Error('No authorization token provided');
   }

   const token = authHeader.substring(7);

   try {
     const decoded = jwt.verify(token, SECRET_KEY);
     return { json: { ...decoded, ...($input.first().json) } };
   } catch (error) {
     throw new Error('Invalid or expired token');
   }
   ```

---

## 🛡️ Comparison: Which Method to Use?

| Method | Security Level | Ease of Use | Best For |
|--------|---------------|-------------|----------|
| **Header Auth** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **Most use cases (RECOMMENDED)** |
| **Basic Auth** | ⭐⭐⭐ | ⭐⭐⭐⭐ | Internal tools, simple apps |
| **IP Whitelist** | ⭐⭐⭐⭐⭐ | ⭐⭐ | Known fixed IPs only |
| **JWT** | ⭐⭐⭐⭐⭐ | ⭐⭐ | Multiple clients, API services |
| **None** | ❌ | ⭐⭐⭐⭐⭐ | **NEVER USE IN PRODUCTION** |

---

## 🔧 Implementation for Each Workflow

### 1. Lead Qualification Webhook

**File:** `01-ai-lead-qualification-scoring.json`

**Current:** `Webhook - New Lead` node

**Add:**
```
Authentication: Header Auth
Header Name: X-Insurance-Lead-Token
Header Value: [Generate unique token for this webhook]
```

**Update website form:**
```javascript
// Store token securely (environment variable, not in frontend code!)
const LEAD_TOKEN = process.env.LEAD_WEBHOOK_TOKEN;

fetch('https://your-n8n.com/webhook/new-lead', {
  method: 'POST',
  headers: {
    'X-Insurance-Lead-Token': LEAD_TOKEN,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(leadData)
});
```

### 2. Appointment Booking Webhook

**File:** `03-appointment-automation-system.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Appointment-Token
Header Value: [Different token from lead webhook]
```

### 3. Referral Received Webhook

**File:** `04-referral-reputation-system.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Referral-Token
Header Value: [Different token]
```

### 4. Missed Call Webhook

**File:** `05-missed-call-recovery.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Missed-Call-Token
Header Value: [Different token]
```

### 5. Quote Request Webhook

**File:** `06-ai-quote-generator-sender.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Quote-Token
Header Value: [Different token]
```

### 6. New Client Webhook

**File:** `08-client-onboarding-retention.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Client-Token
Header Value: [Different token]
```

### 7. Chat Bot Webhook

**File:** `09-pre-qualification-chat-intake.json`

**Add:**
```
Authentication: Header Auth
Header Name: X-Chat-Token
Header Value: [Different token]
```

---

## 🔑 Token Management Best Practices

### 1. Generate Unique Tokens

**Use different tokens for each webhook:**

```bash
# Generate tokens for all webhooks
echo "LEAD_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "APPOINTMENT_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "REFERRAL_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "MISSED_CALL_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "QUOTE_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "CLIENT_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
echo "CHAT_WEBHOOK_TOKEN=$(openssl rand -hex 32)" >> .env
```

### 2. Store Tokens Securely

**DO:**
- ✅ Store in environment variables
- ✅ Store in password manager (1Password, LastPass)
- ✅ Use n8n credential system
- ✅ Use secrets management (AWS Secrets Manager, Vault)

**DON'T:**
- ❌ Commit to Git
- ❌ Hardcode in frontend JavaScript
- ❌ Share via email/Slack
- ❌ Write in plaintext documents

### 3. Rotate Tokens Regularly

**Schedule:**
- Production tokens: Every 90 days
- Development tokens: Every 180 days
- After security incident: Immediately
- After employee departure: Within 24 hours

**Rotation process:**
1. Generate new token
2. Update n8n webhook
3. Update all clients calling webhook
4. Test thoroughly
5. Revoke old token after 48-hour grace period

### 4. Monitor for Unauthorized Access

**Create an alert workflow:**

```sql
-- Check for authentication failures (implement logging first)
SELECT
    COUNT(*) as failed_attempts,
    source_ip,
    webhook_path
FROM webhook_access_log
WHERE
    status = 401
    AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY source_ip, webhook_path
HAVING COUNT(*) > 10;
```

---

## 🚨 What to Do If Token is Compromised

### Immediate Actions (0-30 minutes):

1. **Generate new token:**
   ```bash
   openssl rand -hex 32
   ```

2. **Update n8n webhook immediately:**
   - Open workflow
   - Edit webhook node
   - Replace token
   - Save and activate

3. **Old webhook stops working immediately** (attacker locked out)

### Short-term (30 minutes - 4 hours):

4. **Update all legitimate clients:**
   - Update environment variables
   - Redeploy applications
   - Test connections

5. **Monitor for abuse:**
   - Check database for fraudulent entries
   - Review execution logs
   - Check API usage (OpenAI, Twilio costs)

### Long-term (4+ hours):

6. **Investigate:**
   - How was token compromised?
   - Review code for hardcoded tokens
   - Check if token was committed to Git
   - Review access logs

7. **Prevent recurrence:**
   - Implement better token storage
   - Add monitoring/alerts
   - Train team on security practices

---

## 📊 Testing Your Security

### Test 1: Authenticated Request (Should Work)

```bash
curl -X POST https://your-n8n.com/webhook/new-lead \
  -H "X-Auth-Token: your-correct-token" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","email":"test@example.com"}'

# Expected: 200 OK + workflow executes
```

### Test 2: Unauthenticated Request (Should Fail)

```bash
curl -X POST https://your-n8n.com/webhook/new-lead \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Hacker","email":"hacker@evil.com"}'

# Expected: 401 Unauthorized
```

### Test 3: Wrong Token (Should Fail)

```bash
curl -X POST https://your-n8n.com/webhook/new-lead \
  -H "X-Auth-Token: wrong-token-12345" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Hacker","email":"hacker@evil.com"}'

# Expected: 401 Unauthorized
```

### Test 4: Missing Header (Should Fail)

```bash
curl -X POST https://your-n8n.com/webhook/new-lead \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Hacker","email":"hacker@evil.com"}'

# Expected: 401 Unauthorized
```

**All tests passing = Your webhooks are secure! ✅**

---

## 🌐 Integrating with Common Platforms

### WordPress Form

```php
<?php
// functions.php or custom plugin

add_action('wpcf7_before_send_mail', 'send_to_n8n');

function send_to_n8n($contact_form) {
    $submission = WPCF7_Submission::get_instance();
    $posted_data = $submission->get_posted_data();

    $n8n_url = 'https://your-n8n.com/webhook/new-lead';
    $auth_token = get_option('n8n_auth_token'); // Store in WordPress settings

    $response = wp_remote_post($n8n_url, array(
        'headers' => array(
            'X-Auth-Token' => $auth_token,
            'Content-Type' => 'application/json'
        ),
        'body' => json_encode($posted_data)
    ));
}
?>
```

### Facebook Lead Ads (via Zapier/Make)

```
Facebook Lead Ads → Zapier/Make → HTTP Request to n8n

HTTP Request Settings:
- URL: https://your-n8n.com/webhook/new-lead
- Method: POST
- Headers:
  X-Auth-Token: your-secret-token
  Content-Type: application/json
- Body: {{lead_data}}
```

### Calendly Webhook

```
Calendly → Webhook Settings → Add Webhook

Webhook URL: https://your-n8n.com/webhook/appointment/book
Custom Headers:
  X-Appointment-Token: your-secret-token

Events to subscribe:
- invitee.created
```

### Twilio Voice (Missed Call)

```javascript
// Twilio Function
exports.handler = function(context, event, callback) {
  const axios = require('axios');

  axios.post('https://your-n8n.com/webhook/call/missed', {
    from_number: event.From,
    to_number: event.To,
    call_status: event.CallStatus,
    call_time: new Date().toISOString()
  }, {
    headers: {
      'X-Missed-Call-Token': context.N8N_MISSED_CALL_TOKEN
    }
  })
  .then(() => callback(null, 'OK'))
  .catch((error) => callback(error));
};
```

---

## 📝 Security Checklist

Before going to production:

- [ ] ✅ All webhooks have authentication enabled (NO "None" authentication)
- [ ] ✅ Unique tokens generated for each webhook
- [ ] ✅ Tokens stored securely (environment variables, not in code)
- [ ] ✅ Tested authenticated requests (should work)
- [ ] ✅ Tested unauthenticated requests (should fail with 401)
- [ ] ✅ Tokens not committed to Git repository
- [ ] ✅ Token rotation schedule documented
- [ ] ✅ Team trained on token security
- [ ] ✅ Monitoring in place for failed auth attempts
- [ ] ✅ Incident response plan documented

---

## 🎓 Additional Security Layers

### 1. Rate Limiting

**Prevent brute force attacks:**

Add "Rate Limit" node after webhook:
- Max requests: 10 per minute per IP
- Action on limit: Return 429 error

### 2. Request Validation

**Validate all incoming data:**

```javascript
// Add after webhook node
const requiredFields = ['first_name', 'last_name', 'email', 'phone'];
const data = $input.first().json;

for (const field of requiredFields) {
  if (!data[field] || data[field].trim() === '') {
    throw new Error(`Missing required field: ${field}`);
  }
}

// Validate email format
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(data.email)) {
  throw new Error('Invalid email format');
}

// Validate phone format
const phoneRegex = /^\+?[1-9]\d{1,14}$/;
if (!phoneRegex.test(data.phone)) {
  throw new Error('Invalid phone format');
}

return { json: data };
```

### 3. HTTPS Only

**Ensure all webhooks use HTTPS:**
- Never use `http://` URLs
- Always use `https://` URLs
- Enforce TLS 1.2 or higher

### 4. Webhook Signing (Advanced)

**For maximum security, sign requests:**

```javascript
// Client side
const crypto = require('crypto');
const SECRET = 'your-signing-secret';

const payload = JSON.stringify(leadData);
const signature = crypto
  .createHmac('sha256', SECRET)
  .update(payload)
  .digest('hex');

fetch('https://your-n8n.com/webhook/new-lead', {
  method: 'POST',
  headers: {
    'X-Signature': signature,
    'Content-Type': 'application/json'
  },
  body: payload
});
```

```javascript
// n8n verification node
const crypto = require('crypto');
const SECRET = process.env.WEBHOOK_SIGNING_SECRET;

const signature = $input.first().headers['x-signature'];
const payload = JSON.stringify($input.first().json);

const expectedSignature = crypto
  .createHmac('sha256', SECRET)
  .update(payload)
  .digest('hex');

if (signature !== expectedSignature) {
  throw new Error('Invalid signature');
}

return { json: $input.first().json };
```

---

## 🏆 Summary

**The golden rule: NEVER leave webhooks without authentication in production.**

**Recommended setup:**
1. Use **Header Authentication** for simplicity
2. Generate **unique 32+ character tokens** for each webhook
3. Store tokens in **environment variables**
4. **Rotate tokens every 90 days**
5. **Monitor for unauthorized access**
6. Have a **response plan** for compromised tokens

**With proper authentication:**
- ✅ Prevent unauthorized access
- ✅ Protect against abuse
- ✅ Reduce API costs
- ✅ Keep data integrity
- ✅ Sleep better at night

**Time to implement: 30 minutes**
**Peace of mind: Priceless** 😌

---

**Questions? Issues? Security concerns?**

Open an issue in the repository or contact your security team.

**Stay secure! 🔐**
