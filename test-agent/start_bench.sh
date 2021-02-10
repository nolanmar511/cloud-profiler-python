retry() {
  for i in {1..3}; do
    [ $i == 1 ] || sleep 10  # Backing off after a failed attempt.
    "${@}" && return 0
  done
  return 1
}

# Fail on any error.
set -eo pipefail

# Display commands being run
set -x

# Install dependencies.
# ppa:deadsnakes/ppa contains desired Python versions.
retry add-apt-repository -y ppa:deadsnakes/ppa >/dev/null
# Force IPv4 to prevent long IPv6 timeouts.
# TODO : Validate this solves the issue. Remove if not.
retry apt-get -o Acquire::ForceIPv4=true update >/dev/null
retry apt-get -o Acquire::ForceIPv4=true install -yq git build-essential python3-distutils python3.5-dev python3.5 >/dev/ttyS2

# Install Python dependencies.
retry wget -O /tmp/get-pip.py "https://bootstrap.pypa.io/2.7/get-pip.py" >/dev/null
retry python3.5 /tmp/get-pip.py >/dev/null
retry python3.5 -m pip install --upgrade pyasn1 >/dev/null

# Setup pipenv
retry python3.5 -m pip install pipenv > /dev/null
mkdir bench && cd bench
retry pipenv install > /dev/null

# Fetch agent.
retry apt-get update
retry apt-get install git

git clone https://github.com/nolanmar511/cloud-profiler-python.git
cd cloud-profiler-python
git fetch origin profile-loop:profile-loop
git checkout profile-loop

# Build agent
retry python3.5 -m pip install --user --upgrade setuptools wheel twine
python3.5 setup.py sdist
AGENT_PATH=$(find "$PWD/dist" -name "google-cloud-profiler*")

# Move agent benchmark
cd ..
cp -r cloud-profiler-python/test-agent .
cd test-agent

# Install agent.
retry pipenv run python3.5 -m pip install --ignore-installed "$AGENT_PATH"

# Run bench app.
pipenv run python3.5 bench.py

# Wait for agent to stop due to some error.