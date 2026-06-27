docker stop $(docker ps -qa);
docker rm $(docker ps -qa);
docker rmi $(docker images -q);
docker volume rm $(docker volume ls -qf dangling=true);
docker buildx prune -fa;
docker system prune -fa;
