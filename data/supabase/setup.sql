-- Общие данные групп для приложения «Расписание»: правки старосты и ДЗ группы (Supabase / Postgres).
-- Уже применено к проекту raspisanie_chgu (миграция starosta_shared_data). Файл хранится для воспроизводимости:
-- если проект придётся создать заново, вставьте его целиком в SQL Editor и нажмите Run.
--
-- Устройство: студенты только читают (функция get_group_data), староста пишет по секретному токену,
-- прямого доступа к таблицам из приложения нет ни у кого. Коды старост выдаёт владелец:
--   select public.owner_issue_code('ofo-1-bi-25');   -- вернёт код, который нужно отдать старосте
-- Отозвать старосту / выдать код заново:  update public.group_codes set token = null, used_at = null where code = 'КОД';
--                                          delete from public.group_codes where code = 'КОД';

create table public.group_codes (
  code        text primary key,
  group_id    text not null check (group_id ~ '^[a-z0-9-]{3,40}$'),
  token       text unique,
  used_at     timestamptz,
  created_at  timestamptz not null default now()
);
alter table public.group_codes enable row level security;

create function public.limit_codes_per_group() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (select count(*) from public.group_codes where group_id = new.group_id) >= 2 then
    raise exception 'У группы % уже два кода старосты', new.group_id;
  end if;
  return new;
end $$;
create trigger group_codes_limit before insert on public.group_codes
  for each row execute function public.limit_codes_per_group();

create table public.group_overrides (
  id             uuid primary key default gen_random_uuid(),
  group_id       text not null check (group_id ~ '^[a-z0-9-]{3,40}$'),
  base_hash      text not null check (length(base_hash) <= 64),
  date           date not null,
  pair           int  not null check (pair between 1 and 8),
  type           text not null check (type in ('cancel', 'replace', 'add')),
  subject        text check (length(subject) <= 200),
  room           text check (length(room) <= 40),
  teacher        text check (length(teacher) <= 120),
  note           text check (length(note) <= 300),
  kind           text check (length(kind) <= 20),
  repeat_weekly  boolean not null default false,
  match_subject  text check (length(match_subject) <= 200),
  deleted        boolean not null default false,
  updated_at     timestamptz not null default now()
);
create index group_overrides_sync on public.group_overrides (group_id, updated_at);
alter table public.group_overrides enable row level security;

create table public.group_homework (
  id          uuid primary key default gen_random_uuid(),
  group_id    text not null check (group_id ~ '^[a-z0-9-]{3,40}$'),
  subject     text not null check (length(subject) between 1 and 200),
  body        text not null check (length(body) between 1 and 2000),
  due_date    date not null,
  kind        text check (length(kind) <= 20),
  deleted     boolean not null default false,
  updated_at  timestamptz not null default now()
);
create index group_homework_sync on public.group_homework (group_id, updated_at);
alter table public.group_homework enable row level security;

create function public.editor_group(p_token text) returns text
language plpgsql security definer set search_path = '' as $$
declare g text;
begin
  select group_id into g from public.group_codes where token = p_token and p_token is not null;
  if g is null then raise exception 'bad_token'; end if;
  return g;
end $$;

create function public.purge_tombstones() returns void
language sql security definer set search_path = '' as $$
  delete from public.group_overrides where deleted and updated_at < now() - interval '30 days';
  delete from public.group_homework  where deleted and updated_at < now() - interval '30 days';
$$;

create function public.get_group_data(p_group text, p_since timestamptz default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if p_group is null or p_group !~ '^[a-z0-9-]{3,40}$' then raise exception 'bad_group'; end if;
  return jsonb_build_object(
    'server_time', now(),
    'overrides', coalesce((
      select jsonb_agg(to_jsonb(o) - 'group_id')
      from public.group_overrides o
      where o.group_id = p_group and (p_since is null and not o.deleted or p_since is not null and o.updated_at > p_since)
    ), '[]'::jsonb),
    'homework', coalesce((
      select jsonb_agg(to_jsonb(h) - 'group_id')
      from public.group_homework h
      where h.group_id = p_group and (p_since is null and not h.deleted or p_since is not null and h.updated_at > p_since)
    ), '[]'::jsonb)
  );
end $$;

create function public.redeem_code(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r public.group_codes%rowtype; t text;
begin
  select * into r from public.group_codes where code = upper(trim(p_code));
  if not found then raise exception 'bad_code'; end if;
  if r.token is not null then raise exception 'code_used'; end if;
  t := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  update public.group_codes set token = t, used_at = now() where code = r.code;
  return jsonb_build_object('group_id', r.group_id, 'token', t);
end $$;

create function public.check_editor(p_token text) returns text
language sql security definer set search_path = '' as $$
  select public.editor_group(p_token);
$$;

create function public.put_group_override(p_token text, p_row jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); v_id uuid; n int;
begin
  perform public.purge_tombstones();
  v_id := coalesce((p_row->>'id')::uuid, gen_random_uuid());
  if not exists (select 1 from public.group_overrides where id = v_id) then
    select count(*) into n from public.group_overrides where group_id = g and not deleted;
    if n >= 300 then raise exception 'too_many'; end if;
  end if;
  insert into public.group_overrides (id, group_id, base_hash, date, pair, type, subject, room, teacher, note, kind, repeat_weekly, match_subject, deleted, updated_at)
  values (v_id, g, p_row->>'base_hash', (p_row->>'date')::date, (p_row->>'pair')::int, p_row->>'type',
          nullif(p_row->>'subject',''), nullif(p_row->>'room',''), nullif(p_row->>'teacher',''), nullif(p_row->>'note',''),
          nullif(p_row->>'kind',''), coalesce((p_row->>'repeat_weekly')::boolean, false), nullif(p_row->>'match_subject',''), false, now())
  on conflict (id) do update set
    base_hash = excluded.base_hash, date = excluded.date, pair = excluded.pair, type = excluded.type,
    subject = excluded.subject, room = excluded.room, teacher = excluded.teacher, note = excluded.note, kind = excluded.kind,
    repeat_weekly = excluded.repeat_weekly, match_subject = excluded.match_subject, deleted = false, updated_at = now()
  where public.group_overrides.group_id = g;
  return v_id;
end $$;

create function public.delete_group_override(p_token text, p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token);
begin
  update public.group_overrides set deleted = true, updated_at = now() where id = p_id and group_id = g;
end $$;

create function public.clear_stale_group_overrides(p_token text, p_keep_hash text) returns int
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); n int;
begin
  update public.group_overrides set deleted = true, updated_at = now()
   where group_id = g and not deleted and base_hash <> p_keep_hash;
  get diagnostics n = row_count;
  return n;
end $$;

create function public.put_group_homework(p_token text, p_row jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); v_id uuid; n int;
begin
  perform public.purge_tombstones();
  v_id := coalesce((p_row->>'id')::uuid, gen_random_uuid());
  if not exists (select 1 from public.group_homework where id = v_id) then
    select count(*) into n from public.group_homework where group_id = g and not deleted;
    if n >= 300 then raise exception 'too_many'; end if;
  end if;
  insert into public.group_homework (id, group_id, subject, body, due_date, kind, deleted, updated_at)
  values (v_id, g, p_row->>'subject', p_row->>'body', (p_row->>'due_date')::date, nullif(p_row->>'kind',''), false, now())
  on conflict (id) do update set
    subject = excluded.subject, body = excluded.body, due_date = excluded.due_date, kind = excluded.kind, deleted = false, updated_at = now()
  where public.group_homework.group_id = g;
  return v_id;
end $$;

create function public.delete_group_homework(p_token text, p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token);
begin
  update public.group_homework set deleted = true, updated_at = now() where id = p_id and group_id = g;
end $$;

create function public.owner_issue_code(p_group text) returns text
language plpgsql security definer set search_path = '' as $$
declare c text;
begin
  c := upper(substr(translate(replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''), '01ilo', 'wxyzv'), 1, 10));
  insert into public.group_codes (code, group_id) values (c, p_group);
  return c;
end $$;

revoke all on public.group_codes, public.group_overrides, public.group_homework from anon, authenticated;
revoke execute on function public.editor_group(text), public.purge_tombstones(), public.limit_codes_per_group(),
                           public.owner_issue_code(text) from public, anon, authenticated;
grant execute on function public.get_group_data(text, timestamptz), public.redeem_code(text), public.check_editor(text),
                          public.put_group_override(text, jsonb), public.delete_group_override(text, uuid),
                          public.clear_stale_group_overrides(text, text),
                          public.put_group_homework(text, jsonb), public.delete_group_homework(text, uuid)
  to anon, authenticated;
