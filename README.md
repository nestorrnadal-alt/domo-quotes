# Domo Quote Tool — Deployment Guide

## Step 1: Run the database schema in Supabase
1. Go to https://supabase.com → your project → SQL Editor
2. Click "New Query"
3. Paste the contents of `supabase-schema.sql`
4. Click RUN

## Step 2: Create your team user accounts in Supabase
1. Go to Authentication → Users → Add User
2. Add each team member's email and a password
3. They'll use those to log into the app

## Step 3: Deploy to Netlify
1. Go to https://netlify.com → Add new site → Deploy manually
2. Drag the entire `domo-app` folder onto the deploy zone
3. Wait 30 seconds for it to deploy
4. You'll get a URL like `https://amazing-name-123.netlify.app`

## Step 4: Set environment variables in Netlify
1. In Netlify → Site Settings → Environment Variables
2. Add these two variables:
   - Key: `ANTHROPIC_API_KEY`  Value: your sk-ant-... key
3. Trigger a redeploy (Deploys → Trigger deploy)

## Step 5: (Optional) Custom domain
1. Netlify → Domain Management → Add custom domain
2. Add `quotes.domoyourhome.com`
3. Add a CNAME record in your DNS pointing to the Netlify URL

## That's it!
Your team can now access the tool at your Netlify URL, log in with their credentials, and all data is shared in real time via Supabase.
