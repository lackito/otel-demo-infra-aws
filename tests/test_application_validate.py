"""Exercise validation success and failure paths without contacting a cluster."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/application-validate"
MOCK_KUBECTL = r'''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps(args) + "\n")
scenario = os.environ["SCENARIO"]
if args[:2] == ["config", "get-contexts"]:
    sys.exit(1 if scenario == "missing_context" else 0)
if "--context" not in args or args[args.index("--context") + 1] != "otel-demo-aws":
    sys.exit("Validation used the wrong context")
if "get" in args and "application" in args:
    if scenario == "unauthorized":
        sys.exit("Unauthorized")
    output = args[args.index("--output") + 1] if "--output" in args else ""
    if output == "jsonpath={.status.sync.status}":
        print("Synced")
    elif output == "jsonpath={.status.health.status}":
        print("Degraded" if scenario == "degraded" else "Healthy")
    else:
        print("otel-demo-aws Synced Healthy")
elif "get" in args and "deployments" in args:
    print("deployment/recommendation\ndeployment/ad\ndeployment/product-catalog")
elif "rollout" in args:
    sys.exit(1 if scenario == "rollout_failure" else 0)
elif "get" in args and "pods" in args:
    output = args[args.index("--output") + 1] if "--output" in args else ""
    if output.startswith("jsonpath="):
        selector = args[args.index("--selector") + 1]
        service = selector.split("=", 1)[1]
        if scenario == "missing_image" and service == "ad":
            pass
        elif scenario == "kind_image" and service == "ad":
            print("ghcr.io/lackito/otel-demo-kind-ad:" + "a"*40)
        elif service == "product-catalog":
            print("ghcr.io/open-telemetry/demo:2.1.3-product-catalog")
        else:
            print("650032249451.dkr.ecr.us-east-1.amazonaws.com/" + service + ":" + "a"*40)
    else:
        print("pod summary and image IDs")
else:
    print("diagnostic summary")
'''


class ApplicationValidateTests(unittest.TestCase):
    def run_validation(self, scenario="success", **overrides):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            kubectl = root / "kubectl"
            kubectl.write_text(MOCK_KUBECTL)
            kubectl.chmod(0o755)
            sleeper = root / "sleep"
            sleeper.write_text("#!/bin/sh\nexit 0\n")
            sleeper.chmod(0o755)
            log = root / "calls.jsonl"
            env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                       SCENARIO=scenario, CALL_LOG=str(log), AWS_CLUSTER_CONTEXT="otel-demo-aws",
                       APPLICATION_VALIDATE_TIMEOUT_SECONDS="2", APPLICATION_VALIDATE_POLL_SECONDS="1")
            env.update(overrides)
            result = subprocess.run(["bash", str(SCRIPT)], env=env, text=True,
                                    capture_output=True, timeout=10)
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            return result, calls

    def test_reports_three_images_including_upstream_bootstrap(self):
        result, calls = self.run_validation()
        self.assertEqual(result.returncode, 0, result.stderr)
        for label in ("Recommendation", "Ad", "Product Catalog"):
            self.assertIn(label + " image:", result.stdout)
        self.assertIn("ghcr.io/open-telemetry/demo:2.1.3-product-catalog", result.stdout)
        self.assertIn("Custom service pod image IDs", result.stdout)
        self.assertFalse(any(token in ("apply", "patch", "delete", "annotate")
                             for call in calls for token in call))

    def test_missing_context_fails(self):
        result, _ = self.run_validation("missing_context")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Expected context", result.stderr)

    def test_expired_authentication_fails_promptly(self):
        result, calls = self.run_validation("unauthorized")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unauthorized", result.stderr)
        self.assertEqual(len(calls), 2)

    def test_degraded_application_fails(self):
        result, _ = self.run_validation("degraded")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not become Synced and Healthy", result.stderr)

    def test_failed_rollout_fails(self):
        result, _ = self.run_validation("rollout_failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("AWS application validation passed", result.stdout)

    def test_missing_image_fails(self):
        result, _ = self.run_validation("missing_image")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ad workload image could not be found", result.stderr)

    def test_kind_image_in_aws_fails(self):
        result, _ = self.run_validation("kind_image")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("kind development image", result.stderr)

    def test_kind_context_is_rejected_before_cluster_access(self):
        result, calls = self.run_validation(AWS_CLUSTER_CONTEXT="kind-otel-demo")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires an EKS context", result.stderr)
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
