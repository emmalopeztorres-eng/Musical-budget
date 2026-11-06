-- MUSICAL BUDGET | Migración 001: seguridad multiempresa y permisos
-- Ejecutar en Supabase SQL Editor DESPUÉS de database/schema.sql.
-- Revisar primero en un proyecto de prueba. No contiene claves ni datos reales.

create or replace function public.is_org_member(p_org uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.organization_members m
    where m.organization_id = p_org and m.user_id = auth.uid());
$$;

create or replace function public.has_org_role(p_org uuid, p_roles text[])
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.organization_members m
    where m.organization_id = p_org and m.user_id = auth.uid() and m.role = any(p_roles));
$$;

revoke all on function public.is_org_member(uuid) from public;
revoke all on function public.has_org_role(uuid, text[]) from public;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_org_role(uuid, text[]) to authenticated;

-- Alta atómica: crea organización y asigna owner al usuario autenticado.
create or replace function public.create_organization(p_name text, p_type text)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_org uuid;
begin
  if auth.uid() is null then raise exception 'Se requiere una sesión iniciada'; end if;
  if length(trim(coalesce(p_name, ''))) < 2 then raise exception 'El nombre debe tener al menos 2 caracteres'; end if;
  if p_type not in ('producer','company','venue','coproduction') then raise exception 'Tipo de organización inválido'; end if;
  insert into public.organizations(name, organization_type)
    values (trim(p_name), p_type) returning id into v_org;
  insert into public.organization_members(organization_id, user_id, role)
    values (v_org, auth.uid(), 'owner');
  return v_org;
end;
$$;
revoke all on function public.create_organization(text, text) from public;
grant execute on function public.create_organization(text, text) to authenticated;

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_audit_org_created on public.audit_logs(organization_id, created_at desc);

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.productions enable row level security;
alter table public.budgets enable row level security;
alter table public.budget_items enable row level security;
alter table public.financial_movements enable row level security;
alter table public.exchange_rates enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists org_select_members on public.organizations;
create policy org_select_members on public.organizations
for select to authenticated using (public.is_org_member(id));

drop policy if exists members_select_org on public.organization_members;
create policy members_select_org on public.organization_members
for select to authenticated using (public.is_org_member(organization_id));
drop policy if exists members_insert_admin on public.organization_members;
create policy members_insert_admin on public.organization_members
for insert to authenticated with check (
  public.has_org_role(organization_id, array['owner','admin']) and role <> 'owner'
);
drop policy if exists members_update_admin on public.organization_members;
create policy members_update_admin on public.organization_members
for update to authenticated using (public.has_org_role(organization_id, array['owner','admin']))
with check (public.has_org_role(organization_id, array['owner','admin']) and role <> 'owner');
drop policy if exists members_delete_admin on public.organization_members;
create policy members_delete_admin on public.organization_members
for delete to authenticated using (
  public.has_org_role(organization_id, array['owner','admin']) and role <> 'owner' and user_id <> auth.uid()
);

drop policy if exists productions_select_member on public.productions;
create policy productions_select_member on public.productions
for select to authenticated using (public.is_org_member(organization_id));
drop policy if exists productions_insert_manager on public.productions;
create policy productions_insert_manager on public.productions
for insert to authenticated with check (public.has_org_role(organization_id, array['owner','admin','production_manager','finance_director']));
drop policy if exists productions_update_manager on public.productions;
create policy productions_update_manager on public.productions
for update to authenticated using (public.has_org_role(organization_id, array['owner','admin','production_manager','finance_director']))
with check (public.has_org_role(organization_id, array['owner','admin','production_manager','finance_director']));
drop policy if exists productions_delete_admin on public.productions;
create policy productions_delete_admin on public.productions
for delete to authenticated using (public.has_org_role(organization_id, array['owner','admin']));

drop policy if exists budgets_select_member on public.budgets;
create policy budgets_select_member on public.budgets
for select to authenticated using (public.is_org_member(organization_id));
drop policy if exists budgets_insert_finance on public.budgets;
create policy budgets_insert_finance on public.budgets
for insert to authenticated with check (public.has_org_role(organization_id, array['owner','admin','finance_director','production_manager']));
drop policy if exists budgets_update_finance on public.budgets;
create policy budgets_update_finance on public.budgets
for update to authenticated using (public.has_org_role(organization_id, array['owner','admin','finance_director','production_manager']))
with check (public.has_org_role(organization_id, array['owner','admin','finance_director','production_manager']));
drop policy if exists budgets_delete_admin on public.budgets;
create policy budgets_delete_admin on public.budgets
for delete to authenticated using (public.has_org_role(organization_id, array['owner','admin']));

drop policy if exists budget_items_select_member on public.budget_items;
create policy budget_items_select_member on public.budget_items
for select to authenticated using (
  exists (select 1 from public.budgets b where b.id = budget_id and public.is_org_member(b.organization_id))
);
drop policy if exists budget_items_insert_finance on public.budget_items;
create policy budget_items_insert_finance on public.budget_items
for insert to authenticated with check (
  exists (select 1 from public.budgets b where b.id = budget_id and public.has_org_role(b.organization_id, array['owner','admin','finance_director','production_manager']))
);
drop policy if exists budget_items_update_finance on public.budget_items;
create policy budget_items_update_finance on public.budget_items
for update to authenticated using (
  exists (select 1 from public.budgets b where b.id = budget_id and public.has_org_role(b.organization_id, array['owner','admin','finance_director','production_manager']))
) with check (
  exists (select 1 from public.budgets b where b.id = budget_id and public.has_org_role(b.organization_id, array['owner','admin','finance_director','production_manager']))
);
drop policy if exists budget_items_delete_finance on public.budget_items;
create policy budget_items_delete_finance on public.budget_items
for delete to authenticated using (
  exists (select 1 from public.budgets b where b.id = budget_id and public.has_org_role(b.organization_id, array['owner','admin','finance_director']))
);

drop policy if exists movements_select_member on public.financial_movements;
create policy movements_select_member on public.financial_movements
for select to authenticated using (public.is_org_member(organization_id));
drop policy if exists movements_insert_finance on public.financial_movements;
create policy movements_insert_finance on public.financial_movements
for insert to authenticated with check (
  public.has_org_role(organization_id, array['owner','admin','finance_director','accounting'])
  and (created_by is null or created_by = auth.uid())
);
drop policy if exists movements_update_finance on public.financial_movements;
create policy movements_update_finance on public.financial_movements
for update to authenticated using (public.has_org_role(organization_id, array['owner','admin','finance_director','accounting']))
with check (public.has_org_role(organization_id, array['owner','admin','finance_director','accounting']));
drop policy if exists movements_delete_admin on public.financial_movements;
create policy movements_delete_admin on public.financial_movements
for delete to authenticated using (public.has_org_role(organization_id, array['owner','admin']));

drop policy if exists rates_select_member on public.exchange_rates;
create policy rates_select_member on public.exchange_rates
for select to authenticated using (public.is_org_member(organization_id));
drop policy if exists rates_insert_finance on public.exchange_rates;
create policy rates_insert_finance on public.exchange_rates
for insert to authenticated with check (
  public.has_org_role(organization_id, array['owner','admin','finance_director','accounting'])
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists audit_select_authorized on public.audit_logs;
create policy audit_select_authorized on public.audit_logs
for select to authenticated using (public.has_org_role(organization_id, array['owner','admin','auditor']));
drop policy if exists audit_insert_member on public.audit_logs;
create policy audit_insert_member on public.audit_logs
for insert to authenticated with check (public.is_org_member(organization_id) and (actor_user_id is null or actor_user_id = auth.uid()));

grant select on public.organizations, public.organization_members, public.productions,
  public.budgets, public.budget_items, public.financial_movements,
  public.exchange_rates, public.audit_logs to authenticated;
grant insert, update, delete on public.organization_members, public.productions,
  public.budgets, public.budget_items, public.financial_movements to authenticated;
grant insert on public.exchange_rates, public.audit_logs to authenticated;

-- No hay políticas UPDATE/DELETE para auditoría. Validar todos los roles y
-- pruebas cruzadas entre dos usuarios y dos organizaciones antes de producción.
