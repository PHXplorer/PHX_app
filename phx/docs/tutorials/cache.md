[Back to main README](../../README.md#data-and-environment-variables)

# Cache

## How to reset the cache

When rapidly developing new features, cached outputs become outdated and irrelevant.

First of all, it is recommended to set the environment variable `ENABLE_REDIS=false` when doing development.

If you already have some cache that you would like to delete, there are multiple ways to do it:

1. Using R

If you have a `redis_client` object from `redis.R` module, you can call `redis_client$flush()` and it will remove all the data in Redis cache.

2. Using Redis CLI

Another approach is to use Redis CLI directly.
If you followed the instructions above, you should have a redis docker container running.
You can execute a command in this container without opening it directly with the following command from the terminal:

```shell
docker exec redis redis-cli flushall
```