-- Eksik tablo yetkileri.
--
-- Çalışan uygulamada senkron şu hatayla reddediliyordu:
--   code=42501  permission denied for table records
--
-- Sebep: RLS politikası tek başına yetmiyor. PostgreSQL'de önce rolün TABLO
-- ÜZERİNDE yetkisi olmalı, RLS ondan sonra devreye girip satırları süzüyor.
-- 0001_init.sql tabloyu oluşturup RLS'i açtı ama GRANT vermedi; Supabase'in
-- varsayılan yetkileri de bu tabloya uygulanmamış. Bu dosya onu tamamlıyor.
--
-- Silme yetkisi bilerek verilmiyor: senkron motoru kayıt silmiyor, `deleted`
-- bayrağıyla yumuşak silme yapıyor.

grant select, insert, update on public.records   to authenticated;
grant select, update          on public.profiles to authenticated;

-- Görünümler security definer olduğu için taban tablo yetkisi gerektirmiyor,
-- ama view'ın kendisinde select yetkisi gerekiyor (0002/0003'te de var,
-- tek dosyadan kurulum yapılırsa diye burada tekrarlanıyor).
grant select on public.v_leaderboard_today to authenticated;
grant select on public.v_leaderboard_week  to authenticated;

-- anon hiçbir şeye erişmemeli.
revoke all on public.records  from anon;
revoke all on public.profiles from anon;
