#!/usr/bin/env python3
"""
Advanced SwiftUI Navigation Analyzer
Extracts navigation patterns from SwiftUI code
"""

import re
import os
import json
from pathlib import Path
from collections import defaultdict

class NavigationAnalyzer:
    def __init__(self, project_path='.'):
        self.project_path = Path(project_path)
        self.views = {}
        self.navigation_graph = defaultdict(list)
        
    def find_swift_files(self):
        """Find all Swift files in the project"""
        return list(self.project_path.rglob("*.swift"))
    
    def extract_views(self, content, filename):
        """Extract SwiftUI View definitions"""
        # Find struct definitions that conform to View
        view_pattern = r'struct\s+(\w+)\s*:\s*(?:.*\s+)?View\s*{'
        views = re.findall(view_pattern, content)
        
        # Also find class-based views
        class_pattern = r'class\s+(\w+)\s*:\s*(?:.*\s+)?(?:UIViewController|UIView)'
        views.extend(re.findall(class_pattern, content))
        
        return views
    
    def extract_navigation_patterns(self, content, source_file):
        """Extract all navigation patterns from content"""
        patterns = {
            'navigation_links': [],
            'sheets': [],
            'fullscreen_covers': [],
            'tab_items': [],
            'navigation_destinations': []
        }
        
        # Extract file name without extension
        source_view = Path(source_file).stem
        
        # NavigationLink patterns
        # Pattern 1: NavigationLink(destination: SomeView())
        nav_pattern1 = r'NavigationLink\s*\(\s*destination\s*:\s*(\w+)\s*\('
        patterns['navigation_links'].extend(re.findall(nav_pattern1, content))
        
        # Pattern 2: NavigationLink { SomeView() }
        nav_pattern2 = r'NavigationLink\s*\{[^}]*?(\w+View)\s*\('
        patterns['navigation_links'].extend(re.findall(nav_pattern2, content))
        
        # Pattern 3: NavigationLink("Title", destination: SomeView())
        nav_pattern3 = r'NavigationLink\s*\([^,]+,\s*destination\s*:\s*(\w+)\s*\('
        patterns['navigation_links'].extend(re.findall(nav_pattern3, content))
        
        # Sheet presentations
        # .sheet(isPresented: $showing) { SomeView() }
        sheet_pattern1 = r'\.sheet\s*\([^)]+\)\s*\{[^}]*?(\w+View)\s*\('
        patterns['sheets'].extend(re.findall(sheet_pattern1, content))
        
        # .sheet(item: $item) { item in SomeView() }
        sheet_pattern2 = r'\.sheet\s*\(item:[^)]+\)\s*\{[^}]*?(\w+View)\s*\('
        patterns['sheets'].extend(re.findall(sheet_pattern2, content))
        
        # FullScreenCover
        fullscreen_pattern = r'\.fullScreenCover\s*\([^)]+\)\s*\{[^}]*?(\w+View)\s*\('
        patterns['fullscreen_covers'].extend(re.findall(fullscreen_pattern, content))
        
        # NavigationDestination (iOS 16+)
        nav_dest_pattern = r'\.navigationDestination\s*\([^)]+\)\s*\{[^}]*?(\w+View)\s*\('
        patterns['navigation_destinations'].extend(re.findall(nav_dest_pattern, content))
        
        # TabView items - look for views inside TabView
        if 'TabView' in content:
            # Extract content between TabView { and }
            tabview_matches = re.finditer(r'TabView\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}', content, re.DOTALL)
            for match in tabview_matches:
                tabview_content = match.group(1)
                # Find views within TabView
                tab_views = re.findall(r'(\w+View)\s*\(', tabview_content)
                patterns['tab_items'].extend(tab_views)
        
        return patterns
    
    def analyze_file(self, filepath):
        """Analyze a single Swift file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            filename = filepath.name
            
            # Extract views defined in this file
            views = self.extract_views(content, filename)
            if views:
                self.views[filename] = views
            
            # Extract navigation patterns
            patterns = self.extract_navigation_patterns(content, filename)
            
            # Build navigation graph
            source = Path(filepath).stem
            
            for dest in patterns['navigation_links']:
                self.navigation_graph[source].append(('nav', dest))
            
            for dest in patterns['sheets']:
                self.navigation_graph[source].append(('sheet', dest))
            
            for dest in patterns['fullscreen_covers']:
                self.navigation_graph[source].append(('fullscreen', dest))
                
            for dest in patterns['navigation_destinations']:
                self.navigation_graph[source].append(('nav_dest', dest))
            
            return patterns
            
        except Exception as e:
            print(f"Error analyzing {filepath}: {e}")
            return None
    
    def generate_mermaid_diagram(self):
        """Generate Mermaid diagram from navigation graph"""
        mermaid = ["graph TD"]
        
        # Add nodes with styling
        mermaid.append("    %% Define node styles")
        mermaid.append("    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;")
        mermaid.append("    classDef sheet fill:#ffe4b5,stroke:#ff8c00,stroke-width:2px;")
        mermaid.append("    classDef nav fill:#e6f3ff,stroke:#4169e1,stroke-width:2px;")
        
        # Add edges
        edge_id = 0
        for source, destinations in self.navigation_graph.items():
            for nav_type, dest in destinations:
                edge_id += 1
                if nav_type == 'sheet':
                    mermaid.append(f"    {source} -.->|sheet| {dest}")
                    mermaid.append(f"    class {dest} sheet;")
                elif nav_type == 'fullscreen':
                    mermaid.append(f"    {source} ==>|fullscreen| {dest}")
                else:
                    mermaid.append(f"    {source} -->|nav| {dest}")
                    mermaid.append(f"    class {dest} nav;")
        
        return '\n'.join(mermaid)
    
    def generate_dot_diagram(self):
        """Generate GraphViz DOT diagram"""
        dot = ['digraph NavigationFlow {']
        dot.append('    rankdir=TB;')
        dot.append('    node [shape=box, style="rounded,filled", fillcolor=lightblue];')
        dot.append('    edge [fontsize=10];')
        dot.append('')
        
        # Add edges
        for source, destinations in self.navigation_graph.items():
            for nav_type, dest in destinations:
                if nav_type == 'sheet':
                    dot.append(f'    "{source}" -> "{dest}" [label="sheet", style=dashed, color=orange];')
                elif nav_type == 'fullscreen':
                    dot.append(f'    "{source}" -> "{dest}" [label="fullscreen", style=bold, color=red];')
                else:
                    dot.append(f'    "{source}" -> "{dest}" [label="nav", color=blue];')
        
        dot.append('}')
        return '\n'.join(dot)
    
    def generate_report(self):
        """Generate analysis report"""
        report = []
        report.append("SwiftUI Navigation Analysis Report")
        report.append("=" * 50)
        report.append(f"Total Swift files analyzed: {len(list(self.find_swift_files()))}")
        report.append(f"Total views found: {sum(len(v) for v in self.views.values())}")
        report.append(f"Total navigation connections: {sum(len(v) for v in self.navigation_graph.values())}")
        report.append("")
        
        # Count navigation types
        nav_types = defaultdict(int)
        for dests in self.navigation_graph.values():
            for nav_type, _ in dests:
                nav_types[nav_type] += 1
        
        report.append("Navigation breakdown:")
        for nav_type, count in nav_types.items():
            report.append(f"  - {nav_type}: {count}")
        
        report.append("")
        report.append("Top source views (most outgoing connections):")
        sorted_sources = sorted(
            [(k, len(v)) for k, v in self.navigation_graph.items()],
            key=lambda x: x[1],
            reverse=True
        )[:10]
        for source, count in sorted_sources:
            report.append(f"  - {source}: {count} connections")
        
        # Find orphaned views (views with no incoming connections)
        all_destinations = set()
        for dests in self.navigation_graph.values():
            for _, dest in dests:
                all_destinations.add(dest)
        
        all_sources = set(self.navigation_graph.keys())
        orphaned = all_sources - all_destinations
        
        if orphaned:
            report.append("")
            report.append("Potential root views (no incoming connections):")
            for view in sorted(orphaned):
                report.append(f"  - {view}")
        
        return '\n'.join(report)
    
    def run_analysis(self):
        """Run the complete analysis"""
        print("Starting SwiftUI navigation analysis...")
        
        # Create output directory
        output_dir = Path("navigation_analysis")
        output_dir.mkdir(exist_ok=True)
        
        # Analyze all Swift files
        swift_files = self.find_swift_files()
        print(f"Found {len(swift_files)} Swift files")
        
        for filepath in swift_files:
            self.analyze_file(filepath)
        
        # Generate outputs
        print("Generating diagrams and reports...")
        
        # Mermaid diagram
        with open(output_dir / "navigation.mmd", "w") as f:
            f.write(self.generate_mermaid_diagram())
        
        # DOT diagram
        with open(output_dir / "navigation.dot", "w") as f:
            f.write(self.generate_dot_diagram())
        
        # JSON data
        nav_data = {
            "views": self.views,
            "navigation": {k: [{"type": t, "destination": d} for t, d in v] 
                          for k, v in self.navigation_graph.items()}
        }
        with open(output_dir / "navigation_data.json", "w") as f:
            json.dump(nav_data, f, indent=2)
        
        # Text report
        with open(output_dir / "report.txt", "w") as f:
            f.write(self.generate_report())
        
        # Print summary
        print("\nAnalysis complete!")
        print(f"Results saved to {output_dir}/")
        print(f"  - navigation.mmd: Mermaid diagram")
        print(f"  - navigation.dot: GraphViz diagram")
        print(f"  - navigation_data.json: Raw navigation data")
        print(f"  - report.txt: Analysis report")

if __name__ == "__main__":
    analyzer = NavigationAnalyzer()
    analyzer.run_analysis()