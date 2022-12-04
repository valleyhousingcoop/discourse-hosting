# Discourse Hosting

```shell
docker-compose run --rm web LOAD_PLUGINS=0 bundle exec rake plugin:pull_compatible_all
docker-compose run --rm web bundle exec rake db:migrate
docker-compose run --rm web bundle exec rake themes:update assets:precompile
docker-compose up
```