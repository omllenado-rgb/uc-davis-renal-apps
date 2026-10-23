
-- ============================================================
-- PHASE 2 (FINAL — user-corrected Oct 23): CRRT/NxStage/CCPD track PM 90d ONLY.
-- No disinfection tasks on those classes (their machines don't get routine
-- disinfects logged in this tracker; HD + WRO carry the disinfection load).
-- CCPD keeps monthly effluent culture.
-- ============================================================
alter table public.dl_machines drop constraint if exists dl_machines_type_check;
alter table public.dl_machines add constraint dl_machines_type_check
  check (type in ('HD','WRO','CRRT','NXSTAGE','CCPD'));

alter table public.dl_task_templates drop constraint if exists dl_task_templates_machine_type_check;
alter table public.dl_task_templates add constraint dl_task_templates_machine_type_check
  check (machine_type in ('HD','WRO','CRRT','NXSTAGE','CCPD'));

insert into public.dl_task_templates (task_type, machine_type, label, interval_days, notes)
select v.t, v.mt, v.l, v.d, v.n from (values
  ('pm_full_crrt',    'CRRT',   'Biomed full PM',         90, 'Quarterly'),
  ('pm_nxstage',      'NXSTAGE','Biomed PM',              90, 'Quarterly'),
  ('pm_ccpd',         'CCPD',   'Biomed PM',              90, 'Quarterly'),
  ('culture_effluent','CCPD',   'PD effluent culture',    30, 'Monthly per PD P+P or on symptoms')
) as v(t, mt, l, d, n)
where not exists (
  select 1 from public.dl_task_templates x
  where x.task_type = v.t and x.machine_type = v.mt
);

grant select, insert, update on public.dl_machines to anon;
grant select on public.dl_task_templates to anon;
grant select, insert on public.dl_events to anon;
grant select, insert, update on public.dl_actions to anon;
