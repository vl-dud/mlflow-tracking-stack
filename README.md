# MLflow Tracking Stack

Docker Compose stack for a local MLflow tracking server: MLflow, PostgreSQL, MinIO, and Ofelia.

## What you need

[Docker](https://docs.docker.com/get-docker/) with Compose (`docker compose` or `docker-compose`).

## Run it

1. Copy `.env.example` to `.env` and change passwords, ports, or bucket credentials.

2. Start:

   ```bash
   docker compose up -d
   ```

3. Open in the browser (ports come from `.env`):

   - MLflow: `http://localhost:<MLFLOW_SERVER_PORT>` (default `5000`)
   - MinIO console: `http://localhost:<MINIO_CONSOLE_PORT>` (default `9090`) — log in with `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`

4. Stop:

   ```bash
   docker compose down
   ```

## Additional Notes

- `minio_volume` and `db_volume` volumes are created to persist data for Minio and MySQL, respectively. Data stored in these volumes will be retained across container restarts.
- Health checks and dependencies between services ensure that each service is ready before the next one starts.
- Ofelia job scheduler is used to run `mlflow gc` every 6 hours. `mlflow gc` permanently deletes runs in the *deleted* lifecycle stage.
