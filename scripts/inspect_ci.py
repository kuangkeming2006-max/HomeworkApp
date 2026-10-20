"""Download one real CI run's evidence on Windows/Linux. Requires an authenticated gh CLI."""
import argparse
import json
from pathlib import Path
import subprocess


def gh(arguments, check=True):
    result = subprocess.run(["gh", *arguments], capture_output=True, text=True, encoding="utf-8")
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip() or "GitHub CLI failed")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="kuangkeming2006-max/HomeworkApp")
    parser.add_argument("--run", type=int)
    parser.add_argument("--download", action="store_true")
    args = parser.parse_args()
    run_id = args.run
    if run_id is None:
        runs = json.loads(gh(["run", "list", "--repo", args.repo, "--workflow", "apple.yml",
                              "--branch", "main", "--limit", "1", "--json", "databaseId"]).stdout)
        if not runs:
            raise RuntimeError("No Apple CI run exists yet")
        run_id = runs[0]["databaseId"]
    run = json.loads(gh(["run", "view", str(run_id), "--repo", args.repo,
                         "--json", "status,conclusion,headSha,url,jobs"]).stdout)
    print(f"{run['url']}\nCommit {run['headSha']}\n{run['status']}: {run['conclusion'] or 'pending'}")
    for job in run["jobs"]:
        print(f"  {job['name']}: {job['conclusion'] or job['status']}")
    if args.download:
        if run["status"] != "completed":
            raise RuntimeError("Run is still active; download after completion to obtain all diagnostics")
        destination = Path("artifacts") / str(run_id)
        destination.mkdir(parents=True, exist_ok=False)
        (destination / "run.json").write_text(json.dumps(run, indent=2), encoding="utf-8")
        logs = gh(["run", "view", str(run_id), "--repo", args.repo, "--log"], check=False)
        (destination / "actions.log").write_text(logs.stdout or logs.stderr, encoding="utf-8")
        artifacts = gh(["run", "download", str(run_id), "--repo", args.repo,
                         "--dir", str(destination)], check=False)
        if artifacts.returncode:
            print("Artifact download: " + artifacts.stderr.strip())
        for summary in destination.rglob("test-summary.json"):
            try:
                content = json.loads(summary.read_text())
                print(f"Test summary {summary}: {content.get('result', 'see JSON')}")
            except (ValueError, OSError):
                print(f"Summary unavailable: {summary}; inspect raw logs")
        print(f"Evidence saved to {destination.resolve()}")


if __name__ == "__main__":
    main()
