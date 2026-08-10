-- Liderlik tablosu genişletmesi: avatar + haftalık görünüm + realtime
-- 0002_leaderboard.sql'den sonra çalıştır.

-- ---------------------------------------------------------------------------
-- Avatar
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists avatar_url text;

-- avatars bucket'ı public: liderlik tablosunda herkesin fotoğrafı görünüyor.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Yükleme yolu {user_id}/avatar.jpg — herkes yalnızca kendi klasörüne yazabilir.
drop policy if exists "avatars_read_all" on storage.objects;
create policy "avatars_read_all" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatars_write_own_folder" on storage.objects;
create policy "avatars_write_own_folder" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_update_own_folder" on storage.objects;
create policy "avatars_update_own_folder" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- Görünümler
--
-- security_invoker BİLEREK false — gerekçe 0002'de. Dışarı sadece username,
-- avatar_url ve stopwatch_seconds veriliyor; user_id sızmıyor.
--
-- Sıralama `stopwatchSeconds` üzerinden: `totalSeconds` manuel "Süre Ekle"
-- girişlerini de içeriyor, elle saat girip yükselmek mümkün olurdu.
--
-- Gün sınırı İstanbul saatine sabit: dayKey istemcide yerel saatle üretiliyor,
-- Postgres'in current_date değeri ise UTC olurdu (bkz. 0002).
-- ---------------------------------------------------------------------------
drop view if exists public.v_leaderboard_today;
create view public.v_leaderboard_today
with (security_invoker = false) as
select
  p.username,
  p.avatar_url,
  coalesce((r.data ->> 'stopwatchSeconds')::int, 0) as stopwatch_seconds
from public.records r
join public.profiles p on p.user_id = r.user_id
where r.collection = 'daily_study_stats'
  and not r.deleted
  and r.data ->> 'dayKey' = (now() at time zone 'Europe/Istanbul')::date::text
  and coalesce((r.data ->> 'stopwatchSeconds')::int, 0) > 0;

revoke all on public.v_leaderboard_today from anon;
grant select on public.v_leaderboard_today to authenticated;

-- Son 7 gün (bugün dahil), kullanıcı başına toplanmış.
drop view if exists public.v_leaderboard_week;
create view public.v_leaderboard_week
with (security_invoker = false) as
select
  p.username,
  p.avatar_url,
  sum(coalesce((r.data ->> 'stopwatchSeconds')::int, 0))::int as stopwatch_seconds
from public.records r
join public.profiles p on p.user_id = r.user_id
where r.collection = 'daily_study_stats'
  and not r.deleted
  and (r.data ->> 'dayKey')::date
      > (now() at time zone 'Europe/Istanbul')::date - interval '7 days'
group by p.username, p.avatar_url
having sum(coalesce((r.data ->> 'stopwatchSeconds')::int, 0)) > 0;

revoke all on public.v_leaderboard_week from anon;
grant select on public.v_leaderboard_week to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
--
-- DİKKAT: `records` üzerindeki RLS realtime'da da geçerli. Yani bu yayın
-- kullanıcıya YALNIZCA kendi satırlarının değişimini iletir; başkalarının
-- süre güncellemeleri anlık gelmez. Liderlik tablosu bu yüzden hem realtime
-- dinliyor hem de sayfa açıkken periyodik olarak yeniden çekiyor.
-- Kimin şu anda çalıştığı bilgisi Realtime Presence'tan geliyor, DB'den değil.
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.records;
