# EmailJS Setup Instructions

This guide will help you configure EmailJS for the OTP feature in the registration page.

## Step 1: Create an EmailJS Account

1. Go to [https://www.emailjs.com/](https://www.emailjs.com/)
2. Sign up for a free account
3. Verify your email address

## Step 2: Add Email Service

1. In your EmailJS dashboard, go to **Email Services**
2. Click **Add New Service**
3. Choose your email provider (Gmail, Outlook, etc.)
4. Follow the setup instructions for your provider
5. Note down your **Service ID** (e.g., `service_xxxxxxx`)

## Step 3: Create Email Template

1. Go to **Email Templates** in the dashboard
2. Click **Create New Template**
3. Choose a template or create from scratch
4. In the template editor, add the following variables:
   - `{{to_email}}` - recipient email
   - `{{to_name}}` - recipient name
   - `{{otp_code}}` - the 6-digit OTP code
   - `{{message}}` - custom message

### Example Template:

```
Subject: Your OTP Verification Code

Hello {{to_name}},

Your verification code for Daydream Resort registration is:

{{otp_code}}

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

Thank you,
Daydream Resort Team
```

5. Save the template and note down your **Template ID** (e.g., `template_xxxxxxx`)

## Step 4: Get Your Public Key

1. Go to **Account** → **General** in the EmailJS dashboard
2. Find your **Public Key** (also called User ID)
3. Copy the key (e.g., `xxxxxxxxxxxxxxxx`)

## Step 5: Update the Code

1. Open `lib/services/otp_service.dart`
2. Replace the placeholder values with your actual credentials:

```dart
static const String _emailJSPublicKey = 'YOUR_PUBLIC_KEY'; // Replace with your Public Key
static const String _emailJSServiceID = 'YOUR_SERVICE_ID'; // Replace with your Service ID
static const String _emailJSTemplateID = 'YOUR_TEMPLATE_ID'; // Replace with your Template ID
```

Example:
```dart
static const String _emailJSPublicKey = 'abc123xyz789';
static const String _emailJSServiceID = 'service_gmail123';
static const String _emailJSTemplateID = 'template_otp456';
```

## Step 6: Test the OTP Feature

1. Run your Flutter app
2. Go to the registration page
3. Enter your email and password
4. Click "Send OTP"
5. Check your email for the OTP code
6. Enter the code and complete registration

## Important Notes

- The OTP expires after 5 minutes
- OTPs are stored temporarily in memory (not persistent across app restarts)
- For production, consider storing OTPs in a secure backend service
- Free EmailJS accounts have rate limits - check your plan for details

## Troubleshooting

**OTP not being sent:**
- Verify your EmailJS credentials are correct
- Check your email service connection in EmailJS dashboard
- Verify your email template variables match the code (`otp_code`, `to_email`, etc.)
- Check EmailJS dashboard logs for error messages

**Invalid OTP error:**
- Make sure you're entering the correct 6-digit code
- Check if the OTP has expired (5 minutes)
- Try requesting a new OTP

**API errors:**
- Ensure your Public Key has permission to send emails
- Check EmailJS service status
- Verify your template ID and service ID are correct

