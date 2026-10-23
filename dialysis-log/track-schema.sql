-- ============================================================
-- TRACKER v2 SYNC SCHEMA  (safe column names: pm_interval, entered_by)
-- Run the whole block in the Supabase SQL editor, then reload the app.
-- ============================================================

create table if not exists public.track_machines (
  id          text primary key,
  tag         text not null,
  type        text not null,
  serial      text,
  location    text,
  status      text not null default 'In service',
  last_pm     date,
  pm_interval integer,
  notes       text,
  updated_at  timestamptz not null default now()
);

create table if not exists public.track_logs (
  id          text primary key,
  machine     text not null references public.track_machines(id) on delete cascade,
  type        text not null,
  date        date not null,
  ts          bigint not null default 0,
  entered_by  text,
  notes       text,
  detail      jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

-- Oct-30-proof grants
grant select, insert, update, delete on public.track_machines to anon;
grant select, insert, update, delete on public.track_logs     to anon;

-- match the RLS-off posture of the other app tables
alter table public.track_machines disable row level security;
alter table public.track_logs    disable row level security;
