# ⚙️ Complete Configuration Guide

This guide walks you through configuring each workflow for your insurance agency.

---

## 🎯 1. Lead Qualification System Configuration

### Step 1: Configure Agency Information
In the **"Set Team Info"** node, update:
```javascript
agencyName: "Your Insurance Agency"
agencyPhone: "+1234567890"
agencyEmail: "info@youragency.com"
```

### Step 2: Adjust Scoring Criteria
In the **"Calculate Lead Score"** node, customize:

**Income Scoring (30 points max):**
```javascript
if (income >= 75000) score += 30;  // Adjust threshold
else if (income >= 50000) score += 20;
else if (income >= 35000) score += 10;
```

**Timeline/Urgency (25 points max):**
```javascript
if (timeline.includes('immediate')) score += 25;
else if (timeline.includes('week')) score += 20;
```

**Geographic Scoring:**
```javascript
const highValueStates = ['CA', 'NY', 'TX', 'FL', 'IL'];
// Add your high-value states
```

### Step 3: Set Up Lead Sources
Update cost estimates in scoring algorithm:
```javascript
const costPerLeadEstimates = {
  'Facebook': 45,
  'Google': 60,
  'Referral': 0,
  'SmartFinancial': 55,
  // Add your lead sources
};
```

### Step 4: Configure Integrations

**Airtable:**
- Base ID: `appYourAirtableBase`
- Table: `tblLeads`

**Gmail Notifications:**
- Update recipient: `admin@youragency.com`

**Twilio SMS:**
- From Number: `+1234567890`

**Slack (Optional):**
- Webhook URL: `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`

### Step 5: Set Routing Rules
Adjust thresholds in **"Route Hot Leads"** node:
```javascript
HOT_LEAD: score >= 75    // Immediate call
QUALIFIED: score >= 60    // Call within hour
POTENTIAL: score >= 40    // Add to nurture
LOW_PRIORITY: score >= 25 // Long-term nurture
```

---

## 📞 2. Follow-Up Machine Configuration

### Step 1: Customize Timing
Adjust wait times between touches:
```javascript
Touch 1: Immediate
Touch 2: Wait 24 hours     // Adjust in "Wait 24 Hours" node
Touch 3: Wait 2 days       // Adjust in "Wait 2 Days" node
Touch 4: Wait 2 days
Touch 5: Wait 2 days
Touch 6: Wait 7 days       // Final check-in
```

### Step 2: Personalize Message Templates

**Welcome Email Template:**
```html
Subject: "{{ firstName }}, Quick Question About Your {{ insuranceType }} Coverage"
Body: [Customize in "Touch 1: Welcome Email" node]
```

**SMS Templates:**
```javascript
Touch 1: "Hi {{ firstName }}! It's [Your Name] from [Agency]..."
// Update your name and agency in each SMS node
```

### Step 3: Configure Response Handling
Update the **"Lead Response Webhook"** URL:
```javascript
Path: /lead-response
// This URL receives responses from SMS/email
```

### Step 4: Set Up Auto-Stop Logic
The sequence automatically stops when:
- Lead responds (via webhook)
- Lead books appointment
- Lead marks as spam/unsubscribe

---

## 🗓️ 3. Appointment Reminder Configuration

### Step 1: Set Reminder Schedule
Adjust timing in respective nodes:
```javascript
Immediate: Confirmation sent right away
24 hours: "Wait Until 24h Before" node
2 hours: "Wait Until 2h Before" node
30 minutes: "Wait Until 30min Before" node (optional)
```

### Step 2: Configure Calendar Integration

**Google Calendar:**
```javascript
Add to Calendar Link:
https://calendar.google.com/calendar/render?action=TEMPLATE&text=...
```

**Calendly:**
```javascript
Booking URL: https://calendly.com/youragency/consultation
Reschedule URL: https://calendly.com/youragency/reschedule/{{ appointmentId }}
```

### Step 3: Customize Reminder Messages

**24h Reminder:**
```javascript
Subject: "⏰ Reminder: Your Appointment Tomorrow with {{ agentName }}"
// Edit template in "24h Reminder Email" node
```

**2h Reminder SMS:**
```javascript
"Hi {{ firstName }}! Your appointment is in 2 HOURS..."
// Edit in "2h Reminder SMS" node
```

### Step 4: Set Up Response Handling
Configure actions for:
- ✅ Confirm: Mark appointment as confirmed
- 📅 Reschedule: Send reschedule link
- ❌ Cancel: Notify agent, free up time slot

---

## 🔄 4. Policy Renewal Configuration

### Step 1: Set Notification Schedule
Configure in Airtable formula:
```javascript
Notification Intervals:
90 days: Early notice
60 days: First reminder
30 days: Urgent notice
14 days: High priority
7 days: Critical
3 days: Emergency
0 days: Expiring today
```

### Step 2: Customize Premium Estimates
Update in **"Calculate Renewal Details"** node:
```javascript
const estimatedIncrease = currentPremium * 0.05; // 5% average increase
// Adjust based on your carrier trends
```

### Step 3: Set Agent Assignment Rules
Configure notification routing:
```javascript
if (urgency === 'urgent' || urgency === 'critical') {
  // Notify assigned agent immediately
  notifyAgent(assignedAgent);
}
```

### Step 4: Configure ROI Reporting
Daily report schedule:
```javascript
Cron: "0 8 * * *"  // Daily at 8 AM
// Adjust in "Daily Renewal Check" node
```

---

## 💬 5. Chatbot Configuration

### Step 1: Customize Intent Detection
Update patterns in **"Detect Intent"** node:
```javascript
// Life Insurance Intent
if (message.match(/life insurance|term life|whole life/i)) {
  intent = 'life_insurance_inquiry';
}

// Add your custom intents
```

### Step 2: Customize Bot Responses
Edit responses in **"Generate Bot Response"** node:
```javascript
const responses = {
  welcome_message: {
    text: "Hi! Thanks for visiting...",
    quickReplies: ['Life Insurance', 'Health Insurance']
  },
  // Add more responses
};
```

### Step 3: Configure Lead Capture Flow
Set required fields:
```javascript
Required for capture:
- First Name
- Phone Number
- Email
- Insurance Type Interest
```

### Step 4: Set Up Chatbot Widget
Add to your website:
```html
<script>
  // Chatbot initialization
  const chatbot = new ChatWidget({
    endpoint: 'https://your-n8n.com/webhook/chatbot',
    agencyName: 'Your Agency',
    brandColor: '#667eea'
  });
</script>
```

---

## 📊 6. ROI Tracker Configuration

### Step 1: Set Lead Source Costs
Update cost estimates in **"Calculate ROI Metrics"** node:
```javascript
const costPerLeadEstimates = {
  'Facebook': 45,      // Your actual FB cost
  'Google': 60,        // Your actual Google cost
  'Referral': 0,       // Free
  'SmartFinancial': 55,// Your vendor cost
  'Aged Leads': 15,    // Aged lead cost
  // Add all your sources
};
```

### Step 2: Configure Report Schedule
```javascript
Cron: "0 9 * * 1"  // Monday at 9 AM
// Adjust in "Weekly Report" node
```

### Step 3: Set ROI Thresholds
Define performance grades:
```javascript
grade: roi > 200 ? 'A+' :   // Exceptional
       roi > 100 ? 'A' :    // Excellent
       roi > 50 ? 'B' :     // Good
       roi > 0 ? 'C' :      // Acceptable
       'D'                  // Unprofitable
```

### Step 4: Configure Report Distribution
```javascript
Email Recipients:
- admin@youragency.com
- marketing@youragency.com

Slack Channel:
- #marketing-analytics
```

---

## 🔗 Integration Setup

### Airtable Setup

Create these tables with fields:

**Leads Table:**
```
- Lead ID (Single line text)
- First Name (Single line text)
- Last Name (Single line text)
- Email (Email)
- Phone (Phone)
- Qualification Score (Number)
- Status (Single select: HOT_LEAD, QUALIFIED, POTENTIAL, DISQUALIFIED)
- Lead Source (Single line text)
- Received At (Date/Time)
```

**Appointments Table:**
```
- Appointment ID (Single line text)
- Lead ID (Linked to Leads)
- Appointment Date (Date/Time)
- Status (Single select: Scheduled, Confirmed, Completed, Cancelled)
- Reminders Sent (Multiple select)
```

**Policies Table:**
```
- Policy ID (Single line text)
- Policy Number (Single line text)
- Client Name (Linked to Leads)
- Policy Type (Single select)
- Expiration Date (Date)
- Annual Premium (Currency)
- Renewal Status (Single select)
```

### Twilio Setup

1. Create Twilio account
2. Purchase phone number
3. Get credentials:
   - Account SID
   - Auth Token
4. Configure messaging service
5. Add credentials to n8n

### Gmail/SMTP Setup

1. Enable 2FA on Gmail
2. Generate App Password
3. Add to n8n credentials:
   - Email: your@email.com
   - Password: [App Password]

---

## 🎛️ Advanced Configuration

### A/B Testing Follow-Up Messages

Create workflow variants:
```javascript
// Variant A: Friendly tone
message: "Hi {{ firstName }}! 👋"

// Variant B: Professional tone
message: "Hello {{ firstName }},"

// Track which performs better
```

### Custom Scoring Algorithms

Add your own factors:
```javascript
// Credit score consideration
if (creditScore >= 700) score += 10;

// Property ownership
if (ownsHome) score += 5;

// Family size
if (familySize >= 3) score += 8;
```

### Multi-Language Support

Add language detection:
```javascript
if (detectedLanguage === 'es') {
  sendSpanishTemplate();
} else {
  sendEnglishTemplate();
}
```

---

## 🧪 Testing Configuration

### Test Each Workflow

1. **Lead Qualification:**
   - Send test webhook with sample lead
   - Verify scoring is correct
   - Check routing logic

2. **Follow-Up Machine:**
   - Trigger with test lead
   - Verify timing and messages
   - Test stop conditions

3. **Appointment Reminders:**
   - Create test appointment
   - Verify all reminders send
   - Test reschedule flow

4. **Renewals:**
   - Create test policy expiring soon
   - Verify notifications trigger
   - Check escalation logic

5. **Chatbot:**
   - Test all intent patterns
   - Verify responses are correct
   - Test lead capture flow

6. **ROI Tracker:**
   - Manually trigger report
   - Verify calculations
   - Check email formatting

---

## 📞 Support

Need help with configuration?
- Check the FAQ
- Join our community
- Email: support@youragency.com

---

*Last Updated: November 2025*
