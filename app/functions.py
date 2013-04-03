import time, psutil 

def getCpuLoad():
    """
    Returns the cpu load as a value from the interval [0.0, 1.0]
    """
    load=psutil.cpu_percent(interval=1, percpu=False)
    return load