"""
Generate continuous load on Microsoft Fabric capacity to test auto-scaling.

This script can be run in a Fabric Notebook to generate sustained CPU load
by executing computationally intensive operations.

Usage:
    1. Create a new Fabric Notebook in your workspace
    2. Copy this code into a cell
    3. Update the configuration parameters
    4. Run the cell to generate load
"""

import time
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# ========== CONFIGURATION ==========
DURATION_MINUTES = 10  # How long to generate load
TARGET_UTILIZATION = 85  # Target CPU % (for reference only)
OPERATION_TYPE = 'compute'  # 'compute', 'memory', or 'mixed'
# ===================================

def generate_compute_load():
    """Generate CPU-intensive computation"""
    # Matrix multiplication (CPU intensive)
    size = 2000
    matrix_a = np.random.rand(size, size)
    matrix_b = np.random.rand(size, size)
    result = np.dot(matrix_a, matrix_b)
    
    # Additional computation
    result_sum = np.sum(result)
    result_mean = np.mean(result)
    result_std = np.std(result)
    
    return result_sum

def generate_memory_load():
    """Generate memory-intensive operations"""
    # Create large DataFrames
    size = 1_000_000
    df_list = []
    
    for i in range(10):
        df = pd.DataFrame({
            'id': range(size),
            'value1': np.random.rand(size),
            'value2': np.random.rand(size),
            'value3': np.random.rand(size),
            'category': np.random.choice(['A', 'B', 'C', 'D', 'E'], size)
        })
        
        # Perform aggregations
        grouped = df.groupby('category').agg({
            'value1': ['sum', 'mean', 'std'],
            'value2': ['sum', 'mean', 'std'],
            'value3': ['sum', 'mean', 'std']
        })
        
        df_list.append(grouped)
    
    # Concatenate results
    result = pd.concat(df_list)
    return len(result)

def generate_mixed_load():
    """Generate mixed CPU and memory load"""
    # 50% compute, 50% memory
    if np.random.rand() > 0.5:
        return generate_compute_load()
    else:
        return generate_memory_load()

# Main load generation loop
print("=" * 60)
print("🔥 FABRIC CAPACITY LOAD GENERATOR")
print("=" * 60)
print(f"⏱️  Duration: {DURATION_MINUTES} minutes")
print(f"🎯 Target Utilization: {TARGET_UTILIZATION}%")
print(f"⚙️  Operation Type: {OPERATION_TYPE}")
print(f"🕒 Start Time: {datetime.now().strftime('%H:%M:%S')}")

end_time = datetime.now() + timedelta(minutes=DURATION_MINUTES)
iteration = 0
results = []

print("\n⚡ Generating load... (Stop the cell to terminate)\n")

try:
    while datetime.now() < end_time:
        iteration += 1
        start = time.time()
        
        # Generate load based on configuration
        if OPERATION_TYPE == 'compute':
            result = generate_compute_load()
            op_type = "Compute"
        elif OPERATION_TYPE == 'memory':
            result = generate_memory_load()
            op_type = "Memory"
        else:  # mixed
            result = generate_mixed_load()
            op_type = "Mixed"
        
        elapsed = time.time() - start
        current_time = datetime.now().strftime('%H:%M:%S')
        remaining = (end_time - datetime.now()).total_seconds() / 60
        
        print(f"[{current_time}] Iteration {iteration:3d} | {op_type:7s} | "
              f"Elapsed: {elapsed:.2f}s | Remaining: {remaining:.1f} min")
        
        results.append({
            'iteration': iteration,
            'timestamp': datetime.now(),
            'operation': op_type,
            'elapsed_seconds': elapsed,
            'result': result
        })
        
        # Small pause between iterations (adjust for desired intensity)
        time.sleep(2)

except KeyboardInterrupt:
    print("\n⚠️  Load generation interrupted by user")

print("\n" + "=" * 60)
print("✅ LOAD GENERATION COMPLETE")
print("=" * 60)
print(f"📊 Total Iterations: {iteration}")
print(f"⏱️  Total Duration: {(datetime.now() - (end_time - timedelta(minutes=DURATION_MINUTES))).total_seconds() / 60:.1f} minutes")
print(f"🕒 End Time: {datetime.now().strftime('%H:%M:%S')}")
print("\n💡 Next Steps:")
print("   1. Check Capacity Metrics App for utilization increase")
print("   2. Monitor Logic App run history for scale-up action")
print("   3. Verify capacity SKU change in Azure Portal")
print("=" * 60)

# Display summary statistics
if results:
    df_results = pd.DataFrame(results)
    print("\n📈 Performance Summary:")
    print(df_results.groupby('operation')['elapsed_seconds'].agg(['count', 'mean', 'min', 'max']))
