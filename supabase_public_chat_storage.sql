-- Supabase Storage setup for public chat media.
-- Firebase Auth is the app identity provider; Flutter forwards its Firebase ID token.
-- Register Firebase as a Third-party Auth provider in Supabase and set role=authenticated.

-- Public chat media is intentionally public. Never store private files in this bucket.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('forum-media', 'forum-media', true, 10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Authenticated members upload their own public chat media" on storage.objects;
create policy "Authenticated members upload their own public chat media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'forum-media'
  and (storage.foldername(name))[1] = 'public-chat'
  -- Firebase UID is text; auth.uid() casts sub to UUID and is not safe here.
  and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
  and metadata->>'mimetype' in ('image/jpeg', 'image/png', 'image/webp', 'image/gif')
  and coalesce((metadata->>'size')::bigint, 0) <= 10485760
);

drop policy if exists "Members delete their own public chat media" on storage.objects;
create policy "Members delete their own public chat media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'forum-media'
  and (storage.foldername(name))[1] = 'public-chat'
  and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
);
