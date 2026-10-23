-- ============================================================
-- TRACKER v2 SYNC SCHEMA (matches the uploaded design's data model)
-- Machines: id (text uid, app-generated), tag, type, serial, location,
--           status, lastPM, interval, notes
-- Logs:     id (text uid), machine, type, date, by, ts, notes, method, rinsed,
--           result, cfu, eu, site, cond, status
-- Existing dl_ tables stay (not dropped; history preserved). New tables use the
-- app's ids so the sync layer is a clean 1:1 field mapping.
-- Run whole block in Supabase SQL editor. Grants included (Oct-30 rule).
-- ============================================================

create table if not exists public.track_machines (
  id          text primary key,          -- app's uid()
  tag         text not null,
  type        text not null,
  serial      text,
  location    text,
  status      text not null default 'In service',
  last_pm     date,
  interval    integer,
  notes       text,
  updated_at  timestamptz not null default now()
);

create table if not exists public.track_logs (
  id          text primary key,          -- app's uid()
  machine     text not null references public.track_machines(id) on delete cascade,
  type        text not null,
  date        date not null,
  ts          bigint not null default 0,
  by          text,
  notes       text,
  detail      jsonb not null default '{}'::jsonb,   -- method/rinsed|result/cfu/eu/site|cond|status
  created_at  timestamptz not null default now()
);

-- ======================================== GRANTS (matching app posture) =====
grant select, insert, update, delete  on public.track_machines to anon;
grant select, insert, update, delete  on public.track_logs     to anon;

-- RLS OFF to match the other app tables (SQL editor may auto-enable it)
alter table public.track_machines disable row level security;
alter table public.track_logs    disable row level security;

-- ============================================================ VERIFY ========
-- select count(*) from public.track_machines;   -- 0
-- select count(*) from public.track_logs;       -- 0