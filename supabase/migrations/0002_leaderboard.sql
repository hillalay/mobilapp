-- Liderlik tablosu: kullanıcı adları + bugünün çalışma süresi
-- Supabase SQL Editor'de çalıştır. 0001_init.sql'den sonra gelir.

-- ---------------------------------------------------------------------------
-- profiles: liderlik tablosunda gösterilecek görünen ad.
-- `records` içindeki 'profile' koleksiyonundan ayrı bir şey — o, kullanıcının
-- alan seçimini (MF/TM/...) tutan yerel kayıt ve yalnızca sahibine görünür.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  user_id    uuid        primary key references auth.users(id) on delete cascade,
  username   text        not null unique,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Kullanıcı adları liderlik tablosunda görünüyor: giriş yapmış herkes okur.
drop policy if exists "profiles_read_authenticated" on public.profiles;
create policy "profiles_read_authenticated" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles_write_own" on public.profiles;
create policy "profiles_write_own" on public.profiles
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Kayıt olurken profil satırı trigger ile açılır.
--
-- İstemciden ayrı bir insert atmak yerine trigger kullanılıyor: kullanıcı adı
-- çakışırsa signUp'ın kendisi hata verir ve hesap hiç oluşmaz. Aksi halde
-- "hesabı var ama profili yok" gibi yarım bir durum çıkardı.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (user_id, username)
  values (new.id, new.raw_user_meta_data ->> 'username');
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- v_leaderboard_today
--
-- DİKKAT — security_invoker BİLEREK false:
-- `records` tablosunun RLS politikası herkesi kendi satırlarına kilitliyor.
-- Invoker modunda bu view yalnızca kendi süreni gösterirdi. Definer modunda
-- RLS atlanıyor, bu yüzden dışarı SADECE username ve total_seconds veriliyor;
-- user_id ve diğer alanlar sızmıyor. Erişim `authenticated` rolüyle sınırlı.
--
-- Sıralama `stopwatchSeconds` üzerinden: `totalSeconds` dashboard'daki manuel
-- "Süre Ekle" girişlerini de içeriyor, elle saat girip sırada yükselmek mümkün
-- olurdu. `stopwatchSeconds`'a yalnızca kronometre "Kaydet"e basınca yazılır.
-- Alan eklenmeden önceki kayıtlarda yok, o yüzden coalesce ile 0 sayılıyor.
--
-- Gün karşılaştırması: dayKey istemcide YEREL saatle 'YYYY-MM-DD' üretiliyor
-- (daily_study_stats_storage.dart:9). Postgres'in `current_date` değeri ise
-- sunucu saat diliminde, Supabase'de varsayılan UTC. Türkiye UTC+3 olduğu için
-- gece 00:00-03:00 arası ikisi farklı günü gösterir ve tablo boş kalırdı.
-- Bu yüzden karşılaştırma İstanbul saatine sabitlendi.
-- ---------------------------------------------------------------------------
drop view if exists public.v_leaderboard_today;
create view public.v_leaderboard_today
with (security_invoker = false) as
select
  p.username,
  coalesce((r.data ->> 'stopwatchSeconds')::int, 0) as stopwatch_seconds
from public.records r
join public.profiles p on p.user_id = r.user_id
where r.collection = 'daily_study_stats'
  and not r.deleted
  and r.data ->> 'dayKey' = (now() at time zone 'Europe/Istanbul')::date::text
  and coalesce((r.data ->> 'stopwatchSeconds')::int, 0) > 0;

revoke all on public.v_leaderboard_today from anon;
grant select on public.v_leaderboard_today to authenticated;
