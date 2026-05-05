-- The Pick List Supabase schema
-- Run this in the Supabase SQL editor, then set the URL/anon key in index.html.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  role text not null default 'admin',
  created_at timestamptz not null default now()
);

insert into public.profiles (email, role)
values ('mail2nswr@gmail.com', 'admin')
on conflict (email) do update set role = excluded.role;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'mail2nswr@gmail.com'
    or exists (
      select 1
      from public.profiles
      where email = coalesce(auth.jwt() ->> 'email', '')
        and role = 'admin'
    );
$$;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  category_slug text references public.categories(slug),
  page_id text,
  rank int not null default 999,
  status text not null default 'approved',
  badge text,
  badge_color text default 'b-yellow',
  tagline text,
  description text not null,
  rating numeric(2,1),
  guarantee text,
  best_for text,
  primary_cta text not null default 'Learn More',
  primary_url text not null,
  secondary_cta text,
  secondary_url text,
  keywords text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_slug text references public.products(slug) on delete cascade,
  reviewer_name text,
  reviewer_role text,
  rating numeric(2,1),
  body text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.site_reviews (
  id uuid primary key default gen_random_uuid(),
  reviewer_name text,
  reviewer_role text,
  rating numeric(2,1),
  body text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.partner_applications (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  main_channel text not null,
  audience_size text,
  fit_reason text not null,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table if not exists public.partners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text unique not null,
  code text unique not null,
  status text not null default 'active',
  tier text not null default 'Starter',
  referral_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.referral_clicks (
  id uuid primary key default gen_random_uuid(),
  partner_code text not null,
  landing_page text,
  referrer text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists public.partner_sales (
  id uuid primary key default gen_random_uuid(),
  partner_code text not null,
  product_slug text,
  buyer_email text,
  our_commission numeric(10,2) not null default 0,
  partner_cut_percent numeric(5,2) not null default 20,
  partner_amount numeric(10,2) generated always as (round((our_commission * partner_cut_percent / 100.0), 2)) stored,
  status text not null default 'pending',
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.promo_assets (
  id uuid primary key default gen_random_uuid(),
  asset_type text not null,
  title text not null,
  body text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  subject text,
  message text not null,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_reviews enable row level security;
alter table public.site_reviews enable row level security;
alter table public.partner_applications enable row level security;
alter table public.partners enable row level security;
alter table public.referral_clicks enable row level security;
alter table public.partner_sales enable row level security;
alter table public.promo_assets enable row level security;
alter table public.contact_messages enable row level security;

drop policy if exists "admins manage profiles" on public.profiles;
drop policy if exists "public read categories" on public.categories;
drop policy if exists "admins manage categories" on public.categories;
drop policy if exists "public read products" on public.products;
drop policy if exists "admins manage products" on public.products;
drop policy if exists "public read product reviews" on public.product_reviews;
drop policy if exists "admins manage product reviews" on public.product_reviews;
drop policy if exists "public read site reviews" on public.site_reviews;
drop policy if exists "admins manage site reviews" on public.site_reviews;
drop policy if exists "public create partner applications" on public.partner_applications;
drop policy if exists "admins manage partner applications" on public.partner_applications;
drop policy if exists "admins manage partners" on public.partners;
drop policy if exists "public create referral clicks" on public.referral_clicks;
drop policy if exists "admins read referral clicks" on public.referral_clicks;
drop policy if exists "admins manage partner sales" on public.partner_sales;
drop policy if exists "public read promo assets" on public.promo_assets;
drop policy if exists "admins manage promo assets" on public.promo_assets;
drop policy if exists "public create contact messages" on public.contact_messages;
drop policy if exists "admins manage contact messages" on public.contact_messages;

create policy "admins manage profiles" on public.profiles for all using (public.is_admin()) with check (public.is_admin());
create policy "public read categories" on public.categories for select using (is_active = true);
create policy "admins manage categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "public read products" on public.products for select using (is_active = true and status = 'approved');
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "public read product reviews" on public.product_reviews for select using (is_active = true);
create policy "admins manage product reviews" on public.product_reviews for all using (public.is_admin()) with check (public.is_admin());
create policy "public read site reviews" on public.site_reviews for select using (is_active = true);
create policy "admins manage site reviews" on public.site_reviews for all using (public.is_admin()) with check (public.is_admin());
create policy "public create partner applications" on public.partner_applications for insert with check (true);
create policy "admins manage partner applications" on public.partner_applications for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage partners" on public.partners for all using (public.is_admin()) with check (public.is_admin());
create policy "public create referral clicks" on public.referral_clicks for insert with check (true);
create policy "admins read referral clicks" on public.referral_clicks for select using (public.is_admin());
create policy "admins manage partner sales" on public.partner_sales for all using (public.is_admin()) with check (public.is_admin());
create policy "public read promo assets" on public.promo_assets for select using (is_active = true);
create policy "admins manage promo assets" on public.promo_assets for all using (public.is_admin()) with check (public.is_admin());
create policy "public create contact messages" on public.contact_messages for insert with check (true);
create policy "admins manage contact messages" on public.contact_messages for all using (public.is_admin()) with check (public.is_admin());

insert into public.categories (slug, name, sort_order) values
('ai', 'AI Tools', 1),
('marketing', 'Marketing', 2),
('wellness', 'Wellness', 3),
('content', 'Content', 4),
('saas', 'SaaS', 5),
('money', 'Make Money', 6),
('education', 'Education', 7)
on conflict (slug) do update set name = excluded.name, sort_order = excluded.sort_order;

insert into public.products (slug, name, category_slug, page_id, rank, badge, badge_color, tagline, description, rating, guarantee, best_for, primary_cta, primary_url, secondary_cta, secondary_url, keywords) values
('clickfunnels','ClickFunnels','marketing','prod-clickfunnels',1,'Editor''s Pick','b-yellow','Marketing','The reason 100,000 plus online businesses actually make sales. A website looks good, a funnel makes money. Zero design or coding skills needed.',4.8,'Free Trial','Selling anything online','Start Free Trial','https://www.clickfunnels.com/signup-flow?aff=dd5f9643b9752cc2f09d0543452544e3a33e16485c43d5235407168b213fb979','3 Months for $99','https://www.clickfunnels.com/3-months-for-99?aff=dd5f9643b9752cc2f09d0543452544e3a33e16485c43d5235407168b213fb979',array['sales','funnel','convert','website','sell']),
('medbed','Tesla MedBed X','wellness','prod-medbed',2,'Wellness Pick','b-purple','Wellness','An advanced full-body wellness system combining PEMF therapy, red light therapy, far infrared heat and negative ion infusion.',4.7,'60-Day Money Back','Relaxation and recovery','Get Tesla MedBed X','https://www.checkout-ds24.com/redir/649413/mail2nswr4ed4/',null,null,array['sleep','pain','recovery','energy','wellness']),
('tpp','TPP System','money','prod-tpp',3,'Top Rated','b-green','Make Money','A comprehensive wealth transformation program combining mindset training with practical investment strategies.',4.6,'60-Day Money Back','Wealth and financial mindset','Access TPP System','https://www.checkout-ds24.com/redir/656847/mail2nswr4ed4/',null,null,array['wealth','invest','money','financial']),
('customgpt','CustomGPT','ai','prod-customgpt',4,'AI Pick','b-blue','AI Tools','Build your own AI assistant trained on your business data for customer support, sales FAQs and knowledge bases.',4.7,'Free Trial','Business AI support','Try Free','https://customgpt.ai/?fpr=mohammad-rehan12','Watch Demo','https://customgpt.ai/demo/?fpr=mohammad-rehan12',array['ai','chatbot','support','automation']),
('frase','Frase.io','content','prod-frase',5,'Trending','b-red','Content SEO','Researches, outlines and writes content that actually ranks on Google by analyzing top search results.',4.9,'Free Trial','SEO content and blogs','Try Free','https://www.frase.io/?utm_source=firstpromoter&utm_medium=affiliate&utm_campaign=affiliate_program&via=mohammad64','Free SEO Tools','https://www.frase.io/tools/?via=mohammad64',array['seo','google','rank','content']),
('qc','QC System','education','prod-qc',6,null,null,'Education','An educational video series on quantum computing, encryption and the future monetary system.',4.5,'60-Day Money Back','Future finance education','Access QC System','https://www.checkout-ds24.com/redir/611936/mail2nswr4ed4/',null,null,array['quantum','finance','future']),
('odr','Online Digital Redemption','money','prod-odr',7,null,null,'Make Money','A digital program for building sustainable online income with practical strategies and step-by-step guidance.',4.5,null,'Online income beginners','Access Now','https://onlinedigitalredemption.com/#aff=mail2nswr4ed4',null,null,array['online income','digital','make money']),
('livechat','LiveChat','saas','prod-livechat',8,null,null,'SaaS','Real-time chat that turns visitors into customers and captures leads automatically when offline.',4.8,'14-Day Free Trial','Website conversion','Try Free','https://www.livechat.com/?a=TlvNnoTvR&utm_campaign=pp_livechat-default&utm_source=PP',null,null,array['chat','support','leads']),
('repurpose','Repurpose.io','content','prod-repurpose',9,null,null,'Content','Record once, post everywhere. Automatically distributes content to YouTube, TikTok, Instagram, Facebook and more.',4.6,'Free Trial','Content distribution','Try Free','https://repurpose.io?fpr=658476',null,null,array['video','social media','content']),
('chatbot','ChatBot','saas','prod-chatbot',10,null,null,'SaaS','Handles customer questions, qualifies leads and books appointments without a human involved.',4.5,'Free Trial','Support automation','Try Free','https://www.chatbot.com/?a=TlvNnoTvR&utm_campaign=pp_chatbot-default&utm_source=PP',null,null,array['chatbot','automation','support']),
('helpdesk','HelpDesk','saas','prod-helpdesk',11,null,null,'SaaS','All customer messages in one clean inbox. Teams resolve issues faster and scale support.',4.6,'Free Trial','Support teams','Try Free','https://www.helpdesk.com/?a=TlvNnoTvR&utm_campaign=pp_helpdesk-default&utm_source=PP',null,null,array['helpdesk','tickets','support']),
('ofa','One Funnel Away','money','prod-ofa',12,'Best for Beginners','b-green','Make Money','30 days of daily coaching to build your first profitable funnel and make your first online sale.',4.8,null,'First online sale','Join Challenge','https://www.onefunnelaway.com/?aff=dd5f9643b9752cc2f09d0543452544e3a33e16485c43d5235407168b213fb979',null,null,array['beginner','first sale','online business'])
on conflict (slug) do update set
  name = excluded.name,
  category_slug = excluded.category_slug,
  page_id = excluded.page_id,
  rank = excluded.rank,
  badge = excluded.badge,
  badge_color = excluded.badge_color,
  tagline = excluded.tagline,
  description = excluded.description,
  rating = excluded.rating,
  guarantee = excluded.guarantee,
  best_for = excluded.best_for,
  primary_cta = excluded.primary_cta,
  primary_url = excluded.primary_url,
  secondary_cta = excluded.secondary_cta,
  secondary_url = excluded.secondary_url,
  keywords = excluded.keywords,
  updated_at = now();

insert into public.promo_assets (asset_type, title, body, sort_order) values
('social', 'X / Threads Post', 'I found a shortcut for choosing better tools without wasting weeks testing random apps.\n\nThe Pick List ranks proven AI, marketing, SaaS, wellness and make-money tools in one clean place.\n\nStart here: https://whatuprehan.github.io/thepicklist/?ref=YOURCODE', 1),
('social', 'LinkedIn Post', 'Most people lose time comparing tools instead of using them.\n\nThe Pick List does the filtering first: AI tools, funnel builders, SEO platforms, customer support software and digital income systems that are actually worth a look.\n\nhttps://whatuprehan.github.io/thepicklist/?ref=YOURCODE', 2),
('email', 'My shortcut for finding better tools', 'Hey,\n\nIf you are comparing tools for your business, I found a clean starting point: The Pick List.\n\nBrowse it here:\nhttps://whatuprehan.github.io/thepicklist/?ref=YOURCODE', 3),
('banner', 'Wide Banner', 'FIND THE RIGHT TOOL FASTER', 4),
('banner', 'Square Banner', 'STOP GUESSING. PICK BETTER.', 5)
on conflict do nothing;
