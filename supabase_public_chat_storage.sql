-- Forum media bucket: public media only (avatars, stories, chats, regional rooms, backgrounds).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'forum-media',
  'forum-media',
  true,
  104857600,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/quicktime','audio/mp4','audio/aac','audio/mpeg','audio/wav','audio/ogg','audio/flac','application/vnd.android.package-archive','application/octet-stream','application/zip','application/pdf']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public bucket: allow app users to read media URLs.
drop policy if exists "Forum media public read" on storage.objects;
create policy "Forum media public read"
on storage.objects for select
to public
using (bucket_id = 'forum-media');

-- Upload, update and delete only inside the signed-in Firebase user's own folder.
-- Firebase UID is read from JWT sub; auth.uid() is not a Firebase UID UUID.
drop policy if exists "Forum members upload own media" on storage.objects;
create policy "Forum members upload own media"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'forum-media'
  and (
    (
      (storage.foldername(name))[1] in (
        'public-chat','profiles','stories','private-chat','voice-messages',
        'chat-backgrounds','anime-wallpapers','shared-files'
      )
      and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    )
    or (
      (storage.foldername(name))[1] = 'regional-chat'
      and (storage.foldername(name))[3] = (auth.jwt()->>'sub')
    )
  )
);

drop policy if exists "Forum members update own media" on storage.objects;
create policy "Forum members update own media"
on storage.objects for update
to authenticated
using (
  bucket_id = 'forum-media'
  and (
    (
      (storage.foldername(name))[1] in (
        'public-chat','profiles','stories','private-chat','voice-messages',
        'chat-backgrounds','anime-wallpapers','shared-files'
      )
      and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    )
    or (
      (storage.foldername(name))[1] = 'regional-chat'
      and (storage.foldername(name))[3] = (auth.jwt()->>'sub')
    )
  )
)
with check (
  bucket_id = 'forum-media'
  and (
    (
      (storage.foldername(name))[1] in (
        'public-chat','profiles','stories','private-chat','voice-messages',
        'chat-backgrounds','anime-wallpapers','shared-files'
      )
      and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    )
    or (
      (storage.foldername(name))[1] = 'regional-chat'
      and (storage.foldername(name))[3] = (auth.jwt()->>'sub')
    )
  )
);

drop policy if exists "Forum members delete own media" on storage.objects;
create policy "Forum members delete own media"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'forum-media'
  and (
    (
      (storage.foldername(name))[1] in (
        'public-chat','profiles','stories','private-chat','voice-messages',
        'chat-backgrounds','anime-wallpapers','shared-files'
      )
      and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    )
    or (
      (storage.foldername(name))[1] = 'regional-chat'
      and (storage.foldername(name))[3] = (auth.jwt()->>'sub')
    )
  )
);
