
-- ============================================================
-- PHASE 2: CRRT + NxStage + CCPD classes
-- Run AFTER phase-1 tables exist (they do). Include grants again per Oct-30 rule.
-- ============================================================
-- 1. widen the type constraint on dl_machines
alter table public.dl_machines drop constraint if exists dl_machines_type_check;
alter table public.dl_machines add constraint dl_machines_type_check
  check (type in ('HD','WRO','CRRT','NXSTAGE','CCPD'));

-- widen the same constraint on templates
alter table public.dl_task_templates drop constraint if exists dl_task_templates_machine_type_check;
alter table public.dl_task_templates add constraint dl_task_templates_machine_type_check
  check (machine_type in ('HD','WRO','CRRT','NXSTAGE','CCPD'));

-- 2. seed phase-2 templates
insert into public.dl_task_templates (task_type, machine_type, label, interval_days, notes)
select v.t, v.mt, v.l, v.d, v.n from (values
  -- CRRT (Prismaflex/Prismax)
  ('disinfect_post_patient','CRRT','Post-patient disinfect', 1, 'After each patient run per protocol'),
  ('disinfect_heat_crrt',   'CRRT','Heat disinfect cycle',    7, 'Weekly or per use intensity'),
  ('pm_full_crrt',          'CRRT','Biomed full PM',          90, 'Quarterly'),
  -- NxStage System One
  ('check_per_use',         'NXSTAGE','Per-use system check', 1, 'Before each treatment'),
  ('disinfect_daily',       'NXSTAGE','Dialysate-path disinfect', 1, 'Daily per home-training SOP'),
  ('pm_nxstage',            'NXSTAGE','Biomed/home PM',        90, 'Quarterly'),
  -- CCPD cyclers (HomeChoice / Amia)
  ('disinfect_heat_ccpd',   'CCPD','Heat disinfect after run', 1, 'Daily after cycler session'),
  ('culture_effluent',      'CCPD','PD effluent/dialysate culture', 30, 'Monthly per PD P+P or on symptoms'),
  ('pm_ccpd',               'CCPD','Biomed PM',               90, 'Quarterly')
) as v(t, mt, l, d, n)
where not exists (
  select 1 from public.dl_task_templates x
  where x.task_type = v.t and x.machine_type = v.mt
);

-- 3. grants (Oct-30-proof)
grant select, insert, update on public.dl_machines to anon;
grant select on public.dl_task_templates to anon;
grant select, insert on public.dl_events to anon;
grant select, insert, update on public.dl_actions to anon;
