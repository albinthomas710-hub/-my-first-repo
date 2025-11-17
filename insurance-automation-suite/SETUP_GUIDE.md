# 🚀 Quick Setup Guide - Insurance Automation Suite

**Time to complete: 60-90 minutes**

This guide will walk you through setting up the complete automation suite step-by-step.

---

## ✅ Pre-Setup Checklist

Before you begin, gather these accounts/credentials:

- [ ] n8n instance (cloud or self-hosted)
- [ ] PostgreSQL database (Supabase, Railway, or self-hosted)
- [ ] OpenAI API key
- [ ] Twilio account (for SMS)
- [ ] Email SMTP access (Gmail, SendGrid, etc.)
- [ ] Telegram bot token (optional, for alerts)
- [ ] Slack workspace (optional, for team notifications)
- [ ] CRM account (GoHighLevel, HubSpot, etc.)

---

## 📝 Step-by-Step Setup

### STEP 1: Set Up Database (15 minutes)

1. **Create PostgreSQL database**

   Option A - Supabase (recommended for beginners):
   - Go to [supabase.com](https://supabase.com)
   - Create new project
   - Copy connection string

   Option B - Railway:
   - Go to [railway.app](https://railway.app)
   - New Project → PostgreSQL
   - Copy connection details

   Option C - Self-hosted:
   - Install PostgreSQL 12+
   - Create database: `createdb insurance_automation`

2. **Run database schema**

   ```bash
   psql -h your-host -U your-user -d insurance_automation -f configs/database-schema.sql
   ```

   OR use GUI tool like:
   - pgAdmin
   - DBeaver
   - Supabase SQL Editor

3. **Verify tables created**

   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public';
   ```

   You should see: `leads`, `clients`, `appointments`, `referrals`, etc.

✅ **Checkpoint**: You should have 13+ tables created.

---

### STEP 2: Set Up n8n (10 minutes)

**Option A - n8n Cloud** (easiest):
1. Go to [n8n.io/cloud](https://n8n.io/cloud)
2. Create account
3. Copy your webhook base URL (e.g., `https://your-name.app.n8n.cloud`)

**Option B - Self-Hosted** (more control):
1. Install n8n:
   ```bash
   npm install -g n8n
   # OR
   docker run -it --rm --name n8n -p 5678:5678 n8nio/n8n
   ```
2. Access at `http://localhost:5678`
3. Set up tunnel (for webhooks):
   ```bash
   # Use ngrok for testing
   ngrok http 5678
   ```

✅ **Checkpoint**: n8n is accessible and you have webhook URL.

---

### STEP 3: Configure Environment Variables (10 minutes)

1. **In n8n**, go to: **Settings** → **Variables**

2. **Add these variables** (from `.env.example`):

   **Required (minimum to start):**
   ```
   AGENT_NAME=Your Name
   AGENCY_NAME=Your Agency
   AGENT_PHONE=+1234567890
   AGENT_EMAIL=you@agency.com
   N8N_WEBHOOK_BASE_URL=https://your-n8n-instance.com
   CALENDAR_BOOKING_LINK=https://calendly.com/yourlink
   ```

   **Can add later:**
   - Slack channels
   - Telegram
   - Referral incentive
   - Review links

✅ **Checkpoint**: Core variables are set in n8n.

---

### STEP 4: Set Up Credentials (15 minutes)

In n8n, go to: **Settings** → **Credentials**

**1. PostgreSQL**
- Name: `PostgreSQL - CRM Database`
- Host, Port, Database, User, Password from Step 1
- Test connection ✓

**2. OpenAI**
- Name: `OpenAI API`
- API Key: Get from [platform.openai.com](https://platform.openai.com/api-keys)
- Test ✓

**3. Twilio**
- Name: `Twilio`
- Account SID & Auth Token from [twilio.com/console](https://www.twilio.com/console)
- Test ✓

**4. SMTP (Email)**
- Name: `SMTP Email`

  **For Gmail:**
  ```
  Host: smtp.gmail.com
  Port: 587
  User: your-email@gmail.com
  Password: [App Password - not your Gmail password!]
  ```

  **To get Gmail App Password:**
  1. Google Account → Security
  2. 2-Step Verification → App Passwords
  3. Generate password
  4. Use this in n8n

**5. Telegram (optional)**
- Create bot: Message [@BotFather](https://t.me/botfather) on Telegram
- Use `/newbot` command
- Copy token
- Get your chat ID: Message [@userinfobot](https://t.me/userinfobot)

**6. Slack (optional)**
- Create app at [api.slack.com/apps](https://api.slack.com/apps)
- Add bot scopes: `chat:write`, `channels:read`
- Install to workspace
- Copy OAuth token

**7. CRM - GoHighLevel (or your CRM)**
- Get API key from CRM settings
- Add credentials

✅ **Checkpoint**: All credentials tested and working.

---

### STEP 5: Import Workflows (10 minutes)

1. **Download workflow files** from `/workflows/` folder

2. **Import each workflow:**
   - In n8n: **Workflows** → **Import from File**
   - Select file (e.g., `01-ai-lead-qualification-scoring.json`)
   - Click **Import**

3. **Import all 9 workflows:**
   - 01-ai-lead-qualification-scoring.json
   - 02-smart-follow-up-automation.json
   - 03-appointment-automation-system.json
   - 04-referral-reputation-system.json
   - 05-missed-call-recovery.json
   - 06-ai-quote-generator-sender.json
   - 07-lead-nurture-automation.json
   - 08-client-onboarding-retention.json
   - 09-pre-qualification-chat-intake.json

✅ **Checkpoint**: All 9 workflows imported successfully.

---

### STEP 6: Configure Workflow Credentials (15 minutes)

For each workflow:

1. Open workflow
2. Click on nodes with ⚠️ warning icons
3. Select your credentials from dropdown
4. **Important**: Replace these placeholders:
   - `{{POSTGRES_CREDENTIAL_ID}}` → Your PostgreSQL credential
   - `{{OPENAI_CREDENTIAL_ID}}` → Your OpenAI credential
   - `{{TWILIO_CREDENTIAL_ID}}` → Your Twilio credential
   - `{{SMTP_CREDENTIAL_ID}}` → Your SMTP credential
   - etc.

**Pro Tip**: n8n usually auto-maps credentials if names match!

✅ **Checkpoint**: No warning icons on any nodes.

---

### STEP 7: Test Each Workflow (20 minutes)

**Test Workflow #1: Lead Qualification**

1. Open workflow: `01-ai-lead-qualification-scoring.json`
2. Click **Execute Workflow** (test manually)
3. Or send test webhook:

   ```bash
   curl -X POST https://your-n8n.com/webhook/new-lead \
     -H "Content-Type: application/json" \
     -d '{
       "first_name": "Test",
       "last_name": "User",
       "email": "test@example.com",
       "phone": "+11234567890",
       "age": 35,
       "income": "75000",
       "coverage_type": "Term Life",
       "source": "manual_test"
     }'
   ```

4. **Expected result:**
   - Lead saved to database
   - AI qualification runs
   - Lead scored and tiered
   - Email/SMS sent (if HOT)

5. **Check:**
   - Database: `SELECT * FROM leads ORDER BY id DESC LIMIT 1;`
   - Your email/phone (should receive message)

**Test Workflow #2: Appointment Automation**

1. Send test webhook:
   ```bash
   curl -X POST https://your-n8n.com/webhook/appointment/book \
     -H "Content-Type: application/json" \
     -d '{
       "lead_id": 1,
       "name": "Test User",
       "email": "test@example.com",
       "phone": "+11234567890",
       "appointment_time": "2025-01-20T14:00:00Z",
       "meeting_link": "https://zoom.us/j/test"
     }'
   ```

2. **Expected:** Confirmation email + SMS sent

**Test Other Workflows:**

- **Follow-Up**: Will run automatically every 15 min
- **Referrals**: Trigger when deal closes
- **Missed Call**: Send webhook when call is missed
- **Quote Generator**: Send webhook with lead_id
- **Nurture**: Runs Mon/Thu 9am automatically
- **Onboarding**: Trigger when new client added
- **Chat Bot**: Send chat message webhook

✅ **Checkpoint**: At least workflow #1 tested successfully.

---

### STEP 8: Activate Workflows (5 minutes)

For each workflow:
1. Open workflow
2. Toggle **Active** switch in top-right corner
3. Status should show green "Active"

**Workflows to activate:**
- ✅ All webhook-triggered workflows (instant)
- ✅ All scheduled workflows (run on schedule)

✅ **Checkpoint**: All 9 workflows are ACTIVE.

---

### STEP 9: Connect to Your Website (10 minutes)

**Add lead capture form:**

```html
<form id="insurance-form">
  <input name="first_name" placeholder="First Name" required>
  <input name="last_name" placeholder="Last Name" required>
  <input name="email" type="email" placeholder="Email" required>
  <input name="phone" placeholder="Phone" required>
  <input name="age" type="number" placeholder="Age">
  <select name="coverage_type" required>
    <option value="">Select Coverage Type</option>
    <option value="Term Life">Term Life Insurance</option>
    <option value="Whole Life">Whole Life Insurance</option>
    <option value="Health Insurance">Health Insurance</option>
    <option value="Disability">Disability Insurance</option>
  </select>
  <button type="submit">Get Free Quote</button>
</form>

<script>
document.getElementById('insurance-form').addEventListener('submit', async (e) => {
  e.preventDefault();

  const formData = new FormData(e.target);
  const data = Object.fromEntries(formData);

  // Send to n8n webhook
  const response = await fetch('https://your-n8n.com/webhook/new-lead', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      ...data,
      source: 'website',
      utm_source: new URLSearchParams(window.location.search).get('utm_source')
    })
  });

  if (response.ok) {
    alert('Thank you! We\'ll be in touch within 30 minutes.');
    e.target.reset();
  }
});
</script>
```

✅ **Checkpoint**: Form submits to n8n, lead gets qualified.

---

### STEP 10: Monitor & Optimize (Ongoing)

**Week 1: Monitor**
- Check Slack/Telegram for notifications
- Review database for lead flow
- Verify emails/SMS sending correctly

**Week 2: Optimize**
- Adjust AI prompts based on responses
- Tweak follow-up timing
- Customize messages for your brand

**Month 1: Scale**
- Add more lead sources
- Fine-tune qualification criteria
- A/B test message variations

---

## 🎉 You're Live!

Your insurance automation suite is now running 24/7!

**What happens automatically:**

1. ✅ Leads get qualified instantly
2. ✅ HOT leads contacted within 30 min
3. ✅ Follow-ups sent every 24-72 hours
4. ✅ Appointments confirmed with 3 reminders
5. ✅ No-shows recovered within 15 minutes
6. ✅ Quotes generated in 30 seconds
7. ✅ Referrals requested automatically
8. ✅ Reviews requested from happy clients
9. ✅ Nurture campaigns keep leads warm

---

## 📊 Monitoring Dashboard

**Check these daily:**

```sql
-- Today's Leads
SELECT COUNT(*) FROM leads WHERE DATE(created_at) = CURRENT_DATE;

-- HOT Leads Needing Follow-Up
SELECT * FROM leads
WHERE qualification_tier = 'HOT'
  AND status NOT IN ('closed_won', 'closed_lost')
ORDER BY created_at DESC;

-- This Week's Conversion Rate
SELECT
  COUNT(*) FILTER (WHERE status = 'closed_won')::FLOAT /
  NULLIF(COUNT(*), 0) * 100 as conversion_rate_percent
FROM leads
WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE);
```

---

## 🆘 Troubleshooting

**Problem: Workflow not triggering**
- ✅ Check workflow is ACTIVE
- ✅ Verify webhook URL is correct
- ✅ Check execution log for errors

**Problem: SMS not sending**
- ✅ Verify Twilio credentials
- ✅ Check phone number format (+1234567890)
- ✅ Ensure Twilio account funded

**Problem: Emails not sending**
- ✅ Check SMTP credentials
- ✅ Verify "from" email is correct
- ✅ Check spam folder

**Problem: Database errors**
- ✅ Verify connection string
- ✅ Check tables exist
- ✅ Confirm credentials have write access

**Problem: OpenAI errors**
- ✅ Check API key valid
- ✅ Verify account has credits
- ✅ Check rate limits

---

## 📞 Need Help?

1. Check execution logs in n8n
2. Review database for data issues
3. Test individual nodes manually
4. Check environment variables
5. Verify all credentials

---

## 🎯 Next Steps

**Week 1:**
- [ ] Send 10 test leads
- [ ] Monitor all workflows
- [ ] Customize message templates

**Week 2:**
- [ ] Connect to live lead sources
- [ ] Set up Facebook Lead Ads integration
- [ ] Add team members to Slack/Telegram

**Month 1:**
- [ ] Review metrics and optimize
- [ ] A/B test different message approaches
- [ ] Scale to more lead sources

---

**Congratulations! You now have a world-class insurance automation system running 24/7!** 🎉

This system is doing the work of 2-3 full-time employees. Use your freed-up time to:
- Build deeper client relationships
- Network and generate referrals
- Close more deals
- Take more vacations 🏖️

---

**Remember**: The top-earning agents aren't working harder — they're working smarter with automation.

Welcome to the future of insurance sales! 🚀
