#!/usr/bin/env python3

import hashlib
import os
import shutil
import ssl
import sys
import urllib.request


def download_with_no_cert_check(url: str, destination: str):
    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = False
    ssl_ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(url, context=ssl_ctx) as response, open(destination, "wb") as out_file:
        shutil.copyfileobj(response, out_file)


def sha512sum(filepath: str) -> str:
    sha512 = hashlib.sha512()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha512.update(chunk)
    return sha512.hexdigest().lower()


def main():
    runner_tool_cache = os.environ.get("RUNNER_TOOL_CACHE", "")
    jbr_url = os.environ.get("JBR_URL", "")
    jbr_checksum_url = os.environ.get("JBR_CHECKSUM_URL", "")
    github_output = os.environ.get("GITHUB_OUTPUT", "")

    if not runner_tool_cache or not jbr_url or not jbr_checksum_url:
        print("Missing RUNNER_TOOL_CACHE, JBR_URL, or JBR_CHECKSUM_URL.", file=sys.stderr)
        sys.exit(1)

    os.makedirs(runner_tool_cache, exist_ok=True)
    jbr_filename = jbr_url.split("/")[-1]
    jbr_location = os.path.join(runner_tool_cache, jbr_filename)

    if github_output:
        with open(github_output, "a", encoding="utf-8") as f:
            f.write(f"jbrLocation={jbr_location}\n")

    checksum_file = "checksum.tmp"
    download_with_no_cert_check(jbr_checksum_url, checksum_file)
    with open(checksum_file, "r", encoding="utf-8") as cf:
        expected_checksum = cf.readline().strip().split()[0].lower()

    file_checksum = sha512sum(jbr_location) if os.path.isfile(jbr_location) else ""
    if file_checksum != expected_checksum:
        download_with_no_cert_check(jbr_url, jbr_location)
        file_checksum = sha512sum(jbr_location)

    try:
        os.remove(checksum_file)
    except OSError:
        pass

    if file_checksum != expected_checksum:
        print("JBR checksum verification failed.", file=sys.stderr)
        sys.exit(1)

    print("JBR downloaded and verified.")


if __name__ == "__main__":
    main()
