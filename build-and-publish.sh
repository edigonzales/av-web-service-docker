#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   DOCKERHUB_USERNAME=... DOCKERHUB_TOKEN=... ./build-and-push.sh <docker-image-name> <version>
#
# Example:
#   DOCKERHUB_USERNAME=myuser DOCKERHUB_TOKEN=*** ./build-and-push.sh myuser/avws 1.0.0
#
# Optional env vars:
#   SCRIPT_FILE=avws.java
#   DOCKERFILE=Dockerfile
#   UID_ARG=1001
#   JAR_FILE=tmp/application.jar
#   JBANG_EXPORT_MODE=fatjar     # fatjar | portable | local
#   DOCKERHUB_PASSWORD=...       # alternative to DOCKERHUB_TOKEN

IMAGE_NAME="${1:?Usage: $0 <docker-image-name> <version>}"
VERSION="${2:?Usage: $0 <docker-image-name> <version>}"

SCRIPT_FILE="${SCRIPT_FILE:-avws.java}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
UID_ARG="${UID_ARG:-1001}"
JAR_FILE="${JAR_FILE:-tmp/application.jar}"
JBANG_EXPORT_MODE="${JBANG_EXPORT_MODE:-fatjar}"

DOCKER_USER="${DOCKERHUB_USERNAME:-${DOCKER_USERNAME:-}}"
DOCKER_PASS="${DOCKERHUB_TOKEN:-${DOCKERHUB_PASSWORD:-${DOCKER_PASSWORD:-}}}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

echo "Checking prerequisites..."
require_cmd curl
require_cmd bash
require_cmd docker
require_cmd java

JAVA_VERSION_OUTPUT="$(java -version 2>&1 || true)"
echo "$JAVA_VERSION_OUTPUT" | grep -Eq 'version "21|openjdk version "21' \
  || die "Java 21 not detected. java -version output was: $JAVA_VERSION_OUTPUT"

[[ -f "$SCRIPT_FILE" ]] || die "Script file not found: $SCRIPT_FILE"
[[ -f "$DOCKERFILE" ]] || die "Dockerfile not found: $DOCKERFILE"

mkdir -p "$(dirname "$JAR_FILE")"

echo "Exporting $SCRIPT_FILE via JBang Zero Install..."
# JBang ohne vorgängige Installation ausführen.
# fatjar passt zu einem Dockerfile, das genau ein JAR_FILE erwartet.
curl -Ls https://sh.jbang.dev | bash -s - export "$JBANG_EXPORT_MODE" \
  --force \
  --output "$JAR_FILE" \
  "$SCRIPT_FILE"

[[ -f "$JAR_FILE" ]] || die "Expected exported jar not found: $JAR_FILE"

echo "Building Docker image..."
docker build \
  --pull \
  --no-cache \
  --force-rm \
  --build-arg "JAR_FILE=$JAR_FILE" \
  --build-arg "UID=$UID_ARG" \
  -t "${IMAGE_NAME}:${VERSION}" \
  -t "${IMAGE_NAME}:latest" \
  -f "$DOCKERFILE" \
  .

if [[ -n "$DOCKER_USER" && -n "$DOCKER_PASS" ]]; then
  echo "Logging in to Docker Hub..."
  printf '%s' "$DOCKER_PASS" | docker login --username "$DOCKER_USER" --password-stdin
else
  echo "No Docker credentials env vars found; assuming docker login already exists."
fi

echo "Pushing Docker image tags..."
docker push "${IMAGE_NAME}:${VERSION}"
docker push "${IMAGE_NAME}:latest"

echo "Done:"
echo "  ${IMAGE_NAME}:${VERSION}"
echo "  ${IMAGE_NAME}:latest"