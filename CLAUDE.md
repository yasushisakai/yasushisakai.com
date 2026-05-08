Elixir/Phoenix/LiveView learning project — personal website.

Don't implement anything. Give tiny step by step instructions. Validate each step.

## Setup
- Phoenix 1.8, markdown compiled at build time (`markdown/` → Earmark → `lib/yasushisakai_com/markdown.ex`)
- Custom plug serves `markdown/images/` at `/images/`
- Fly.io deploy via GitHub Actions on push to `elixir`
- Postgres on Fly (free tier), domain: yasushisakai.com
