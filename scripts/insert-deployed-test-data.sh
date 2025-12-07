#!/bin/bash

# Insert test data into deployed Mattermost PostgreSQL database
# Creates test users, channels, 100 messages + 50 thread replies per channel

set -e

# Configuration
TEAM_ID="1tnct5ma97rtmcynqnmpbf69gh"  # kerberos-prime team
PASSWORD_HASH='$pbkdf2$f=SHA256,w=600000,l=32$E30peQJ71oBG0wpAP2FS8w$D2aQX1wIgV9syNwi7IbR5Ol1TiB61dZdtB9fyrLACkc'

# Current timestamp in milliseconds
NOW=$(date +%s)000

# Generate a random 26-char ID (alphanumeric lowercase)
generate_id() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 26
}

# Pre-generate user IDs
ALICE_ID=$(generate_id)
BOB_ID=$(generate_id)
CHARLIE_ID=$(generate_id)

# Pre-generate channel IDs
MAJOR_PROJECT_ID=$(generate_id)
WAR_ROOM_ID=$(generate_id)
CRITICAL_BUG_ID=$(generate_id)

echo "Generated IDs:"
echo "  Alice: $ALICE_ID"
echo "  Bob: $BOB_ID"
echo "  Charlie: $CHARLIE_ID"
echo "  Major Project: $MAJOR_PROJECT_ID"
echo "  War Room: $WAR_ROOM_ID"
echo "  Critical Bug: $CRITICAL_BUG_ID"

# Message templates for each channel
PROJECT_MESSAGES=(
    "Hey team, we just got approval for Project Phoenix!"
    "Awesome news! What's the timeline looking like?"
    "Executive wants it launched Q1 2026."
    "That's tight. Let me start pulling together the technical requirements."
    "I'll work on the project charter and stakeholder analysis."
    "Should we schedule a kickoff meeting for next week?"
    "Good idea. How about Tuesday at 2 PM?"
    "Works for me!"
    "I'll send out the calendar invite."
    "Can we also invite the product team?"
    "Just finished the architecture document."
    "Looking at the doc now. The microservices approach looks solid."
    "I have some concerns about the database schema."
    "Sure, what's on your mind?"
    "The user_preferences table seems over-normalized."
    "Good catch. Let me revise that section."
    "Should we use PostgreSQL or stick with MySQL?"
    "I'd recommend PostgreSQL for the JSON support."
    "Agreed. PostgreSQL it is."
    "I'll update the infrastructure requirements."
    "The frontend team is asking about the API contracts."
    "I'm working on the OpenAPI spec."
    "Perfect. That will unblock them."
    "Sprint planning is tomorrow. Everyone ready?"
    "I need to finish estimating my stories first."
    "Same here. Give me a couple more hours."
    "No rush, we have until tomorrow morning."
    "The stakeholder demo is scheduled for Friday."
    "We should do a dry run Thursday afternoon."
    "Good idea. I'll book a conference room."
    "Morning team! Quick sync before standup?"
    "Sure, what's up?"
    "I found a potential issue with the auth flow."
    "Can you elaborate?"
    "The OAuth callback isn't handling edge cases properly."
    "I can take a look at that after my current task."
    "Thanks! The code is in the auth-service repo."
    "Got it. I'll review it this afternoon."
    "Also, the QA team wants to start testing next week."
    "We should have the staging environment ready by then."
    "I'm working on the CI/CD pipeline today."
    "Need any help with that?"
    "Actually yes, can you help with the Docker configs?"
    "Sure thing. I'll ping you after lunch."
    "The product owner wants to add a new feature to the scope."
    "Ugh, scope creep already?"
    "Let me push back and see if it can wait for v1.1."
    "Good call. We need to protect our timeline."
    "Update: They agreed to defer it. Crisis averted!"
    "Nice work!"
    "Just pushed the latest changes to the feature branch."
    "Running the test suite now."
    "Getting a few flaky tests. Investigating..."
    "The payment integration tests are timing out."
    "Might be the sandbox API being slow."
    "Let me check the logs."
    "Found it - there was a network retry issue."
    "Fix is on the way."
    "Great, let me know when it's ready for review."
    "PR is up! Can someone review?"
    "Looking at it now."
    "The code looks good. Just a few minor comments."
    "Addressing them now..."
    "All done! Ready for another look."
    "Approved!"
    "Let me start the deployment to staging."
    "Staging looks good. Running smoke tests."
    "All tests passing. Ready for production?"
    "Let's wait for the team lead to sign off."
    "Team lead approved. Deploying now."
    "Deployment successful!"
    "Great work everyone!"
    "Time for a coffee break."
    "I'll bring donuts tomorrow to celebrate."
    "Now we're talking!"
    "Don't forget to update the release notes."
    "Already on it."
    "The customer is going to love this feature."
    "Marketing wants to do a blog post about it."
    "I can help with the technical content."
    "That would be great. I'll set up a meeting."
    "We should also update the API documentation."
    "I'll handle that today."
    "The load testing results look promising."
    "P99 latency is under 100ms."
    "That's well within our SLO."
    "Security review is scheduled for next week."
    "I'll prepare the threat model document."
    "Don't forget about the penetration test results."
    "Those are already in the security folder."
    "Perfect. We're in good shape."
    "Let's discuss the monitoring strategy."
    "I suggest we use Prometheus and Grafana."
    "Agreed. I'll set up the dashboards."
    "Don't forget alerting for critical metrics."
    "Already configured. PagerDuty integration is live."
    "The on-call rotation is updated too."
    "Great teamwork everyone!"
    "See you all at the retrospective."
    "Looking forward to it!"
)

WAR_ROOM_MESSAGES=(
    "Heads up: v2.5.0 deployment scheduled for today."
    "That's a Saturday. Are we sure about weekend deployment?"
    "Product wants it live before Monday for the marketing push."
    "Okay, let's start planning the runbook."
    "I'll set up the monitoring dashboards."
    "We should do a practice run on staging first."
    "Agreed. Let's target staging deployment now."
    "I'll coordinate with the database team."
    "Don't forget to notify the support team."
    "Already on it. They'll have extra staff on standby."
    "Staging deployment completed successfully!"
    "Nice! Any issues to report?"
    "Minor hiccup with the cache invalidation. Fixed now."
    "Good catch. Is the fix in the release branch?"
    "Yes, cherry-picked it this morning."
    "QA sign-off completed. We're go for production."
    "Excellent! Let's do the final checklist review."
    "Database backups: Done"
    "Rollback scripts tested: Done"
    "Monitoring alerts configured: Done"
    "On-call rotation confirmed: Done"
    "Load balancer configuration updated: Done"
    "CDN cache rules verified: Done"
    "External dependencies checked: Done"
    "Communication templates ready: Done"
    "We're looking good. Thanks everyone!"
    "Should we do one more staging run?"
    "I think we're solid, but couldn't hurt."
    "Running it now. Will report back soon."
    "Staging re-run successful. Zero issues!"
    "T-24 hours. Final status check."
    "Infrastructure team is ready."
    "Database team standing by."
    "Frontend team has approved the build."
    "Backend services are all green."
    "External API partners have been notified."
    "Support team briefed on new features."
    "Marketing has the blog post ready to publish."
    "Legal approved the updated ToS."
    "Security scan completed. No critical issues."
    "Everyone get some rest tonight!"
    "See you all at 6 AM!"
    "I'll bring donuts."
    "Now we're talking!"
    "What flavor?"
    "Assorted. Can't please everyone otherwise."
    "Smart choice."
    "Setting my alarm for 5:30 AM..."
    "Same. This is going to be a long day."
    "But worth it when we see those metrics spike!"
    "Good morning everyone! War room is now active."
    "I'm here. Coffee in hand."
    "Present and accounted for."
    "Starting the deployment sequence now."
    "Deployment pod 1 of 4 complete."
    "Monitoring looks stable so far."
    "Pod 2 complete. Moving to pod 3."
    "Seeing a slight latency increase. Within expected range."
    "Pod 3 complete. Final pod coming up."
    "All pods deployed! Starting health checks."
    "Health checks passing on all instances."
    "Running smoke tests now..."
    "API endpoints responding correctly."
    "Frontend loading properly."
    "DEPLOYMENT SUCCESSFUL!"
    "Amazing work everyone!"
    "Current response time: 145ms - within target."
    "Error rate: 0.02% - excellent."
    "CPU usage: 45% - normal range."
    "Memory usage: 68% - normal range."
    "Database connections: 230/500 - healthy."
    "Cache hit rate: 94% - excellent."
    "First user reports coming in. All positive!"
    "Seeing about 15% increase in traffic."
    "Expected due to the marketing campaign."
    "Should we scale up proactively?"
    "Let's wait. Auto-scaling is configured."
    "Good call. Don't want to overspend."
    "Traffic spike incoming! Marketing email blast sent."
    "Watching the metrics closely..."
    "Response time increased to 180ms. Still within limits."
    "Auto-scaler adding two more instances."
    "Smart. The system is handling it well."
    "New instances are up and serving traffic."
    "Response time back to 140ms. Nice!"
    "Error rate still at 0.02%. Rock solid."
    "Great job everyone. Textbook deployment."
    "Couldn't have done it without the prep work."
    "The staging runs really paid off."
    "We should document this process."
    "Already started a retro doc."
    "Include the timing breakdown if you can."
    "Will do. Total deployment time: 47 minutes."
    "That's our fastest major release yet!"
    "Previous record was 1 hour 15 minutes."
    "Almost 40% improvement!"
    "Let's target 30 minutes for the next one."
    "Challenge accepted!"
)

BUG_MESSAGES=(
    "CRITICAL: Customer reporting payment failures!"
    "How many customers affected?"
    "Checking... looks like about 50 transactions in the last hour."
    "That's significant. What's the error message?"
    "They're seeing 'Transaction could not be processed.'"
    "Checking the payment service logs now."
    "Found it! Stripe webhook timeout errors."
    "Is it on their end or ours?"
    "Looks like ours. The handler is taking too long."
    "Let me check the code..."
    "Had some time to dig deeper into BUG-4521."
    "What did you find?"
    "The payment webhook handler is making synchronous DB calls."
    "That explains the timeouts under load."
    "We need to make it async."
    "I can work on that. What's the priority?"
    "High. Finance is getting daily reports now."
    "Okay, I'll start on a fix today."
    "Thanks! Let me know if you need any context."
    "Actually, can you explain the current flow?"
    "Sure. Webhook comes in, validate, update order, send email, respond."
    "That's a lot of synchronous work!"
    "Yeah, the email sending is the biggest culprit."
    "We should queue that for sure."
    "Agreed. I'll add SQS integration."
    "Good plan. Let me help with the infrastructure."
    "Perfect. I'll handle the code, you handle the queue setup."
    "Deal! Let's sync up tomorrow."
    "Sounds good. Talk then."
    "Oh, and document everything in the ticket please."
    "Progress update: SQS queue is set up and tested."
    "Great! I'm almost done with the code changes."
    "How are you handling retries?"
    "Exponential backoff with 3 max attempts."
    "Perfect. That should handle transient failures."
    "The dead letter queue is also configured."
    "Smart. We can investigate failed messages there."
    "Exactly. Want to review the PR?"
    "Sure, send it over."
    "PR #892 is up."
    "Looking at it now..."
    "The queue consumer looks good."
    "Thanks! Any concerns?"
    "Minor: add more logging in the error handler."
    "Good catch. Adding that now."
    "Also, should we add metrics for queue depth?"
    "Yes! Great idea. I'll add CloudWatch metrics."
    "This is coming together nicely."
    "We should be ready for staging deploy tomorrow."
    "I'll prepare the deployment plan."
    "Staging deployment complete! Starting tests."
    "Running the load test suite now."
    "Simulating 1000 concurrent payments..."
    "All transactions processed successfully!"
    "What about the response times?"
    "P99 latency: 180ms. Down from 2.5 seconds!"
    "That's a massive improvement!"
    "No timeout errors in the logs."
    "The queue is draining properly too."
    "Email delivery is now decoupled. Nice!"
    "Ready for production?"
    "Let's do one more test cycle to be safe."
    "Good call. Better safe than sorry."
    "Running edge case tests..."
    "All passing! We're go for prod!"
    "Deploying to production now."
    "First pod updated successfully."
    "Monitoring the payment metrics..."
    "All transactions going through!"
    "No errors in the past 10 minutes."
    "This fix is working beautifully."
    "Finance team is already celebrating."
    "The ticket can finally be closed!"
    "Let's update the incident report."
    "I'll write the postmortem doc."
    "Include the root cause analysis please."
    "Already on it. Adding timeline too."
    "Don't forget the action items."
    "We need to add more monitoring for this."
    "Agreed. Creating follow-up tickets now."
    "We should also review other webhook handlers."
    "Good point. Adding that to the backlog."
    "The customer support team is happy."
    "Ticket volume has dropped significantly."
    "Great outcome for everyone."
    "Let's schedule a quick retrospective."
    "How about tomorrow at 2 PM?"
    "Works for me."
    "I'll send the calendar invite."
    "Include the entire payments team."
    "Will do."
    "This was a great team effort."
    "Everyone stepped up when it mattered."
    "Definitely learned some valuable lessons."
    "The async pattern should be our standard."
    "I'll update the engineering guidelines."
    "Documentation is key for the future."
    "Closing this channel for now."
    "Great work everyone!"
)

# Thread message templates
PROJECT_THREAD_MESSAGES=(
    "Let's discuss the API rate limiting strategy here."
    "I think we should implement a token bucket algorithm."
    "What rate limits are we thinking? 100 req/min per user?"
    "That seems reasonable for the initial launch."
    "We should also consider different tiers for premium users."
    "Good point. Maybe 500 req/min for premium?"
    "Let me check what competitors are offering..."
    "Found some benchmarks. Most offer 100-1000 depending on tier."
    "Let's go with 100/300/1000 for free/pro/enterprise."
    "Sounds good. I'll document this in the API spec."
    "Should we add rate limit headers to responses?"
    "Definitely. X-RateLimit-Remaining and X-RateLimit-Reset."
    "I'll implement that in the API gateway."
    "Don't forget to add it to the documentation too."
    "Already on it!"
    "What happens when users hit the limit?"
    "We return 429 Too Many Requests with a Retry-After header."
    "Should we also send an email notification?"
    "That might be too noisy. Maybe just for repeated violations."
    "Agreed. Let's add that to the backlog for v1.1."
    "I'm also thinking about implementing request queuing."
    "That would help with burst traffic."
    "We could use Redis for the queue."
    "Already have Redis in the stack, so that works."
    "Let me prototype this over the weekend."
    "Don't burn yourself out!"
    "It's fine, I'm curious about the implementation."
    "Just pushed a rough draft of the rate limiter."
    "Wow, that was fast!"
    "It's not production ready yet, but the core logic is there."
    "I'll review it on Monday."
    "Thanks! Appreciate any feedback."
    "This is looking really solid."
    "Minor suggestion: add circuit breaker pattern too."
    "Great idea! Adding it to the TODO."
    "Should we also log rate limit violations?"
    "Yes, that would help with security monitoring."
    "I'll add integration with our logging pipeline."
    "Perfect. This thread has been super productive."
    "Agreed! Let's summarize the decisions in Confluence."
    "I'll create the page now."
    "Don't forget to link it to the project wiki."
    "Done! Here's the link to the doc."
    "Looks great. Let's present this at the next team meeting."
    "I can do a quick demo of the implementation."
    "Perfect. Meeting is Thursday at 10 AM."
    "Added to my calendar."
    "Same here. Thanks everyone!"
    "Great collaboration!"
    "See you all Thursday!"
)

WAR_ROOM_THREAD_MESSAGES=(
    "Post-deployment metrics thread. Let's track everything here."
    "Current response time: 145ms (target: under 200ms)"
    "Error rate: 0.02% (target: under 0.1%)"
    "CPU usage: 45% (normal range)"
    "Memory usage: 68% (normal range)"
    "Database connections: 230/500"
    "Cache hit rate: 94%"
    "First user reports coming in. All positive so far!"
    "Seeing about 15% increase in traffic compared to last Saturday."
    "Expected due to the marketing campaign."
    "Should we scale up proactively?"
    "Let's wait and see. Auto-scaling is configured."
    "Good call. Don't want to overspend on infrastructure."
    "Traffic spike incoming! Marketing just sent the email blast."
    "Watching the metrics closely..."
    "Response time increased to 180ms. Still within limits."
    "Auto-scaler adding two more instances."
    "Smart. The system is handling it well."
    "New instances are up and serving traffic."
    "Response time back to 140ms. Nice!"
    "Error rate still at 0.02%. Rock solid."
    "Great job everyone. This is a textbook deployment."
    "Couldn't have done it without the prep work."
    "The staging runs really paid off."
    "We should document this process for future deployments."
    "Already started a retro doc."
    "Include the timing breakdown if you can."
    "Will do. Total deployment time: 47 minutes."
    "That's our fastest major release yet!"
    "Previous record was 1 hour 15 minutes."
    "Almost 40% improvement!"
    "Let's target 30 minutes for the next one."
    "Challenge accepted!"
    "Marketing is reporting great engagement numbers."
    "Support tickets are minimal. Just a few password resets."
    "Nothing deployment-related. Perfect."
    "I think we can start winding down the war room."
    "Agreed. Let's monitor for another 2 hours then all-clear."
    "I'll stay on for the first hour."
    "I can cover the second hour."
    "Thanks team. I'll prep the all-clear communication."
    "Should we do a team celebration next week?"
    "Definitely! Pizza party?"
    "I'm in!"
    "Count me in too!"
    "Let's do it. Wednesday lunch?"
    "Works for me!"
    "Perfect. I'll book the big conference room."
    "Great deployment everyone. Get some rest!"
    "Thanks all! Signing off for now."
)

BUG_THREAD_MESSAGES=(
    "Technical deep-dive thread for BUG-4521."
    "Root cause: Synchronous operations blocking webhook response."
    "Stripe expects response within 20 seconds."
    "Our handler was taking 30+ seconds under load."
    "Breaking down the timing:"
    "- Webhook validation: 50ms"
    "- Database update: 200ms"
    "- Inventory check: 300ms"
    "- Email sending: 25-30 seconds!"
    "The email service was the bottleneck."
    "Why is it so slow?"
    "It was doing template rendering synchronously."
    "Plus, SMTP connection for each email."
    "We should batch those connections."
    "That's a separate optimization. Focus on the queue first."
    "Right. One thing at a time."
    "The fix moves email to SQS queue."
    "Webhook just acknowledges and queues work."
    "Response time drops to around 500ms."
    "That gives us plenty of headroom."
    "What about order status visibility?"
    "Orders are still updated synchronously."
    "Email is just notification, can be delayed."
    "Makes sense. Users see immediate confirmation."
    "Email arrives a few seconds later."
    "Tested with 10-second email delay. No complaints."
    "Good. Let's not over-engineer this."
    "Here's the architecture diagram:"
    "Webhook -> Validate -> Update DB -> Queue Email -> Respond"
    "Then SQS Consumer -> Send Email"
    "Clean and simple. I like it."
    "The DLQ catches any failures."
    "We can replay failed emails if needed."
    "Added CloudWatch alarms for queue depth."
    "Alert if depth > 1000 for 5 minutes."
    "That would indicate a consumer issue."
    "Good monitoring! What about metrics?"
    "Tracking: queue depth, processing time, error rate."
    "Dashboard is already set up."
    "Perfect. This is a solid fix."
    "Documentation updated in Confluence."
    "Added runbook for queue issues too."
    "Great work everyone!"
    "This bug has been haunting us for weeks."
    "Finally we can close it!"
    "And we improved the architecture too."
    "Win-win!"
    "Let's merge and deploy."
    "Deployment complete!"
    "BUG-4521 is officially closed."
)

# Function to escape single quotes for SQL
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

# Generate SQL
generate_sql() {
    echo "-- Test data for deployed Mattermost instance"
    echo "-- Generated at: $(date)"
    echo ""

    # Delete existing test users and their data
    echo "-- Clean up any existing test data"
    echo "DELETE FROM posts WHERE userid IN (SELECT id FROM users WHERE username IN ('alice', 'bob', 'charlie'));"
    echo "DELETE FROM channelmembers WHERE userid IN (SELECT id FROM users WHERE username IN ('alice', 'bob', 'charlie'));"
    echo "DELETE FROM teammembers WHERE userid IN (SELECT id FROM users WHERE username IN ('alice', 'bob', 'charlie'));"
    echo "DELETE FROM users WHERE username IN ('alice', 'bob', 'charlie');"
    echo "DELETE FROM channelmembers WHERE channelid IN (SELECT id FROM channels WHERE name IN ('major-project', 'war-room', 'critical-bug'));"
    echo "DELETE FROM posts WHERE channelid IN (SELECT id FROM channels WHERE name IN ('major-project', 'war-room', 'critical-bug'));"
    echo "DELETE FROM channels WHERE name IN ('major-project', 'war-room', 'critical-bug');"
    echo ""

    # Create users
    echo "-- Create test users"
    for user_data in "alice:Alice:Johnson:$ALICE_ID" "bob:Bob:Smith:$BOB_ID" "charlie:Charlie:Brown:$CHARLIE_ID"; do
        IFS=':' read -r username firstname lastname userid <<< "$user_data"
        escaped_password=$(echo "$PASSWORD_HASH" | sed "s/'/''/g")
        echo "INSERT INTO users (id, createat, updateat, deleteat, username, password, authdata, authservice, email, emailverified, nickname, firstname, lastname, roles, allowmarketing, props, notifyprops, lastpasswordupdate, lastpictureupdate, failedattempts, locale, mfaactive, mfasecret, position, timezone, remoteid, lastlogin)"
        echo "VALUES ('$userid', $NOW, $NOW, 0, '$username', '$escaped_password', '', '', '${username}@test.com', true, '$firstname', '$firstname', '$lastname', 'system_user', false, '{}', '{\"channel\":\"true\",\"comments\":\"never\",\"desktop\":\"mention\",\"desktop_sound\":\"true\",\"email\":\"true\",\"first_name\":\"false\",\"mention_keys\":\"\",\"push\":\"mention\",\"push_status\":\"away\"}', $NOW, 0, 0, 'en', false, '', '', '{\"automaticTimezone\":\"\",\"manualTimezone\":\"\",\"useAutomaticTimezone\":\"true\"}', '', 0);"
    done
    echo ""

    # Add users to team
    echo "-- Add users to team"
    for userid in "$ALICE_ID" "$BOB_ID" "$CHARLIE_ID"; do
        echo "INSERT INTO teammembers (teamid, userid, roles, deleteat, schemeuser, schemeadmin, schemeguest, createat)"
        echo "VALUES ('$TEAM_ID', '$userid', '', 0, true, false, false, $NOW);"
    done
    echo ""

    # Create channels
    echo "-- Create test channels"
    for channel_data in "major-project:Major Project:$MAJOR_PROJECT_ID" "war-room:War Room:$WAR_ROOM_ID" "critical-bug:Critical Bug:$CRITICAL_BUG_ID"; do
        IFS=':' read -r name displayname channelid <<< "$channel_data"
        echo "INSERT INTO channels (id, createat, updateat, deleteat, teamid, type, displayname, name, header, purpose, lastpostat, totalmsgcount, extraupdateat, creatorid, schemeid, groupconstrained, shared, totalmsgcountroot, lastrootpostat)"
        echo "VALUES ('$channelid', $NOW, $NOW, 0, '$TEAM_ID', 'O', '$displayname', '$name', '', 'Test channel for AI summarization', $NOW, 0, 0, '$ALICE_ID', NULL, false, false, 0, 0);"
    done
    echo ""

    # Add users to channels
    echo "-- Add users to channels"
    for channelid in "$MAJOR_PROJECT_ID" "$WAR_ROOM_ID" "$CRITICAL_BUG_ID"; do
        for userid in "$ALICE_ID" "$BOB_ID" "$CHARLIE_ID"; do
            echo "INSERT INTO channelmembers (channelid, userid, roles, lastviewedat, msgcount, mentioncount, notifyprops, lastupdateat, schemeuser, schemeadmin, schemeguest, mentioncountemail, mentioncount_root, msg_count_root, urgentmentioncount)"
            echo "VALUES ('$channelid', '$userid', '', $NOW, 0, 0, '{\"desktop\":\"default\",\"email\":\"default\",\"ignore_channel_mentions\":\"default\",\"mark_unread\":\"all\",\"push\":\"default\"}', $NOW, true, false, false, 0, 0, 0, 0);"
        done
    done
    echo ""

    USERS=("$ALICE_ID" "$BOB_ID" "$CHARLIE_ID")

    for channel_name in "major-project" "war-room" "critical-bug"; do
        if [ "$channel_name" = "major-project" ]; then
            CHANNEL_ID="$MAJOR_PROJECT_ID"
            MESSAGES=("${PROJECT_MESSAGES[@]}")
            THREAD_MESSAGES=("${PROJECT_THREAD_MESSAGES[@]}")
        elif [ "$channel_name" = "war-room" ]; then
            CHANNEL_ID="$WAR_ROOM_ID"
            MESSAGES=("${WAR_ROOM_MESSAGES[@]}")
            THREAD_MESSAGES=("${WAR_ROOM_THREAD_MESSAGES[@]}")
        else
            CHANNEL_ID="$CRITICAL_BUG_ID"
            MESSAGES=("${BUG_MESSAGES[@]}")
            THREAD_MESSAGES=("${BUG_THREAD_MESSAGES[@]}")
        fi

        echo "-- Messages for $channel_name"

        # Insert 100 main messages
        FIRST_POST_ID=""
        for i in $(seq 0 99); do
            POST_ID=$(generate_id)
            if [ $i -eq 0 ]; then
                FIRST_POST_ID="$POST_ID"
            fi

            USER_ID="${USERS[$((i % 3))]}"
            MSG_IDX=$((i % ${#MESSAGES[@]}))
            MESSAGE=$(escape_sql "${MESSAGES[$MSG_IDX]}")

            # Distribute timestamps across time ranges
            if [ $i -lt 15 ]; then
                # Last hour (15 messages)
                OFFSET=$((i * 200000))
                TIMESTAMP=$((NOW - OFFSET))
            elif [ $i -lt 40 ]; then
                # Last 24 hours (25 messages)
                OFFSET=$((3600000 + (i - 15) * 3000000))
                TIMESTAMP=$((NOW - OFFSET))
            elif [ $i -lt 70 ]; then
                # Last 7 days (30 messages)
                OFFSET=$((86400000 + (i - 40) * 15000000))
                TIMESTAMP=$((NOW - OFFSET))
            else
                # Last 30 days (30 messages)
                OFFSET=$((604800000 + (i - 70) * 60000000))
                TIMESTAMP=$((NOW - OFFSET))
            fi

            echo "INSERT INTO posts (id, createat, updateat, deleteat, userid, channelid, rootid, originalid, message, type, props, hashtags, filenames, fileids, hasreactions, editat, ispinned, remoteid)"
            echo "VALUES ('$POST_ID', $TIMESTAMP, $TIMESTAMP, 0, '$USER_ID', '$CHANNEL_ID', '', '', '$MESSAGE', '', '{}', '', '[]', '[]', false, 0, false, '');"
        done

        echo ""
        echo "-- Thread messages for $channel_name (replies to first post)"

        # Insert 50 thread messages
        for i in $(seq 0 49); do
            POST_ID=$(generate_id)
            USER_ID="${USERS[$((i % 3))]}"
            MSG_IDX=$((i % ${#THREAD_MESSAGES[@]}))
            MESSAGE=$(escape_sql "${THREAD_MESSAGES[$MSG_IDX]}")

            # Thread messages in last 2 hours
            OFFSET=$((i * 120000))  # 2 minutes apart
            TIMESTAMP=$((NOW - OFFSET))

            echo "INSERT INTO posts (id, createat, updateat, deleteat, userid, channelid, rootid, originalid, message, type, props, hashtags, filenames, fileids, hasreactions, editat, ispinned, remoteid)"
            echo "VALUES ('$POST_ID', $TIMESTAMP, $TIMESTAMP, 0, '$USER_ID', '$CHANNEL_ID', '$FIRST_POST_ID', '', '$MESSAGE', '', '{}', '', '[]', '[]', false, 0, false, '');"
        done

        echo ""
    done

    # Update channel message counts
    echo "-- Update channel message counts"
    echo "UPDATE channels SET totalmsgcount = 150, totalmsgcountroot = 100, lastpostat = $NOW, lastrootpostat = $NOW WHERE id IN ('$MAJOR_PROJECT_ID', '$WAR_ROOM_ID', '$CRITICAL_BUG_ID');"
}

echo ""
echo "Generating SQL and inserting into database..."
SQL=$(generate_sql)
echo "$SQL" | ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "sudo docker exec -i mattermost-postgres-1 psql -U mmuser -d mattermost"

echo ""
echo "Done! Verifying counts..."
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "sudo docker exec mattermost-postgres-1 psql -U mmuser -d mattermost -c \"
SELECT c.displayname,
       COUNT(*) FILTER (WHERE p.rootid = '') as main_messages,
       COUNT(*) FILTER (WHERE p.rootid != '') as thread_replies
FROM channels c
LEFT JOIN posts p ON p.channelid = c.id AND p.deleteat = 0 AND p.type = ''
WHERE c.name IN ('major-project', 'war-room', 'critical-bug')
GROUP BY c.id, c.displayname;\""

echo ""
echo "Test users created:"
echo "  Username: alice, Password: (same as 'test' user)"
echo "  Username: bob, Password: (same as 'test' user)"
echo "  Username: charlie, Password: (same as 'test' user)"
echo ""
echo "Test channels created:"
echo "  - Major Project"
echo "  - War Room"
echo "  - Critical Bug"
