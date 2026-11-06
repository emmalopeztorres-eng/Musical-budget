-- MUSICAL BUDGET | PostgreSQL / Supabase
-- Esquema inicial de referencia. Ejecutar únicamente luego de revisar políticas y entorno.
create extension if not exists pgcrypto;

create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  organization_type text not null check (organization_type in ('producer','company','venue','coproduction')),
  country_code char(2) default 'AR',
  created_at timestamptz not null default now()
);

create table if not exists organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','finance_director','production_manager','accounting','viewer','auditor')),
  created_at timestamptz not null default now(),
  unique (organization_id,user_id)
);

create table if not exists productions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  season text,
  status text not null default 'planning' check (status in ('planning','production','season','closed')),
  created_at timestamptz not null default now()
);

create table if not exists budgets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  production_id uuid not null references productions(id) on delete cascade,
  name text not null,
  version integer not null default 1,
  status text not null default 'draft' check (status in ('draft','submitted','approved','locked')),
  currency char(3) not null check (currency in ('ARS','USD')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(production_id,name,version)
);

create table if not exists budget_items (
  id uuid primary key default gen_random_uuid(),
  budget_id uuid not null references budgets(id) on delete cascade,
  category text not null,
  description text not null,
  quantity numeric(18,4) not null default 1 check (quantity >= 0),
  unit_amount numeric(18,2) not null default 0 check (unit_amount >= 0),
  currency char(3) not null check (currency in ('ARS','USD')),
  created_at timestamptz not null default now()
);

create table if not exists financial_movements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  production_id uuid references productions(id) on delete set null,
  movement_type text not null check (movement_type in ('expense','income')),
  movement_date date not null,
  category text not null,
  description text not null,
  amount numeric(18,2) not null check (amount >= 0),
  currency char(3) not null check (currency in ('ARS','USD')),
  status text not null default 'pending' check (status in ('pending','paid','cancelled')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists exchange_rates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  base_currency char(3) not null,
  quote_currency char(3) not null,
  rate numeric(18,6) not null check (rate > 0),
  rate_date date not null,
  source text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check (base_currency <> quote_currency)
);

create index if not exists idx_productions_org on productions(organization_id);
create index if not exists idx_budgets_org_production on budgets(organization_id,production_id);
create index if not exists idx_movements_org_date on financial_movements(organization_id,movement_date);
create index if not exists idx_members_user on organization_members(user_id);

-- SECURITY NOTE:
-- Enable RLS and add organization-membership policies before connecting a client.
-- Do not expose service-role keys in frontend code. This schema is a starting point,
-- not a complete accounting, tax, payroll or regulatory implementation.
