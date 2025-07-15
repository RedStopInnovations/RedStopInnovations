### Docker setup for development

1. Install Docker
https://www.docker.com/products/docker-desktop

2. Open terminal and `cd` to the project's root

```
cd /path/to/project
```

3. Init `.env` file & `database` config


```
cp .env.template .env

```

3. Build docker containers

```
docker compose build
```

4. Start application

```
docker compose up -d
```

5. Init database

```
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed:admin_users
docker compose exec web bin/rails db:seed:subscription_plans
docker compose exec web bin/rails db:seed:hicaps_items
```

6. Check the app by visiting: http://localhost:3000


7. SSH to web container
```
docker compose exec web sh
```