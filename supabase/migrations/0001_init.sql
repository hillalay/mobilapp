-- Lesson tracker — offline-first senkron deposu
-- Supabase SQL Editor'de bir kez çalıştır.

-- ---------------------------------------------------------------------------
-- Tek tablo, kullanıcı başına anahtar/değer. Her yerel Hive kaydı burada bir
-- satır: (user_id, collection, key) -> jsonb data.
--
-- comment: tek jsonb tablosu; her domain için ayrı tablo yazmak yerine
-- senkron mantığı tek yerde toplanıyor. Sunucuda tipli sorgu gerekince
-- aşağıdaki view'lar gibi view eklenir, tablo şeması değişmez.
-- ---------------------------------------------------------------------------
create table if not exists public.records (
  user_id    uuid        not null references auth.users(id) on delete cascade,
  collection text        not null,
  key        text        not null,
  data       jsonb,
  deleted    boolean     not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, collection, key)
);

-- Çekme (pull) sorgusunun indeksi
create index if not exists records_user_updated_idx
  on public.records (user_id, updated_at);

-- updated_at her zaman sunucu saatiyle yazılır; istemci saatine güvenilmez
-- (cihaz saati yanlışsa senkron sırası bozulurdu).
create or replace function public.records_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists records_touch on public.records;
create trigger records_touch
  before insert or update on public.records
  for each row execute function public.records_touch();

-- ---------------------------------------------------------------------------
-- Row Level Security: her kullanıcı yalnızca kendi satırlarını görür/yazar.
-- ---------------------------------------------------------------------------
alter table public.records enable row level security;

drop policy if exists "records_own_rows" on public.records;
create policy "records_own_rows" on public.records
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Raporlama view'ları: jsonb'yi tipli kolonlara açar, SQL ile sorgulanabilir.
-- security_invoker = true -> view de RLS'e tabi kalır.
-- ---------------------------------------------------------------------------
create or replace view public.v_study_sessions
with (security_invoker = true) as
select
  user_id,
  key                                  as session_id,
  (data ->> 'startTime')::timestamptz  as start_time,
  (data ->> 'endTime')::timestamptz    as end_time,
  (data ->> 'durationSeconds')::int    as duration_seconds,
  updated_at
from public.records
where collection = 'study_sessions' and not deleted;

create or replace view public.v_daily_study_stats
with (security_invoker = true) as
select
  user_id,
  (data ->> 'dayKey')::date          as day,
  (data ->> 'totalSeconds')::int     as total_seconds,
  (data ->> 'manualQuestions')::int  as manual_questions,
  updated_at
from public.records
where collection = 'daily_study_stats' and not deleted;
