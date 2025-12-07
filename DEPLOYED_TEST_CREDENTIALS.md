# Deployed Mattermost Test Credentials

**Production URL:** http://35.88.175.112

## Test Users

All test users have the same password: `TestPass123!`

| Username | Email | Password | Full Name |
|----------|-------|----------|-----------|
| alice | alice@test.com | TestPass123! | Alice Johnson |
| bob | bob@test.com | TestPass123! | Bob Smith |
| charlie | charlie@test.com | TestPass123! | Charlie Brown |

## Test Channels

The following test channels have been created in the **Kerberos Prime** team:

| Channel Name | Display Name | Messages | Thread Replies |
|--------------|--------------|----------|----------------|
| major-project | Major Project | 100 | 50 |
| war-room | War Room | 100 | 50 |
| critical-bug | Critical Bug | 100 | 50 |

## Message Distribution

Messages are distributed across different time ranges:
- **Last hour:** 15 messages
- **Last 24 hours:** 25 messages
- **Last 7 days:** 30 messages
- **Last 30 days:** 30 messages

Each channel also has 50 thread replies to the first message, distributed over the last 2 hours.

## Channel Topics

- **Major Project:** Software development project discussions (sprints, PRs, architecture)
- **War Room:** Production deployment coordination and monitoring
- **Critical Bug:** Bug investigation and resolution (payment processing issues)

## Quick Access

1. Go to http://35.88.175.112
2. Login with any of the test users above (password: `TestPass123!`)
3. Join the "Kerberos Prime" team if prompted
4. Navigate to any of the test channels to see messages

**Alternative:** If the test user passwords don't work, you can log in with your admin account (yibin) which has access to all channels.

## Notes

- All test users are members of the Kerberos Prime team
- All test users are members of all 3 test channels
- The admin user (yibin) has also been added to all test channels
- Messages are from realistic conversation scenarios
- Thread replies demonstrate the threading functionality
