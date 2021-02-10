import sys
import threading
import time
import traceback
import googlecloudprofiler
import random

# Use recursion to generate lots of random call stacks.
def python_bench1(calls):
  for counter in range(1, 50):
    pass
  if calls > 0:
    if random.random() < 0.5:
      python_bench1(calls-1)
    else:
      python_bench2(calls-1)

def python_bench2(calls):
  for counter in range(1, 50):
    pass
  if calls > 0:
    if random.random() < 0.5:
      python_bench1(calls-1)
    else:
      python_bench2(calls-1)

def repeat_bench():
  while True:
    python_bench1(50)

def logging():
  while True:
    print('The benchmark is running.')
    time.sleep(60)

if __name__ == '__main__':
  try:
    googlecloudprofiler.start(
          project_id='glassy-azimuth-303722',
          service='app',
          verbose=3)
  except BaseException:  # pylint: disable=broad-except
    sys.exit('Failed to start the profiler: %s' % traceback.format_exc())
  print('Profiler started.')
  logging_thread = threading.Thread(target=logging)
  logging_thread.daemon = True
  logging_thread.start()
  repeat_bench()
  print('repeat_bench finished.')

