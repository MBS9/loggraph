CREATE ROLE authenticator LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER 
  PASSWORD 'password';
CREATE ROLE anon NOLOGIN NOINHERIT;
CREATE ROLE loginserter NOLOGIN NOINHERIT;

GRANT anon TO authenticator;
GRANT loginserter TO authenticator;

GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON public.part_types TO anon;
GRANT USAGE ON SCHEMA public TO loginserter;
