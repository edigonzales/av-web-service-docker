#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./build-and-publish.sh <image-name> <version>
#
# Example:
#   ./build-and-publish.sh ghcr.io/my-org/avws 1.0.0
#
# Optional env vars:
#   DOCKERFILE=Dockerfile
#   UID_ARG=1001
#   JAR_FILE=build/libs/avws.jar
#   PUSH_LATEST=true|false (default: true)
#   DOCKER_USERNAME=...
#   DOCKER_PASSWORD=...

IMAGE_NAME="${1:?Usage: $0 <image-name> <version>}"
VERSION="${2:?Usage: $0 <image-name> <version>}"

DOCKERFILE="${DOCKERFILE:-Dockerfile}"
UID_ARG="${UID_ARG:-1001}"
JAR_FILE="${JAR_FILE:-build/libs/avws.jar}"
PUSH_LATEST="${PUSH_LATEST:-true}"

DOCKER_USER="${DOCKER_USERNAME:-}"
DOCKER_PASS="${DOCKER_PASSWORD:-}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

echo "Checking prerequisites..."
require_cmd bash
require_cmd docker
require_cmd java

JAVA_VERSION_OUTPUT="$(java -version 2>&1 || true)"
echo "$JAVA_VERSION_OUTPUT" | grep -Eq 'version "21|openjdk version "21' \
  || die "Java 21 not detected. java -version output was: $JAVA_VERSION_OUTPUT"

[[ -f "$DOCKERFILE" ]] || die "Dockerfile not found: $DOCKERFILE"

echo "Running Gradle build (includes frontend)..."
./gradlew clean build

[[ -f "$JAR_FILE" ]] || die "Expected jar not found: $JAR_FILE"

echo "Building Docker image..."
docker build \
  --pull \
  --no-cache \
  --force-rm \
  --build-arg "JAR_FILE=$JAR_FILE" \
  --build-arg "UID=$UID_ARG" \
  -t "${IMAGE_NAME}:${VERSION}" \
  -f "$DOCKERFILE" \
  .

if [[ "$PUSH_LATEST" == "true" ]]; then
  docker tag "${IMAGE_NAME}:${VERSION}" "${IMAGE_NAME}:latest"
fi

if [[ -n "$DOCKER_USER" && -n "$DOCKER_PASS" ]]; then
  echo "Logging in to container registry..."
  printf '%s' "$DOCKER_PASS" | docker login --username "$DOCKER_USER" --password-stdin
else
  echo "No DOCKER_USERNAME/DOCKER_PASSWORD provided; assuming existing docker login."
fi

echo "Pushing Docker image tags..."
docker push "${IMAGE_NAME}:${VERSION}"
if [[ "$PUSH_LATEST" == "true" ]]; then
  docker push "${IMAGE_NAME}:latest"
fi

echo "Done:"
echo "  ${IMAGE_NAME}:${VERSION}"
if [[ "$PUSH_LATEST" == "true" ]]; then
  echo "  ${IMAGE_NAME}:latest"
fi
