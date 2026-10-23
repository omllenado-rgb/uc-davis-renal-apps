-- ============================================================================
-- DIALYSIS & WATER PLANT LOG TRACKER — schema + grants
-- For: HD machines + WRO plant (phase 1; CRRT/NxStage/CCPD classes phase 2)
-- ============================================================================
-- HOW TO RUN: Oliver pastes this whole block into the Supabase SQL editor
-- (Dashboard → your project → SQL Editor → New query → paste → Run).
-- After Oct 30 2026 Supabase no longer auto-grants Data API access to NEW
-- public tables — the GRANTs below are therefore PART of this migration.
-- ============================================================================

-- ============================================================ 1. MACHINES ===
create table if not exists public.dl_machines (
  id           bigint generated always as identity primary key,
  type         text not null check (type in ('HD','WRO')),
  label        text not null unique,              -- '#6', 'RO skid'
  model        text,                              -- '2008K', 'Nikkiso', 'RO skid brand'
  location     text,                              -- 'Bay 2', 'Water room'
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);

-- ================================================== 2. TASK TEMPLATES =======
-- Interval clocks per machine CLASS. Machines inherit these.
create table if not exists public.dl_task_templates (
  id           bigint generated always as identity primary key,
  task_type    text not null,                     -- 'disinfect_citric','disinfect_bleach','disinfect_heat','pm_full','culture_water','culture_machine','reading_conductivity','reading_hardness'
  machine_type text not null check (machine_type in ('HD','WRO')),
  label        text not null,
  interval_days integer,                          -- null = hours-based or on-demand
  notes        text
);

-- ======================================================= 3. LOG EVENTS ======
-- Every disinfect / PM / culture / reading, one row, machine + date + who.
create table if not exists public.dl_events (
  id           bigint generated always as identity primary key,
  machine_id   bigint not null references public.dl_machines(id) on delete cascade,
  task_type    text not null,
  event_date   date not null default current_date,
  performed_by text not null,                     -- initials / name
  result       text check (result in ('pass','fail','retest')) default 'pass',
  values       jsonb not null default '{}'::jsonb,-- {conductivity_uS, hardness_gpg, residual_ppm, cfu_ml, eu_ml, hours, ...}
  notes        text,
  created_at   timestamptz not null default now()
);

-- ================================ 4. OPEN ACTIONS (AAMI breaches / overdue) ==
create table if not exists public.dl_actions (
  id           bigint generated always as identity primary key,
  event_id     bigint references public.dl_events(id) on delete cascade,
  machine_id   bigint not null references public.dl_machines(id) on delete cascade,
  action_type  text not null,                     -- 'aami_breach_retest','overdue_disinfect', ...
  description  text not null,
  due_by       date,
  status       text not null default 'open' check (status in ('open','done')),
  created_at   timestamptz not null default now(),
  resolved_at  timestamptz,
  resolved_by  text
);

-- ============================== 5. SEED THE TASK TEMPLATES (idempotent) =====
insert into public.dl_task_templates (task_type, machine_type, label, interval_days, notes)
select v.t, v.mt, v.l, v.d, v.n from (values
  ('disinfect_citric',    'HD',  'Citric acid disinfect',        1,  'Daily after last patient per unit P+P'),
  ('disinfect_bleach',    'HD',  'Bleach disinfect',             7,  'Weekly; document residual check'),
  ('disinfect_heat',      'HD',  'Heat disinfect',               1,  'Daily per machine auto-cycle'),
  ('pm_full',             'HD',  'Biomed full PM',               90, 'Quarterly'),
  ('culture_machine',     'HD',  'Machine inlet culture',        30, 'Monthly per policy'),
  ('disinfect_chemical',  'WRO', 'Chemical disinfect cycle',     30, 'Per water quality policy'),
  ('disinfect_hot',       'WRO', 'Hot water disinfect',          7,  'Weekly'),
  ('pm_prefilter',        'WRO', 'Prefilter swap',               90, 'Quarterly or by pressure drop'),
  ('pm_membrane',         'WRO', 'RO membrane check/clean',      180,'Semiannual or by hours/conductivity'),
  ('pm_uv_lamp',          'WRO', 'UV lamp check/hours',          90, 'Quarterly lamp hours review'),
  ('reading_conductivity','WRO', 'Conductivity reading',         1,  'Daily; flag >10 uS/cm'),
  ('reading_hardness',    'WRO', 'Hardness test',                1,  'Daily on softened feed'),
  ('culture_water',       'WRO', 'Water culture (CFU + EU)',     30, 'Monthly AAMI sampling, post-RO site')
) as v(t, mt, l, d, n)
where not exists (
  select 1 from public.dl_task_templates x
  where x.task_type = v.t and x.machine_type = v.mt
);

-- ======================================================== 6. GRANTS =========
-- CRITICAL: after Oct 30 2026, new tables get NO automatic Data API grants.
-- These are the app's grants; adjust the update/delete posture to RLS plans.
grant select, insert, update          on public.dl_machines        to anon;
grant select, insert, update, delete  on public.dl_machines        to service_role;
grant select                          on public.dl_task_templates  to anon;
grant select, insert, update, delete  on public.dl_task_templates  to service_role;
grant select, insert                  on public.dl_events          to anon;
grant select, insert, update, delete  on public.dl_events          to service_role;
grant select, insert, update          on public.dl_actions         to anon;
grant select, insert, update, delete  on public.dl_actions         to service_role;

-- ======================================================== 7. VERIFY =========
-- (paste the below into a second query if you want a quick check)
-- select count(*) from public.dl_task_templates;          -- expect 13
-- select type, label from public.dl_machines;             -- expect empty