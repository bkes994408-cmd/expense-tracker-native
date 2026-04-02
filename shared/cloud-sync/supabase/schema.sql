-- Phase 1 minimal schema for cross-device sync
-- Scope: expenses + categories (generic mutation log)

create table if not exists public.sync_mutations (
  id text primary key,
  user_id text not null,
  device_id text,
  entity text not null,
  entity_id text not null,
  mutation_type text not null check (mutation_type in ('create', 'update', 'delete')),
  payload text not null,
  updated_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists sync_mutations_user_updated_at_idx
  on public.sync_mutations (user_id, updated_at);

create index if not exists sync_mutations_user_entity_idx
  on public.sync_mutations (user_id, entity, entity_id);

alter table public.sync_mutations enable row level security;

-- Minimal RLS policy (adapt auth model later)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sync_mutations'
      and policyname = 'sync_mutations_user_isolation'
  ) then
    create policy sync_mutations_user_isolation
      on public.sync_mutations
      for all
      using (user_id = auth.uid()::text)
      with check (user_id = auth.uid()::text);
  end if;
end $$;
