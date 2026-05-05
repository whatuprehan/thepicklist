# The Pick List - Database Setup Guide

This site is now connected to Supabase for:
- Products and categories
- Partner applications
- Partners and sales
- Referral clicks
- Contact messages
- Newsletter subscribers

## 1) Where to see your database

### In Supabase Dashboard
1. Open [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Open your project
3. Go to `Table Editor`
4. Open tables like:
   - `products`
   - `partner_applications`
   - `contact_messages`
   - `newsletter_subscribers`

### Manage data from outside the site
Use Supabase Dashboard only (the public admin page has been removed from the website).

## 2) One-time SQL step

Run `supabase-schema.sql` in Supabase SQL Editor once (or again after updates) to ensure all tables/policies exist.

## 3) Runtime config (no hardcoded keys in index.html)

This project loads Supabase credentials from `config.js`.

- Copy `config.example.js` to `config.js` if needed
- Put your values in `config.js`:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`

The site also supports fallback from browser localStorage keys:
- `picklist.supabase.url`
- `picklist.supabase.anonKey`

## 4) Important security notes

- Never put Supabase `service_role` key in frontend files.
- Supabase anon/publishable key is safe for frontend when RLS is enabled correctly.
- Manage data with Supabase project access controls (team members, roles, and SQL policies).

## 5) Deploy checklist

1. Confirm `config.js` has correct project URL/key
2. Confirm SQL schema is applied
3. Publish `index.html`, `config.js`, and other site files to GitHub Pages
4. Test:
   - Email signup form saves into `newsletter_subscribers`
   - Contact form saves into `contact_messages`
   - Data is visible in Supabase Table Editor
