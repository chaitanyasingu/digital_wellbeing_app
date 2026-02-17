# Play Store Listing - Quick Reference
# Copy and paste these values when filling out Google Play Console

## App Identity

**App Name (30 chars max):**
```
Digital Mindfulness
```

**Package Name (cannot change after publish):**
```
com.digitalwellbeing.digital_wellbeing_app
```

---

## Store Listing

**Short Description (80 chars max):**
```
Reduce screen time with mindful app blocking. Focus on what matters.
```

**Full Description (4000 chars max):**
```
🧘 Digital Mindfulness - Take Control of Your Screen Time

Digital Mindfulness helps you build healthier phone habits through scheduled app restrictions and mindful awareness.

✨ KEY FEATURES

🔒 Scheduled App Blocking
Set custom time windows (like 9pm-7am) when distracting apps are restricted. Only your essential apps remain accessible during mindful periods.

🧘 Mindful Design
Beautiful purple theme with encouraging messages. No punishment, just gentle reminders to stay focused.

🛡️ Robust Enforcement
• Survives app force-closes
• Persists after device reboots
• Detects bypass attempts
• Accessibility-powered blocking

⚙️ Easy Setup
1. Choose apps to keep accessible (like Phone, Messages)
2. Set your mindful hours
3. Enable enforcement
4. Stay focused!

🔔 Smart Notifications
Non-dismissible during restrictions to keep you accountable. See exactly when your mindful period ends.

🔐 Settings Lock
Can't change settings during restricted hours - helping you stick to your goals.

📊 Transparent Tracking
See force-close attempts and accessibility changes. Full transparency about what's monitored.

💚 Built for You
Created for personal digital wellbeing, not parental control. You're in charge of your own mindfulness journey.

WHY DIGITAL MINDFULNESS?

Modern smartphones are designed to be addictive. Digital Mindfulness gives you the tools to reclaim your time and attention. Perfect for:

• Reducing late-night phone use
• Improving sleep quality
• Increasing productivity
• Better work-life balance
• Mindful living

REQUIREMENTS

• Android 5.0+ (API 21+)
• Accessibility service permission (for blocking)
• Notification permission (Android 13+)

PRIVACY

• All data stored locally on your device
• No account required
• No personal data collected
• No ads, no trackers
• Open source

SUPPORT

Questions? Email: [YOUR_EMAIL]
GitHub: [YOUR_GITHUB]

Start your mindful journey today! 🌟
```

---

## Categorization

**Category:** Productivity

**Tags (5 max):**
- digital wellbeing
- mindfulness
- screen time
- focus
- productivity

**Content Rating:** Everyone (likely)

---

## Contact & Policy

**Developer Email (visible to users):**
```
[YOUR_EMAIL@domain.com]
```

**Website (optional):**
```
[YOUR_WEBSITE or GitHub]
```

**Privacy Policy URL (REQUIRED):**
```
[YOUR_PRIVACY_POLICY_URL]
# Example: https://yourusername.github.io/digital-mindfulness/privacy
```

---

## Version Info

**Initial Version:**
```
Version Name: 1.0.0
Version Code: 1
```

**Release Notes (What's New):**
```
🎉 Welcome to Digital Mindfulness v1.0!

✨ Features:
• Scheduled app blocking with custom time windows
• Beautiful mindful design with purple theme
• Robust enforcement that survives reboots
• Smart notifications during restrictions
• Settings lock for accountability
• Anti-tamper detection

Start your mindfulness journey today! 🧘
```

---

## Data Safety (Answer these in Play Console)

**Does your app collect or share user data?**
- ❌ No

**Why does your app need these permissions?**

1. **BIND_ACCESSIBILITY_SERVICE**
   - Purpose: Detect app launches to enforce restrictions
   - Note: Required for core functionality

2. **POST_NOTIFICATIONS (Android 13+)**
   - Purpose: Show enforcement status
   - Note: User can see restriction times

3. **RECEIVE_BOOT_COMPLETED**
   - Purpose: Restore enforcement after device restart
   - Note: Ensures continuous protection

4. **FOREGROUND_SERVICE**
   - Purpose: Keep enforcement running
   - Note: Shows persistent notification

5. **SCHEDULE_EXACT_ALARM**
   - Purpose: Start/end restrictions at exact times
   - Note: Ensures accurate time-based blocking

**Data stored locally:**
- Restriction times
- Allowed apps list
- Force-close attempt counts
- All data stays on device

**No third-party services:**
- No analytics
- No crash reporting
- No ads
- No cloud storage

---

## Screenshots Needed

Capture these screens:

1. **Home Screen** - Show enforcement toggle, purple theme, stats
2. **Time Configuration** - Show time pickers with sample times
3. **Allowed Apps** - Show app list with some selected
4. **Active Notification** - Show "🧘 Mindful Time Active" notification
5. **Blocking Screen** - Show "Mindful Moment" with purple design
6. **Settings Lock** - Show toast message "Cannot modify during restriction"
7. **Accessibility Setup** - Show permission grant screen (optional)
8. **Success State** - Show home screen with enforcement enabled

**Screenshot specs:**
- Minimum 2 screenshots required
- Recommended 4-8 screenshots
- Portrait orientation: 16:9 or taller
- PNG or JPEG format
- Minimum dimension: 320px
- Maximum dimension: 3840px

**Tips:**
- Use actual device screenshots (looks more authentic)
- Ensure purple theme is visible
- Show "Digital Mindfulness" branding
- Keep UI in light mode (easier to see)
- Don't include device frames (Play Console adds them)

---

## Feature Graphic (REQUIRED)

**Dimensions:** 1024 x 500 pixels
**Format:** PNG or JPEG

**Design suggestions:**
- Purple gradient background (#6B4FA0 to #8B75B8)
- Large 🧘 meditation emoji or icon (center)
- "Digital Mindfulness" text (white, bold)
- Tagline: "Focus on What Matters" (smaller text)
- Minimalist, clean design
- No transparency

**Tools:**
- Canva (free, easy): https://www.canva.com/
- Figma (free, professional): https://www.figma.com/
- Adobe Express (free): https://www.adobe.com/express/

---

## App Icon (512x512)

You should already have this from development, but ensure:
- 512 x 512 pixels exactly
- PNG format with transparency
- 32-bit color
- Purple theme consistent with app
- Meditation/mindfulness theme
- Recognizable at small sizes

**Test your icon:**
- View at 48x48 (how it appears on phone)
- View at 96x96 (notification size)
- Ensure it's distinguishable from other apps

---

## Target Audience

**Age Rating:**
- Select: Everyone / Teen (13+)
- Reason: No mature content, suitable for all ages

**Is your app designed for children under 13?**
- ❌ No

---

## Content Declaration Checklist

Before submission, complete these sections in Play Console:

- [ ] **Privacy Policy** - URL published and accessible
- [ ] **Content Rating** - Questionnaire completed
- [ ] **Target Audience** - Age group selected
- [ ] **Data Safety** - All questions answered
- [ ] **News App** - Declared (select No)
- [ ] **COVID-19 Tracing** - Declared (select No)
- [ ] **Advertising ID** - Declared (select No)
- [ ] **Government App** - Declared (select No)

---

## Launch Checklist

### Pre-Submission
- [ ] All features working on test device
- [ ] No crashes or critical bugs
- [ ] Accessibility permission works
- [ ] Blocking works correctly
- [ ] Persistence tested (force-close, reboot)
- [ ] Notifications display properly
- [ ] Settings lock functions

### Build
- [ ] Keystore created and backed up
- [ ] `key.properties` configured
- [ ] Version number set (1.0.0+1)
- [ ] Release AAB built successfully
- [ ] Release AAB tested on device

### Assets
- [ ] App icon 512x512 ready
- [ ] Feature graphic 1024x500 ready
- [ ] 2-8 screenshots captured
- [ ] All images optimized

### Play Console
- [ ] Developer account registered ($25 paid)
- [ ] App created in console
- [ ] Store listing completed
- [ ] Privacy policy published
- [ ] All content declarations done
- [ ] Countries selected
- [ ] Release rollout configured

### Final
- [ ] Pre-launch report reviewed (if using)
- [ ] All sections have green checkmarks
- [ ] Ready to submit!

---

## Post-Launch To-Do

**First 24 Hours:**
- [ ] Verify app is live on Play Store
- [ ] Search for app by name (test discoverability)
- [ ] Install on test device from Play Store
- [ ] Share link with friends/family for initial reviews

**First Week:**
- [ ] Monitor crash reports in Play Console
- [ ] Respond to all user reviews
- [ ] Watch install/uninstall metrics
- [ ] Fix any critical bugs immediately

**First Month:**
- [ ] Analyze user feedback
- [ ] Plan version 1.1 with improvements
- [ ] Promote app on social media
- [ ] Encourage satisfied users to leave reviews

---

## Marketing Copy (Optional)

**One-Liner:**
> "Take back your time with mindful app restrictions."

**Tweets/Social:**
> Just launched Digital Mindfulness - a free Android app to help reduce screen time through scheduled app blocking. No tricks, just gentle enforcement. Check it out! 🧘 #digitalwellbeing #mindfulness

**Reddit Post Title:**
> [Dev] I built a free Android app to enforce mindful phone usage with scheduled app blocking

**Email Signature:**
```
Check out Digital Mindfulness - Take control of your screen time
[Play Store Link]
```

---

## Support Resources

**If stuck on Play Console:**
- Help Center: https://support.google.com/googleplay/android-developer
- Community: https://www.reddit.com/r/androiddev
- Live Chat: Available in Play Console (if eligible)

**If app rejected:**
- Don't panic! Most rejections are fixable
- Read rejection reason carefully
- Common issues: Missing privacy policy, unclear permissions
- Fix and resubmit (usually faster review)

---

**Ready to publish? Follow DEPLOYMENT_GUIDE.md step-by-step!**

Good luck! 🚀
