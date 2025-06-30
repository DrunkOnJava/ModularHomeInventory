#!/usr/bin/env python3
"""
Parse performance test results from xcresult and generate a summary report.
"""

import json
import sys
import statistics
from typing import Dict, List, Any

def parse_performance_metrics(json_path: str) -> str:
    """Parse performance metrics from xcresult JSON output."""
    
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    metrics = extract_metrics(data)
    report = generate_report(metrics)
    
    return report

def extract_metrics(data: Dict[str, Any]) -> Dict[str, List[float]]:
    """Extract performance metrics from test results."""
    
    metrics = {
        'launch_time': [],
        'memory_usage': [],
        'cpu_usage': [],
        'disk_writes': [],
        'response_time': []
    }
    
    # Navigate through the JSON structure to find test results
    if 'actions' in data:
        for action in data['actions']['_values']:
            if 'actionResult' in action:
                parse_action_result(action['actionResult'], metrics)
    
    return metrics

def parse_action_result(result: Dict[str, Any], metrics: Dict[str, List[float]]):
    """Parse individual test action results."""
    
    if 'testsRef' not in result:
        return
    
    tests = result.get('testsRef', {}).get('_values', [])
    
    for test in tests:
        if 'subtests' in test:
            for subtest in test['subtests']['_values']:
                parse_performance_test(subtest, metrics)

def parse_performance_test(test: Dict[str, Any], metrics: Dict[str, List[float]]):
    """Parse individual performance test metrics."""
    
    if 'performanceMetrics' not in test:
        return
    
    perf_metrics = test['performanceMetrics'].get('_values', [])
    
    for metric in perf_metrics:
        metric_type = metric.get('identifier', {}).get('_value', '')
        measurements = metric.get('measurements', {}).get('_values', [])
        
        for measurement in measurements:
            value = measurement.get('_value', 0)
            
            if 'launch' in metric_type.lower():
                metrics['launch_time'].append(value)
            elif 'memory' in metric_type.lower():
                metrics['memory_usage'].append(value / 1024 / 1024)  # Convert to MB
            elif 'cpu' in metric_type.lower():
                metrics['cpu_usage'].append(value * 100)  # Convert to percentage
            elif 'disk' in metric_type.lower():
                metrics['disk_writes'].append(value / 1024 / 1024)  # Convert to MB
            elif 'duration' in metric_type.lower():
                metrics['response_time'].append(value * 1000)  # Convert to ms

def generate_report(metrics: Dict[str, List[float]]) -> str:
    """Generate a markdown report from metrics."""
    
    report = ["# Performance Test Results\n"]
    report.append("## Summary\n")
    
    # Launch time
    if metrics['launch_time']:
        avg_launch = statistics.mean(metrics['launch_time'])
        report.append(f"- **Average Launch Time**: {avg_launch:.2f}ms")
        report.append(f"  - Min: {min(metrics['launch_time']):.2f}ms")
        report.append(f"  - Max: {max(metrics['launch_time']):.2f}ms")
        report.append(f"  - Std Dev: {statistics.stdev(metrics['launch_time']):.2f}ms\n")
    
    # Memory usage
    if metrics['memory_usage']:
        avg_memory = statistics.mean(metrics['memory_usage'])
        report.append(f"- **Average Memory Usage**: {avg_memory:.1f}MB")
        report.append(f"  - Peak: {max(metrics['memory_usage']):.1f}MB\n")
    
    # CPU usage
    if metrics['cpu_usage']:
        avg_cpu = statistics.mean(metrics['cpu_usage'])
        report.append(f"- **Average CPU Usage**: {avg_cpu:.1f}%")
        report.append(f"  - Peak: {max(metrics['cpu_usage']):.1f}%\n")
    
    # Response time
    if metrics['response_time']:
        percentiles = calculate_percentiles(metrics['response_time'])
        report.append(f"- **Response Time**:")
        report.append(f"  - P50: {percentiles['p50']:.2f}ms")
        report.append(f"  - P90: {percentiles['p90']:.2f}ms")
        report.append(f"  - P99: {percentiles['p99']:.2f}ms\n")
    
    # Performance grade
    grade = calculate_performance_grade(metrics)
    report.append(f"## Overall Performance Grade: {grade}\n")
    
    # Recommendations
    recommendations = generate_recommendations(metrics)
    if recommendations:
        report.append("## Recommendations\n")
        for rec in recommendations:
            report.append(f"- {rec}")
    
    return "\n".join(report)

def calculate_percentiles(values: List[float]) -> Dict[str, float]:
    """Calculate percentiles for a list of values."""
    
    sorted_values = sorted(values)
    n = len(sorted_values)
    
    return {
        'p50': sorted_values[int(n * 0.5)],
        'p90': sorted_values[int(n * 0.9)],
        'p99': sorted_values[int(n * 0.99)]
    }

def calculate_performance_grade(metrics: Dict[str, List[float]]) -> str:
    """Calculate an overall performance grade."""
    
    score = 100
    
    # Deduct points for poor metrics
    if metrics['launch_time'] and statistics.mean(metrics['launch_time']) > 1000:
        score -= 20  # Launch time over 1 second
    
    if metrics['memory_usage'] and max(metrics['memory_usage']) > 200:
        score -= 15  # Memory usage over 200MB
    
    if metrics['cpu_usage'] and statistics.mean(metrics['cpu_usage']) > 50:
        score -= 15  # Average CPU over 50%
    
    if metrics['response_time'] and calculate_percentiles(metrics['response_time'])['p90'] > 100:
        score -= 10  # P90 response time over 100ms
    
    # Convert to grade
    if score >= 90:
        return "A ✅"
    elif score >= 80:
        return "B 👍"
    elif score >= 70:
        return "C ⚠️"
    elif score >= 60:
        return "D 🚨"
    else:
        return "F ❌"

def generate_recommendations(metrics: Dict[str, List[float]]) -> List[str]:
    """Generate performance improvement recommendations."""
    
    recommendations = []
    
    if metrics['launch_time'] and statistics.mean(metrics['launch_time']) > 1000:
        recommendations.append("⚡ Optimize app launch time - consider lazy loading and reducing initial work")
    
    if metrics['memory_usage'] and max(metrics['memory_usage']) > 200:
        recommendations.append("💾 High memory usage detected - review image caching and data structures")
    
    if metrics['cpu_usage'] and statistics.mean(metrics['cpu_usage']) > 50:
        recommendations.append("🔥 High CPU usage - profile and optimize compute-intensive operations")
    
    if metrics['response_time']:
        p90 = calculate_percentiles(metrics['response_time'])['p90']
        if p90 > 100:
            recommendations.append("⏱️ Slow response times - consider optimizing database queries and network calls")
    
    return recommendations

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: parse_performance_metrics.py <json_file>")
        sys.exit(1)
    
    report = parse_performance_metrics(sys.argv[1])
    print(report)