# CS2 Server Platform - Development Roadmap

**Vision**: Build an on-demand CS2 training server platform similar to Refrag.gg, leveraging Terraform automation and AWS spot instances for cost-effective modded game servers.

**Current Status**: ✅ Base infrastructure complete with spot instance optimization (~$12/month vs Refrag's $7/month revenue model)

---

## Phase 1: Custom Game Modes (Weeks 1-2)

### Goal
Add CounterStrikeSharp plugin framework and implement 3-5 popular training modes

### Tasks
- [x] Terraform infrastructure with spot instances
- [ ] Install CounterStrikeSharp plugin framework
- [ ] Add Retake plugin (post-plant scenarios)
- [ ] Add Practice plugin (.noclip, .god, utility commands)
- [ ] Add Deathmatch/FFA plugin
- [ ] Create `plugin_mode` variable in Terraform
- [ ] Automate plugin installation in user_data.sh.tftpl
- [ ] Test each game mode manually

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

## Phase 3: Web Dashboard (Weeks 5-8)

### Goal
Build web interface for starting/stopping servers on-demand (Refrag-style)

### Components

#### 3.1 Backend API (Flask/FastAPI)
```python
# Endpoints
POST   /api/servers/start       # Start new server
POST   /api/servers/{id}/stop   # Stop server
GET    /api/servers/{id}        # Server status
GET    /api/servers             # List user's servers
GET    /api/servers/{id}/connect # Get connect info
```

#### 3.2 Terraform Automation
- Wrap Terraform CLI in Python
- Dynamic workspace creation per user/server
- Auto-cleanup on stop
- Output parsing for IP/connect string

#### 3.3 Frontend (React/Next.js)
- Login/registration
- Server creation form (mode, region, map)
- Active servers list
- Connect button (steam:// protocol)
- Usage tracking

### Tasks
- [ ] Set up Flask/FastAPI backend
- [ ] Create Terraform wrapper module
- [ ] Build authentication system (JWT)
- [ ] Create React frontend
- [ ] Implement server start/stop flow
- [ ] Add real-time status updates
- [ ] Deploy web app to AWS/Vercel

### Success Criteria
- Click button → server starts in 2 min
- Auto-shutdown after 30 min idle
- Users can see connection info
- Basic billing tracking

---

## Phase 4: Billing & Payments (Weeks 9-10)

### Goal
Implement Stripe subscription and usage-based billing

### Pricing Strategy
```
Tier 1 - Basic: $7/month
- 20 hours server time
- 3 game modes (retake, deathmatch, practice)
- US regions only

Tier 2 - Pro: $15/month
- 60 hours server time
- All game modes
- All regions
- Priority support

Tier 3 - Team: $50/month
- 200 hours server time
- 5 simultaneous servers
- Custom configs
- Team management
```

### Tasks
- [ ] Integrate Stripe API
- [ ] Create subscription plans
- [ ] Track server usage hours per user
- [ ] Implement usage limits
- [ ] Add payment history page
- [ ] Handle failed payments
- [ ] Add monthly billing cycle

### Success Criteria
- Users can sign up and pay
- Usage tracked accurately
- Auto-stop servers when out of credits
- Monthly invoices sent

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

## Phase 6: Scale & Optimize (Weeks 15-16)

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

## Phase 7: Go-to-Market (Weeks 17-20)

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
- Platform: $200/mo (web hosting, database, monitoring)
- Marketing: $500/mo
Total costs: $1,200/mo

Net profit (month 12): $5,800/mo
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

### vs Commercial Hosts
- ✅ Specialized for training (not just servers)
- ✅ Modern UI/UX
- ✅ One-click deployment
- ✅ Usage-based pricing (pay for what you use)

### vs Self-Hosting
- ✅ No technical knowledge required
- ✅ Multi-region support
- ✅ Professional support
- ✅ Managed updates

---

## Technical Stack

### Infrastructure
- **Cloud**: AWS (EC2, VPC, Security Groups, EBS)
- **IaC**: Terraform
- **Container**: Docker (joedwards32/cs2)
- **Cost Optimization**: Spot instances

### Backend
- **API**: Python FastAPI or Flask
- **Database**: PostgreSQL (user data, usage tracking)
- **Queue**: Redis (server job queue)
- **Storage**: S3 (demos, configs)
- **Auth**: JWT tokens

### Frontend
- **Framework**: React + Next.js
- **Styling**: Tailwind CSS
- **State**: React Query
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

1. ✅ Add spot instance support (DONE)
2. ✅ Commit and push changes (DONE)
3. [ ] Deploy test server with spot instance
4. [ ] SSH to server and manually install CounterStrikeSharp
5. [ ] Install CS2-Retakes plugin
6. [ ] Test retake mode with 2-3 people
7. [ ] Document installation steps
8. [ ] Automate plugin installation in Terraform

---

## Learning Outcomes

**DevOps Skills:**
- Terraform automation at scale
- Multi-region cloud deployment
- Cost optimization strategies
- Infrastructure monitoring

**Backend Skills:**
- RESTful API design
- Payment integration
- Usage tracking/metering
- Job queue management

**Product Skills:**
- SaaS business model
- User acquisition
- Pricing strategy
- Customer support

**Gaming Industry:**
- CS2 server administration
- Plugin development ecosystem
- Gaming community dynamics
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

**Status**: Phase 1 in progress
**Last Updated**: February 11, 2026
**Next Milestone**: CounterStrikeSharp + Retakes plugin working
