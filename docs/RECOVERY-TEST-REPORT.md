# Backup & Recovery Test Report

**Date:** 2026-09-20
**Environment:** AWS EC2 (`nestjs-ddd-devops-ec2`, t3.small, Elastic IP)
**Database:** PostgreSQL 16 (`postgresql-dev` container, database `db-dev`)
**Tester:** Mohamed Ayman Aboelmagd

## 1. Objective

Verify that the automated backup and restore scripts (`scripts/backup.sh`, `scripts/restore.sh`) can reliably back up the PostgreSQL database and Docker volume, and fully recover from a real data-loss scenario without manual intervention beyond running the scripts.

## 2. Scope

- PostgreSQL logical backup via `pg_dump` (primary recovery mechanism)
- Docker volume (bind-mounted data directory) filesystem backup via `tar`
- Automated daily scheduling via `cron` (`0 2 * * *`)
- Full restore test simulating real data loss

## 3. Test Procedure & Results

| Step | Action | Time (UTC) | Result |
|---|---|---|---|
| 1 | Created test table `recovery_test` with 3 sample rows | 06:15:52 | Success — 3 rows inserted and verified |
| 2 | Ran `./scripts/backup.sh` | 06:16:29 | Success — `db_20260920_061629.sql.gz` (895 bytes) and `volume_20260920_061629.tar.gz` created |
| 3 | Simulated data loss: `DROP TABLE recovery_test;` | 06:17:xx | Table dropped |
| 4 | Verified data loss: `SELECT * FROM recovery_test;` | 06:17:xx | Confirmed — `ERROR: relation "recovery_test" does not exist` |
| 5 | Ran `./scripts/restore.sh backups/db_20260920_061629.sql.gz` | 06:18:12 | Success — app container stopped, database restored (`COPY 3`), app container restarted |
| 6 | Verified restored data: `SELECT * FROM recovery_test;` | 06:18:13 | **All 3 rows recovered with identical `id`, `note`, and `created_at` values** |
| 7 | Verified application health post-restore: `curl /api/v1/health` | — | `"status":"ok"`, database connectivity confirmed |

**Total recovery time (backup taken to data verified restored):** ~2 minutes (manual execution; the scripts themselves complete in seconds — most of the time was manual verification between steps).

**Application downtime during restore:** A few seconds — `restore.sh` stops the `nestjs-app` container before touching the database (to release active connections) and restarts it immediately after. This is a known, intentional trade-off documented below.

## 4. Findings

- **Data integrity:** 100% — every field of every row matched exactly between the original and restored data, including auto-generated timestamps.
- **Automation reliability:** Both scripts ran without manual SQL intervention; all database operations (drop/create/restore) are handled by the scripts themselves.
- **Permissions issue found and fixed:** The initial `backup.sh` attempt failed to archive the Docker volume directory because it's owned by the PostgreSQL container's internal user, not the `ubuntu` host user. Fixed by using `sudo tar` for that step only (the `pg_dump` step needs no elevated privileges).
- **Active-connection issue found and fixed:** The initial `restore.sh` attempt failed because PostgreSQL refused to drop the database while the application held an active connection. Fixed by having the script stop the `nestjs-app` container before restoring, and restart it afterward.

## 5. Backup Automation

A `cron` job runs `scripts/backup.sh` daily at 02:00 UTC on the EC2 instance:

```
0 2 * * * /home/ubuntu/devops-project1/scripts/backup.sh >> /home/ubuntu/devops-project1/backups/backup.log 2>&1
```

Backups are retained locally for 7 days (`scripts/backup.sh` automatically deletes older `.sql.gz` and `.tar.gz` files); older backups are not currently archived offsite (see Known Limitations).

## 6. Known Limitations

- **Local storage only.** Backups are stored on the same EC2 instance they protect. If the instance's disk fails or the instance is terminated, both the live data and its backups would be lost together. Storing backups off-instance (e.g., S3) was considered but deferred as out of scope for this exercise.
- **Brief application downtime.** The restore process requires stopping the app container to safely release database connections; this is a deliberate trade-off for restore reliability over zero-downtime restores, which would require a more complex setup (e.g., connection draining, read replicas).
- **Volume backup not restore-tested.** This test validated the `pg_dump`/`psql` restore path (the primary recovery mechanism). The filesystem-level volume backup (`volume_*.tar.gz`) was created successfully but a full volume restore was not exercised in this test.
- **Single test scenario.** This test covers accidental table loss. Other failure modes (full disk corruption, container image loss, complete instance loss) are not yet tested.

## 7. Conclusion

The backup and recovery process is **verified working** for the primary failure scenario (accidental data loss within a running database). Recovery is fast, automated, and produces byte-for-byte accurate results. The system is scheduled to back up automatically on a daily basis without manual intervention.
