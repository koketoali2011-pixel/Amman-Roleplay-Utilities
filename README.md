# Discord Welcome Bot

Welcomes each new server member in a configured channel with an embed and a member emoji beside the server's current member count.

## Setup

1. Install [Node.js](https://nodejs.org/), then run `npm install`.
2. Copy `.env.example` to `.env` and fill in your bot token, Gemini API key, and welcome channel ID. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey); keep both keys private. `MEMBER_EMOJI` is optional; it defaults to `👥` and can also be set to a custom Discord emoji.
3. In the Discord Developer Portal, enable the **Server Members Intent** and **Message Content Intent** for your bot.
4. Invite the bot to your server with permission to view and send messages in the welcome channel, embed links, and manage roles.
5. Start the bot with `npm start`.

## Railway hosting

Railway can build this project from its root [Dockerfile](./Dockerfile). This folder's `.gitignore` excludes `.env` and runtime data files. To publish it, install [GitHub Desktop](https://desktop.github.com/), add this existing project folder as a local repository, and publish it as a **private** repository. Check the changes list before publishing and make sure `.env`, `shift-data.json`, and `erlc-log-state.json` are not included. Then create a Railway project and deploy the GitHub repository. No web port is needed; the bot connects to Discord over an outbound gateway connection.

In the Railway service:

1. Add the variables from `.env.example` in the service's Variables settings. Set secret values there, not in source files. Also set `DATA_DIR=/data`.
2. Create a volume for the bot service and set its mount path to `/data`. The volume preserves shift totals and ER:LC duplicate-log state between deployments. Keep one replica for this volume-backed service.
3. Set `RAILWAY_RUN_UID=0`. Railway mounts volumes as root, and this is needed for the bot to write its JSON state files to `/data`. This runs the container as root on Railway; the Docker image otherwise uses the unprivileged `node` user.
4. Deploy and check the service logs for `Ready! Logged in as ...`.
5. In service Settings, choose the restart policy. Free and Trial plans only allow `On Failure`, limited to 10 restarts; `Always` requires a paid plan.

**Cost note:** Railway's Free plan includes $1 of usage credit per month, and its Trial is a one-time $5 credit for up to 30 days. A bot running continuously uses memory and CPU, so the free allowance may not cover 24/7 operation. Check Railway's current [plans and usage pricing](https://docs.railway.com/pricing/plans) before deploying and set usage limits. See Railway's guides for [Dockerfiles](https://docs.railway.com/builds/dockerfiles), [volumes](https://docs.railway.com/volumes), and [restart policies](https://docs.railway.com/deployments/restart-policy).

## Docker hosting

This project includes a [Dockerfile](./Dockerfile) and [Docker Compose configuration](./docker-compose.yml). To host it on an always-on Linux VM, install Docker Engine and the Docker Compose plugin on the VM, then copy the project files there without `.env` or `node_modules`. Create `.env` on the VM from `.env.example` and fill in the values privately. Start the bot with:

```sh
docker compose up -d --build
```

The Compose service restarts automatically if it exits or the VM reboots. Its named volume keeps shift totals and ER:LC duplicate-log tracking across container rebuilds. To check the logs, run `docker compose logs -f`; to update the bot, copy the changed project files to the VM and run `docker compose up -d --build`. The container runs as an unprivileged user. Keep `.env` private and do not bake secrets into the image.

## Staff commands

The bot registers these staff-only commands in each server it joins:

- `/promote member role reason` assigns the selected rank role, removes the member's other roles listed in `PROMOTION_ROLE_IDS`, and posts a promotion embed in the command channel. The reason is optional. The member is also sent the promotion embed by DM. Access: Management, Staff Supervisor, Ownership, or Founders.
- `/infraction member reason` posts an infraction embed in the command channel and sends the member the infraction embed by DM. It does not assign a punishment role. Access: Management, Staff Supervisor, Ownership, or Founders.
- `/moderation-log roblox-username punishment reason staff-signature` records a Warning, Kick, or BOLO Ban. Warning and Kick logs are posted in the command channel and copied to `1550947148915540099`. BOLO Ban requests are posted with approval buttons in `1561783116849352926` and copied without buttons to both the command channel and `1550947148915540099`; all copies are updated with the final decision. A different member with role `1554204519766818916` must approve or deny it. Approval sends `:ban <username> BOLO Ban approved via Discord` to the ER:LC private server through the API. Denial and expiration do not issue a ban. The API request requires `ERLC_SERVER_KEY` and the server's ER:LC API pack. Access: Staff Team.
- `/moderation-count roblox-username` publicly shows counts for Warning, Kick, and BOLO Ban entries for the resolved Roblox account by scanning the moderation archive in `1550947148915540099`. BOLO totals include denied and expired requests. The bot needs permission to view that channel and read its message history. Access: Staff Team.
- `/perm-log permission server reason duration roblox-username` posts a staff-only in-game permission log in the channel configured by `PERM_LOG_CHANNEL_ID`, with the selected Roadwork / Construction, Hostage, or Special Roleplay permission, Server A or Server B, reason, Roblox username, and relative end time. The Roblox username is verified and links to the player's profile. Enter durations such as `1 hour`, `30 minutes`, or `2 days` (1 minute to 365 days). It records the permission in Discord; it does not change Roblox permissions. Access: Staff Team.
- `/shift-manage start roblox-username` starts your shift; `/shift-manage end` closes it. Both actions are logged in `SHIFT_LOG_CHANNEL_ID`. The start and end log embeds include the Roblox username, staff rank, timestamps, and completed shift length. Shift totals persist in `shift-data.json`. Access: Staff Team (a member with an active shift can still end it if their role is removed).
- `/shift-adjust add|remove member duration reason` adjusts a staff member's recorded shift total. Access: Management, Staff Supervisor, Ownership, or Founders; adjustments are also logged in the shift log channel.
- `/shift-leaderboard` shows the top ten shift totals and the invoking staff member's position. Time from a currently active shift is included. Access: Staff Team.
- `/weekly-quota` publicly shows your progress toward the 3-hour weekly shift quota in a green embed when met and red while below quota. It counts completed shift logs and time accrued on your active shift, based on the shift log channel; the week starts Monday at 00:00 UTC. The bot needs permission to read shift log message history. Access: Staff Team.
- `/shift-online` publicly posts an embed listing currently shifted staff with the Roblox username and rank given at shift start. Rank names are recognized in this order: Management, Staff Supervisor, Internal Affairs, Administration, Moderation. Access: Staff Team.
- `/dc-checks` reads the live ER:LC player list and checks which Roblox players are not matched to a member with the exact `Verified` role. A matching Discord nickname must exactly equal the Roblox username (case-insensitive). **Next** only advances after the current player is in the Discord server with that role; **Skip** records the player as skipped, and **Cancel** ends the check. Only the staff member who started the check can use its buttons. The panel expires after 24 hours and does not survive a bot restart. Access: Staff Team.
- ER:LC API polling automatically posts player joins and leaves, kill logs, and in-game command logs to the channels configured by `ERLC_JOIN_LOG_CHANNEL_ID`, `ERLC_KILL_LOG_CHANNEL_ID`, and `ERLC_COMMAND_LOG_CHANNEL_ID`. Join/leave log usernames link to the Roblox profile when the API supplies a numeric Roblox user ID. Set `ERLC_SERVER_KEY` in `.env` to the private server API key. The bot polls every 30 seconds and stores seen log entries in `erlc-log-state.json` to prevent repeat posts; existing API entries are skipped on first startup.
- `/say message` posts the supplied text as the bot. Access: Ownership or Founders; mentions are disabled to prevent unintended pings.
- `/server-startup message` and `/server-shutdown message` post server status announcement embeds in the command channel. The message is optional. Access: Community Handler.
- `/server-session-vote question` posts a Yes/No vote in the command channel. Members can change their vote; the vote closes after 15 minutes and displays the final totals. Access to start the vote: Community Handler; anyone in the server can vote.
- `/activity-check question minutes [title]` opens a timed activity-check embed in the current channel with a custom duration. Members click the “I’m active” button to confirm they are present; the bot keeps a live count and closes the check automatically when the timer ends. Access: Management, Staff Supervisor, Ownership, or Founders.
- Greetings containing `hi`, `hello`, or common Arabic greetings get a playful, teen-style roast in the greeting's language. For other messages, Gemini answers only when a member mentions the bot or directly replies to one of its AI responses. It answers in 2-3 concise sentences in English or colloquial Jordanian Arabic to match the message, with a short, playful roast about the message; serious or sensitive topics are answered kindly without a roast. The message and, for direct replies, the replied-to bot message are sent to Google's Gemini API; Google's free-tier terms may use submitted content to improve its products.
- GIF attachments and Giphy/Tenor or `.gif` links are removed from members without a role listed in `GIF_ALLOWED_ROLE_IDS`. The bot then mentions the member with a playful notice. This setting currently allows the server's Server Booster and VIP roles. For allowed members, Tenor `/view/` links get an additional animated GIF file reply.
- Discord's explicit-media scan is set to all members. Server AutoMod blocks Discord's sexual-content keyword preset and links containing configured adult-site domains for all members, showing the sender a warning. The sexual-content preset rule has no role or channel exemptions.
- Each slash command checks the role list documented above. Role matching is case-insensitive and allows a role name to include additional text after the configured role title (for example, `Management Team`).

To configure the commands, turn on Developer Mode in Discord (**User Settings → Advanced**), then right-click a role or channel and choose **Copy ID**. Set `SHIFT_LOG_CHANNEL_ID` to the channel ID where shift start, end, and adjustment logs should be posted. Set the three `ERLC_*_LOG_CHANNEL_ID` values to the channels for in-game join/leave, kill, and command logs, and set `ERLC_SERVER_KEY` to the private server's ER:LC API key. Keep the key secret. For `/dc-checks`, enable the Server Members intent in the Discord Developer Portal, make sure the bot can fetch server members, give verified members the exact `Verified` role, and have your verification bot set each verified member's Discord nickname to their Roblox username. Set `PROMOTION_ROLE_IDS` to the comma-separated IDs of every rank role the bot should use and replace during promotions. `STAFF_ROLE_IDS` is used to identify staff targets and rank labels for shift tracking, not to grant command access. Set `GIF_ALLOWED_ROLE_IDS` to the comma-separated IDs of roles allowed to post GIFs. The bot's highest role must be above the member and all rank roles it needs to manage.

Keep your `.env` file private; it contains your bot token.
