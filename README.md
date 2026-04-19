# MLflow Tracking Stack

Docker Compose stack for a local MLflow tracking server: MLflow, PostgreSQL, MinIO, and Ofelia.

## What you need

[Docker](https://docs.docker.com/get-docker/) with Compose (`docker compose` or `docker-compose`).

## Services

| Service | Role | Depends on |
| --- | --- | --- |
| **minio** | S3-compatible store for MLflow artifacts. | — |
| **mc** | One-shot bootstrap: configures the MinIO client alias and creates the `mlflow` bucket so the server can use `s3://mlflow/`. | **minio** |
| **db** | PostgreSQL backend store for MLflow metadata (experiments, runs, params, metrics). | — |
| **server** | Custom image running `mlflow server` against Postgres and MinIO. | **mc**, **db** |
| **ofelia** | Scheduler; talks to Docker and runs labeled jobs on the **server** container. | **server** |

Startup order in practice: **minio** and **db** start first; **mc** runs its bootstrap against MinIO; **server** starts after **mc** and a healthy **db**; **ofelia** starts after **server** so it can schedule jobs on that container.

## Environment variables

Defaults match [`.env.example`](.env.example). Change secrets before any shared or production use.

| Name | Purpose | Default |
| --- | --- | --- |
| `AWS_ACCESS_KEY_ID` | MinIO root user; also passed to MLflow for S3 artifact access. | `minio_key` |
| `AWS_SECRET_ACCESS_KEY` | MinIO root password; also passed to MLflow for S3 artifact access. | `minio_secret` |
| `MINIO_PORT` | MinIO S3 API port (host and container). | `9000` |
| `MINIO_CONSOLE_PORT` | MinIO web console port. | `9090` |
| `DB_PORT` | PostgreSQL port inside the stack (used in URLs and health checks). | `5432` |
| `DB_NAME` | PostgreSQL database name for MLflow metadata. | `mlflow_database` |
| `DB_USER` | PostgreSQL user for MLflow. | `mlflow_user` |
| `DB_PASSWORD` | PostgreSQL password for `DB_USER`. | `mlflow` |
| `DEFAULT_ARTIFACT_ROOT` | Reference for clients/docs; the server artifact root is set in `docker-compose.yml` (`s3://mlflow/`). Update both if you rename the bucket. | `s3://mlflow/` |
| `MLFLOW_SERVER_PORT` | Host port mapped to MLflow UI and API (`5000` in the container). | `5000` |

## Run it

1. Copy `.env.example` to `.env` and set variables from the table above (especially credentials and ports).

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

- `minio_volume` and `db_volume` volumes are created to persist data for Minio and PostgreSQL, respectively. Data stored in these volumes will be retained across container restarts.
- Health checks and dependencies between services ensure that each service is ready before the next one starts.
- Ofelia job scheduler is used to run `mlflow gc` every 6 hours. `mlflow gc` permanently deletes runs in the *deleted* lifecycle stage.
