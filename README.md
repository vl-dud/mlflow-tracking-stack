# MLflow Tracking Stack

Docker Compose stack for a local MLflow tracking server: MLflow, PostgreSQL, MinIO, and Ofelia.

## What you need

[Docker](https://docs.docker.com/get-docker/) with Compose (`docker compose` or `docker-compose`).

## Services


| Service    | Role                                                                                                                        | Depends on     |
| ---------- | --------------------------------------------------------------------------------------------------------------------------- | -------------- |
| **minio**  | S3-compatible store for MLflow artifacts.                                                                                   | —              |
| **mc**     | One-shot bootstrap: configures the MinIO client alias and creates the `mlflow` bucket so the server can use `s3://mlflow/`. | **minio**      |
| **db**     | PostgreSQL backend store for MLflow metadata (experiments, runs, params, metrics).                                          | —              |
| **server** | Custom image running `mlflow server` against Postgres and MinIO.                                                            | **mc**, **db** |
| **ofelia** | Scheduler; talks to Docker and runs labeled jobs on the **server** container.                                               | **server**     |


Startup order in practice: **minio** and **db** start first; **mc** runs its bootstrap against MinIO; **server** starts after **mc** and a healthy **db**; **ofelia** starts after **server** so it can schedule jobs on that container.

## Environment variables

Defaults match `[.env.example](.env.example)`. Change secrets before any shared or production use.


| Name                    | Purpose                                                                                                                                     | Default           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `AWS_ACCESS_KEY_ID`     | MinIO root user; also passed to MLflow for S3 artifact access.                                                                              | `minio_key`       |
| `AWS_SECRET_ACCESS_KEY` | MinIO root password; also passed to MLflow for S3 artifact access.                                                                          | `minio_secret`    |
| `MINIO_PORT`            | MinIO S3 API port (host and container).                                                                                                     | `9000`            |
| `MINIO_CONSOLE_PORT`    | MinIO web console port.                                                                                                                     | `9090`            |
| `DB_PORT`               | PostgreSQL port inside the stack (used in URLs and health checks).                                                                          | `5432`            |
| `DB_NAME`               | PostgreSQL database name for MLflow metadata.                                                                                               | `mlflow_database` |
| `DB_USER`               | PostgreSQL user for MLflow.                                                                                                                 | `mlflow_user`     |
| `DB_PASSWORD`           | PostgreSQL password for `DB_USER`.                                                                                                          | `mlflow`          |
| `DEFAULT_ARTIFACT_ROOT` | Passed to `mlflow server --default-artifact-root` in Compose; must match the bucket the **mc** service creates (`mlflow` → `s3://mlflow/`). | `s3://mlflow/`    |
| `MLFLOW_SERVER_PORT`    | Host port mapped to MLflow UI and API (`5000` in the container).                                                                            | `5000`            |


## Run it

1. Copy `.env.example` to `.env` and set variables from the table above (especially credentials and ports).
2. Start:
  ```bash
   docker compose up -d
  ```
3. Open in the browser (ports come from `.env`):
  - MLflow: `http://localhost:<MLFLOW_SERVER_PORT>` (default `5000`)
  - MinIO console: `http://localhost:<MINIO_CONSOLE_PORT>` (default `9090`); log in with `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
4. Stop:
  ```bash
   docker compose down
  ```

## Use MLflow from Python

**MinIO bucket:** On startup, the **mc** service creates the `mlflow` bucket (see `docker-compose.yml`) so the artifact root `s3://mlflow/` exists before MLflow writes artifacts.

Point the client at the tracking server (host port from `MLFLOW_SERVER_PORT`, default `5000`):

```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")
```

Or with the environment variable (works for any MLflow client):

```bash
export MLFLOW_TRACKING_URI=http://localhost:5000
```

**Artifacts from the same machine as Compose:** Logging models or files (`mlflow.log_artifact`, `log_model`, etc.) usually requires direct access to MinIO using the same credentials as in `.env` and the **S3 API** port (`MINIO_PORT`, default `9000`). Set these before importing/using artifact APIs:

```python
import os

os.environ["MLFLOW_TRACKING_URI"] = "http://localhost:5000"
os.environ["MLFLOW_S3_ENDPOINT_URL"] = "http://127.0.0.1:9000"
os.environ["AWS_ACCESS_KEY_ID"] = "minio_key"  # match .env
os.environ["AWS_SECRET_ACCESS_KEY"] = "minio_secret"
```

If MinIO rejects virtual-hosted-style requests, set `AWS_S3_ADDRESSING_STYLE=path` for boto3.

**Another container on the same Compose network:** use `http://server:5000` for the tracking URI and `http://minio:9000` (with internal `MINIO_PORT`) for `MLFLOW_S3_ENDPOINT_URL`, with the same access key and secret.

## Additional Notes

- `minio_volume` and `db_volume` volumes are created to persist data for Minio and PostgreSQL, respectively. Data stored in these volumes will be retained across container restarts.
- Health checks and dependencies between services ensure that each service is ready before the next one starts.
- Ofelia job scheduler is used to run `mlflow gc` every 6 hours. `mlflow gc` permanently deletes runs in the *deleted* lifecycle stage.

