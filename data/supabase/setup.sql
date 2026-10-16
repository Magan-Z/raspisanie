-- Общие данные групп для приложения «UniGraf»: правки старосты и ДЗ группы (Supabase / Postgres).
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
  if (select count(*) from public.group_codes where group_id = new.group_id) >= 3 then
    raise exception 'У группы % уже три кода старосты', new.group_id;
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

-- ============================================================================
-- Часть 2 (миграция group_homework_files): файлы и фото к ДЗ старосты.
-- Содержимое файла хранится в таблице group_files, в ДЗ лежит только список (id, название, размер).
-- Лимиты: файл до 8 МБ, до 5 файлов на ДЗ, до 150 МБ на группу. Файлы без ДЗ удаляются сами.
-- ============================================================================
alter table public.group_homework add column files jsonb not null default '[]'::jsonb
  check (jsonb_typeof(files) = 'array' and jsonb_array_length(files) <= 5);

create table public.group_files (
  id          uuid primary key,
  group_id    text not null check (group_id ~ '^[a-z0-9-]{3,40}$'),
  name        text not null check (length(name) between 1 and 200),
  size        int  not null check (size between 1 and 8388608),
  data        bytea not null,
  created_at  timestamptz not null default now()
);
create index group_files_group on public.group_files (group_id);
alter table public.group_files enable row level security;
revoke all on public.group_files from anon, authenticated;

create function public.purge_group_files(p_group text) returns void
language sql security definer set search_path = '' as $$
  delete from public.group_files f
   where f.group_id = p_group
     and f.created_at < now() - interval '1 hour'
     and not exists (
       select 1 from public.group_homework h, jsonb_array_elements(h.files) e
        where h.group_id = p_group and not h.deleted and e->>'id' = f.id::text);
$$;

create function public.put_group_file(p_token text, p_id uuid, p_name text, p_data text) returns void
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); bytes bytea; used bigint;
begin
  if length(p_data) > 11500000 then raise exception 'file_too_big'; end if;
  bytes := decode(p_data, 'base64');
  if octet_length(bytes) > 8388608 or octet_length(bytes) = 0 then raise exception 'file_too_big'; end if;
  perform public.purge_group_files(g);
  select coalesce(sum(size), 0) into used from public.group_files where group_id = g;
  if used + octet_length(bytes) > 157286400 then raise exception 'quota'; end if;
  insert into public.group_files (id, group_id, name, size, data)
  values (p_id, g, left(p_name, 200), octet_length(bytes), bytes)
  on conflict (id) do nothing;
end $$;

create function public.get_group_file(p_group text, p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare r public.group_files%rowtype;
begin
  if p_group is null or p_group !~ '^[a-z0-9-]{3,40}$' then raise exception 'bad_group'; end if;
  select * into r from public.group_files where id = p_id and group_id = p_group;
  if not found then raise exception 'no_file'; end if;
  return jsonb_build_object('name', r.name, 'data', encode(r.data, 'base64'));
end $$;

create or replace function public.put_group_homework(p_token text, p_row jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); v_id uuid; n int; fl jsonb := coalesce(p_row->'files', '[]'::jsonb);
begin
  perform public.purge_tombstones();
  if jsonb_typeof(fl) <> 'array' or jsonb_array_length(fl) > 5 then raise exception 'too_many_files'; end if;
  v_id := coalesce((p_row->>'id')::uuid, gen_random_uuid());
  if not exists (select 1 from public.group_homework where id = v_id) then
    select count(*) into n from public.group_homework where group_id = g and not deleted;
    if n >= 300 then raise exception 'too_many'; end if;
  end if;
  insert into public.group_homework (id, group_id, subject, body, due_date, kind, files, deleted, updated_at)
  values (v_id, g, p_row->>'subject', p_row->>'body', (p_row->>'due_date')::date, nullif(p_row->>'kind',''), fl, false, now())
  on conflict (id) do update set
    subject = excluded.subject, body = excluded.body, due_date = excluded.due_date, kind = excluded.kind, files = excluded.files, deleted = false, updated_at = now()
  where public.group_homework.group_id = g;
  perform public.purge_group_files(g);
  return v_id;
end $$;

create or replace function public.delete_group_homework(p_token text, p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token);
begin
  update public.group_homework set deleted = true, updated_at = now() where id = p_id and group_id = g;
  perform public.purge_group_files(g);
end $$;

revoke execute on function public.purge_group_files(text) from public, anon, authenticated;
grant execute on function public.put_group_file(text, uuid, text, text), public.get_group_file(text, uuid) to anon, authenticated;

-- ============================================================================
-- Часть 3 (миграция group_homework_subgroup): ДЗ можно задать одной подгруппе.
-- subgroup — номер подгруппы (1–6); null — всей группе.
-- ============================================================================
alter table public.group_homework add column subgroup smallint check (subgroup between 1 and 6);

create or replace function public.put_group_homework(p_token text, p_row jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare g text := public.editor_group(p_token); v_id uuid; n int; fl jsonb := coalesce(p_row->'files', '[]'::jsonb);
begin
  perform public.purge_tombstones();
  if jsonb_typeof(fl) <> 'array' or jsonb_array_length(fl) > 5 then raise exception 'too_many_files'; end if;
  v_id := coalesce((p_row->>'id')::uuid, gen_random_uuid());
  if not exists (select 1 from public.group_homework where id = v_id) then
    select count(*) into n from public.group_homework where group_id = g and not deleted;
    if n >= 300 then raise exception 'too_many'; end if;
  end if;
  insert into public.group_homework (id, group_id, subject, body, due_date, kind, subgroup, files, deleted, updated_at)
  values (v_id, g, p_row->>'subject', p_row->>'body', (p_row->>'due_date')::date, nullif(p_row->>'kind',''),
          nullif(p_row->>'subgroup','')::smallint, fl, false, now())
  on conflict (id) do update set
    subject = excluded.subject, body = excluded.body, due_date = excluded.due_date, kind = excluded.kind,
    subgroup = excluded.subgroup, files = excluded.files, deleted = false, updated_at = now()
  where public.group_homework.group_id = g;
  perform public.purge_group_files(g);
  return v_id;
end $$;

-- ============================================================================
-- Часть 4 (миграция group_files_download_ceiling): суточный потолок на скачивание файлов ДЗ.
-- Защита от многократной загрузки одних и тех же файлов (бесплатный план: 5 ГБ трафика в месяц).
-- Не больше 100 скачиваний одного файла в сутки и не больше 160 МБ в сутки на весь проект.
-- Когда потолок достигнут, get_group_file отвечает ошибкой download_limit (приложение пишет «Попробуйте завтра»);
-- остальное (расписание, правки, ДЗ без файлов, уже скачанные файлы) работает. Изменить потолки: числа в функции ниже.
-- ============================================================================
create table public.download_day (
  day   date primary key,
  bytes bigint not null default 0
);
create table public.download_file_day (
  day     date not null,
  file_id uuid not null,
  n       int  not null default 0,
  primary key (day, file_id)
);
alter table public.download_day enable row level security;
alter table public.download_file_day enable row level security;
revoke all on public.download_day, public.download_file_day from anon, authenticated;

create or replace function public.get_group_file(p_group text, p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r public.group_files%rowtype; cnt int; total bigint;
begin
  if p_group is null or p_group !~ '^[a-z0-9-]{3,40}$' then raise exception 'bad_group'; end if;
  select * into r from public.group_files where id = p_id and group_id = p_group;
  if not found then raise exception 'no_file'; end if;
  -- потолок на один файл: не больше 100 скачиваний в сутки (в группе обычно 20-30 человек, каждый качает один раз)
  insert into public.download_file_day (day, file_id, n) values (current_date, p_id, 1)
    on conflict (day, file_id) do update set n = public.download_file_day.n + 1
    returning n into cnt;
  if cnt > 100 then raise exception 'download_limit'; end if;
  -- общий потолок на весь проект: 160 МБ в сутки (бесплатный план: 5 ГБ трафика в месяц)
  insert into public.download_day (day, bytes) values (current_date, r.size)
    on conflict (day) do update set bytes = public.download_day.bytes + excluded.bytes
    returning bytes into total;
  if total > 167772160 then raise exception 'download_limit'; end if;
  -- старые счётчики не копим
  delete from public.download_day where day < current_date - 7;
  delete from public.download_file_day where day < current_date - 7;
  return jsonb_build_object('name', r.name, 'data', encode(r.data, 'base64'));
end $$;


-- ============================================================================
-- Часть 5 (миграция teacher_mode): режим преподавателя и ДЗ от преподавателя.
-- Код преподавателя выдаёт владелец (на преподавателя и список его групп):
--   select public.owner_issue_teacher_code('Фамилия И.О.', array['ofo-1-bi-25', 'ofo-2-bi-25']);
-- Список групп строит скрипт data/tools/teacher_codes_sql.py из расписания.
-- Отозвать: delete from public.teacher_codes where code = 'КОД';  (токены уже введённых кодов тоже перестают работать)
-- Выдать заново: update public.teacher_codes set token = null, used_at = null where code = 'КОД';
-- Изменить список групп: update public.teacher_codes set groups = array[...] where teacher = 'Фамилия И.О.';
-- ДЗ преподавателей: group_homework.author (имя) и batch_id (одна отправка нескольким группам); студенты читают их
-- отдельным ключом teacher_homework в get_group_data (старые версии приложения его не видят).
-- ============================================================================
create table public.teacher_codes (
  code       text primary key,
  teacher    text not null check (length(teacher) between 3 and 80),
  groups     text[] not null check (cardinality(groups) between 1 and 80),
  token      text unique,
  used_at    timestamptz,
  created_at timestamptz not null default now()
);
alter table public.teacher_codes enable row level security;
revoke all on public.teacher_codes from anon, authenticated;

create function public.limit_teacher_codes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (select count(*) from public.teacher_codes where lower(teacher) = lower(new.teacher)) >= 2 then
    raise exception 'У преподавателя % уже два кода', new.teacher;
  end if;
  if exists (select 1 from unnest(new.groups) g where g !~ '^[a-z0-9-]{3,40}$') then
    raise exception 'bad_group';
  end if;
  return new;
end $$;
create trigger teacher_codes_limit before insert on public.teacher_codes
  for each row execute function public.limit_teacher_codes();

alter table public.group_homework add column author text check (length(author) <= 80);
alter table public.group_homework add column batch_id uuid;
create index group_homework_batch on public.group_homework (batch_id) where batch_id is not null;
create index group_homework_author on public.group_homework (author) where author is not null;

create function public.teacher_row(p_token text) returns public.teacher_codes
language plpgsql security definer set search_path = '' as $$
declare r public.teacher_codes%rowtype;
begin
  select * into r from public.teacher_codes where token = p_token and p_token is not null;
  if not found then raise exception 'bad_token'; end if;
  return r;
end $$;

create function public.redeem_teacher_code(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r public.teacher_codes%rowtype; t text;
begin
  select * into r from public.teacher_codes where code = upper(trim(p_code));
  if not found then raise exception 'bad_code'; end if;
  if r.token is not null then raise exception 'code_used'; end if;
  t := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  update public.teacher_codes set token = t, used_at = now() where code = r.code;
  return jsonb_build_object('teacher', r.teacher, 'groups', to_jsonb(r.groups), 'token', t);
end $$;

create function public.check_teacher(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r public.teacher_codes%rowtype;
begin
  r := public.teacher_row(p_token);
  return jsonb_build_object('teacher', r.teacher, 'groups', to_jsonb(r.groups));
end $$;

-- Файлы преподавателя хранятся один раз (для всех групп пачки) под служебным «группой» teacher-XXXXXXXX
create function public.purge_teacher_files(p_gid text) returns void
language sql security definer set search_path = '' as $$
  delete from public.group_files f
   where f.group_id = p_gid
     and f.created_at < now() - interval '1 hour'
     and not exists (
       select 1 from public.group_homework h, jsonb_array_elements(h.files) e
        where h.author is not null and not h.deleted and e->>'id' = f.id::text);
$$;

create function public.put_teacher_file(p_token text, p_id uuid, p_name text, p_data text) returns void
language plpgsql security definer set search_path = '' as $$
declare t public.teacher_codes%rowtype; g text; bytes bytea; used bigint;
begin
  t := public.teacher_row(p_token);
  g := 'teacher-' || substr(md5(lower(t.teacher)), 1, 8);
  if length(p_data) > 11500000 then raise exception 'file_too_big'; end if;
  bytes := decode(p_data, 'base64');
  if octet_length(bytes) > 8388608 or octet_length(bytes) = 0 then raise exception 'file_too_big'; end if;
  perform public.purge_teacher_files(g);
  select coalesce(sum(size), 0) into used from public.group_files where group_id = g;
  if used + octet_length(bytes) > 157286400 then raise exception 'quota'; end if;
  insert into public.group_files (id, group_id, name, size, data)
  values (p_id, g, left(p_name, 200), octet_length(bytes), bytes)
  on conflict (id) do nothing;
end $$;

create function public.put_teacher_homework(p_token text, p_row jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  t public.teacher_codes%rowtype; v_batch uuid; fl jsonb; tg jsonb; e record; ids text[] := '{}'; gid text; sg smallint;
  is_new boolean; n int; g text;
begin
  t := public.teacher_row(p_token);
  perform public.purge_tombstones();
  fl := coalesce(p_row->'files', '[]'::jsonb);
  if jsonb_typeof(fl) <> 'array' or jsonb_array_length(fl) > 5 then raise exception 'too_many_files'; end if;
  tg := p_row->'groups';
  if tg is null or jsonb_typeof(tg) <> 'array' or jsonb_array_length(tg) < 1 or jsonb_array_length(tg) > 80 then raise exception 'bad_groups'; end if;
  -- каждая цель: {id, subgroup?}; только группы из списка преподавателя, без повторов
  for e in select value from jsonb_array_elements(tg) loop
    gid := e.value->>'id';
    if gid is null or not (gid = any (t.groups)) then raise exception 'forbidden_group'; end if;
    if gid = any (ids) then raise exception 'bad_groups'; end if;
    ids := ids || gid;
  end loop;

  v_batch := coalesce((p_row->>'batch_id')::uuid, gen_random_uuid());
  if exists (select 1 from public.group_homework where batch_id = v_batch and author is distinct from t.teacher) then raise exception 'bad_batch'; end if;
  is_new := not exists (select 1 from public.group_homework where batch_id = v_batch and author = t.teacher);
  if is_new then
    select count(distinct batch_id) into n from public.group_homework where author = t.teacher and not deleted;
    if n >= 300 then raise exception 'too_many'; end if;
    select count(distinct batch_id) into n from public.group_homework where author = t.teacher and updated_at > now() - interval '1 hour';
    if n >= 30 then raise exception 'rate_limit'; end if;
  end if;

  -- группы, которых больше нет в пачке, снимаем
  update public.group_homework set deleted = true, updated_at = now()
   where batch_id = v_batch and author = t.teacher and not deleted and not (group_id = any (ids));

  foreach g in array ids loop
    sg := null;
    select nullif(x.value->>'subgroup', '')::smallint into sg from jsonb_array_elements(tg) x where x.value->>'id' = g;
    update public.group_homework set subject = p_row->>'subject', body = p_row->>'body', due_date = (p_row->>'due_date')::date,
           kind = nullif(p_row->>'kind', ''), subgroup = sg, files = fl, deleted = false, updated_at = now()
     where batch_id = v_batch and author = t.teacher and group_id = g;
    if not found then
      select count(*) into n from public.group_homework where group_id = g and author is not null and not deleted;
      if n >= 100 then raise exception 'too_many'; end if;
      insert into public.group_homework (group_id, subject, body, due_date, kind, subgroup, files, deleted, updated_at, author, batch_id)
      values (g, p_row->>'subject', p_row->>'body', (p_row->>'due_date')::date, nullif(p_row->>'kind', ''), sg, fl, false, now(), t.teacher, v_batch);
    end if;
  end loop;
  perform public.purge_teacher_files('teacher-' || substr(md5(lower(t.teacher)), 1, 8));
  return v_batch;
end $$;

create function public.delete_teacher_homework(p_token text, p_batch uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare t public.teacher_codes%rowtype;
begin
  t := public.teacher_row(p_token);
  update public.group_homework set deleted = true, updated_at = now() where batch_id = p_batch and author = t.teacher;
  perform public.purge_teacher_files('teacher-' || substr(md5(lower(t.teacher)), 1, 8));
end $$;

create function public.get_teacher_homework(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare t public.teacher_codes%rowtype;
begin
  t := public.teacher_row(p_token);
  return coalesce((
    select jsonb_agg(b order by (b->>'due_date') desc, b->>'batch_id') from (
      select jsonb_build_object(
        'batch_id', batch_id, 'subject', min(subject), 'body', min(body), 'due_date', min(due_date), 'kind', min(kind),
        'files', (array_agg(files))[1],
        'groups', jsonb_agg(jsonb_build_object('id', group_id, 'subgroup', subgroup) order by group_id),
        'updated_at', max(updated_at)) as b
        from public.group_homework
       where author = t.teacher and not deleted and batch_id is not null
       group by batch_id) s), '[]'::jsonb);
end $$;

-- Читает группа: ДЗ старосты отдельно, ДЗ преподавателей — отдельным ключом (старые версии приложения его просто не видят)
create or replace function public.get_group_data(p_group text, p_since timestamptz default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
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
      select jsonb_agg(to_jsonb(h) - 'group_id' - 'author' - 'batch_id')
      from public.group_homework h
      where h.group_id = p_group and h.author is null and (p_since is null and not h.deleted or p_since is not null and h.updated_at > p_since)
    ), '[]'::jsonb),
    'teacher_homework', coalesce((
      select jsonb_agg(to_jsonb(h) - 'group_id' - 'batch_id')
      from public.group_homework h
      where h.group_id = p_group and h.author is not null and (p_since is null and not h.deleted or p_since is not null and h.updated_at > p_since)
    ), '[]'::jsonb)
  );
end $$;

-- Файл отдаётся, если он лежит в этой группе или прикреплён к живому ДЗ этой группы (файлы преподавателя хранятся один раз)
create or replace function public.get_group_file(p_group text, p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare r public.group_files%rowtype; cnt int; total bigint;
begin
  if p_group is null or p_group !~ '^[a-z0-9-]{3,40}$' then raise exception 'bad_group'; end if;
  select * into r from public.group_files f
   where f.id = p_id and (f.group_id = p_group or (f.group_id like 'teacher-%' and exists (
     select 1 from public.group_homework h, jsonb_array_elements(h.files) e
      where h.group_id = p_group and h.author is not null and not h.deleted and e->>'id' = p_id::text)));
  if not found then raise exception 'no_file'; end if;
  insert into public.download_file_day (day, file_id, n) values (current_date, p_id, 1)
    on conflict (day, file_id) do update set n = public.download_file_day.n + 1
    returning n into cnt;
  if cnt > 100 then raise exception 'download_limit'; end if;
  insert into public.download_day (day, bytes) values (current_date, r.size)
    on conflict (day) do update set bytes = public.download_day.bytes + excluded.bytes
    returning bytes into total;
  if total > 167772160 then raise exception 'download_limit'; end if;
  delete from public.download_day where day < current_date - 7;
  delete from public.download_file_day where day < current_date - 7;
  return jsonb_build_object('name', r.name, 'data', encode(r.data, 'base64'));
end $$;

create function public.owner_issue_teacher_code(p_teacher text, p_groups text[]) returns text
language plpgsql security definer set search_path = '' as $$
declare c text;
begin
  c := upper(substr(translate(replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''), '01ilo', 'wxyzv'), 1, 10));
  insert into public.teacher_codes (code, teacher, groups) values (c, p_teacher, p_groups);
  return c;
end $$;

revoke execute on function public.teacher_row(text), public.purge_teacher_files(text), public.limit_teacher_codes(),
                           public.owner_issue_teacher_code(text, text[]) from public, anon, authenticated;
grant execute on function public.redeem_teacher_code(text), public.check_teacher(text), public.put_teacher_file(text, uuid, text, text),
                          public.put_teacher_homework(text, jsonb), public.delete_teacher_homework(text, uuid), public.get_teacher_homework(text)
  to anon, authenticated;

-- ============================================================================
-- Часть 6 (миграции fix_file_base64_newlines и file_functions_statement_timeout): исправления работы с файлами.
-- 1) encode(..., 'base64') вставляет перенос строки каждые 76 знаков, а приложение (Dart) такой текст не читает:
--    любой файл больше ~57 байт не скачивался («Не удалось скачать файл»). get_group_file теперь отдаёт base64 без переносов
--    (функция выше в части 5 переопределена так: в конце translate(encode(r.data, 'base64'), E'\n\r', '')).
-- 2) Роль anon обрывает запрос через 3 секунды; загрузка файла до 8 МБ иногда не успевала. Функциям работы с файлами
--    выдан свой срок 25 секунд (настройка внутри функции действует), а столбец с файлами не сжимается повторно.
-- ============================================================================
alter function public.put_group_file(text, uuid, text, text) set statement_timeout = '25s';
alter function public.put_teacher_file(text, uuid, text, text) set statement_timeout = '25s';
alter function public.get_group_file(text, uuid) set statement_timeout = '25s';
alter table public.group_files alter column data set storage external;

create or replace function public.get_group_file(p_group text, p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' set statement_timeout = '25s' as $$
declare r public.group_files%rowtype; cnt int; total bigint;
begin
  if p_group is null or p_group !~ '^[a-z0-9-]{3,40}$' then raise exception 'bad_group'; end if;
  select * into r from public.group_files f
   where f.id = p_id and (f.group_id = p_group or (f.group_id like 'teacher-%' and exists (
     select 1 from public.group_homework h, jsonb_array_elements(h.files) e
      where h.group_id = p_group and h.author is not null and not h.deleted and e->>'id' = p_id::text)));
  if not found then raise exception 'no_file'; end if;
  insert into public.download_file_day (day, file_id, n) values (current_date, p_id, 1)
    on conflict (day, file_id) do update set n = public.download_file_day.n + 1
    returning n into cnt;
  if cnt > 100 then raise exception 'download_limit'; end if;
  insert into public.download_day (day, bytes) values (current_date, r.size)
    on conflict (day) do update set bytes = public.download_day.bytes + excluded.bytes
    returning bytes into total;
  if total > 167772160 then raise exception 'download_limit'; end if;
  delete from public.download_day where day < current_date - 7;
  delete from public.download_file_day where day < current_date - 7;
  return jsonb_build_object('name', r.name, 'data', translate(encode(r.data, 'base64'), E'\n\r', ''));
end $$;
