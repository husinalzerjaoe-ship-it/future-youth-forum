-- Supabase Storage policy for public-chat image/GIF uploads.
-- Run this in Supabase Dashboard > SQL Editor for project xwfzdiftlzrjsprnbwpf.
-- The app uploads to bucket "forum-media" at public-chat/<auth.uid()>/<filename>.
drop policy if exists "Authenticated members upload their own public chat media" on storage.objects;
create policy "Authenticated members upload their own public chat media"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'forum-media'
  and (storage.foldername(name))[1] = 'public-chat'
  and (storage.foldername(name))[2] = auth.uid()::text
  and metadata->>'mimetype' in ('image/jpeg', 'image/png', 'image/webp', 'image/gif')
  and coalesce((metadata->>'size')::bigint, 0) <= 10485760
);

-- Public chat images are displayed with getPublicUrl(), so the forum-media
-- bucket must be configured as a PUBLIC bucket in Supabase Storage settings.
-- Keep this bucket public only if its stories/profile media are intended public too.
