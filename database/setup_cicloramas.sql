-- MUSICAL BUDGET | Instalación inicial para Cicloramas Producciones
-- Ejecutar UNA SOLA VEZ en Supabase > SQL Editor > New query.
-- Este script crea estructura, permisos RLS y la organización inicial.
-- No contiene claves ni datos financieros. No ejecutar sobre una base que ya tenga datos.

create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','finance_director','production_manager','accounting','viewer','auditor')),
  created_at timestamptz not null default now(),
  unique (organization_id,user_id)
);

create table if not exists public.productions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  season text,
  status text not null default 'planning' check (status in ('planning','production','season','closed')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  production_id uuid not null references public.productions(id) on delete cascade,
  name text not null,
  version integer not null default 1 check (version > 0),
  status text not null default 'draft' check (status in ('draft','submitted','approved','locked')),
  currency char(3) not null check (currency in ('ARS','USD')),
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (production_id,name,version)
);

create table if not exists public.budget_items (
  id uuid primary key default gen_random_uuid(),
  budget_id uuid not null references public.budgets(id) on delete cascade,
  category text not null,
  subcategory text,
  description text not null,
  quantity numeric(18,4) not null default 1 check (quantity >= 0),
  unit_amount numeric(18,2) not null default 0 check (unit_amount >= 0),
  currency char(3) not null check (currency in ('ARS','USD')),
  created_at timestamptz not null default now()
);

create table if not exists public.financial_movements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  production_id uuid references public.productions(id) on delete set null,
  movement_type text not null check (movement_type in ('expense','income')),
  movement_date date not null,
  category text not null,
  description text not null,
  amount numeric(18,2) not null check (amount >= 0),
  currency char(3) not null check (currency in ('ARS','USD')),
  status text not null default 'pending' check (status in ('pending','paid','cancelled')),
  supplier_name text,
  reference_number text,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  category text,
  email text,
  phone text,
  tax_id text,
  payment_terms text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.exchange_rates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  base_currency char(3) not null default 'USD',
  quote_currency char(3) not null default 'ARS',
  rate numeric(18,6) not null check (rate > 0),
  rate_date date not null,
  source text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check (base_currency <> quote_currency)
);

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

create index if not exists idx_members_user on public.organization_members(user_id);
create index if not exists idx_productions_org on public.productions(organization_id);
create index if not exists idx_budgets_org_prod on public.budgets(organization_id,production_id);
create index if not exists idx_movements_org_date on public.financial_movements(organization_id,movement_date desc);
create index if not exists idx_suppliers_org_name on public.suppliers(organization_id,name);
create index if not exists idx_rates_org_date on public.exchange_rates(organization_id,rate_date desc);
create index if not exists idx_audit_org_date on public.audit_logs(organization_id,created_at desc);

create or replace function public.is_org_member(p_org uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_org and m.user_id = auth.uid()
  );
$$;

create or replace function public.has_org_role(p_org uuid, p_roles text[])
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_org and m.user_id = auth.uid() and m.role = any(p_roles)
  );
$$;

revoke all on function public.is_org_member(uuid) from public;
revoke all on function public.has_org_role(uuid,text[]) from public;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_org_role(uuid,text[]) to authenticated;

-- Se ejecuta desde la sesión autenticada de la primera administradora.
-- Crea Cicloramas una sola vez y asigna el rol owner al usuario que inició sesión.
create or replace function public.bootstrap_cicloramas()
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  v_org uuid;
begin
  if auth.uid() is null then
    raise exception 'Primero tenés que iniciar sesión.';
  end if;

  select organization_id into v_org
  from public.organization_members
  where user_id = auth.uid()
  limit 1;

  if v_org is not null then
    return v_org;
  end if;

  if exists (select 1 from public.organizations) then
    raise exception 'Cicloramas ya fue creada. Un administrador debe habilitar tu usuario.';
  end if;

  insert into public.organizations(name)
  values ('Cicloramas Producciones')
  returning id into v_org;

  insert into public.organization_members(organization_id,user_id,role)
  values (v_org,auth.uid(),'owner');

  return v_org;
end;
$$;
revoke all on function public.bootstrap_cicloramas() from public;
grant execute on function public.bootstrap_cicloramas() to authenticated;

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.productions enable row level security;
alter table public.budgets enable row level security;
alter table public.budget_items enable row level security;
alter table public.financial_movements enable row level security;
alter table public.suppliers enable row level security;
alter table public.exchange_rates enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists org_read_member on public.organizations;
create policy org_read_member on public.organizations for select to authenticated
using (public.is_org_member(id));

drop policy if exists members_read_org on public.organization_members;
create policy members_read_org on public.organization_members for select to authenticated
using (public.is_org_member(organization_id));

drop policy if exists members_manage_admin on public.organization_members;
create policy members_manage_admin on public.organization_members for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin']))
with check (public.has_org_role(organization_id,array['owner','admin']) and role <> 'owner');

drop policy if exists productions_read_member on public.productions;
create policy productions_read_member on public.productions for select to authenticated
using (public.is_org_member(organization_id));
drop policy if exists productions_write_manager on public.productions;
create policy productions_write_manager on public.productions for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin','production_manager','finance_director']))
with check (public.has_org_role(organization_id,array['owner','admin','production_manager','finance_director']));

drop policy if exists budgets_read_member on public.budgets;
create policy budgets_read_member on public.budgets for select to authenticated
using (public.is_org_member(organization_id));
drop policy if exists budgets_write_finance on public.budgets;
create policy budgets_write_finance on public.budgets for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin','finance_director','production_manager']))
with check (public.has_org_role(organization_id,array['owner','admin','finance_director','production_manager']));

drop policy if exists budget_items_read_member on public.budget_items;
create policy budget_items_read_member on public.budget_items for select to authenticated
using (exists (select 1 from public.budgets b where b.id=budget_id and public.is_org_member(b.organization_id)));
drop policy if exists budget_items_write_finance on public.budget_items;
create policy budget_items_write_finance on public.budget_items for all to authenticated
using (exists (select 1 from public.budgets b where b.id=budget_id and public.has_org_role(b.organization_id,array['owner','admin','finance_director','production_manager'])))
with check (exists (select 1 from public.budgets b where b.id=budget_id and public.has_org_role(b.organization_id,array['owner','admin','finance_director','production_manager'])));

drop policy if exists movements_read_member on public.financial_movements;
create policy movements_read_member on public.financial_movements for select to authenticated
using (public.is_org_member(organization_id));
drop policy if exists movements_write_finance on public.financial_movements;
create policy movements_write_finance on public.financial_movements for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin','finance_director','accounting']))
with check (public.has_org_role(organization_id,array['owner','admin','finance_director','accounting']) and (created_by is null or created_by=auth.uid()));

drop policy if exists suppliers_read_member on public.suppliers;
create policy suppliers_read_member on public.suppliers for select to authenticated
using (public.is_org_member(organization_id));
drop policy if exists suppliers_write_manager on public.suppliers;
create policy suppliers_write_manager on public.suppliers for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin','finance_director','production_manager','accounting']))
with check (public.has_org_role(organization_id,array['owner','admin','finance_director','production_manager','accounting']));

drop policy if exists rates_read_member on public.exchange_rates;
create policy rates_read_member on public.exchange_rates for select to authenticated
using (public.is_org_member(organization_id));
drop policy if exists rates_write_finance on public.exchange_rates;
create policy rates_write_finance on public.exchange_rates for all to authenticated
using (public.has_org_role(organization_id,array['owner','admin','finance_director','accounting']))
with check (public.has_org_role(organization_id,array['owner','admin','finance_director','accounting']));

drop policy if exists audit_read_authorized on public.audit_logs;
create policy audit_read_authorized on public.audit_logs for select to authenticated
using (public.has_org_role(organization_id,array['owner','admin','auditor']));
drop policy if exists audit_add_member on public.audit_logs;
create policy audit_add_member on public.audit_logs for insert to authenticated
with check (public.is_org_member(organization_id) and (actor_user_id is null or actor_user_id=auth.uid()));

grant select on public.organizations,public.organization_members,public.productions,public.budgets,
  public.budget_items,public.financial_movements,public.suppliers,public.exchange_rates,public.audit_logs to authenticated;
grant insert,update,delete on public.productions,public.budgets,public.budget_items,
  public.financial_movements,public.suppliers,public.exchange_rates to authenticated;
grant insert,update,delete on public.organization_members to authenticated;
grant insert on public.audit_logs to authenticated;

-- Importante: la auditoría queda preparada como tabla; los registros automáticos
-- por cada cambio se incorporarán con triggers en una siguiente etapa.
