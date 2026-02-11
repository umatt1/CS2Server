# CS2 Server Platform - Development Roadmap

**Vision**: Build an on-demand CS2 training server platform similar to Refrag.gg, leveraging Terraform automation and AWS spot instances for cost-effective modded game servers.

**Current Status**: ✅ Phase 1 CODE COMPLETE - Plugin automation implemented, ready for deployment testing

---

## Phase 1: Custom Game Modes (Weeks 1-2) - ✅ CODE COMPLETE

### Goal
Add CounterStrikeSharp plugin framework and implement 3-5 popular training modes

### Tasks
- [x] Terraform infrastructure with spot instances
- [x] Install CounterStrikeSharp plugin framework
- [x] Add Retake plugin (post-plant scenarios)
- [x] Add Practice plugin (.noclip, .god, utility commands)
- [x] Add Deathmatch/FFA plugin
- [x] Create `plugin_mode` variable in Terraform
- [x] Automate plugin installation in user_data.sh.tftpl
- [ ] Deploy and test each game mode manually
- [ ] Update ENHANCEMENTS.md with plugin usage guide

### Technical Implementation
```hcl
# variables.tf - NEW
variable "plugin_mode" {
  description = "Primary plugin mode for this server"
  type        = string
  default     = "retakes"
  validation {
    condition = contains(["vanilla", "retakes", "executes", "practice", "prefire", "deathmatch"], var.plugin_mode)
    error_message = "Must be valid plugin mode"
  }
}
```

### Plugins to Install
1. **CounterStrikeSharp** - Base framework
   - URL: https://github.com/roflmuffin/CounterStrikeSharp
   
2. **CS2-Retakes** - Most popular training mode
   - URL: https://github.com/b3none/cs2-retakes
   - Features: Post-plant scenarios, respawn, loadouts
   
3. **Practice Mode**
   - URL: https://github.com/lengran/cs2-practice-plugin
   - Features: .noclip, .god, .bot, grenade save/load
   
4. **DeathmatchCore**
   - URL: https://github.com/KillStr3aK/cs2-deathmatch
   - Features: FFA respawn, weapon menu

### Success Criteria
- All 3 plugins load without errors
- Can switch game modes via terraform.tfvars
- Friends can join and test each mode
- Documentation written in ENHANCEMENTS.md

---

## Phase 2: Multi-Server Architecture (Weeks 3-4)

### Goal
Support running multiple servers simultaneously with different game modes

### Tasks
- [ ] Create reusable Terraform module for CS2 servers
- [ ] Support multiple instances on different ports
- [ ] Add port variable and security group rules
- [ ] Test 3 simultaneous servers (retake, practice, competitive)
- [ ] Add server discovery/listing

### Technical Implementation
```hcl
# modules/cs2-server/main.tf
module "retake_server" {
  source = "./modules/cs2-server"
  server_name  = "Retake Server"
  plugin_mode  = "retakes"
  port         = 27015
}

module "practice_server" {
  source = "./modules/cs2-server"
  server_name  = "Practice Server"
  plugin_mode  = "practice"
  port         = 27016
}
```

### Cost Impact
- 3 servers on spot: ~$36/month
- Potential to run 5-10 servers on single t3.large: ~$25/month

### Success Criteria
- 3+ servers running simultaneously
- Each accessible on different ports
- No port conflicts or networking issues

---

## Phase 3: Discord Bot Interface (Weeks 5-6) 🎯 **STRATEGIC PIVOT**

### Goal
Build Discord bot for server management - **60-70% faster than web dashboard**, natural fit for CS2 gaming community

### Why Discord Bot?
- ✅ **Users already there**: CS2 players coordinate on Discord
- ✅ **Built-in auth**: No need to build user system
- ✅ **Real-time notifications**: Webhooks, embeds, DMs
- ✅ **Community features**: Voice channels, roles, permissions
- ✅ **Faster development**: 2 weeks vs 6-8 weeks for web

### Components

#### 3.1 Discord Bot (discord.py or discord.js)
**Slash Commands:**
```python
/server start mode:retakes map:de_dust2 tickrate:128
/server stop server_id:abc123
/server status
/server list
/server connect server_id:abc123
/server usage  # Show remaining hours
```

**Embeds & Notifications:**
- Server starting (with progress updates)
- Server ready (with connect command)
- Server stopped
- Usage warnings (80%, 90%, 100% used)

#### 3.2 Backend Service (Python)
- Terraform wrapper module (reuse from Phase 2)
- SQLite/PostgreSQL for user tracking
- Discord user ID → server mappings
- Usage tracking and limits

#### 3.3 Admin Features
- Server management commands
- User usage reports
- Ban/whitelist users
- Server cleanup tasks

### Tasks
- [ ] Set up Discord bot with discord.py
- [ ] Implement slash command handlers
- [ ] Create Terraform wrapper module
- [ ] Build user/server tracking database
- [ ] Add rich embeds for status updates
- [ ] Implement usage limits
- [ ] Deploy bot to cloud (Railway, Fly.io, EC2)
- [ ] Create Discord server for community

### Success Criteria
- `/server start` → server starts in 2 min
- Rich embeds show server status
- Auto-shutdown after 30 min idle
- Users get DM when server ready
- Usage tracking prevents overages
- Bot responds in <2 seconds

### Example User Flow
```
User: /server start mode:retakes tickrate:128
Bot:  🚀 Starting your CS2 Retakes server...
      Region: us-east-2
      Estimated: 35 minutes
      [Progress bar]
      
      You have 15 hours remaining this month.

[35 minutes later]
Bot (DM): ✅ Your server is ready!
          connect 3.139.108.216:27015
          Mode: Retakes
          [Copy Command] [Stop Server]
```

---

## Phase 4: Monetization via Discord + Patreon/Ko-fi (Weeks 7-8)

### Goal
Monetize through Discord Server Boosts + Patreon/Ko-fi - **simpler than Stripe integration**

### Monetization Strategy

#### Option A: Discord Server Boosts (Easiest)
- **Free Tier**: 5 hours/month, vanilla mode only
- **Server Booster**: Boost our Discord → 20 hours/month, all modes
- **Nitro Boosters**: 40 hours/month, priority support

Discord handles payments, we just check boost status via API.

#### Option B: Patreon/Ko-fi Integration
```
Tier 1 - Basic: $7/month (Patreon)
- 20 hours server time
- 3 game modes (retake, deathmatch, practice)
- US regions only

Tier 2 - Pro: $15/month (Patreon)
- 60 hours server time
- All game modes
- All regions
- Priority support

Tier 3 - Team: $50/month (Patreon)
- 200 hours server time
- 5 simultaneous servers
- Custom configs
- Team management
```

#### Option C: Hybrid (Recommended)
- Free users: 5 hours/month
- Discord Boost: 10 hours/month bonus
- Patreon subscribers: Full tier benefits
- Link Patreon to Discord for auto-role assignment

### Tasks
- [ ] Implement usage tracking per Discord user
- [ ] Add Patreon OAuth integration
- [ ] Create Patreon webhook handler
- [ ] Add Discord role-based limits
- [ ] Build usage dashboard command
- [ ] Implement auto-stop when out of credits
- [ ] Send monthly usage reports via DM
- [ ] Set up Ko-fi as alternative payment

### Success Criteria
- Users link Patreon to Discord seamlessly
- Usage tracked accurately per user
- Auto-stop servers when out of credits
- Monthly usage summaries sent
- Payment status syncs within 5 minutes

---

## Phase 5: Advanced Features (Weeks 11-14)

### 5.1 Additional Game Modes
- [ ] Executes plugin (site execute practice)
- [ ] Prefire plugin (angle training)
- [ ] 1v1 arena plugin
- [ ] Gun game plugin
- [ ] Surf/KZ movement modes

### 5.2 Analytics & Stats
- [ ] Player statistics tracking
- [ ] Demo file storage (S3)
- [ ] Match history
- [ ] Performance metrics (headshot %, K/D)
- [ ] Leaderboards

### 5.3 Workshop Integration
- [ ] Custom map collections
- [ ] Auto-download workshop maps
- [ ] Community map voting

### 5.4 Advanced Practice Tools
- [ ] Grenade lineup viewer (like Refrag)
- [ ] 2D demo replay viewer
- [ ] Warmup routine generator

---

## Phase 6: Optional Web Dashboard (Weeks 15-18)

### Goal
Build web companion to Discord bot (only if needed after validating Discord approach)

### Components
- Simple landing page (marketing)
- Discord OAuth login
- Server management dashboard
- Usage statistics graphs
- Demo file downloads

### Why Optional?
- Discord bot may be sufficient
- Build only if users request web access
- Keep it minimal - Discord is primary interface

### Tasks
- [ ] Build Next.js landing page
- [ ] Add Discord OAuth
- [ ] Create dashboard with server list
- [ ] Add usage graphs
- [ ] Deploy to Vercel

---

## Phase 7: Scale & Optimize (Weeks 19-20)

### Infrastructure Optimization
- [ ] Pre-baked AMI with CS2 pre-installed (saves 30 min)
- [ ] Multi-region deployment
- [ ] Load balancer for multiple servers
- [ ] Auto-scaling based on demand
- [ ] Monitoring with CloudWatch
- [ ] Cost optimization review

### Cost Targets
```
Current: $0.012/hour per server (spot)
Goal: $0.008/hour via:
- Pre-baked AMI (faster start = less waste)
- Reserved instances for base capacity
- Spot fleet for burst capacity
- Aggressive auto-shutdown
```

### Success Criteria
- Server start time < 90 seconds
- 99% uptime for paid users
- Sub-30ms latency in target regions
- Cost per user < $2/month

---

## Phase 8: Go-to-Market (Weeks 21-24)

### Launch Strategy

#### 7.1 Beta Testing
- [ ] Discord server for CS2 community
- [ ] Recruit 20-50 beta testers
- [ ] Free access for feedback
- [ ] Fix critical bugs

#### 7.2 Content Marketing
- [ ] YouTube videos (setup guides)
- [ ] Reddit posts (r/GlobalOffensive, r/learncounters)
- [ ] Twitter/X presence
- [ ] Blog posts about features

#### 7.3 Partnerships
- [ ] CS2 content creators
- [ ] Esports teams
- [ ] CS2 Discord servers
- [ ] Streamer sponsorships

#### 7.4 Launch
- [ ] Public release
- [ ] Press release
- [ ] Product Hunt launch
- [ ] Indie Hackers post

### Success Metrics
- 100 users in month 1
- 500 users by month 3
- $1,000 MRR by month 3
- 20% conversion free → paid

---

## Revenue Projections

### Conservative (Year 1)
```
Month 1:  50 users × $7  = $350/mo
Month 3:  200 users × $7 = $1,400/mo
Month 6:  500 users × $7 = $3,500/mo
Month 12: 1000 users × $7 = $7,000/mo

Costs:
- AWS: ~$500/mo (1000 users × 10 hours × $0.012/hour × 4 servers)
- Platform: $50/mo (Discord bot hosting, database)
- Patreon fees: ~$200/mo (8% + processing)
- Marketing: $500/mo
Total costs: $1,250/mo

Net profit (month 12): $5,750/mo

**Cost savings vs web approach:**
- No web hosting needed
- No frontend development time
- No JWT/auth system to maintain
- Discord handles user management
- Patreon handles payment processing
```

### Optimistic (Year 1)
```
Month 12: 3000 users × $10 avg = $30,000/mo
Costs: ~$4,000/mo
Net profit: $26,000/mo
```

---

## Competitive Advantages

### vs Refrag.gg
- ✅ 70% lower infrastructure costs (spot vs dathost)
- ✅ Open-source Terraform configs (transparency)
- ✅ More AWS regions available
- ✅ Developer-friendly (IaC as product)
- ✅ Lower pricing potential
- ✅ **Discord-native** (users already there)

### vs Commercial Hosts
- ✅ Specialized for training (not just servers)
- ✅ **Discord bot interface** (no new login needed)
- ✅ One-click deployment via slash commands
- ✅ Usage-based pricing (pay for what you use)
- ✅ **Community built-in** (Discord server)

### vs Self-Hosting
- ✅ No technical knowledge required
- ✅ Multi-region support
- ✅ Professional support
- ✅ Managed updates
- ✅ **Discord commands** (no SSH, no CLI)

---

## Technical Stack

### Infrastructure
- **Cloud**: AWS (EC2, VPC, Security Groups, EBS)
- **IaC**: Terraform
- **Container**: Docker (joedwards32/cs2)
- **Cost Optimization**: Spot instances

### Discord Bot
- **Framework**: discord.py (Python) or discord.js (Node.js)
- **Commands**: Slash commands + context menus
- **Database**: SQLite/PostgreSQL (user/server tracking)
- **Hosting**: Railway.app, Fly.io, or AWS EC2
- **Auth**: Discord OAuth (built-in)

### Backend Service
- **API**: Python FastAPI (Terraform wrapper)
- **Job Queue**: Redis (async server operations)
- **Storage**: S3 (demos, logs)
- **Monitoring**: Discord webhooks for alerts

### Web Dashboard (Optional - Phase 6)
- **Framework**: Next.js (minimal landing page)
- **Auth**: Discord OAuth
- **Hosting**: Vercel

### Game Server
- **Base**: CS2 Dedicated Server
- **Framework**: CounterStrikeSharp
- **Plugins**: Community plugins + custom

### Monitoring
- **Metrics**: CloudWatch + Prometheus
- **Logs**: CloudWatch Logs
- **Alerting**: PagerDuty
- **Analytics**: PostHog or Mixpanel

---

## Risk Mitigation

### Technical Risks
- **Spot interruptions**: Use multiple AZs, fallback to on-demand
- **Plugin bugs**: Test thoroughly, have rollback plan
- **Scale issues**: Load test before launch, monitor closely

### Business Risks
- **Low adoption**: Start small, iterate on feedback
- **High costs**: Monitor AWS spend, optimize aggressively
- **Competition**: Focus on niche (training, not general hosting)
- **Valve changes**: Stay updated on CS2 server requirements

### Legal Risks
- **Terms of Service**: Comply with Steam/Valve ToS
- **Privacy**: GDPR compliance for EU users
- **Payment**: PCI compliance via Stripe

---

## Next Actions (This Week)

### Phase 1 - Testing ✅
1. ✅ Add spot instance support (DONE)
2. ✅ Commit and push changes (DONE)
3. ✅ Automate CounterStrikeSharp installation (DONE)
4. ✅ Automate CS2-Retakes plugin installation (DONE)
5. ✅ Create plugin_mode variable in Terraform (DONE)
6. ✅ Update terraform.tfvars.example with plugin_mode (DONE)
7. ✅ **Strategic pivot to Discord Bot** (DONE)
8. [ ] **Deploy test server with plugin_mode="retakes"**
9. [ ] **Verify CounterStrikeSharp loads successfully**
10. [ ] **Test retake mode with 2-3 people**

### Phase 2 - Multi-Server (Next)
11. [ ] Create Terraform module for reusable servers
12. [ ] Test 3 simultaneous servers

### Phase 3 - Discord Bot (After Phase 2)
13. [ ] Set up Discord bot project
14. [ ] Implement `/server start` command
15. [ ] Test bot in private Discord server

---

## Learning Outcomes

**DevOps Skills:**
- Terraform automation at scale
- Multi-region cloud deployment
- Cost optimization strategies
- Infrastructure monitoring

**Backend Skills:**
- Discord bot development (discord.py/discord.js)
- Slash command architecture
- Webhook integrations
- Patreon/Ko-fi API integration
- Usage tracking/metering

**Product Skills:**
- Community-first product design
- Discord-native monetization
- User acquisition in gaming communities
- Lean MVP development
- Strategic pivots based on user behavior

**Gaming Industry:**
- CS2 server administration
- Plugin development ecosystem
- Gaming community dynamics
- Discord server management
- Modded server economics

---

## Success Definition

**6-Month Goal**: 
- 500 paying users @ $7/month = $3,500 MRR
- Profitable (Revenue > Costs)
- Portfolio showcase for DevOps/SaaS skills

**1-Year Goal**:
- 2,000 paying users @ $7/month = $14,000 MRR
- Small team (1-2 contractors)
- Recognized in CS2 training community

**Long-term**:
- Expand to other games (Valorant, Overwatch)
- White-label platform for other hosting providers
- Exit opportunity or sustainable lifestyle business

---

**Status**: Phase 1 CODE COMPLETE - Ready for deployment testing  
**Last Updated**: February 11, 2026  
**Next Milestone**: Deploy and verify retakes plugin functionality
