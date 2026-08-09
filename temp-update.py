with open('index.html', 'r') as f:
    content = f.read()

# Find the KtV coming soon card and replace with live version
old_ktv = '''<!-- App 3: Kt/V Calculator (Coming Soon) -->
            <div class="app-card coming-soon">
                <span class="app-badge new">COMING SOON</span>
                <div class="app-icon">📊</div>
                <h3 class="app-title">Kt/V Calculator</h3>
                <p class="app-description">Dialysis adequacy calculator for hemodialysis patients. Single-pool, equilibrated, and standardized Kt/V.</p>
                <ul class="app-features">
                    <li>spKt/V calculation</li>
                    <li>eKt/V (equilibrated)</li>
                    <li>stdKt/V (standardized)</li>
                    <li>URR calculation</li>
                    <li>Trend tracking</li>
                </ul>
                <span class="app-link">Request This App</span>
            </div>'''

new_ktv = '''<!-- App 3: Kt/V Calculator (LIVE) -->
            <div class="app-card">
                <span class="app-badge">LIVE</span>
                <div class="app-icon">📊</div>
                <h3 class="app-title">Kt/V Calculator</h3>
                <p class="app-description">Dialysis adequacy calculator for hemodialysis patients. Single-pool, equilibrated, and standardized Kt/V.</p>
                <ul class="app-features">
                    <li>spKt/V calculation (Daugirdas II)</li>
                    <li>eKt/V (equilibrated)</li>
                    <li>stdKt/V (standardized weekly)</li>
                    <li>URR calculation</li>
                    <li>KDOQI guidelines integrated</li>
                </ul>
                <a href="ktv-calculator.html" class="app-link" target="_blank">Open Kt/V Calculator →</a>
            </div>'''

content = content.replace(old_ktv, new_ktv)

with open('index.html', 'w') as f:
    f.write(content)

print("✓ Landing page updated with KtV Calculator")
