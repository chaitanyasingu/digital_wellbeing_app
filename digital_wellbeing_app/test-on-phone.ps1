# Digital Mindfulness - Quick Testing Checklist
# Use this to verify all features work correctly on your device

Write-Host "=== Digital Mindfulness - Test Checklist ===" -ForegroundColor Cyan
Write-Host ""

function Test-Feature {
    param($name, $description)
    Write-Host "[ ] $name" -ForegroundColor Yellow
    Write-Host "    → $description" -ForegroundColor Gray
    $result = Read-Host "    Did it work? (y/n)"
    if ($result -eq "y") {
        Write-Host "    ✅ PASS" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    ❌ FAIL" -ForegroundColor Red
        return $false
    }
    Write-Host ""
}

$passed = 0
$failed = 0

Write-Host "=== Phase 1: Basic Functionality ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "App Launch" "Open Digital Mindfulness app. Does it load without crashing?") { $passed++ } else { $failed++ }
if (Test-Feature "Purple Theme" "Is the app purple/mindfulness-themed? See meditation icon 🧘?") { $passed++ } else { $failed++ }
if (Test-Feature "Navigation" "Can you tap between Home, Allowed Apps, Time Config screens?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 2: App Selection ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "Load Apps" "Go to Allowed Apps. Does list of installed apps appear?") { $passed++ } else { $failed++ }
if (Test-Feature "Select Apps" "Tap some apps to select/deselect. Does it toggle?") { $passed++ } else { $failed++ }
if (Test-Feature "Save Apps" "Tap Save. Does it show success message?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 3: Time Configuration ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "Set Start Time" "Go to Time Config. Set restriction start time (e.g., 9:00 PM).") { $passed++ } else { $failed++ }
if (Test-Feature "Set End Time" "Set restriction end time (e.g., 7:00 AM next day).") { $passed++ } else { $failed++ }
if (Test-Feature "Save Times" "Tap Save. Do times appear correctly on home screen?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 4: Enforcement ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "Enable Toggle" "Go to Home. Toggle 'Enforcement Enabled' to ON.") { $passed++ } else { $failed++ }
if (Test-Feature "Accessibility Request" "Did app prompt you to enable accessibility service?") { $passed++ } else { $failed++ }
if (Test-Feature "Grant Permission" "Go to Settings → Accessibility → Digital Mindfulness. Turn ON.") { $passed++ } else { $failed++ }
if (Test-Feature "Notification Appears" "Return to app. See notification 'Digital Mindfulness Active'?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 5: Blocking (Set time to NOW) ===" -ForegroundColor Magenta
Write-Host ""

Write-Host "⚠️  Now set start time to current time to test blocking:" -ForegroundColor Yellow
Write-Host "    1. Go to Time Config"
Write-Host "    2. Set start = current time (e.g., if now is 3:15 PM, set 3:15 PM)"
Write-Host "    3. Set end = 2 hours from now"
Write-Host "    4. Save"
Write-Host ""
Read-Host "Press Enter when ready to continue..."

if (Test-Feature "Active Restriction" "Notification changed to '🧘 Mindful Time Active'?") { $passed++ } else { $failed++ }
if (Test-Feature "Block Screen" "Try opening a NON-allowed app. See 'Mindful Moment' blocking screen?") { $passed++ } else { $failed++ }
if (Test-Feature "Go Back Button" "Tap 'GO BACK' button. Does it return to home screen?") { $passed++ } else { $failed++ }
if (Test-Feature "Allowed Apps Work" "Open an app from your allowed list. Does it open normally?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 6: Persistence ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "Settings Lock" "Try changing times during restriction. Blocked with toast message?") { $passed++ } else { $failed++ }
if (Test-Feature "Force Close" "Force-stop the app via Android Settings. Does enforcement continue?") { $passed++ } else { $failed++ }
if (Test-Feature "Reboot (Optional)" "Restart phone. After boot, is enforcement still active?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Phase 7: Notifications ===" -ForegroundColor Magenta
Write-Host ""

if (Test-Feature "Non-Dismissible" "During restriction, notification cannot be swiped away?") { $passed++ } else { $failed++ }
if (Test-Feature "Auto-Updates" "Wait 60 seconds. Does notification update countdown?") { $passed++ } else { $failed++ }
Write-Host ""

Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Passed: $passed" -ForegroundColor Green
Write-Host "❌ Failed: $failed" -ForegroundColor Red
Write-Host ""

$total = $passed + $failed
$percentage = [math]::Round(($passed / $total) * 100, 1)

if ($percentage -ge 95) {
    Write-Host "🎉 Excellent! Ready for Play Store!" -ForegroundColor Green
} elseif ($percentage -ge 80) {
    Write-Host "👍 Good! Fix failed tests, then ready." -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Needs work. Review failed tests." -ForegroundColor Red
}

Write-Host ""
Write-Host "See DEPLOYMENT_GUIDE.md for troubleshooting." -ForegroundColor Cyan
