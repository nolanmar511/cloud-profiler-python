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
# Force IPv4 to prevent long IPv6 timeouts.
# TODO : Validate this solves the issue. Remove if not.
retry apt-get -o Acquire::ForceIPv4=true update >/dev/null
# Second line is pyenv dependencies
retry apt-get -o Acquire::ForceIPv4=true install -yq git build-essential \
make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev >/dev/ttyS2

# Install Python
retry curl https://pyenv.run | bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init)"

pyenv install 3.5.9
pyenv global 3.5.9
python3.5 --version
export PATH="$HOME/.pyenv/versions/3.5.9/lib/python3.5/site-packages:$PATH"


# Install Python dependencies.
retry wget -O /tmp/get-pip.py "https://bootstrap.pypa.io/2.7/get-pip.py" >/dev/null
retry python3.5 /tmp/get-pip.py >/dev/null
retry python3.5 -m pip install --upgrade pyasn1 >/dev/null

# Setup pipenv
retry python3.5 -m pip install pipenv > /dev/null

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
retry python3.5 -m pip install --ignore-installed "$AGENT_PATH"

# Run bench app.
python3.5 bench.py

# Wait for agent to stop due to some error.