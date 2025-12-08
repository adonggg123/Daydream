# Firebase Billing Setup - How to Stay Free

## Understanding Blaze Plan Free Tier

The Blaze plan has a **generous free tier** that covers most small to medium apps:

### Free Tier Limits (Blaze Plan)
- **Storage**: 5 GB free
- **Downloads**: 1 GB/day free
- **Uploads**: 20,000 operations/day free
- **Downloads**: 50,000 operations/day free

### Real-World Example
For profile pictures:
- Average profile picture: ~200 KB
- 1,000 users with profile pictures = ~200 MB
- Daily downloads: Even 1,000 downloads = ~200 MB/day
- **You'll stay well within the free tier!**

## Setting Up Billing Alerts (IMPORTANT)

To ensure you never get unexpected charges:

### Step 1: Set Budget Alerts
1. Go to Firebase Console → **Project Settings** → **Usage and billing**
2. Click **Set budget alert**
3. Set a budget (e.g., $1 or $5)
4. Set alert threshold (e.g., 50% = $0.50)
5. Add your email to receive alerts

### Step 2: Set Usage Limits
1. Go to **Usage and billing** → **Quotas**
2. Review the free tier limits
3. Set up email alerts when approaching limits

### Step 3: Monitor Usage
1. Go to **Usage and billing** → **Usage**
2. Check daily/weekly usage
3. You'll see if you're approaching free tier limits

## Cost Protection

### Option 1: Set Budget Cap (Recommended)
1. Go to Google Cloud Console (linked from Firebase)
2. Navigate to **Billing** → **Budgets & alerts**
3. Create a budget with a **hard cap** at $0 or $1
4. This prevents any charges beyond your set limit

### Option 2: Disable Billing (Not Recommended)
- You can disable billing, but this will disable Storage
- Not recommended if you need Storage

## Typical Costs for Your App

For a small resort booking app:
- **Profile pictures**: ~200 MB storage = **FREE** (within 5 GB)
- **Daily downloads**: ~500 MB = **FREE** (within 1 GB/day)
- **Monthly cost**: **$0** (stays within free tier)

## When You Might Pay

You'll only pay if you exceed:
- 5 GB storage (unlikely for profile pictures)
- 1 GB/day downloads (unlikely for small app)
- 20,000 uploads/day (very unlikely)

**For profile pictures alone, you'll likely never pay anything.**

## Recommendation

1. ✅ Upgrade to Blaze plan
2. ✅ Set budget alert at $1
3. ✅ Monitor usage monthly
4. ✅ You'll stay free for profile pictures

The free tier is very generous for profile picture storage!

