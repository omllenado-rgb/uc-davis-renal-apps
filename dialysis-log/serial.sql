
-- ============================================================
-- ADD serial_number to machines (run in Supabase SQL editor)
-- ============================================================
alter table public.dl_machines add column if not exists serial_no text;

-- backfill nothing (machines already added lack serials; label/model stay).
-- The Machines tab form will now carry Serial number; existing rows edited from
-- the app can adopt it.

-- grants unchanged; verify:
-- select id,label,serial_no from public.dl_machines;
