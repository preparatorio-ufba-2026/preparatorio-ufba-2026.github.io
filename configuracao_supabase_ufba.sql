-- Execute no SQL Editor de um projeto Supabase SEPARADO para o Preparatório UFBA.
create table if not exists public.ufba_administradores (
 user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.ufba_questoes (
 id bigint primary key,
 conteudo jsonb not null,
 imagens jsonb not null default '[]'::jsonb,
 atualizado_em timestamptz not null default now()
);
alter table public.ufba_administradores enable row level security;
alter table public.ufba_questoes enable row level security;
create policy "Ler proprio perfil" on public.ufba_administradores for select to authenticated using (user_id = (select auth.uid()));
create policy "Leitura publica de questoes" on public.ufba_questoes for select to anon, authenticated using (true);
create policy "Admin cadastra questoes" on public.ufba_questoes for insert to authenticated with check (exists(select 1 from public.ufba_administradores a where a.user_id = (select auth.uid())));
create policy "Admin edita questoes" on public.ufba_questoes for update to authenticated using (exists(select 1 from public.ufba_administradores a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.ufba_administradores a where a.user_id = (select auth.uid())));
create policy "Admin exclui questoes" on public.ufba_questoes for delete to authenticated using (exists(select 1 from public.ufba_administradores a where a.user_id = (select auth.uid())));
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('ufba-imagens','ufba-imagens',true,5242880,array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;
create policy "Imagens publicas UFBA" on storage.objects for select to anon, authenticated using (bucket_id='ufba-imagens');
create policy "Admin envia imagens UFBA" on storage.objects for insert to authenticated with check (bucket_id='ufba-imagens' and exists(select 1 from public.ufba_administradores a where a.user_id=(select auth.uid())));
-- APOS CRIAR O USUARIO EM Authentication > Users, copie o UUID e execute:
-- insert into public.ufba_administradores(user_id) values ('UUID-DO-SEU-USUARIO');
